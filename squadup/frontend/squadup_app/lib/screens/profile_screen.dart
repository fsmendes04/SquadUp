import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/avatar_widget.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State {
  final _userService = UserService();
  Map? userData;
  bool _isLoading = true;
  bool _profileUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future _loadUserData() async {
    try {
      final response = await _userService.getProfile();
      // Extrair o campo 'data' da resposta
      final data = response['data'] as Map?;
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
        backgroundColor: darkBlue,
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    // App Bar Background with dark blue
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: darkBlue,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    // Main Content
                    SafeArea(
                      child: Column(
                        children: [
                          // Top bar with back button and settings
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context, _profileUpdated);
                                  },
                                  tooltip: 'Back',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 32,
                                    color: Colors.white,
                                  ),
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
                                  tooltip: 'Settings',
                                ),
                              ],
                            ),
                          ),
                          // White Card Container with all content
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 90),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                      bottom: kBottomNavigationBarHeight + 20,
                                      left: 20,
                                      right: 20,
                                      top: 90,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // User Info Section
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getDisplayName(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: darkBlue,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  userData?['email'] ??
                                                      'No email',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: darkBlue.withValues(
                                                      alpha: 0.6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            _buildStatColumn('0', 'Groups'),
                                          ],
                                        ),
                                        const SizedBox(height: 30),
                                        // Weekly XP Chart
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Weekly XP',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: darkBlue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            _buildWeeklyChart(primaryBlue),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Avatar positioned on top
                                Positioned(
                                  left: 24,
                                  top: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: AvatarWidget(
                                      key: ValueKey(
                                        userData?['avatar_url'] ?? 'no-avatar',
                                      ),
                                      radius: 65,
                                      allowEdit: false,
                                      avatarUrl: userData?['avatar_url'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    );
  }

  Widget _buildStatColumn(String value, String label) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkBlue.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(Color primaryBlue) {
    final List weekData = [15, 25, 10, 15, 12, 18, 5];
    final List days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxValue = weekData.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final height = (weekData[index] / maxValue) * 100;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color.fromARGB(
                    255,
                    29,
                    56,
                    95,
                  ).withValues(alpha: 0.6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
