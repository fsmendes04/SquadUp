import 'package:flutter/foundation.dart';

class AppConfig {
  // URLs da API para diferentes ambientes
  static const String _developmentUrl =
      'http://10.0.2.2:3000'; // Emulador Android
  static const String _developmentUrlIOS =
      'http://localhost:3000'; // Simulator iOS

  // URL base atual baseada no ambiente
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _developmentUrlIOS;
    } else {
      return _developmentUrl;
    }
  }

  // Configurações de timeout
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Headers padrão
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Configurações de debug
  static bool get enableApiLogs => kDebugMode;

  // Versão da API
  static const String apiVersion = 'v1';

  // URLs específicas
  static String get authUrl => '$baseUrl/auth';
  static String get groupsUrl => '$baseUrl/groups';
  static String get expensesUrl => '$baseUrl/expenses';
}
