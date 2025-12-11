import '../config/api_config.dart';
import '../models/profile_models.dart';

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
  String? dob,
}) {
  // Calculate age from DOB if available
  int? age;
  if (dob != null && dob.isNotEmpty) {
    try {
      final dobDate = DateTime.parse(dob);
      age = calculateAge(dobDate);
    } catch (_) {}
  }

  // Get location labels
  String location = '';
  if (lookupData != null) {
    final cityLabel = _getLabelFromLookup(lookupData, 'city', apiProfile.city);
    final stateLabel =
        _getLabelFromLookup(lookupData, 'state', apiProfile.state);
    final countryLabel =
        _getLabelFromLookup(lookupData, 'country', apiProfile.country);
    location = [cityLabel, stateLabel, countryLabel]
        .where((s) => s != null && s.isNotEmpty && s != 'Not Filled')
        .join(', ');
  }

  if (location.isEmpty) {
    location = [
      apiProfile.city,
      apiProfile.state,
      apiProfile.country,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
  }

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
    'height': formatHeight(apiProfile.height),
    'location': location,
    'religion':
        _getLabelFromLookup(lookupData, 'religion', apiProfile.religion) ??
            (apiProfile.religion?.toString()),
    'caste': _getLabelFromLookup(lookupData, 'casts', apiProfile.caste) ??
        (apiProfile.caste?.toString()),
    'occupation':
        _getLabelFromLookup(lookupData, 'occupation', apiProfile.occupation) ??
            (apiProfile.occupation?.toString()),
    'income': formatIncome(apiProfile.income),
    'qualification': _getLabelFromLookup(
            lookupData, 'qualification', apiProfile.qualification) ??
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

/// Calculate age from date of birth
int calculateAge(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
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
