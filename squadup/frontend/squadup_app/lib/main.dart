import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/locale_provider.dart';
import 'config/screens.dart';

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
    // ...existing code...
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SquadUp',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
        '/album-detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return AlbumDetailScreen(
            gallery: args['gallery'] as Gallery,
            groupName: args['groupName'] as String,
          );
        },
        '/make-payment': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return MakePaymentScreen(
            groupId: args['groupId'] as String,
            groupName: args['groupName'] as String,
            groupDetails: args['groupDetails'],
          );
        },
        '/payment-history': (context) => const PaymentHistoryScreen(),
      },
    );
  }
}
