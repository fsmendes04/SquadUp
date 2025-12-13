import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../services/user_service.dart';
import '../models/groups.dart';
import '../widgets/avatar_group.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/loading_overlay.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final GroupsService _groupsService = GroupsService();
  final UserService _userService = UserService();
  GroupWithMembers? _group;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  String? _editedName;
  late TextEditingController _nameController;
  bool _saving = false;
  String? _pendingAvatarPath; // novo: path da imagem selecionada

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _fetchGroup();
  }

  Future<void> _fetchGroup() async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await _groupsService.getGroupById(widget.groupId);
      setState(() {
        _group = GroupWithMembers.fromJson(response['data'] ?? response);
        _editedName = _group?.name;
        _nameController.text = _editedName ?? '';
        _loading = false;
        _pendingAvatarPath = null; // limpa seleção ao recarregar
      });
    } catch (e) {
      setState(() {
        _group = null;
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _group == null) return;
    _formKey.currentState!.save();
    setState(() {
      _saving = true;
    });
    try {
      // Se houver avatar novo, faz upload primeiro
      if (_pendingAvatarPath != null) {
        final response = await _groupsService.uploadGroupAvatar(
          groupId: _group!.id,
          avatarFilePath: _pendingAvatarPath!,
        );
        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Erro ao atualizar avatar');
        }
      }
      await _groupsService.updateGroup(
        groupId: _group!.id,
        name: _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Sinaliza atualização
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _showAddMemberDialog() async {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final emailController = TextEditingController();
    bool isSearching = false;
    Map<String, dynamic>? foundUser;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Member',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.poppins(color: darkBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: darkBlue, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  if (isSearching)
                    const CircularProgressIndicator()
                  else if (foundUser != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            avatarUrl: foundUser!['avatar_url'],
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              foundUser!['name'] ?? 'User',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: darkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                if (foundUser == null)
                  ElevatedButton(
                    onPressed: isSearching
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) return;

                            setDialogState(() {
                              isSearching = true;
                              errorMessage = null;
                            });

                            try {
                              final response = await _userService.getUserByEmail(email);
                              if (response['success'] == true && response['data'] != null) {
                                setDialogState(() {
                                  foundUser = response['data'];
                                  isSearching = false;
                                });
                              } else {
                                setDialogState(() {
                                  errorMessage = 'User not found';
                                  isSearching = false;
                                });
                              }
                            } catch (e) {
                              setDialogState(() {
                                errorMessage = 'Error searching user';
                                isSearching = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Search',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _groupsService.addMember(
                          groupId: widget.groupId,
                          userId: foundUser!['id'],
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          await _fetchGroup();
                        }
                      // ignore: empty_catches
                      } catch (e) {
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Add',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return LoadingOverlay(
      isLoading: _loading || _saving,
      message: _loading ? 'Loading group...' : 'Saving changes...',
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body:
            _group == null
                ? Center(
                  child: Text(
                    'Group not found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Stack(
                          children: [
                            // Blue header
                            Container(
                              height: 320.0,
                              width: double.infinity,
                              color: darkBlue,
                            ),
                            // Back and Save buttons
                            Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 10,
                                left: 15,
                                right: 15,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      size: 32,
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    color: Colors.white,
                                    tooltip: 'Back',
                                  ),
                                  TextButton(
                                    onPressed: _saving ? null : _saveChanges,
                                    child: Text(
                                      'Save',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // White card elevated
                            Positioned(
                              top: 240.0,
                              left: 15.0,
                              right: 15.0,
                              child: Material(
                                elevation: 3.0,
                                borderRadius: BorderRadius.circular(16.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 50.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.0),
                                    color: Colors.white,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 100),
                                        Center(
                                          child: Text(
                                            'Group Information',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: darkBlue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Group Name',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: darkBlue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _nameController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: darkBlue,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter group name',
                                            hintStyle: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: darkBlue.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: darkBlue,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: darkBlue,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: darkBlue,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: darkBlue,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: darkBlue,
                                                    width: 2,
                                                  ),
                                                ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Group name cannot be empty';
                                            }
                                            if (value.trim().length < 2) {
                                              return 'Name must be at least 2 characters long';
                                            }
                                            if (value.trim().length > 50) {
                                              return 'Name must be less than 50 characters';
                                            }
                                            if (!RegExp(
                                              r"^[a-zA-ZÀ-ÿ0-9\s\-']+$",
                                            ).hasMatch(value.trim())) {
                                              return 'Name can only contain letters, numbers, spaces, hyphens, and apostrophes';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 40),
                                        // Members Section
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Members',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: darkBlue,
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: _showAddMemberDialog,
                                                icon: Icon(Icons.person_add, color: darkBlue, size: 20),
                                                label: Text(
                                                  'Add',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: darkBlue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          constraints: BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: darkBlue.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: _group!.members.isEmpty
                                              ? Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(24.0),
                                                    child: Text(
                                                      'No members yet',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  shrinkWrap: true,
                                                  itemCount: _group!.members.length,
                                                  separatorBuilder: (context, index) => Divider(
                                                    height: 1,
                                                    color: darkBlue.withValues(alpha: 0.1),
                                                  ),
                                                  itemBuilder: (context, index) {
                                                    final member = _group!.members[index];
                                                    return ListTile(
                                                      leading: AvatarWidget(
                                                        avatarUrl: member.avatarUrl,
                                                        radius: 20,
                                                      ),
                                                      title: Text(
                                                        member.name ?? 'User',
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w500,
                                                          color: darkBlue,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        member.role,
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        const SizedBox(height: 40),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: darkBlue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            icon: const Icon(
                                              Icons.save,
                                              size: 22,
                                            ),
                                            label:
                                                _saving
                                                    ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                    : Text(
                                                      'Save changes',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                            onPressed:
                                                _saving ? null : _saveChanges,
                                          ),
                                        ),
                                        // ...mensagem de erro/sucesso pode ser adicionada aqui...
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Avatar centralizado sobre o card
                            Positioned(
                              top: 130.0,
                              left:
                                  (MediaQuery.of(context).size.width / 2 -
                                      120.0),
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
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: AvatarGroupWidget(
                                  groupId: _group!.id,
                                  avatarUrl: _group!.avatarUrl,
                                  radius: 110,
                                  allowEdit: true,
                                  deferredUpload: true,
                                  onImageSelected: (localPath) {
                                    setState(() {
                                      _pendingAvatarPath = localPath;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
