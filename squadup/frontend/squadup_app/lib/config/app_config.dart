import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _devBaseUrl = 'http://10.0.2.2:3000';
  static const String _prodBaseUrl = 'https://api.yourapp.com';

  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const bool enableApiLogs = !kReleaseMode;
  static const bool enableCrashReporting = kReleaseMode;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5MB

  static const List<String> allowedAvatarTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedAvatarExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static const int maxNameLength = 100;
  static const int minPasswordLength = 8;

  static const Duration profileCacheDuration = Duration(minutes: 5);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  static const Map<String, int> rateLimits = {
    'register': 3,
    'login': 5,
    'profile_update': 10,
    'profile_get': 30,
    'logout': 10,
    'refresh': 10,
  };

  static const String networkErrorMessage =
      'Connection failed. Please check your internet connection.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String unauthorizedErrorMessage =
      'Session expired. Please login again.';
}
