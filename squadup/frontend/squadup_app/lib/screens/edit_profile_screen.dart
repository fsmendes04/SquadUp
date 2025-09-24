import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _avatarService = AvatarService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingUserData = true;
  bool _isUploadingAvatar = false;
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
      final user = await _authService.getStoredUser();
      setState(() {
        userData = user;
        _nameController.text = user?['name'] ?? '';
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  String _getDisplayName() {
    if (userData != null) {
      // If name is available and not null, use it
      if (userData!['name'] != null && userData!['name']!.isNotEmpty) {
        return userData!['name']!;
      }

      // Otherwise, generate name from email
      if (userData!['email'] != null) {
        final email = userData!['email']!;
        return email
            .split('@')[0]
            .replaceAll('.', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '',
            )
            .join(' ');
      }
    }
    return 'User';
  }

  String _getInitials() {
    final displayName = _getDisplayName();
    final words = displayName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _showAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final darkBlue = const Color.fromARGB(255, 29, 56, 95);

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Avatar',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAvatarOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildAvatarOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (userData?['avatar_url'] != null)
                    _buildAvatarOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      onTap: () {
                        Navigator.pop(context);
                        _removeAvatar();
                      },
                      isDestructive: true,
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isDestructive
                      ? Colors.red.shade50
                      : primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDestructive
                        ? Colors.red.shade200
                        : primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red.shade600 : primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.red.shade600 : darkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error selecting image: ${e.toString()}';
          _isSuccessMessage = false;
        });
      }
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    setState(() {
      _isUploadingAvatar = true;
      _message = '';
    });

    try {
      // Validate the image file
      final validationError = _avatarService.validateImageFile(imageFile);
      if (validationError != null) {
        setState(() {
          _message = validationError;
          _isSuccessMessage = false;
        });
        return;
      }

      // Upload the avatar
      final response = await _avatarService.uploadAvatar(imageFile);

      if (response.success && response.data != null) {
        // Update local user data
        setState(() {
          userData = {...userData!, 'avatar_url': response.data!.avatarUrl};
          _message = 'Avatar updated successfully!';
          _isSuccessMessage = true;
        });

        // Update stored user data
        await _authService.updateStoredUserAvatar(response.data!.avatarUrl);
      } else {
        setState(() {
          _message = response.message;
          _isSuccessMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error uploading avatar: ${e.toString()}';
        _isSuccessMessage = false;
      });
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
      _message = '';
    });

    try {
      final response = await _avatarService.deleteAvatar();

      if (response.success) {
        // Update local user data
        setState(() {
          userData = {...userData!, 'avatar_url': null};
          _message = 'Avatar removed successfully!';
          _isSuccessMessage = true;
        });

        // Update stored user data
        await _authService.updateStoredUserAvatar(null);
      } else {
        setState(() {
          _message = response.message;
          _isSuccessMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error removing avatar: ${e.toString()}';
        _isSuccessMessage = false;
      });
    } finally {
      setState(() {
        _isUploadingAvatar = false;
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

                      // Profile Picture with upload functionality
                      GestureDetector(
                        onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:
                                    userData?['avatar_url'] == null
                                        ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            primaryBlue,
                                            primaryBlue.withValues(alpha: 0.8),
                                          ],
                                        )
                                        : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child:
                                  userData?['avatar_url'] != null
                                      ? ClipOval(
                                        child: Image.network(
                                          userData!['avatar_url']!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    primaryBlue,
                                                    primaryBlue.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _getInitials(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                      : Center(
                                        child: Text(
                                          _getInitials(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                            ),
                            // Loading overlay
                            if (_isUploadingAvatar)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            // Edit overlay
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      _isUploadingAvatar
                                          ? Colors.grey
                                          : primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isUploadingAvatar
                                      ? Icons.hourglass_empty
                                      : Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
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
