import '../config/api_config.dart';
import '../models/profile_models.dart';
import '../services/static_data_service.dart';

/// Get gender-based placeholder image
String getGenderPlaceholder(String? gender) {
  if (gender == null) return 'assets/images/girl-placeholder-lazy.png';
  final normalized = gender.trim().toUpperCase();
  if (normalized == 'M' || normalized == 'MALE') {
    return 'assets/images/boy-planceholder-lazy.png';
  }
  return 'assets/images/girl-placeholder-lazy.png';
}

/// Build profile image URL from clientId and imageId
String buildImageUrl(String clientId, String imageId) {
  return ApiConfig.buildImageUrl(clientId, imageId);
}

/// Get first profile image URL from ApiProfile
String? getProfileImageUrl(ApiProfile profile) {
  if (profile.profilePic != null && profile.profilePic!.isNotEmpty) {
    final pic = profile.profilePic!.first;
    if (pic.s3Link != null && pic.id != null) {
      final clientId = profile.clientID ?? profile.id ?? '';
      return buildImageUrl(clientId, pic.id!);
    }
  }
  return null;
}

/// Transform API profile to display format
Map<String, dynamic> transformProfile(
  ApiProfile apiProfile, {
  Map<String, List<LookupOption>>? lookupData,
  List<LookupOption>? countries,
  String? dob,
}) {
  // Calculate age from DOB if available (prioritize apiProfile.dob, then parameter dob)
  int? age;
  final dobToUse = apiProfile.dob ?? dob;
  if (dobToUse != null && dobToUse.isNotEmpty) {
    try {
      final dobDate = DateTime.parse(dobToUse);
      age = calculateAge(dobDate);
    } catch (_) {
      // If parsing fails, try to calculate from age field if available
      age = apiProfile.age;
    }
  } else {
    // Fallback to age field if DOB is not available
    age = apiProfile.age;
  }

  // Get location labels - use static data for cities, states, countries (fast, no API call)
  String location = '';
  final staticDataService = StaticDataService.instance;

  String? cityLabel;
  if (apiProfile.city != null && apiProfile.city!.isNotEmpty) {
    // Try static data first (fast, synchronous if already loaded)
    if (staticDataService.isCitiesLoaded) {
      cityLabel = staticDataService.getCityLabel(apiProfile.city);
    }

    // Fallback to lookup data if static data doesn't have it or not loaded yet
    if (cityLabel == null && lookupData != null) {
      cityLabel = _getLabelFromLookup(lookupData, 'city', apiProfile.city);
    }
  }

  String? stateLabel;
  if (apiProfile.state != null && apiProfile.state!.isNotEmpty) {
    // Try static data first (fast, synchronous if already loaded)
    if (staticDataService.isStatesLoaded) {
      stateLabel = staticDataService.getStateLabel(apiProfile.state);
    }

    // If static data doesn't have it and we have country, try to fetch states for that country
    // Note: This would require async call, so we skip it for now and rely on static data
    // Fallback to lookup data if static data doesn't have it or not loaded yet
    if (stateLabel == null && lookupData != null) {
      stateLabel = _getLabelFromLookup(lookupData, 'state', apiProfile.state);
    }
  }

  String? countryLabel;
  if (apiProfile.country != null && apiProfile.country!.isNotEmpty) {
    // Try static data first (fast, synchronous if already loaded)
    if (staticDataService.isCountriesLoaded) {
      countryLabel = staticDataService.getCountryLabel(apiProfile.country);
    }

    // Fallback to countries list if provided
    if (countryLabel == null && countries != null) {
      try {
        final country = countries.firstWhere(
          (c) => c.value?.toString() == apiProfile.country?.toString(),
        );
        countryLabel = country.label;
      } catch (_) {
        // Country not found in list
      }
    }

    // Final fallback to lookup data if static data doesn't have it or not loaded yet
    if (countryLabel == null && lookupData != null) {
      countryLabel = _getLabelFromLookup(
        lookupData,
        'country',
        apiProfile.country,
      );
    }
  }

  // Use labels if available, otherwise fallback to raw values
  final cityDisplay = cityLabel ?? apiProfile.city;
  final stateDisplay = stateLabel ?? apiProfile.state;
  final countryDisplay = countryLabel ?? apiProfile.country;

  location = [
    cityDisplay,
    stateDisplay,
    countryDisplay,
  ].where((s) => s != null && s.isNotEmpty && s != 'Not Filled').join(', ');

  // Get primary image
  String? imageUrl;
  if (apiProfile.profilePic != null && apiProfile.profilePic!.isNotEmpty) {
    final primaryPic = apiProfile.profilePic!.firstWhere(
      (pic) =>
          pic.s3Link != null &&
          pic.s3Link!.isNotEmpty &&
          pic.id != null &&
          pic.id!.isNotEmpty,
      orElse: () => apiProfile.profilePic!.first,
    );
    if (primaryPic.id != null && primaryPic.id!.isNotEmpty) {
      final clientId = apiProfile.clientID ?? apiProfile.id ?? '';
      imageUrl = buildImageUrl(clientId, primaryPic.id!);
    }
  }

  return {
    'id': apiProfile.clientID ?? apiProfile.id ?? '',
    'clientID': apiProfile.clientID ?? apiProfile.id ?? '',
    'name': apiProfile.heartsId != null
        ? 'HEARTS-${apiProfile.heartsId}'
        : (apiProfile.name ?? 'Unknown'),
    'age': age ?? apiProfile.age ?? 0,
    'height': formatHeightInMeters(apiProfile.height),
    'location': location,
    'religion':
        _getLabelFromLookup(lookupData, 'religion', apiProfile.religion) ??
            (apiProfile.religion?.toString()),
    'caste': _getCastLabel(apiProfile.caste, staticDataService, lookupData),
    'cast': _getCastLabel(apiProfile.caste, staticDataService,
        lookupData), // Also include 'cast' key for compatibility
    'occupation':
        _getLabelFromLookup(lookupData, 'occupation', apiProfile.occupation) ??
            (apiProfile.occupation?.toString()),
    'income': formatIncome(apiProfile.income),
    'qualification': _getLabelFromLookup(
          lookupData,
          'qualification',
          apiProfile.qualification,
        ) ??
        (apiProfile.qualification?.toString()),
    'imageUrl': imageUrl,
    'heartsId': apiProfile.heartsId,
    'gender': apiProfile.gender,
    'dob': dob,
  };
}

