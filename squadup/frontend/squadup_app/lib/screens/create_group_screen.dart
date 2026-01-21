import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/avatar_group.dart';
import '../widgets/loading_overlay.dart';
import '../services/groups_service.dart';
import '../widgets/header.dart';
import '../widgets/squadup_input.dart';
import '../widgets/squadup_button.dart';
import '../config/responsive_utils.dart';

class CreateGroupScreen extends StatefulWidget {
  final Future<void> Function(
    String name,
    List<String> members,
    String? avatarPath,
  )
  onCreateGroup;

  const CreateGroupScreen({super.key, required this.onCreateGroup});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  String? _avatarPath;
  bool _isLoading = false;
  final GroupsService _groupsService = GroupsService();
  final List<Map<String, String>> _selectedMembers = [];

  final Color darkBlue = const Color(0xFF1D385F);
  final Color primaryBlue = const Color(0xFF51A3E6);

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _removeMember(String userId) {
    setState(() {
      _selectedMembers.removeWhere((member) => member['id'] == userId);
    });
  }

  void _showAddMembersBottomSheet() {
    _searchController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddMembersSheet(),
    );
  }

  Widget _buildAddMembersSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Members',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: darkBlue,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Search field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by email or username...',
                        prefixIcon: Icon(Icons.search, color: darkBlue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) => setModalState(() {}),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Members list
              Expanded(
                child: _buildMembersList(setModalState),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersList(StateSetter setModalState) {
    // Mock data - substituir por dados reais do serviço
    final allMembers = [
      {'id': '1', 'name': 'João Silva', 'username': '@joao'},
      {'id': '2', 'name': 'Maria Santos', 'username': '@maria'},
      {'id': '3', 'name': 'Pedro Costa', 'username': '@pedro'},
      {'id': '4', 'name': 'Ana Ferreira', 'username': '@ana'},
      {'id': '5', 'name': 'Carlos Oliveira', 'username': '@carlos'},
    ];

    final searchQuery = _searchController.text.toLowerCase();
    final filteredMembers = searchQuery.isEmpty
        ? allMembers
        : allMembers.where((member) {
            return member['name']!.toLowerCase().contains(searchQuery) ||
                member['username']!.toLowerCase().contains(searchQuery);
          }).toList();

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final isSelected = _selectedMembers.any((m) => m['id'] == member['id']);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryBlue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryBlue,
              child: Text(
                member['name']![0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              member['name']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              member['username']!,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Checkbox(
              value: isSelected,
              activeColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedMembers.add(member);
                  } else {
                    _selectedMembers.removeWhere((m) => m['id'] == member['id']);
                  }
                });
                setModalState(() {});
              },
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedMembers.removeWhere((m) => m['id'] == member['id']);
                } else {
                  _selectedMembers.add(member);
                }
              });
              setModalState(() {});
            },
          ),
        );
      },
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final memberIds = _selectedMembers.map((m) => m['id']!).toList();
      // 1. Criar grupo
      final response = await _groupsService.createGroup(
        name: _groupNameController.text.trim(),
        memberIds: memberIds,
      );
      if (response['success'] == true && response['data'] != null) {
        final groupId = response['data']['id']?.toString();
        // 2. Se houver avatar, fazer upload
        if (_avatarPath != null && groupId != null) {
          final avatarResp = await _groupsService.uploadGroupAvatar(
            groupId: groupId,
            avatarFilePath: _avatarPath!,
          );
          if (avatarResp['success'] != true) {
            throw Exception(
              avatarResp['message'] ?? 'Erro ao fazer upload do avatar',
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(response['message'] ?? 'Erro ao criar grupo');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Creating group...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomHeader(
                darkBlue: darkBlue,
                title: 'New Group',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: r.symmetricPadding(horizontal: 18, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        r.verticalSpace(10),
                        Center(
                          child: AvatarGroupWidget(
                            groupId: 'temp_group',
                            avatarUrl: _avatarPath,
                            radius: r.width(75),
                            allowEdit: true,
                            deferredUpload: true,
                            onImageSelected: (localPath) {
                              setState(() {
                                _avatarPath = localPath;
                              });
                            },
                          ),
                        ),
                        r.verticalSpace(30),
                        SquadUpInput(
                          controller: _groupNameController,
                          label: 'Group Name',
                          icon: Icons.groups_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a group name';
                            }
                            if (value.trim().length < 3) {
                              return 'Group name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        r.verticalSpace(20),
                        // Members section
                        Text(
                          'Members',
                          style: TextStyle(
                            fontSize: r.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: darkBlue,
                          ),
                        ),
                        r.verticalSpace(12),
                        // Add members button
                        InkWell(
                          onTap: _showAddMembersBottomSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(r.width(16)),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[40],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add_rounded,
                                  color: const Color.fromARGB(255, 19, 85, 146),
                                  size: r.width(24),
                                ),
                                SizedBox(width: r.width(12)),
                                Text(
                                  'Add Members',
                                  style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontSize: r.fontSize(14),
                                  fontWeight: FontWeight.w400,
                                ),  
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: const Color.fromARGB(255, 19, 85, 146),
                                  size: r.width(20),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedMembers.isNotEmpty) ...[
                          r.verticalSpace(20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _selectedMembers.map((member) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: darkBlue.withOpacity(0.3),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.width(8),
                                  vertical: r.width(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: primaryBlue,
                                      radius: r.width(14),
                                      child: Text(
                                        member['name']![0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: r.fontSize(12),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: r.width(8)),
                                    Text(
                                      member['name']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(13),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(width: r.width(6)),
                                    GestureDetector(
                                      onTap: () => _removeMember(member['id']!),
                                      child: Icon(
                                        Icons.close,
                                        size: r.width(16),
                                        color: darkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        r.verticalSpace(30),
                        SquadUpButton(
                          text: 'Create',
                          onPressed: _isLoading ? null : _createGroup,
                          isLoading: _isLoading,
                          backgroundColor: darkBlue,
                          disabledColor: darkBlue.withAlpha(128),
                          textColor: Colors.white,
                          borderRadius: r.borderRadius(16),
                          height: r.height(55),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
