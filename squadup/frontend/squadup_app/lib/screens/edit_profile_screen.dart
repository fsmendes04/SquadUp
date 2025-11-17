import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../widgets/avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userService = UserService();
  final _avatarController = AvatarController();

  bool _isLoading = false;
  bool _isLoadingUserData = true;
  String _message = '';
  Map<String, String?>? userData;
  String? _currentAvatarUrl; // Avatar atual do usuário

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _nameController.addListener(_clearErrorMessage);
  }

  @override
  void dispose() {
    _nameController.removeListener(_clearErrorMessage);
    _nameController.dispose();
    super.dispose();
  }

  void _clearErrorMessage() {
    if (_message.isNotEmpty) {
      setState(() {
        _message = '';
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _userService.getProfile();
      final user = response['data'] as Map<String, dynamic>?;

      setState(() {
        userData = user?.map((key, value) => MapEntry(key, value?.toString()));
        _currentAvatarUrl = user?['avatar_url']; // Armazena avatar atual
        _nameController.text = user?['name'] ?? '';
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      bool avatarSuccess = true;
      bool nameSuccess = true;
      bool hadAvatarChanges = _avatarController.hasUnsavedChanges();

      // Primeiro, fazer upload do avatar se houver mudanças pendentes
      if (hadAvatarChanges) {
        avatarSuccess = await _avatarController.uploadSelectedAvatar();
        if (!avatarSuccess) {
          setState(() {
            _message = 'Erro ao fazer upload do avatar. Tente novamente.';
            _isLoading = false;
          });
          return;
        }
      }

      // Depois, atualizar o nome se foi alterado
      final newName = _nameController.text.trim();
      final currentName = userData?['name'] ?? '';

      if (newName.isNotEmpty && newName != currentName) {
        try {
          await _userService.updateProfile(name: newName);
          nameSuccess = true;
        } catch (e) {
          nameSuccess = false;
        }
      }

      if (avatarSuccess && nameSuccess) {
        if (mounted) {
          String successMessage = '';
          if (hadAvatarChanges && newName.isNotEmpty) {
            successMessage = 'Nome e avatar atualizados com sucesso!';
          } else if (hadAvatarChanges) {
            successMessage = 'Avatar atualizado com sucesso!';
          } else if (newName.isNotEmpty) {
            successMessage = 'Nome atualizado com sucesso!';
          } else {
            successMessage = 'Perfil salvo com sucesso!';
          }

          setState(() {
            _message = successMessage;
          });

          // Recarregar dados do usuário para pegar o novo avatar
          await _loadUserData();

          // Update local userData
          setState(() {
            userData = {...userData!, 'name': newName};
          });

          // Show success message and navigate back after a delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context, true); // Return true to indicate success
            }
          });
        }
      } else {
        if (mounted) {
          String errorMessage = '';
          if (!avatarSuccess && !nameSuccess) {
            errorMessage = 'Falha ao atualizar avatar e nome. Tente novamente.';
          } else if (!avatarSuccess) {
            errorMessage = 'Falha ao atualizar avatar. Tente novamente.';
          } else if (!nameSuccess) {
            errorMessage = 'Falha ao atualizar o nome. Tente novamente.';
          }

          setState(() {
            _message = errorMessage;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Erro inesperado. Tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (_avatarController.hasUnsavedChanges()) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Mudanças não salvas'),
                  content: const Text(
                    'Você tem mudanças no avatar que não foram salvas. Deseja descartar as mudanças?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        _avatarController.discardChanges();
                        Navigator.pop(context, true);
                      },
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
          );
          if (!(shouldDiscard ?? false)) {
            return;
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body:
            _isLoadingUserData
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Stack(
                          children: [
                            // Blue header (aumentado)
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
                                    onPressed: () => Navigator.pop(context),
                                    color: Colors.white,
                                    tooltip: 'Back',
                                  ),
                                  TextButton(
                                    onPressed: _isLoading ? null : _saveProfile,
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 110),
                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                'Personal Information',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkBlue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 30),
                                            Text(
                                              'Name',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: darkBlue,
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
                                                hintText:
                                                    'Enter your full name',
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
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: darkBlue,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
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
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
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
                                                  return 'Please enter your name';
                                                }
                                                if (value.trim().length < 2) {
                                                  return 'Name must be at least 2 characters long';
                                                }
                                                if (value.trim().length > 50) {
                                                  return 'Name must be less than 50 characters';
                                                }
                                                if (!RegExp(
                                                  r"^[a-zA-ZÀ-ÿ\s\-']+$",
                                                ).hasMatch(value.trim())) {
                                                  return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              'Email',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: darkBlue,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      userData?['email'] ??
                                                          'No email',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: darkBlue
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.lock_outline,
                                                    size: 20,
                                                    color: darkBlue.withValues(
                                                      alpha: 0.5,
                                                    ),
                                                  ),
                                                ],
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
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  elevation: 2,
                                                ),
                                                icon: const Icon(
                                                  Icons.lock_reset,
                                                  size: 22,
                                                ),
                                                label: Text(
                                                  'Change Password',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/change-password',
                                                  );
                                                },
                                              ),
                                            ),
                                            // ...nenhuma caixa de mensagem de erro ou sucesso...
                                          ],
                                        ),
                                      ),
                                    ],
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
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: AvatarWidget(
                                  key: ValueKey(
                                    _currentAvatarUrl ?? 'no-avatar',
                                  ),
                                  radius: 110,
                                  allowEdit: true,
                                  controller: _avatarController,
                                  avatarUrl: _currentAvatarUrl,
                                  onAvatarChanged: () {
                                    setState(() {
                                      _message = '';
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
