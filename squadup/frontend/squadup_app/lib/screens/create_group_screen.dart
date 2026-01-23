import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/avatar_group.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/loading_overlay.dart';
import '../services/groups_service.dart';
import '../services/user_service.dart';
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
  bool _isSearching = false;
  final GroupsService _groupsService = GroupsService();
  final UserService _userService = UserService();
  final List<Map<String, String>> _selectedMembers = [];
  Map<String, dynamic>? _searchedUser;

  final Color darkBlue = const Color(0xFF1D385F);
  final Color primaryBlue = const Color(0xFF51A3E6);

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _removeMember(String email) {
    setState(() {
      _selectedMembers.removeWhere((member) => member['email'] == email);
    });
  }

  Future<void> _searchUserByEmail(String email) async {
    if (email.trim().isEmpty) {
      setState(() {
        _searchedUser = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _userService.getUserByEmail(email.trim());
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _searchedUser = response['data'];
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchedUser = null;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchedUser = null;
        _isSearching = false;
      });
    }
  }

  void _addMemberFromSearch() {
    if (_searchedUser == null) return;
    
    final userEmail = _searchedUser!['email']?.toString() ?? '';
    final userName = _searchedUser!['name']?.toString() ?? 'Unknown';
    final avatarUrl = _searchedUser!['avatar_url']?.toString();
    
    final isAlreadySelected = _selectedMembers.any((m) => m['email'] == userEmail);
    
    if (!isAlreadySelected) {
      setState(() {
        _selectedMembers.add({
          'email': userEmail,
          'name': userName,
          'avatar_url': avatarUrl ?? '',
        });
        _searchController.clear();
        _searchedUser = null;
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final memberEmails = _selectedMembers.map((m) => m['email']!).toList();
      // 1. Criar grupo
      final response = await _groupsService.createGroup(
        name: _groupNameController.text.trim(),
        memberEmails: memberEmails,
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
                        r.verticalSpace(14),
                        // Selected members chips
                        if (_selectedMembers.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                'Selected Members',
                                style: GoogleFonts.poppins(
                                  fontSize: r.fontSize(15),
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.width(8),
                                  vertical: r.width(4),
                                ),
                                child: Text(
                                  '${_selectedMembers.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: r.fontSize(15),
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          r.verticalSpace(12),
                          Wrap(
                            spacing: r.width(8),
                            runSpacing: r.height(8),
                            children: _selectedMembers.map((member) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(r.borderRadius(20)),
                                  border: Border.all(
                                    color: darkBlue.withOpacity(0.3),
                                    width: r.borderWidth(2),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.width(12),
                                  vertical: r.width(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AvatarWidget(
                                      avatarUrl: member['avatar_url'],
                                      radius: r.width(16),
                                    ),
                                    SizedBox(width: r.width(8)),
                                    Text(
                                      member['name']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(14),
                                        fontWeight: FontWeight.w500,
                                        color: darkBlue,
                                      ),
                                    ),
                                    SizedBox(width: r.width(10)),
                                    GestureDetector(
                                      onTap: () => _removeMember(member['email']!),
                                      child: Container(
                                        padding: EdgeInsets.all(r.width(2)),
                                        decoration: BoxDecoration(
                                          color: darkBlue.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: r.width(14),
                                          color: darkBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          r.verticalSpace(16),
                        ],
                        // Search box
                        SquadUpInput(
                          controller: _searchController,
                          label: 'Add Members',
                          icon: Icons.search,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => _searchUserByEmail(value),
                          suffixIcon: _isSearching
                              ? Padding(
                                  padding: EdgeInsets.all(r.width(12)),
                                  child: SizedBox(
                                    width: r.width(20),
                                    height: r.width(20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryBlue,
                                    ),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: darkBlue,
                                        size: r.iconSize(20),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchedUser = null;
                                        });
                                      },
                                    )
                                  : null,
                        ),
                        // Search results
                        if (_searchedUser != null) ...[
                          r.verticalSpace(8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.borderRadius(12)),
                              border: Border.all(color: Colors.grey[300]!, width: r.borderWidth(1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: r.width(8),
                                  offset: Offset(0, r.height(2)),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _addMemberFromSearch,
                                borderRadius: BorderRadius.circular(r.borderRadius(12)),
                                child: Padding(
                                  padding: EdgeInsets.all(r.width(12)),
                                  child: Row(
                                    children: [
                                      AvatarWidget(
                                        avatarUrl: _searchedUser!['avatar_url']?.toString(),
                                        radius: r.width(20),
                                      ),
                                      SizedBox(width: r.width(12)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _searchedUser!['name']?.toString() ?? 'Unknown',
                                              style: GoogleFonts.poppins(
                                                fontSize: r.fontSize(14),
                                                fontWeight: FontWeight.w600,
                                                color: darkBlue,
                                              ),
                                            ),
                                            Text(
                                              _searchedUser!['email']?.toString() ?? '',
                                              style: GoogleFonts.poppins(
                                                fontSize: r.fontSize(12),
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _selectedMembers.any((m) =>
                                            m['email'] == _searchedUser!['email']?.toString())
                                            ? Icons.check_circle
                                            : Icons.add_circle_outline,
                                        color: _selectedMembers.any((m) =>
                                            m['email'] == _searchedUser!['email']?.toString())
                                            ? Colors.green
                                            : primaryBlue,
                                        size: r.iconSize(24),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
