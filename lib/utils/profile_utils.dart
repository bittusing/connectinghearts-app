import '../config/api_config.dart';
import '../models/profile_models.dart';

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
Map<String, dynamic> transformProfile(ApiProfile apiProfile) {
  final location = [
    apiProfile.city,
    apiProfile.state,
    apiProfile.country,
  ].where((s) => s != null && s.isNotEmpty).join(', ');

  return {
    'id': apiProfile.clientID ?? apiProfile.id ?? '',
    'name': apiProfile.heartsId != null 
        ? 'HEARTS-${apiProfile.heartsId}' 
        : (apiProfile.name ?? 'Unknown'),
    'age': apiProfile.age ?? 0,
    'height': apiProfile.height ?? '',
    'location': location,
    'religion': apiProfile.religion,
    'caste': apiProfile.caste,
    'occupation': apiProfile.occupation,
    'income': apiProfile.income,
    'qualification': apiProfile.qualification,
    'imageUrl': getProfileImageUrl(apiProfile),
  };
}

/// Format height string
String formatHeight(String? height) {
  if (height == null || height.isEmpty) return '';
  // Height might be in cm or feet'inches format
  return height;
}

/// Format income string
String formatIncome(String? income) {
  if (income == null || income.isEmpty) return '';
  return income;
}

/// Calculate age from date of birth
int calculateAge(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || 
      (now.month == dob.month && now.day < dob.day)) {
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
