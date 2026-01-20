import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_utils.dart';

class SquadUpButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color disabledColor;
  final Color textColor;
  final double? borderRadius;
  final Key? buttonKey;

  const SquadUpButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor = const Color.fromARGB(255, 17, 80, 138),
    this.disabledColor = const Color.fromARGB(255, 19, 85, 146),
    this.textColor = Colors.white,
    this.borderRadius,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    final responsiveWidth = width ?? r.width(175);
    final responsiveHeight = height ?? r.height(55);
    final responsiveBorderRadius = borderRadius ?? r.borderRadius(15);
    final responsiveFontSize = r.fontSize(18);
    final responsiveLoaderSize = r.width(20);
    
    return SizedBox(
      width: responsiveWidth,
      height: responsiveHeight,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
          ),
          elevation: 0,
          disabledBackgroundColor: disabledColor,
        ),
        child: isLoading
            ? SizedBox(
                width: responsiveLoaderSize,
                height: responsiveLoaderSize,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: responsiveFontSize,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
