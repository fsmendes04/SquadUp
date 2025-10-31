import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_name_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool envLoaded = false;
  try {
    await dotenv.load(fileName: ".env");
    envLoaded = true;
  } catch (e) {
    debugPrint('No .env file found, continuing...');
  }

  if (envLoaded &&
      dotenv.env['SUPABASE_URL']?.isNotEmpty == true &&
      dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true) {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SquadUp',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('pt', '')],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-name': (context) => const AddNameScreen(),
      },
    );
  }
}
