import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/avatar_widget.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _profileUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _userService.getProfile();
      // Extrair o campo 'data' da resposta
      final data = response['data'] as Map<String, dynamic>?;
      
      if (mounted) {
        setState(() {
          userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDisplayName() {
    if (userData?['name'] != null && userData!['name'].toString().isNotEmpty) {
      return userData!['name'];
    }
    return userData?['email']?.split('@')[0] ?? 'User';
  }

  Future<void> _logout() async {
    try {
      await _userService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _profileUpdated);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // Top bar with back button
                        SizedBox(
                          height: kToolbarHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 22),
                                color: darkBlue,
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/edit-profile',
                                  );

                                  // If profile was updated, reload user data
                                  if (result == true) {
                                    _profileUpdated = true;
                                    _loadUserData();
                                  }
                                },
                                tooltip: 'Edit profile',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Profile Picture and Name
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: AvatarWidget(
                                key: ValueKey(userData?['avatar_url'] ?? 'no-avatar'),
                                radius: 60,
                                allowEdit: false, // Apenas visualização
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _getDisplayName(),
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: darkBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userData?['email'] ?? 'No email',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: darkBlue.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // User Information Cards
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom: kBottomNavigationBarHeight + 20,
                            ),
                            child: Column(
                              children: [
                                // App Settings
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        'App Settings',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: darkBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildActionRow(
                                      Icons.notifications_outlined,
                                      'Notifications',
                                      'Manage your notifications',
                                      () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Notifications settings coming soon!',
                                            ),
                                            backgroundColor: primaryBlue,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildActionRow(
                                      Icons.privacy_tip_outlined,
                                      'Privacy',
                                      'Privacy and security settings',
                                      () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Privacy settings coming soon!',
                                            ),
                                            backgroundColor: primaryBlue,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildActionRow(
                                      Icons.help_outline,
                                      'Help & Support',
                                      'Get help and contact support',
                                      () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Help & Support coming soon!',
                                            ),
                                            backgroundColor: primaryBlue,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // Logout Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Text(
                                              'Logout',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: darkBlue,
                                              ),
                                            ),
                                            content: Text(
                                              'Are you sure you want to logout?',
                                              style: GoogleFonts.poppins(
                                                color: darkBlue.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.poppins(
                                                    color: darkBlue.withValues(
                                                      alpha: 0.7,
                                                    ),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _logout();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Logout',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.logout, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Logout',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
        bottomNavigationBar: CustomCircularNavBar(
          currentIndex: 1, // Profile está selecionado
          onTap: (index) {
            if (index == 0) {
              Navigator.pop(
                context,
                _profileUpdated,
              ); // Volta para home with update flag
            } else if (index == 1) {
              // Profile - já estamos no perfil, não faz nada
            }
          },
        ),
      ),
    ); // End of Scaffold
  } // End of WillPopScope

  Widget _buildActionRow(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    return _SettingsCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      darkBlue: darkBlue,
      primaryBlue: primaryBlue,
    );
  }
}

class _SettingsCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color darkBlue;
  final Color primaryBlue;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.darkBlue,
    required this.primaryBlue,
  });

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
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
                _isPressed
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Title and subtitle (sem ícone)
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.darkBlue,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: const Color.fromARGB(255, 29, 56, 95),
              ),
            ],
          ),
        ),
      ),
    );
  }
}