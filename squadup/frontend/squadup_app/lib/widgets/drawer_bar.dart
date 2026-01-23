import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../config/responsive_utils.dart';

class _RoundedBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;

  _RoundedBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius - borderWidth / 2),
    );
    final paint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final int index;

  DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}

class CustomDrawerBar extends StatefulWidget {
  final Function(int) onItemTap;
  final Widget child;
  final String? userName;

  const CustomDrawerBar({
    super.key,
    required this.onItemTap,
    required this.child,
    this.userName,
  });

  @override
  State<CustomDrawerBar> createState() => CustomDrawerBarState();
}

class CustomDrawerBarState extends State<CustomDrawerBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sidebarAnim;

  bool _isMenuOpen = false;
  bool _darkMode = false;

  //static const Color darkBlue = Color.fromARGB(255, 5, 33, 61);
  static const Color darkBlue = Color.fromARGB(255, 29, 56, 95);

  final springDesc = const SpringDescription(
    mass: 0.1,
    stiffness: 40,
    damping: 5,
  );

  final List<DrawerMenuItem> _menuItems = [
    DrawerMenuItem(icon: Icons.settings, title: 'Settings', index: 0),
    DrawerMenuItem(icon: Icons.language, title: 'Language', index: 1),
    DrawerMenuItem(icon: Icons.logout, title: 'Logout', index: 2),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      upperBound: 1,
      vsync: this,
    );

    _sidebarAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });

    if (_isMenuOpen) {
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _animationController.animateWith(springAnim);
    } else {
      _animationController.reverse();
    }
  }

  void _onMenuItemTap(DrawerMenuItem item) {
    widget.onItemTap(item.index);
    toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Solid dark blue background for the whole screen
          Container(color: darkBlue),

          // Main content with animation (direita)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                final r = context.responsive;
                final borderRadius = _sidebarAnim.value * r.borderRadius(30);
                final showBorder = (_sidebarAnim.value >= 0.8);
                return Transform.scale(
                  scale: 1 - (_sidebarAnim.value * 0.1),
                  child: Transform.translate(
                    offset: Offset(-_sidebarAnim.value * r.width(265), 0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(
                              (-_sidebarAnim.value * 30) * math.pi / 180,
                            ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            child!,
                            if (showBorder)
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _RoundedBorderPainter(
                                    borderRadius: borderRadius,
                                    borderWidth: r.borderWidth(4),
                                    borderColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: IgnorePointer(ignoring: _isMenuOpen, child: widget.child),
            ),
          ),

          // Gesture detector invisível para fechar o menu ao clicar na tela
          if (_isMenuOpen)
            GestureDetector(
              onTap: toggleMenu,
              child: Container(color: Colors.transparent),
            ),

          // Side Menu (direita)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                final r = context.responsive;
                return Align(
                  alignment: Alignment.centerRight,
                  child: Transform(
                    alignment: Alignment.center,
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(
                            ((1 - _sidebarAnim.value) * 30) * math.pi / 180,
                          )
                          ..translate((1 - _sidebarAnim.value) * r.width(300)),
                    child: child,
                  ),
                );
              },
              child: FadeTransition(
                opacity: _sidebarAnim,
                child: _buildSideMenu(),
              ),
            ),
          ),

          // (Removido o botão de menu da drawer bar. O controle é feito pelo botão do HomeScreen)
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + r.height(20),
        bottom: MediaQuery.of(context).padding.bottom + r.height(20),
      ),
      constraints: BoxConstraints(maxWidth: r.width(288)),
      decoration: const BoxDecoration(color: darkBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Padding(
            padding: r.padding(left: 24, top: 24, right: 24, bottom: 24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  radius: r.width(24),
                  child: Icon(Icons.person_outline, size: r.iconSize(28)),
                ),
                SizedBox(width: r.width(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName ?? 'User',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: r.fontSize(18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: Colors.white,
            thickness: r.borderWidth(1),
            indent: r.width(24),
            endIndent: r.width(24),
          ),

          SizedBox(height: r.height(20)),

          // Menu items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: r.padding(left: 24, bottom: 12),
                    child: Text(
                      'MENU',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: r.fontSize(12),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ..._menuItems.map((item) => _buildMenuItem(item)),
                ],
              ),
            ),
          ),

          // Interruptor para alternar entre dark/light mode (sem lógica)
          Padding(
            padding: r.symmetricPadding(horizontal: 24, vertical: 45),
            child: Row(
              children: [
                Icon(
                  _darkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: r.iconSize(26),
                ),
                SizedBox(width: r.width(12)),
                Expanded(
                  child: Text(
                    _darkMode ? 'Dark Mode' : 'Light Mode',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: r.fontSize(15),
                      color: Colors.white,
                    ),
                  ),
                ),
                Switch(
                  value: _darkMode,
                  onChanged: (val) {
                    setState(() {
                      _darkMode = val;
                    });
                  },
                  activeColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.grey[400],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(DrawerMenuItem item) {
    final r = context.responsive;
    return Container(
      margin: r.symmetricPadding(horizontal: 12, vertical: 4),
      // Sem destaque visual para o item selecionado
      child: InkWell(
        onTap: () => _onMenuItemTap(item),
        borderRadius: BorderRadius.circular(r.borderRadius(12)),
        child: Padding(
          padding: r.symmetricPadding(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.white, size: r.iconSize(24)),
              SizedBox(width: r.width(16)),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: r.fontSize(16),
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Sem barra lateral de seleção
            ],
          ),
        ),
      ),
    );
  }
}
