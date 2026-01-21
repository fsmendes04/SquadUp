import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/locale_provider.dart';
import '../config/responsive_utils.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Language',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: r.fontSize(22),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D385F),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: r.padding(left: 24, top: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your preferred language:',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(18),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D385F),
              ),
            ),
            r.verticalSpace(30),
            ListTile(
              leading: Icon(Icons.language, color: const Color(0xFF1D385F), size: r.iconSize(24)),
              title: Text('English', style: GoogleFonts.poppins(fontSize: r.fontSize(16))),
              onTap: () {
                Provider.of<LocaleProvider>(
                  context,
                  listen: false,
                ).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: const Color(0xFF1D385F), size: r.iconSize(24)),
              title: Text(
                'Português',
                style: GoogleFonts.poppins(fontSize: r.fontSize(16)),
              ),
              onTap: () {
                Provider.of<LocaleProvider>(
                  context,
                  listen: false,
                ).setLocale(const Locale('pt'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
