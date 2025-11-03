import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Center(
        child: Text(
          'Expenses Screen - Coming Soon!',
          style: GoogleFonts.lato(fontSize: 24),
        ),
      ),
    );
  }
}
