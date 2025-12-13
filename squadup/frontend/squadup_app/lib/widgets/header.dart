import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class CustomHeader extends StatelessWidget {
  final Color darkBlue;
  final String title;
  final VoidCallback? onBack;

  const CustomHeader({
    super.key,
    required this.darkBlue,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
