import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupCard extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF1D385F);
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final groupColor = widget.group['color'] as Color;
    final isActive = widget.group['isActive'] as bool;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color:
                _isPressed ? Colors.grey.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.8), primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [groupColor.withOpacity(0.7), groupColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.groups, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Group info - estilo Instagram post
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do grupo
                    Text(
                      widget.group['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Activity indicator dot
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),

              const SizedBox(width: 8),

              // Subtle arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
