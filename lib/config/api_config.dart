class ApiConfig {
  static const String apiBaseUrl = 'https://backendapp.connectingheart.co.in/api';
  static const String backendBaseUrl = 'https://backendapp.connectingheart.co.in';

  static String buildImageUrl(String clientId, String imageId) {
    return '$backendBaseUrl/api/profile/file/$clientId/$imageId';
  }
}
