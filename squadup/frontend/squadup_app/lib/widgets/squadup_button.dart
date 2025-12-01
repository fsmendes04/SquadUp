import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SquadUpButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color disabledColor;
  final Color textColor;
  final double borderRadius;
  final Key? buttonKey;

  const SquadUpButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width = 175,
    this.height = 55,
    this.backgroundColor = const Color.fromARGB(255, 17, 80, 138),
    this.disabledColor = const Color.fromARGB(255, 19, 85, 146),
    this.textColor = Colors.white,
    this.borderRadius = 15,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          disabledBackgroundColor: disabledColor,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
