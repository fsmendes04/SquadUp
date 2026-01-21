import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Padding(
          padding: r.padding(left: 18),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: r.iconSize(32)),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: r.fontSize(22),
            color: darkBlue,
          ),
        ),
        iconTheme: IconThemeData(color: darkBlue),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: r.symmetricPadding(horizontal: 18, vertical: 24),
        children: [
          _buildSectionTitle('Account', darkBlue, r),
          _buildSettingsCard(
            icon: Icons.person,
            label: 'Account Info',
            onTap: () {},
            darkBlue: darkBlue,
            r: r,
          ),
          r.verticalSpace(18),
          _buildSectionTitle('Preferences', darkBlue, r),
          _buildSettingsCard(
            icon: Icons.notifications,
            label: 'Notifications',
            onTap: () {},
            darkBlue: darkBlue,
            r: r,
          ),
          r.verticalSpace(18),
          _buildSettingsCard(
            icon: Icons.lock,
            label: 'Privacy',
            onTap: () {},
            darkBlue: darkBlue,
            r: r,
          ),
          r.verticalSpace(18),
          _buildSectionTitle('About', darkBlue, r),
          _buildSettingsCard(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () {},
            darkBlue: darkBlue,
            r: r,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color darkBlue, ResponsiveUtils r) {
    return Padding(
      padding: r.padding(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: r.fontSize(14),
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
    required ResponsiveUtils r,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: r.circularBorderRadius(14),
      child: InkWell(
        borderRadius: r.circularBorderRadius(14),
        onTap: onTap,
        child: Padding(
          padding: r.symmetricPadding(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: darkBlue.withValues(alpha: 0.08),
                  borderRadius: r.circularBorderRadius(10),
                ),
                padding: r.padding(left: 10, top: 10, right: 10, bottom: 10),
                child: Icon(icon, color: darkBlue, size: r.iconSize(26)),
              ),
              r.horizontalSpace(18),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: r.fontSize(16),
                    fontWeight: FontWeight.w500,
                    color: darkBlue,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: darkBlue.withValues(alpha: 0.5),
                size: r.iconSize(18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