String? _getLabelFromLookup(
  Map<String, List<LookupOption>>? lookupData,
  String key,
  dynamic value,
) {
  if (lookupData == null || value == null) return null;
  final options = lookupData[key];
  if (options == null) return null;
  try {
    final option = options.firstWhere(
      (opt) => opt.value.toString() == value.toString(),
    );
    return option.label;
  } catch (_) {
    return null;
  }
}

/// Get cast label from value using static data first, then lookup data
String? _getCastLabel(
  dynamic castValue,
  StaticDataService staticDataService,
  Map<String, List<LookupOption>>? lookupData,
) {
  if (castValue == null) return null;
  final castValueStr = castValue.toString();
  if (castValueStr.isEmpty) return null;

  // Try static data first (fast, synchronous if already loaded)
  if (staticDataService.isLookupsLoaded) {
    final castLabel = staticDataService.getCastLabel(castValueStr);
    if (castLabel != null && castLabel.isNotEmpty) {
      return castLabel;
    }
  }

  // Fallback to lookup data
  if (lookupData != null) {
    return _getLabelFromLookup(lookupData, 'casts', castValue);
  }

  // Final fallback to raw value
  return castValueStr;
}

/// Format height from inches to feet'inches format
String formatHeight(dynamic height) {
  if (height == null) return '';
  if (height is String && height.isEmpty) return '';

  int inches;
  if (height is int) {
    inches = height;
  } else if (height is double) {
    inches = height.toInt();
  } else if (height is String) {
    inches = int.tryParse(height) ?? 0;
  } else {
    return height.toString();
  }

  if (inches == 0) return '';

  final feet = inches ~/ 12;
  final remainingInches = inches % 12;
  return "$feet' $remainingInches\"";
}

