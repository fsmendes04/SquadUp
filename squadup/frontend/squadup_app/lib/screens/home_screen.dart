import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/drawer_bar.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/group_card.dart';
import '../services/user_service.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';
import '../screens/group_home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    if (_isLoadingGroups) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_groupsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _groupsError!,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tentar novamente',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_userGroups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo com gradiente e sombra
            SizedBox(
              width: 300,
              height: 300,
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Subtitle
            Text(
              'You\'re not part of any group yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Create or join a group to get started!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Botão de ação
            GestureDetector(
              onTap: () => _showCreateGroupDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 15, 74, 128),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Group',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userGroups.length,
      itemBuilder: (context, index) {
        final group = _userGroups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GroupCard(
            group: group,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupHomeScreen(
                    groupId: group.id,
                    groupName: group.name,
                  ),
                ),
              );
            },
          ),
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
        _showErrorSnackBar('Erro ao fazer logout');
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

  // Nova abordagem: controlar a drawer bar animada
  final GlobalKey<CustomDrawerBarState> _drawerKey = GlobalKey<CustomDrawerBarState>();

  void _openDrawer() {
  _drawerKey.currentState?.toggleMenu();
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CreateGroupDialog(
          onCreateGroup: (String name, List<String> memberIds) async {
            Navigator.of(dialogContext).pop();
            await _createGroup(name, memberIds);
          },
        );
      },
    );
  }

  Future<void> _createGroup(String name, List<String> memberIds) async {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    try {
      // Criar o grupo
      final response = await _groupsService.createGroup(
        name: name,
        memberIds: memberIds.isNotEmpty ? memberIds : null,
      );

      if (response['success'] == true) {
        // Recarregar lista de grupos
        await _refreshGroups();

        // Mostrar mensagem de sucesso
        if (mounted) {
          String successMessage = 'Grupo "$name" criado com sucesso!';
          if (memberIds.isNotEmpty) {
            successMessage += ' ${memberIds.length} membro(s) adicionado(s).';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        _showErrorSnackBar(response['message'] ?? 'Erro ao criar grupo');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
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
    final theme = Theme.of(context);
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

      return CustomDrawerBar(
        key: _drawerKey,
        userName: _getDisplayName(),
        onItemTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            _logout();
            break;
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              children: [
                // Top bar with avatar and notification
                SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'lib/images/logo_v3.png',
                            height: 40,
                            width: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SquadUp',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
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
                                icon: const Icon(
                                  Icons.notifications_none_outlined,
                                  size: 34,
                                ),
                                color: darkBlue,
                                onPressed: () {
                                  // TODO: Implementar navegação para notificações
                                },
                                tooltip: 'Notificações',
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4.5),
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.menu_rounded, size: 34),
                            color: darkBlue,
                            onPressed: _openDrawer,
                            tooltip: 'Menu',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                // Greeting
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${_getDisplayName()}!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Scrollable main content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshGroups,
                    color: primaryBlue,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: kBottomNavigationBarHeight + 12,
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
                                    200,
                                child: _buildGroupsList(primaryBlue),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section title and add button
                                  Row(
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
                                        onTap: () => _showCreateGroupDialog(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryBlue,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: darkBlue.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'New',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
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

                                  const SizedBox(height: 20),

                                  // Groups list
                                  _buildGroupsList(primaryBlue),

                                  const SizedBox(height: 20),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
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
    );
  }
}
