import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class AvatarWidget extends StatefulWidget {
  final double radius;
  final bool allowEdit;
  final VoidCallback? onAvatarChanged;

  const AvatarWidget({
    Key? key,
    this.radius = 30,
    this.allowEdit = false,
    this.onAvatarChanged,
  }) : super(key: key);

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  final AuthService _authService = AuthService();
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
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
                        _pickAndUploadAvatar(ImageSource.gallery);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Câmera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadAvatar(ImageSource.camera);
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

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_isLoading) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _authService.uploadAvatar(pickedFile.path);

        if (response.success && mounted) {
          await _loadAvatar(); // Recarregar avatar
          widget.onAvatarChanged?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar avatar: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro inesperado: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
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
                  : _avatarUrl == null
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
