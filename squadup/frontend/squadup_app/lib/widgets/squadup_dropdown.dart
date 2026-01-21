import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_utils.dart';

class SquadUpDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?)? onChanged;
  final IconData icon;
  final String? Function(String?)? validator;

  const SquadUpDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    return Container(
      margin: r.verticalPadding(8),
      child: DropdownButtonFormField<String>(
        value: value,
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
          enabledBorder: OutlineInputBorder(
            borderRadius: r.circularBorderRadius(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: r.borderWidth(1.5)),
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
            borderSide: BorderSide(color: Colors.red.shade400, width: r.borderWidth(1.5)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: r.circularBorderRadius(16),
            borderSide: BorderSide(color: Colors.red.shade400, width: r.borderWidth(2)),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: r.symmetricPadding(vertical: 18, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: r.fontSize(14),
          fontWeight: FontWeight.w500,
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        borderRadius: r.circularBorderRadius(12),
        isExpanded: true,
      ),
    );
  }
}
