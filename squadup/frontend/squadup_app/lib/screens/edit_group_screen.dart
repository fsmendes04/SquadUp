import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/squadup_input.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';
import '../widgets/avatar_group.dart';

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

  void _onAvatarSelected(String? localPath) {
    setState(() {
      _pendingAvatarPath = localPath;
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grupo atualizado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.of(context).pop(true); // Sinaliza atualização
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Group',
          style: GoogleFonts.poppins(
            color: darkBlue,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            tooltip: 'Back',
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _group == null
                  ? Center(
                      child: Text(
                        'Group not found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            Center(
                              child: AvatarGroupWidget(
                                groupId: _group!.id,
                                avatarUrl: _group!.avatarUrl,
                                allowEdit: true,
                                deferredUpload: true,
                                onImageSelected: _onAvatarSelected,
                                radius: 48,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SquadUpInput(
                              controller: _nameController,
                              label: 'Group name',
                              icon: Icons.group,
                              onChanged: (value) {
                                // Opcional: lógica ao digitar
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Group name cannot be empty';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: _saving ? null : _saveChanges,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _saving ? Colors.grey[400] : primaryBlue,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: darkBlue.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _saving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Save changes',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}