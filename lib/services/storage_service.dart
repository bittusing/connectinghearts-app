import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _tokenKey = 'connectingheart-token';
  static const String _userIdKey = 'connectingheart-userId';
  static const String _profileNameKey = 'connectingheart-profileName';
  static const String _profileImageUrlKey = 'connectingheart-profileImageUrl';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> setUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // Profile name storage
  Future<String?> getProfileName() async {
    return await _storage.read(key: _profileNameKey);
  }

  Future<void> setProfileName(String name) async {
    await _storage.write(key: _profileNameKey, value: name);
  }

  Future<void> deleteProfileName() async {
    await _storage.delete(key: _profileNameKey);
  }

  // Profile image URL storage
  Future<String?> getProfileImageUrl() async {
    return await _storage.read(key: _profileImageUrlKey);
  }

  Future<void> setProfileImageUrl(String imageUrl) async {
    await _storage.write(key: _profileImageUrlKey, value: imageUrl);
  }

  Future<void> deleteProfileImageUrl() async {
    await _storage.delete(key: _profileImageUrlKey);
  }

  // Clear profile data
  Future<void> clearProfileData() async {
    await deleteProfileName();
    await deleteProfileImageUrl();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
