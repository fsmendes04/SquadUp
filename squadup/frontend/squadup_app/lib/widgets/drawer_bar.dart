import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDrawerBar extends StatelessWidget {
  final Function(int) onItemTap;

  const CustomDrawerBar({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color(0xFF0B3A66);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            index: 0,
            darkBlue: darkBlue,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Perfil',
            index: 1,
            darkBlue: darkBlue,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.chat,
            title: 'Chat',
            index: 2,
            darkBlue: darkBlue,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Definições',
            index: 3,
            darkBlue: darkBlue,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            index: 4,
            darkBlue: darkBlue,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
    required Color darkBlue,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => onItemTap(index),
      borderRadius: BorderRadius.circular(isLast ? 16 : 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
        ),
        child: Row(
          children: [
            Icon(icon, color: darkBlue, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: darkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
