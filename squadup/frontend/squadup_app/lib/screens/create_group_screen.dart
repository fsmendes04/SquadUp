import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../widgets/avatar_group.dart';
import '../services/groups_service.dart';

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
  final _membersController = TextEditingController();
  String? _avatarPath;
  bool _isLoading = false;
  final GroupsService _groupsService = GroupsService();

  final Color darkBlue = const Color(0xFF1D385F);
  final Color primaryBlue = const Color(0xFF51A3E6);

  @override
  void dispose() {
    _groupNameController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  List<String> _parseMembersList(String membersText) {
    if (membersText.trim().isEmpty) return [];
    return membersText
        .split(',')
        .map((member) => member.trim())
        .where((member) => member.isNotEmpty)
        .toList();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final members = _parseMembersList(_membersController.text);
      // 1. Criar grupo
      final response = await _groupsService.createGroup(
        name: _groupNameController.text.trim(),
        memberIds: members,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create New Group',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GroupAvatarDisplay(avatarUrl: _avatarPath, radius: 90),
              ),
              const SizedBox(height: 30),
              Text(
                'Group Name',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _groupNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 3) {
                    return 'Group name must be at least 3 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g., College Friends',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.groups_rounded,
                    color: darkBlue,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Group Members',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _membersController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Enter user IDs separated by commas\ne.g., user1, user2, user3',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: darkBlue,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: darkBlue,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'Create',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
