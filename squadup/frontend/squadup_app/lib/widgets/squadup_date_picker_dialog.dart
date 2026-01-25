import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/responsive_utils.dart';

/// Shows a custom SquadUp date picker dialog
Future<DateTime?> showSquadUpDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return await showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => _CustomDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      parentContext: context,
    ),
  );
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final BuildContext parentContext;

  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.parentContext,
  });

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  bool _showMonthYearPicker = false;
  late int _selectedYear;
  static const primaryBlue = Color(0xFF51A3E6);
  static const darkBlue = Color(0xFF1D385F);
  
  late ResponsiveUtils _responsive;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _responsive = widget.parentContext.responsive;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _selectedYear = _selectedDate.year;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _previousYear() {
    setState(() {
      _selectedYear--;
    });
  }

  void _nextYear() {
    setState(() {
      _selectedYear++;
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _currentMonth = DateTime(_selectedYear, month);
      _showMonthYearPicker = false;
    });
  }

  bool _isDateInRange(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final firstDateOnly = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final lastDateOnly = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !dateOnly.isBefore(firstDateOnly) && !dateOnly.isAfter(lastDateOnly);
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    List<DateTime?> days = List.filled(firstWeekday, null, growable: true);
    
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    return days;
  }

  Widget _buildMonthYearPicker() {
    final r = _responsive;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Year selector
        Padding(
          padding: EdgeInsets.fromLTRB(r.width(16), r.height(20), r.width(16), r.height(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousYear,
                icon: const Icon(Icons.chevron_left),
                color: darkBlue,
                iconSize: r.iconSize(28),
              ),
              Text(
                '$_selectedYear',
                style: GoogleFonts.poppins(
                  fontSize: r.fontSize(20),
                  fontWeight: FontWeight.w700,
                  color: darkBlue,
                ),
              ),
              IconButton(
                onPressed: _nextYear,
                icon: const Icon(Icons.chevron_right),
                color: darkBlue,
                iconSize: r.iconSize(28),
              ),
            ],
          ),
        ),
        
        // Month grid
        Padding(
          padding: EdgeInsets.fromLTRB(r.width(16), r.height(0), r.width(16), r.height(20)),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: r.width(12),
              mainAxisSpacing: r.height(12),
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final isCurrentMonth = _currentMonth.month == index + 1 && 
                                     _currentMonth.year == _selectedYear;
              
              return GestureDetector(
                onTap: () => _selectMonth(index + 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth ? primaryBlue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(r.borderRadius(12)),
                  ),
                  child: Center(
                    child: Text(
                      months[index],
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: isCurrentMonth ? Colors.white : darkBlue,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final r = _responsive;
    final days = _getDaysInMonth();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month navigation
        Padding(
          padding: EdgeInsets.fromLTRB(r.width(16), r.height(20), r.width(16), r.height(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: darkBlue,
                iconSize: r.iconSize(28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedYear = _currentMonth.year;
                    _showMonthYearPicker = true;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: r.width(16), vertical: r.height(8)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(r.borderRadius(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                      SizedBox(width: r.width(4)),
                      Icon(Icons.arrow_drop_down, color: darkBlue, size: r.iconSize(20)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: darkBlue,
                iconSize: r.iconSize(28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        
        // Weekday labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.width(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: r.width(40),
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(14),
                      fontWeight: FontWeight.w800,
                      color: primaryBlue.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: r.height(8)),
        
        // Calendar grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.width(16)),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: r.width(4),
              mainAxisSpacing: r.height(4),
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox();
              
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              
              final isInRange = _isDateInRange(date);
              
              return GestureDetector(
                onTap: isInRange ? () {
                  setState(() {
                    _selectedDate = date;
                  });
                } : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryBlue
                        : isToday
                            ? primaryBlue.withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(r.borderRadius(12)),
                    border: isToday && !isSelected
                        ? Border.all(color: primaryBlue, width: r.borderWidth(2))
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(14),
                        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isInRange
                                ? darkBlue
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _responsive;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: r.width(400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.borderRadius(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: r.width(20),
              offset: Offset(0, r.height(10)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(r.borderRadius(28))),
              ),
              padding: EdgeInsets.all(r.width(25)),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select Date',
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(16),
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: r.height(16)),
                  Text(
                    DateFormat('EEE, MMM d').format(_selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(32),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Calendar or Month/Year picker
            _showMonthYearPicker ? _buildMonthYearPicker() : _buildCalendar(),
            
            SizedBox(height: r.height(20)),
            
            // Action buttons
            Padding(
              padding: EdgeInsets.fromLTRB(r.width(20), 0, r.width(20), r.height(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: r.width(24), vertical: r.height(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  SizedBox(width: r.width(8)),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: r.width(32), vertical: r.height(12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.borderRadius(12)),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(14),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
