import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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

  //static const Color darkBlue = Color.fromARGB(255, 5, 33, 61);
  static const Color darkBlue = Color.fromARGB(255, 29, 56, 95);


  final springDesc = const SpringDescription(
    mass: 0.1,
    stiffness: 40,
    damping: 5,
  );

  final List<DrawerMenuItem> _menuItems = [
    DrawerMenuItem(icon: Icons.settings, title: 'Settings', index: 0),
    DrawerMenuItem(icon: Icons.logout, title: 'Logout', index: 1),
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
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
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
          Container(
            color: darkBlue,
          ),

          // Main content with animation (direita)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 - (_sidebarAnim.value * 0.1),
                  child: Transform.translate(
                    offset: Offset(-_sidebarAnim.value * 265, 0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY((-_sidebarAnim.value * 30) * math.pi / 180),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _sidebarAnim.value * 30,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: IgnorePointer(
                ignoring: _isMenuOpen,
                child: widget.child,
              ),
            ),
          ),

          // Gesture detector invisível para fechar o menu ao clicar na tela
          if (_isMenuOpen)
            GestureDetector(
              onTap: toggleMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),

          // Side Menu (direita)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(((1 - _sidebarAnim.value) * 30) * math.pi / 180)
                      ..translate((1 - _sidebarAnim.value) * 300),
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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      constraints: const BoxConstraints(maxWidth: 288),
      decoration: const BoxDecoration(
        color: darkBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  radius: 24,
                  child: const Icon(Icons.person_outline, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName ?? 'User',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            color: Colors.white,
            thickness: 1,
            indent: 24,
            endIndent: 24,
          ),

          const SizedBox(height: 20),

          // Menu items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 12),
                    child: Text(
                      'MENU',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
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

        ],
      ),
    );
  }

  Widget _buildMenuItem(DrawerMenuItem item) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // Sem destaque visual para o item selecionado
      child: InkWell(
        onTap: () => _onMenuItemTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
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
