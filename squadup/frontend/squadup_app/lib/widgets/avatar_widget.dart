import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

class AvatarWidget extends StatefulWidget {
  final double radius;
  final bool allowEdit;
  final VoidCallback? onAvatarChanged;
  final AvatarController? controller;
  final String? avatarUrl;

  const AvatarWidget({
    super.key,
    this.radius = 30,
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

class _AvatarWidgetState extends State<AvatarWidget> {
  final UserService _userService = UserService();
  String? _selectedImagePath; // Para armazenar o caminho da imagem selecionada
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Escolher foto do perfil',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Imagem selecionada. Clique em "Save" para salvar as alterações.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Método para fazer upload do avatar selecionado (será chamado pelo EditProfileScreen)
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

  // Método para descartar mudanças pendentes
  void discardChanges() {
    if (mounted) {
      setState(() {
        _selectedImagePath = null;
      });
    }
  }

  // Verifica se há mudanças pendentes
  bool hasUnsavedChanges() {
    return _selectedImagePath != null;
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.radius;

    return Stack(
      children: [
        Container(
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
                            Colors.grey,
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
                    : (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                    ? Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                      width: radius * 2,
                      height: radius * 2,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.person,
                            size: widget.radius * 0.8,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                    : Center(
                      child: Icon(
                        Icons.person,
                        size: widget.radius * 0.8,
                        color: Colors.grey,
                      ),
                    ),
          ),
        ),
        if (widget.allowEdit && !_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: EdgeInsets.all(widget.radius * 0.15),
                child: Icon(
                  Icons.camera_alt,
                  size: widget.radius * 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Widget simples para exibir avatar apenas (sem edição)
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
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child:
            avatarUrl == null
                ? Icon(
                  Icons.person,
                  size: radius * 0.8,
                  color: Colors.grey[600],
                )
                : null,
      ),
    );
  }
}
