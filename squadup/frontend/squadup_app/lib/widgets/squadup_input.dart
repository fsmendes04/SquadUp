import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_utils.dart';

class SquadUpInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const SquadUpInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.suffixIcon,
    this.focusNode,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    return Container(
      margin: r.verticalPadding(8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: r.fontSize(14),
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        onSubmitted: onFieldSubmitted,
        cursorColor: Color.fromARGB(255, 19, 85, 146),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: r.fontSize(14),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: r.padding(left: 12, right: 8),
            child: Icon(icon, color: const Color.fromARGB(255, 19, 85, 146)),
          ),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: r.circularBorderRadius(16),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: r.borderWidth(1.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: r.circularBorderRadius(16),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 19, 85, 146),
              width: r.borderWidth(2),
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: r.circularBorderRadius(16),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: r.borderWidth(1.5),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: r.circularBorderRadius(16),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: r.borderWidth(2),
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: r.symmetricPadding(vertical: 18, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}
