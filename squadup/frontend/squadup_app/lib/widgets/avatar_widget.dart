import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../config/responsive_utils.dart';

class AvatarWidget extends StatefulWidget {
  final double? radius;
  final bool allowEdit;
  final VoidCallback? onAvatarChanged;
  final AvatarController? controller;
  final String? avatarUrl;

  const AvatarWidget({
    super.key,
    this.radius,
    this.allowEdit = false,
    this.onAvatarChanged,
    this.controller,
    this.avatarUrl,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class AvatarController {
  _AvatarWidgetState? _state;

  void _attach(_AvatarWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  Future<bool> uploadSelectedAvatar() async {
    return await _state?.uploadSelectedAvatar() ?? true;
  }

  void discardChanges() {
    _state?.discardChanges();
  }

  bool hasUnsavedChanges() {
    return _state?.hasUnsavedChanges() ?? false;
  }
}

final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

class _AvatarWidgetState extends State<AvatarWidget> {
  final UserService _userService = UserService();
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    if (_isLoading) return;
    final r = context.responsive;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.borderRadius(20))),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: r.padding(left: 20, top: 20, right: 20, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: r.width(40),
                  height: r.height(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(r.borderRadius(2)),
                  ),
                ),
                SizedBox(height: r.height(20)),
                Text(
                  'Select Image Source',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: r.height(20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Galeria',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Câmera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ],
                ),
                SizedBox(height: r.height(20)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final r = context.responsive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: r.padding(left: 20, top: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(r.borderRadius(12)),
          border: Border.all(color: Colors.grey[200]!, width: r.borderWidth(1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.iconSize(32), color: Theme.of(context).primaryColor),
            SizedBox(height: r.height(8)),
            Text(
              label,
              style: TextStyle(fontSize: r.fontSize(14), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });

      widget.onAvatarChanged?.call(); // Notifica que houve uma mudança pendente
    }
  }

  Future<bool> uploadSelectedAvatar() async {
    if (_selectedImagePath == null) return true; // Nada para fazer upload

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload do avatar e atualização do perfil
      await _userService.updateProfileWithAvatar(
        avatarFilePath: _selectedImagePath!,
      );

      // Notificar que o avatar foi alterado
      widget.onAvatarChanged?.call();

      setState(() {
        _selectedImagePath = null; // Limpar seleção após upload bem-sucedido
      });
      return true;
    } catch (e) {
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void discardChanges() {
    if (mounted) {
      setState(() {
        _selectedImagePath = null;
      });
    }
  }

  bool hasUnsavedChanges() {
    return _selectedImagePath != null;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final double radius = widget.radius ?? r.width(30);

    final bool hasImage =
        (_selectedImagePath != null) ||
        (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty);
    const String defaultAvatarAsset = 'lib/images/avatar2.png';
    return Stack(
      children: [
        hasImage
            ? Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child:
                    _isLoading
                        ? Center(
                          child: SizedBox(
                            width: widget.radius,
                            height: widget.radius,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                        : (_selectedImagePath != null)
                        ? Image.file(
                          File(_selectedImagePath!),
                          fit: BoxFit.cover,
                          width: radius * 2,
                          height: radius * 2,
                        )
                        : Image.network(
                          widget.avatarUrl!,
                          fit: BoxFit.cover,
                          width: radius * 2,
                          height: radius * 2,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              defaultAvatarAsset,
                              fit: BoxFit.cover,
                              width: radius * 2,
                              height: radius * 2,
                            );
                          },
                        ),
              ),
            )
            : Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  defaultAvatarAsset,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                ),
              ),
            ),
        if (widget.allowEdit && !_isLoading)
          Positioned(
            bottom: 0,
            right: context.responsive.width(10),
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryBlue, // Fundo azul
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: context.responsive.borderWidth(2)),
                ),
                padding: EdgeInsets.all(radius * 0.1),
                child: Icon(
                  Icons.add_a_photo, // Ícone de 'mais'
                  size: radius * 0.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class UserAvatarDisplay extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatarDisplay({
    super.key,
    this.avatarUrl,
    this.radius = 25,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const String defaultAvatarAsset = 'lib/images/avatar2.png';
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child:
            avatarUrl == null
                ? ClipOval(
                  child: Image.asset(
                    defaultAvatarAsset,
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                  ),
                )
                : null,
      ),
    );
  }
}
