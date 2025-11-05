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
    const darkBlue = Color.fromARGB(255, 29, 56, 95);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _profileUpdated);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.grey[100],
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        // Background container
                        SizedBox(height: 350.0, width: double.infinity),
                        // Blue header
                        Container(
                          height: 200.0,
                          width: double.infinity,
                          color: darkBlue,
                        ),
                        // Back and Edit buttons com padding lateral
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 10,
                            left: 15,
                            right: 15,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 32,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, _profileUpdated);
                                },
                                color: Colors.white,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 32),
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
                          top: 140.0,
                          left: 15.0,
                          right: 15.0,
                          child: Material(
                            elevation: 3.0,
                            borderRadius: BorderRadius.circular(16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 32.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.0),
                                color: Colors.white,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 90),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getDisplayName(),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20.0,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.group,
                                        color: darkBlue,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userData?['email'] ?? 'No email',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 15.0,
                                            color: Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '2', // Troque por userData?['groupsCount'] se disponível
                                        style: GoogleFonts.poppins(
                                          fontSize: 17.0,
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
                          top: 75.0,
                          left: (MediaQuery.of(context).size.width / 2 - 80.0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: AvatarWidget(
                              key: ValueKey(
                                userData?['avatar_url'] ?? 'no-avatar',
                              ),
                              radius: 75,
                              allowEdit: false,
                              avatarUrl: userData?['avatar_url'],
                            ),
                          ),
                        ),
                        // ...removido, agora está dentro do card branco...
                      ],
                    ),
                    const SizedBox(height: 35.0),
                    // Recent expenses section
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Expenses',
                            style: GoogleFonts.poppins(
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'see all',
                            style: GoogleFonts.poppins(
                              fontSize: 15.0,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 5.0),
                      child: SizedBox(
                        height: 125.0,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildExpenseCard(
                              'Dinner',
                              Icons.restaurant,
                              '\$45.50',
                              primaryBlue,
                            ),
                            _buildExpenseCard(
                              'Movies',
                              Icons.movie,
                              '\$28.00',
                              primaryBlue,
                            ),
                            _buildExpenseCard(
                              'Gas',
                              Icons.local_gas_station,
                              '\$35.20',
                              primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25.0),
                    // Statistics section
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Statistics',
                            style: GoogleFonts.poppins(
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'this month',
                            style: GoogleFonts.poppins(
                              fontSize: 15.0,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: _buildStatisticsCard(darkBlue),
                    ),
                    SizedBox(height: kBottomNavigationBarHeight + 30),
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
    );
  }

  Widget _buildExpenseCard(
    String title,
    IconData icon,
    String amount,
    Color primaryBlue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        height: 100.0,
        width: 125.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0),
          gradient: LinearGradient(
            colors: [primaryBlue, primaryBlue.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: GoogleFonts.poppins(
                      fontSize: 16.0,
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
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(7.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0),
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
            const SizedBox(height: 20),
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
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.0,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
