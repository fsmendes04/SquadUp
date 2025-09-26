import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class AvatarWidget extends StatefulWidget {
  final double radius;
  final bool allowEdit;
  final VoidCallback? onAvatarChanged;
  final AvatarController? controller;

  const AvatarWidget({
    Key? key,
    this.radius = 30,
    this.allowEdit = false,
    this.onAvatarChanged,
    this.controller,
  }) : super(key: key);

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

// Classe controller para acessar métodos do AvatarWidget
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
  final AuthService _authService = AuthService();
  String? _avatarUrl;
  String? _selectedImagePath; // Para armazenar o caminho da imagem selecionada
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final avatarUrl = await _authService.getUserAvatarUrl();
    if (mounted) {
      setState(() {
        _avatarUrl = avatarUrl;
      });
    }
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
      final response = await _authService.uploadAvatar(_selectedImagePath!);

      if (response.success) {
        await _loadAvatar(); // Recarregar avatar
        setState(() {
          _selectedImagePath = null; // Limpar seleção após upload bem-sucedido
        });
        return true;
      } else {
        return false;
      }
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
    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              _selectedImagePath != null
                  ? FileImage(File(_selectedImagePath!)) as ImageProvider
                  : _avatarUrl != null
                  ? NetworkImage(_avatarUrl!)
                  : null,
          child:
              _isLoading
                  ? SizedBox(
                    width: widget.radius,
                    height: widget.radius,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : (_selectedImagePath == null && _avatarUrl == null)
                  ? Icon(
                    Icons.person,
                    size: widget.radius * 0.8,
                    color: Colors.grey[600],
                  )
                  : null,
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
    Key? key,
    this.avatarUrl,
    this.radius = 25,
    this.onTap,
  }) : super(key: key);

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
