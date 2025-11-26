import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';
import '../widgets/avatar_group.dart';
import '../widgets/loading_overlay.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final GroupsService _groupsService = GroupsService();
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
