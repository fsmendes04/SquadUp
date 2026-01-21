import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_utils.dart';


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
    final r = context.responsive;
    
    return Padding(
      padding: r.symmetricPadding(horizontal: 20, vertical: 6),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: r.iconSize(32)),
            ),
            r.horizontalSpace(10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: r.fontSize(25),
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
