import 'package:flutter/material.dart';
import '../widgets/avatar_group.dart';
import '../widgets/loading_overlay.dart';
import '../services/groups_service.dart';
import '../widgets/header.dart';
import '../widgets/squadup_input.dart';
import '../widgets/squadup_button.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: GroupAvatarDisplay(avatarUrl: _avatarPath, radius: 90),
                        ),
                        const SizedBox(height: 30),
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
                        SquadUpInput(
                          controller: _membersController,
                          label: 'Group Members (IDs, comma separated)',
                          icon: Icons.person_add_rounded,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 30),
                        SquadUpButton(
                          text: 'Create',
                          onPressed: _isLoading ? null : _createGroup,
                          isLoading: _isLoading,
                          backgroundColor: darkBlue,
                          disabledColor: darkBlue.withAlpha(128),
                          textColor: Colors.white,
                          borderRadius: 16,
                          height: 55,
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
