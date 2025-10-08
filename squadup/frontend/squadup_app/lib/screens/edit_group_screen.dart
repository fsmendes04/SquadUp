import 'package:flutter/material.dart';
import '../services/groups_service.dart';
import '../models/group_with_members.dart';
import '../widgets/avatar_group_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchGroup();
  }

  Future<void> _fetchGroup() async {
    setState(() => _loading = true);
    try {
      final group = await _groupsService.getGroup(widget.groupId);
      setState(() {
        _group = group;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar grupo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onAvatarChanged() async {
    await _fetchGroup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Grupo')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _group == null
              ? const Center(child: Text('Grupo não encontrado'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvatarGroupWidget(
                      groupId: _group!.id,
                      avatarUrl: _group!.avatarUrl,
                      allowEdit: true,
                      radius: 48,
                      onAvatarChanged: _onAvatarChanged,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _group!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    // ...outros campos de edição do grupo...
                  ],
                ),
              ),
    );
  }
}
