import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/drawer_bar.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/group_card.dart';
import '../services/auth_service.dart';
import '../services/groups_service.dart';
import '../models/group_with_members.dart';
import '../models/create_group_request.dart';
import '../models/add_member_request.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _groupsService = GroupsService();
  Map<String, String?>? userData;
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
      final user = await _authService.getStoredUser();

      if (user != null && (user['name'] == null || user['name']!.isEmpty)) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/add-name');
          return;
        }
      }

      if (mounted) {
        setState(() {
          userData = user;
        });

        // Carregar grupos do usuário após carregar os dados do usuário
        if (user != null && user['id'] != null) {
          await _loadUserGroups(user['id']!);
        }
      }
    } catch (e) {
      // Handle error silently or show a message
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
          _groupsError = 'Erro ao carregar dados do usuário';
        });
      }
    }
  }

  Future<void> _loadUserGroups(String userId) async {
    try {
      setState(() {
        _isLoadingGroups = true;
        _groupsError = null;
      });

      final groups = await _groupsService.getUserGroups(userId);

      if (mounted) {
        setState(() {
          _userGroups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      print('Error loading user groups: $e');
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
          _groupsError = 'Erro ao carregar seus grupos';
        });
      }
    }
  }

  Future<void> _refreshGroups() async {
    if (userData != null && userData!['id'] != null) {
      await _loadUserGroups(userData!['id']!);
    }
  }

  // Converte GroupWithMembers para o formato esperado pelo GroupCard
  Map<String, dynamic> _groupToCardFormat(GroupWithMembers group, int index) {
    // Cores predefinidas para os grupos
    final colors = [
      const Color(0xFF51A3E6),
      const Color(0xFF6C63FF),
      const Color(0xFF2ECC71),
      const Color(0xFFE74C3C),
      const Color(0xFFF39C12),
      const Color(0xFF9B59B6),
    ];

    // Imagens predefinidas para os grupos
    final images = [
      'lib/images/group1.png',
      'lib/images/group2.png',
      'lib/images/group3.png',
    ];

    // Calcular última atividade (simulado - você pode implementar com dados reais)
    final now = DateTime.now();
    final difference = now.difference(group.updatedAt);
    String lastActivity;

    if (difference.inMinutes < 60) {
      lastActivity = '${difference.inMinutes} min atrás';
    } else if (difference.inHours < 24) {
      lastActivity = '${difference.inHours}h atrás';
    } else {
      lastActivity = '${difference.inDays} dias atrás';
    }

    return {
      'id': group.id,
      'name': group.name,
      'memberCount': group.memberCount,
      'lastActivity': lastActivity,
      'image': images[index % images.length],
      'color': colors[index % colors.length],
      'isActive': true,
    };
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
      const SizedBox(height: 100);
      return Center(
        child: Column(
          children: [
            Icon(Icons.group_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Você ainda não faz parte de nenhum grupo',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie seu primeiro grupo ou peça para ser adicionado!',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
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
        final groupData = _groupToCardFormat(_userGroups[index], index);
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GroupCard(
            group: groupData,
            onTap: () {
              // Navegar para a tela específica do grupo
              Navigator.pushNamed(
                context,
                '/group',
                arguments: {
                  'groupId': groupData['id'],
                  'groupName': groupData['name'],
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  String _getDisplayName() {
    if (userData != null) {
      if (userData!['name'] != null && userData!['name']!.isNotEmpty) {
        return userData!['name']!;
      }
    }
    return 'User';
  }

  void _showTopDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: CustomDrawerBar(
              onItemTap: (index) {
                Navigator.of(context).pop(); // Fecha o drawer
                // Navegação baseada no index (sem redirecionamentos ainda)
                switch (index) {
                  case 0: // Home
                    // Já está na home
                    break;
                  case 1: // Perfil
                    // TODO: Implementar navegação para perfil
                    break;
                  case 2: // Chat
                    // TODO: Implementar navegação para chat
                    break;
                  case 3: // Definições
                    // TODO: Implementar navegação para definições
                    break;
                  case 4: // Logout
                    _logout();
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CreateGroupDialog(
          onCreateGroup: (String name, List<String> members) async {
            await _createGroup(name, members);
          },
        );
      },
    );
  }

  Future<void> _createGroup(String name, List<String> members) async {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    try {
      if (userData == null || userData!['id'] == null) {
        _showErrorSnackBar('Erro: usuário não encontrado');
        return;
      }

      // Criar o grupo usando o service
      final createdGroup = await _groupsService.createGroup(
        CreateGroupRequest(name: name),
        userData!['id']!,
      );

      // Variáveis para rastrear membros adicionados
      List<String> failedToAdd = [];

      // Adicionar membros ao grupo se foram especificados
      if (members.isNotEmpty) {
        List<String> successfullyAdded = [];

        for (String memberId in members) {
          try {
            await _groupsService.addMember(
              createdGroup.id,
              AddMemberRequest(userId: memberId),
              userData!['id']!,
            );
            successfullyAdded.add(memberId);
          } catch (e) {
            print('Erro ao adicionar membro $memberId: $e');
            failedToAdd.add(memberId);
          }
        }

        // Mostrar feedback sobre membros que falharam
        if (failedToAdd.isNotEmpty && mounted) {
          _showErrorSnackBar(
            'Alguns membros não puderam ser adicionados: ${failedToAdd.join(', ')}',
          );
        }
      }

      // Recarregar a lista de grupos
      await _refreshGroups();

      // Mostrar mensagem de sucesso
      if (mounted) {
        String successMessage = 'Grupo "$name" criado com sucesso!';
        if (members.isNotEmpty) {
          final addedCount = members.length - failedToAdd.length;
          if (addedCount > 0) {
            successMessage += ' $addedCount membro(s) adicionado(s).';
          }
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
    } catch (e) {
      print('Error creating group: $e');
      _showErrorSnackBar('Erro ao criar grupo: ${e.toString()}');
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
    // Usando as mesmas cores da login page
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230); // #51A3E6
    final darkBlue = const Color.fromARGB(
      255,
      29,
      56,
      95,
    ); // Mesma cor do texto principal da login/ Mesma cor do texto secundário

    return Scaffold(
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
                                size: 32,
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
                        Builder(
                          builder:
                              (context) => IconButton(
                                icon: const Icon(Icons.menu_rounded, size: 32),
                                color: darkBlue,
                                onPressed: () => _showTopDrawer(context),
                                tooltip: 'Menu',
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
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

              const SizedBox(height: 15),

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title and add button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: darkBlue.withValues(alpha: 0.3),
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
        currentIndex: 0, // Home está selecionado por padrão
        onTap: (index) async {
          if (index == 0) {
            // Home - já estamos na home, não faz nada
          } else if (index == 1) {
            // Profile - navegar para página de perfil
            final result = await Navigator.pushNamed(context, '/profile');

            // If profile was updated, reload user data
            if (result == true) {
              _loadUserData();
            }
          }
        },
      ),
    );
  }
}
