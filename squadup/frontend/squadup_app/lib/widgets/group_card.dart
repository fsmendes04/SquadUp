import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupCard extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  String _formatLastActivity(String lastActivity) {
    // Converte atividade para indicadores mais visuais
    if (lastActivity.contains('min')) {
      return 'Active now';
    } else if (lastActivity.contains('hora')) {
      return 'Recently active';
    } else if (lastActivity.contains('dia')) {
      return 'Active today';
    } else {
      return lastActivity;
    }
  }

  Color _getActivityColor(String lastActivity) {
    if (lastActivity.contains('min')) {
      return const Color(0xFF2ECC71); // Verde - muito ativo
    } else if (lastActivity.contains('hora')) {
      return const Color(0xFFF39C12); // Laranja - ativo
    } else {
      return const Color(0xFF95A5A6); // Cinza - menos ativo
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF1D385F);
    final groupColor = widget.group['color'] as Color;
    final isActive = widget.group['isActive'] as bool;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _isPressed
                      ? groupColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    _isPressed
                        ? groupColor.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                blurRadius: _isPressed ? 15 : 12,
                offset: Offset(0, _isPressed ? 6 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Group avatar com animação
              Hero(
                tag: 'group_${widget.group['id']}',
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [groupColor.withOpacity(0.8), groupColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: groupColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Ícone principal
                      Center(
                        child: Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      // Badge de atividade
                      if (isActive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome e status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.group['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkBlue,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Activity indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getActivityColor(
                              widget.group['lastActivity'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatLastActivity(widget.group['lastActivity']),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getActivityColor(
                                widget.group['lastActivity'],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Informações adicionais
                    Row(
                      children: [
                        // Membros
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: groupColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 14,
                                color: groupColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.group['memberCount']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: groupColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Última atividade
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.group['lastActivity'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Arrow com animação
              AnimatedRotation(
                turns: _isPressed ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: groupColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
