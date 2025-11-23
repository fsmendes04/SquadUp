import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  StorageService._internal();

  static const String _userProfileKey = 'user_profile';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: _userProfileKey, value: jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final profileString = await _storage.read(key: _userProfileKey);
    if (profileString == null) return null;
    return jsonDecode(profileString) as Map<String, dynamic>;
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> updateUserProfileField(String key, dynamic value) async {
    final profile = await getUserProfile();
    if (profile != null) {
      profile[key] = value;
      await saveUserProfile(profile);
    }
  }

  Future<void> clearUserData() async {
    await _storage.delete(key: _userProfileKey);
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
