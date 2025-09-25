import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/avatar_widget.dart';
import '../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isLoadingUserData = true;
  String _message = '';
  bool _isSuccessMessage = false;
  Map<String, String?>? userData;
  User? _currentUser;

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

  void _onAvatarUpdated(User updatedUser) {
    setState(() {
      _currentUser = updatedUser;
      // Atualizar também os dados básicos
      userData = {
        'id': updatedUser.id,
        'email': updatedUser.email,
        'name': updatedUser.name,
        'avatar_url': updatedUser.avatarUrl,
      };
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getStoredUser();
      setState(() {
        userData = user;
        _nameController.text = user?['name'] ?? '';
      });

      // Carregar dados completos do servidor incluindo avatar
      try {
        final serverUser = await _authService.getCurrentUserProfile();
        if (serverUser != null) {
          setState(() {
            _currentUser = serverUser;
          });
        }
      } catch (e) {
        print('Erro ao carregar perfil do servidor: $e');
        // Se falhar, criar User a partir dos dados locais
        if (user != null) {
          setState(() {
            _currentUser = User(
              id: user['id']!,
              email: user['email']!,
              name: user['name'],
              avatarUrl: user['avatar_url'],
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            );
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    } finally {
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
      final newName = _nameController.text.trim();
      final success = await _authService.updateUserName(newName);

      if (success) {
        if (mounted) {
          setState(() {
            _message = 'Profile updated successfully!';
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
          setState(() {
            _message = 'Failed to update profile. Please try again.';
            _isSuccessMessage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Unexpected error. Please try again.';
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

    return Scaffold(
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
                              icon: const Icon(Icons.arrow_back_ios, size: 22),
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

                      // Profile Picture with avatar editing
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
                          user: _currentUser,
                          size: 120,
                          showEditButton: true,
                          onAvatarUpdated: _onAvatarUpdated,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: primaryBlue,
                                              width: 2,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                    onPressed: _isLoading ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
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
                                              child: CircularProgressIndicator(
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
                                                    fontWeight: FontWeight.w600,
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
    );
  }
}
