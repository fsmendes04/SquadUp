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
  bool _isSuccessMessage = false;
  Map<String, String?>? userData;

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
        _isSuccessMessage = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _userService.getProfile();
      final user = response['data'] as Map<String, dynamic>?;
      
      setState(() {
        userData = user?.map((key, value) => MapEntry(key, value?.toString()));
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
            _isSuccessMessage = false;
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
            _isSuccessMessage = true;
          });

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
            _isSuccessMessage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Erro inesperado. Tente novamente.';
          _isSuccessMessage = false;
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
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    final lightGray = const Color.fromARGB(255, 248, 249, 250);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Verificar se há mudanças não salvas
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child:
              _isLoadingUserData
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // Top bar with back button and save button
                        SizedBox(
                          height: kToolbarHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 22,
                                ),
                                color: darkBlue,
                                onPressed: () => Navigator.pop(context),
                                tooltip: 'Back',
                              ),
                              Text(
                                'Edit Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _isLoading
                                            ? darkBlue.withValues(alpha: 0.5)
                                            : primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Profile Picture with edit capability
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AvatarWidget(
                            radius: 60,
                            allowEdit: true,
                            controller: _avatarController,
                            onAvatarChanged: () {
                              // Avatar foi selecionado (não salvo ainda)
                              setState(() {
                                _message = '';
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Edit Form
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Personal Information Section
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: lightGray,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Personal Information',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: darkBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Name Field
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
                                            hintText: 'Enter your full name',
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
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: primaryBlue,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.red.shade400,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.red.shade400,
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
                                            // Check for valid characters (letters, spaces, hyphens, apostrophes)
                                            if (!RegExp(
                                              r"^[a-zA-ZÀ-ÿ\s\-']+$",
                                            ).hasMatch(value.trim())) {
                                              return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 20),

                                        // Email Field (Read-only)
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: darkBlue.withValues(
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
                                      ],
                                    ),
                                  ),

                                  if (_message.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _isSuccessMessage
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              _isSuccessMessage
                                                  ? Colors.green.shade200
                                                  : Colors.red.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _isSuccessMessage
                                                ? Icons.check_circle_outline
                                                : Icons.error_outline,
                                            color:
                                                _isSuccessMessage
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _message,
                                              style: GoogleFonts.poppins(
                                                color:
                                                    _isSuccessMessage
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade600,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 30),

                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        elevation: 2,
                                        disabledBackgroundColor: primaryBlue
                                            .withValues(alpha: 0.6),
                                        shadowColor: primaryBlue.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.save_outlined,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Save Changes',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}