import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: darkBlue,
          ),
        ),
        iconTheme: IconThemeData(color: darkBlue),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        children: [
          _buildSectionTitle('Account', darkBlue),
          _buildSettingsCard(
            icon: Icons.person,
            label: 'Account Info',
            onTap: () {},
            darkBlue: darkBlue,
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Preferences', darkBlue),
          _buildSettingsCard(
            icon: Icons.notifications,
            label: 'Notifications',
            onTap: () {},
            darkBlue: darkBlue,
          ),
          const SizedBox(height: 18),
          _buildSettingsCard(
            icon: Icons.lock,
            label: 'Privacy',
            onTap: () {},
            darkBlue: darkBlue,
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('About', darkBlue),
          _buildSettingsCard(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () {},
            darkBlue: darkBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color darkBlue) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkBlue.withValues(alpha: 0.8),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color darkBlue,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: darkBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: darkBlue, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: darkBlue,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: darkBlue.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