//////formate height from feet and inches to meters like 5'0" (1.52 mts)
String formatHeightInMeters(dynamic height) {
  if (height == null) return '';

  int inches;
  if (height is int) {
    inches = height;
  } else if (height is double) {
    inches = height.toInt();
  } else if (height is String) {
    if (height.isEmpty) return '';
    inches = int.tryParse(height) ?? 0;
  } else {
    return '';
  }

  if (inches == 0) return '';

  final feet = inches ~/ 12;
  final remainingInches = inches % 12;
  final meters = (inches * 0.0254).toStringAsFixed(2);
  return "$feet'$remainingInches\" ($meters mts)";
}

/// Format income from code to readable string
String formatIncome(dynamic income) {
  if (income == null) return '';
  if (income is String && income.isEmpty) return '';

  // Income codes: 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
  // Map to income ranges (this is a simplified mapping, adjust based on actual API)
  final incomeMap = {
    0.5: 'Not Working',
    1: 'Rs. 0 - 1 Lakh',
    2: 'Rs. 1 - 2.5 Lakh',
    3: 'Rs. 2.5 - 5 Lakh',
    4: 'Rs. 5 - 7.5 Lakh',
    5: 'Rs. 7.5 - 10 Lakh',
    6: 'Rs. 10 - 15 Lakh',
    7: 'Rs. 15 - 20 Lakh',
    8: 'Rs. 20 - 25 Lakh',
    9: 'Rs. 25 - 30 Lakh',
    10: 'Rs. 30 - 40 Lakh',
    11: 'Rs. 40 - 50 Lakh',
    12: 'Rs. 50 - 75 Lakh',
    13: 'Rs. 75 Lakh - 1 Crore',
    14: 'Rs. 1 - 2 Crore',
    15: 'Rs. 2+ Crore',
  };

  if (income is num) {
    return incomeMap[income] ?? income.toString();
  }
  if (income is String) {
    final numValue = double.tryParse(income);
    if (numValue != null) {
      return incomeMap[numValue] ?? income;
    }
  }
  return income.toString();
}

/// Calculate age from date of birth (matches TypeScript version)
/// const calculateAge = (dob: string): number => {
///   const birthDate = new Date(dob)
///   const today = new Date()
///   let age = today.getFullYear() - birthDate.getFullYear()
///   const monthDiff = today.getMonth() - birthDate.getMonth()
///   if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
///     age--
///   }
///   return age
/// }
int calculateAge(DateTime dob) {
  final today = DateTime.now();
  int age = today.year - dob.year;
  final monthDiff = today.month - dob.month;
  if (monthDiff < 0 || (monthDiff == 0 && today.day < dob.day)) {
    age--;
  }
  return age;
}

/// Calculate age from date of birth string (ISO format)
int? calculateAgeFromString(String? dobString) {
  if (dobString == null || dobString.isEmpty) return null;
  try {
    final dob = DateTime.parse(dobString);
    return calculateAge(dob);
  } catch (_) {
    return null;
  }
}

/// Format date to readable string
String formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '';
  try {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  } catch (_) {
    return dateString;
  }
}

/// Format time of birth
String formatTimeOfBirth(String? tob) {
  if (tob == null || tob.isEmpty) return '';
  try {
    final date = DateTime.parse(tob);
    final hours = date.hour;
    final minutes = date.minute;
    final ampm = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours % 12 == 0 ? 12 : hours % 12;
    final displayMinutes = minutes.toString().padLeft(2, '0');
    return '$displayHours:$displayMinutes $ampm';
  } catch (_) {
    return tob;
  }
}
