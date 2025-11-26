import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'config/locale_provider.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/group_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_name_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_group_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/language_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expense_history_screen.dart';
import 'screens/group_gallery_screen.dart';
import 'screens/create_gallery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SquadUp',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/add-name': (context) => const AddNameScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/group-home':
                (context) => const GroupHomeScreen(groupId: '', groupName: ''),
            '/edit-group': (context) => const EditGroupScreen(groupId: ''),
            '/create-group':
                (context) => CreateGroupScreen(
                  onCreateGroup:
                      (
                        String name,
                        List<String> members,
                        String? avatarPath,
                      ) async {},
                ),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/language': (context) => const LanguageScreen(),
            '/expenses': (context) => const ExpensesScreen(),
            '/add-expense': (context) => const AddExpenseScreen(),
            '/expense-history': (context) => const ExpenseHistoryScreen(),
            '/group-gallery': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return GroupGalleryScreen(
                groupId: args['groupId'] as String,
                groupName: args['groupName'] as String,
              );
            },
            '/create-gallery': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return CreateGalleryScreen(
                groupId: args['groupId'] as String,
                groupName: args['groupName'] as String,
              );
            },
          },
        );
      },
    );
  }
}
