import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/drawer_bar.dart';
import '../widgets/group_card.dart';
import '../widgets/group_search_bar.dart';
import '../widgets/loading_overlay.dart';
import '../services/user_service.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';
import '../screens/group_home_screen.dart';
import '../config/responsive_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserService();
  final _groupsService = GroupsService();

  Map<String, dynamic>? _userData;
  List<GroupWithMembers> _userGroups = [];
  bool _isLoadingGroups = true;
  String? _groupsError;

  // Search functionality
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  List<GroupWithMembers> get _filteredGroups {
    if (_searchQuery.isEmpty) {
      return _userGroups;
    }
    return _userGroups.where((group) {
      return group.name.toLowerCase().startsWith(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _userService.getProfile();

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'];

        if (userData['name'] == null || userData['name'].toString().isEmpty) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/add-name');
            return;
          }
        }

        if (mounted) {
          setState(() {
            _userData = userData;
          });

          await _loadUserGroups();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
          _groupsError = 'Erro ao carregar dados do usuário';
        });
      }
    }
  }

  Future<void> _loadUserGroups() async {
    try {
      setState(() {
        _isLoadingGroups = true;
        _groupsError = null;
      });

      final response = await _groupsService.getUserGroups();

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final groupsList =
              (response['data'] as List)
                  .map((json) => GroupWithMembers.fromJson(json))
                  .toList();

          setState(() {
            _userGroups = groupsList;
            _isLoadingGroups = false;
          });
        } else {
          setState(() {
            _isLoadingGroups = false;
            _groupsError = response['message'] ?? 'Erro ao carregar grupos';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
          _groupsError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _refreshGroups() async {
    await _loadUserGroups();
  }

  Widget _buildGroupsList(Color primaryBlue) {
    final r = context.responsive;
    
    if (_isLoadingGroups) {
      return Center(
        child: Padding(
          padding: r.padding(top: 40, bottom: 40, left: 40, right: 40),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_groupsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: r.iconSize(48), color: Colors.grey[400]),
            r.verticalSpace(16),
            Text(
              'Error loading groups',
              style: GoogleFonts.poppins(fontSize: r.fontSize(16), color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            r.verticalSpace(16),
            ElevatedButton(
              onPressed: _refreshGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: r.circularBorderRadius(12),
                ),
              ),
              child: Text(
                'Try again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final groupsToShow = _filteredGroups;

    if (_userGroups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: r.symmetricPadding(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo com gradiente e sombra
            SizedBox(
              width: r.width(300),
              height: r.height(300),
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    width: r.width(300),
                    height: r.height(300),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            r.verticalSpace(32),
            Text(
              "You're not part of any group yet",
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(16),
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            r.verticalSpace(8),
            Text(
              'Create or join a group to get started!',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(16),
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            r.verticalSpace(40),
            GestureDetector(
              onTap:
                  () => Navigator.of(context).pushNamed('/create-group').then((
                    _,
                  ) async {
                    await _refreshGroups();
                  }),
              child: Container(
                padding: r.symmetricPadding(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 15, 74, 128),
                  borderRadius: BorderRadius.circular(r.borderRadius(15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Group',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (groupsToShow.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: r.symmetricPadding(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: r.width(300),
              height: r.height(300),
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    width: r.width(300),
                    height: r.height(300),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            r.verticalSpace(32),
            Text(
              'No groups found',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(18),
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupsToShow.length,
      itemBuilder: (context, index) {
        final group = groupsToShow[index];
        return GroupCard(
          group: group,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => GroupHomeScreen(
                      groupId: group.id,
                      groupName: group.name,
                    ),
              ),
            );
            if (result != null) {
              await _refreshGroups();
            }
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await _userService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error logging out');
      }
    }
  }

  String _getDisplayName() {
    if (_userData != null) {
      // O nome agora vem diretamente do perfil (campo 'name')
      final name = _userData!['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    return 'User';
  }

  final GlobalKey<CustomDrawerBarState> _drawerKey =
      GlobalKey<CustomDrawerBarState>();

  void _openDrawer() {
    _drawerKey.currentState?.toggleMenu();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final theme = Theme.of(context);
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return LoadingOverlay(
      isLoading: _isLoadingGroups && _userData == null,
      message: 'Loading your groups...',
      child: CustomDrawerBar(
        key: _drawerKey,
        userName: _getDisplayName(),
        onItemTap: (index) async {
          switch (index) {
            case 0:
              await Navigator.pushNamed(context, '/settings');
              break;
            case 1:
              await Navigator.pushNamed(context, '/language');
              break;
            case 2:
              _logout();
              break;
          }
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: r.symmetricPadding(horizontal: 14),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_isSearching) {
                    setState(() {
                      _isSearching = false;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'lib/images/logo_v3.png',
                                height: r.height(40),
                                width: r.width(40),
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: r.width(10)),
                              Text(
                                'SquadUp',
                                style: GoogleFonts.poppins(
                                  fontSize: r.fontSize(24),
                                  fontWeight: FontWeight.w500,
                                  color: darkBlue,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Notification with badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.notifications_none_outlined,
                                      size: r.iconSize(34),
                                    ),
                                    color: darkBlue,
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/notifications');
                                      },
                                    tooltip: 'Notificações',
                                  ),
                                  Positioned(
                                    right: r.width(6),
                                    top: r.height(6),
                                    child: Container(
                                      padding: r.padding(left: 4.5, top: 4.5, right: 4.5, bottom: 4.5),
                                      decoration: BoxDecoration(
                                        color: primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.scaffoldBackgroundColor,
                                          width: r.borderWidth(1.5),
                                        ),
                                      ),
                                      child: Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: r.fontSize(9),
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(Icons.menu_rounded, size: r.iconSize(34)),
                                color: darkBlue,
                                onPressed: _openDrawer,
                                tooltip: 'Menu',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    r.verticalSpace(25),
                    // Greeting
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              Text(
                                'Hi, ${_getDisplayName()}!',
                                style: GoogleFonts.poppins(
                                  fontSize: r.fontSize(24),
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                        ],
                      ),
                    ),

                    r.verticalSpace(25),

                    // Scrollable main content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshGroups,
                        color: primaryBlue,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: kBottomNavigationBarHeight + r.height(12),
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child:
                              _userGroups.isEmpty &&
                                      !_isLoadingGroups &&
                                      _groupsError == null
                                  ? SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height -
                                        kToolbarHeight -
                                        kBottomNavigationBarHeight -
                                        r.height(200),
                                    child: _buildGroupsList(primaryBlue),
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Section title and add button
                                      
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'My Groups',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkBlue,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap:
                                                    () => Navigator.of(context)
                                                        .pushNamed(
                                                          '/create-group',
                                                        )
                                                        .then((_) async {
                                                          await _refreshGroups();
                                                        }),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: primaryBlue,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: darkBlue
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.add,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'New',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        r.verticalSpace(20),

                                      // Search bar
                                      GroupSearchBar(
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                        onSearchingChanged: (searching) {
                                          setState(() {
                                            _isSearching = searching;
                                          });
                                        },
                                      ),

                                      r.verticalSpace(14),

                                      // Groups list
                                      _buildGroupsList(primaryBlue),

                                      r.verticalSpace(8),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: CustomCircularNavBar(
            currentIndex: 0,
            onTap: (index) async {
              if (index == 0) {
                // Home - já estamos na home
              } else if (index == 1) {
                // Profile
                final result = await Navigator.pushNamed(context, '/profile');
                if (result == true) {
                  _loadUserData();
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
