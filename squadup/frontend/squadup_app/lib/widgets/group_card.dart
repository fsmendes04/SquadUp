import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:squadup_app/models/groups.dart';
import 'avatar_group.dart';

class GroupCard extends StatefulWidget {
  final GroupWithMembers group;
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

  String _getLastActivity() {
    final now = DateTime.now();
    final difference =
        widget.group.updatedAt != null
            ? now.difference(widget.group.updatedAt!)
            : now.difference(widget.group.createdAt);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${(difference.inDays / 7).floor()}sem atrás';
    }
  }

  bool get _isActive {
    if (widget.group.updatedAt == null) return false;
    final difference = DateTime.now().difference(widget.group.updatedAt!);
    return difference.inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF1D385F);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color:
                _isPressed
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AvatarGroupWidget(
                groupId: widget.group.id,
                avatarUrl: widget.group.avatarUrl,
                radius: 33,
              ),
              const SizedBox(width: 20),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do grupo
                    Text(
                      widget.group.name,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),

                    // Informações adicionais (membros + última atividade)
                    Row(
                      children: [
                        // Número de membros
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.group.memberCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Última atividade
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getLastActivity(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Activity indicator dot (verde se ativo nas últimas 24h)
              if (_isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),

              // Subtle arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
