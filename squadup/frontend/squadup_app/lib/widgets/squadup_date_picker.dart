import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_utils.dart';

class SquadUpDatePicker extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final Future<void> Function() onDateSelected;
  final IconData icon;

  const SquadUpDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    required this.icon,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      margin: r.symmetricPadding(vertical: 8),
      child: GestureDetector(
        onTap: onDateSelected,
        child: AbsorbPointer(
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: r.fontSize(14),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: r.padding(left: 16, right: 10),
                child: Icon(icon, color: const Color.fromARGB(255, 19, 85, 146), size: r.iconSize(22)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: r.circularBorderRadius(16),
                borderSide: BorderSide(color: Colors.grey.shade300, width: r.borderWidth(1.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: r.circularBorderRadius(16),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 19, 85, 146),
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
              contentPadding: r.symmetricPadding(
                vertical: 18,
                horizontal: 16,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              suffixIcon: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ),
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: r.fontSize(14),
              fontWeight: FontWeight.w500,
            ),
            controller: TextEditingController(text: _formatDate(selectedDate)),
          ),
        ),
      ),
    );
  }
}
