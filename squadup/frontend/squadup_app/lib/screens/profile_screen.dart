import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/loading_overlay.dart';
import '../services/user_service.dart';
import '../config/responsive_utils.dart';

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
      final cachedData = await _userService.getProfileFromStorage();

      if (cachedData != null) {
        if (mounted) {
          setState(() {
            userData = cachedData;
            _isLoading = false;
          });
        }
      } else {
        final response = await _userService.getProfile();
        final data = response['data'] as Map?;

        if (data != null) {
          await _userService.getProfileFromStorage(); 
        }

        if (mounted) {
          setState(() {
            userData = data;
            _isLoading = false;
          });
        }
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
    final r = context.responsive;
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    const darkBlue = Color.fromARGB(255, 29, 56, 95);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _profileUpdated);
        }
      },
      child: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading profile...',
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.grey[100],
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  // Background container
                  SizedBox(height: r.height(350), width: double.infinity),
                  // Blue header
                  Container(
                    height: r.height(200),
                    width: double.infinity,
                    color: darkBlue,
                  ),
                  // Back and Edit buttons com padding lateral
                  Padding(
                    padding: r.padding(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 15,
                      right: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, size: r.iconSize(32)),
                          onPressed: () {
                            Navigator.pop(context, _profileUpdated);
                          },
                          color: Colors.white,
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: r.iconSize(32)),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/edit-profile',
                            );
                            if (result == true) {
                              _profileUpdated = true;
                              _loadUserData();
                            }
                          },
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // White card (ajustado para não cortar)
                  Positioned(
                    top: r.height(165),
                    left: r.width(15),
                    right: r.width(15),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: r.circularBorderRadius(16),
                      child: Container(
                        padding: r.symmetricPadding(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: r.circularBorderRadius(16),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            r.verticalSpace(90),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getDisplayName(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: r.fontSize(20),
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.group, color: darkBlue, size: r.iconSize(22)),
                              ],
                            ),
                            r.verticalSpace(2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    userData?['email'] ?? 'No email',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w400,
                                      fontSize: r.fontSize(15),
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '2', // Troque por userData?['groupsCount'] se disponível
                                  style: GoogleFonts.poppins(
                                    fontSize: r.fontSize(17),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Avatar
                  Positioned(
                    top: r.height(90),
                    left: (MediaQuery.of(context).size.width / 2 - r.width(85)),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: r.borderWidth(4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: r.width(10),
                            offset: Offset(0, r.height(5)),
                          ),
                        ],
                      ),
                      child: AvatarWidget(
                        key: ValueKey(userData?['avatar_url'] ?? 'no-avatar'),
                        radius: r.width(80),
                        allowEdit: false,
                        avatarUrl: userData?['avatar_url'],
                      ),
                    ),
                  ),
                  // ...removido, agora está dentro do card branco...
                ],
              ),
              r.verticalSpace(35),
              // Recent expenses section
              Padding(
                padding: r.padding(left: 15, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Expenses',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(17),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'see all',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(15),
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              r.verticalSpace(15),
              Padding(
                padding: r.padding(left: 15, right: 5),
                child: SizedBox(
                  height: r.height(125),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildExpenseCard(
                        'Dinner',
                        Icons.restaurant,
                        '\$45.50',
                        primaryBlue.withValues(alpha: 0.8),
                      ),
                      _buildExpenseCard(
                        'Movies',
                        Icons.movie,
                        '\$28.00',
                        primaryBlue.withValues(alpha: 0.8),
                      ),
                      _buildExpenseCard(
                        'Gas',
                        Icons.local_gas_station,
                        '\$35.20',
                        primaryBlue.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
              r.verticalSpace(25),
              // Statistics section
              Padding(
                padding: r.padding(left: 15, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statistics',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(17),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'this month',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(15),
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              r.verticalSpace(15),
              Padding(
                padding: r.symmetricPadding(horizontal: 15),
                child: _buildStatisticsCard(darkBlue),
              ),
              SizedBox(height: kBottomNavigationBarHeight + r.height(30)),
            ],
          ),
          bottomNavigationBar: CustomCircularNavBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.pop(context, _profileUpdated);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
    String title,
    IconData icon,
    String amount,
    Color primaryBlue,
  ) {
    final r = context.responsive;
    return Padding(
      padding: r.padding(right: 10),
      child: Container(
        height: r.height(100),
        width: r.width(125),
        decoration: BoxDecoration(
          borderRadius: r.circularBorderRadius(7),
          gradient: LinearGradient(
            colors: [primaryBlue, primaryBlue.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.3),
              blurRadius: r.width(8),
              offset: Offset(0, r.height(4)),
            ),
          ],
        ),
        child: Padding(
          padding: r.padding(left: 12, top: 12, right: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: r.iconSize(32)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(14),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  r.verticalSpace(4),
                  Text(
                    amount,
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(Color primaryBlue) {
    final r = context.responsive;
    return Material(
      elevation: 4.0,
      borderRadius: r.circularBorderRadius(7),
      child: Container(
        padding: r.padding(left: 20, top: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: r.circularBorderRadius(7),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Spent', '\$431.45', primaryBlue),
                _buildStatItem('Groups', '2', primaryBlue),
              ],
            ),
            r.verticalSpace(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Expenses', '12', primaryBlue),
                _buildStatItem('Avg/Day', '\$14.38', primaryBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color primaryBlue) {
    final r = context.responsive;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: r.fontSize(20),
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        r.verticalSpace(4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: r.fontSize(13),
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
