import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../services/user_service.dart';
import '../models/groups.dart';
import '../widgets/avatar_group.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/squadup_input.dart';
import '../config/responsive_utils.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final GroupsService _groupsService = GroupsService();
  final UserService _userService = UserService();
  GroupWithMembers? _group;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _searchController;
  bool _saving = false;
  bool _isSearchingMember = false;
  bool _isAddingMember = false;
  String? _pendingAvatarPath;
  Map<String, dynamic>? _searchedUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _searchController = TextEditingController();
    _fetchGroup();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroup({bool preserveDrafts = false}) async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await _groupsService.getGroupById(widget.groupId);
      setState(() {
        _group = GroupWithMembers.fromJson(response['data'] ?? response);
        if (!preserveDrafts) {
          _nameController.text = _group?.name ?? '';
          _pendingAvatarPath = null;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _group = null;
        _loading = false;
      });
    }
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
        Navigator.of(context).pop(true); // Sinaliza atualização
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  bool _isSearchedUserAlreadyMember() {
    if (_searchedUser == null || _group == null) return false;
    final searchedUserId = _searchedUser!['id']?.toString();
    if (searchedUserId == null || searchedUserId.isEmpty) return false;
    return _group!.members.any((member) => member.userId == searchedUserId);
  }

  Future<void> _searchUserByEmail(String email) async {
    if (email.trim().isEmpty) {
      setState(() {
        _searchedUser = null;
        _isSearchingMember = false;
      });
      return;
    }

    setState(() {
      _isSearchingMember = true;
    });

    try {
      final response = await _userService.getUserByEmail(email.trim());
      setState(() {
        if (response['success'] == true && response['data'] != null) {
          _searchedUser = response['data'];
        } else {
          _searchedUser = null;
        }
        _isSearchingMember = false;
      });
    } catch (e) {
      setState(() {
        _searchedUser = null;
        _isSearchingMember = false;
      });
    }
  }

  Future<void> _addMemberFromSearch() async {
    if (_searchedUser == null || _group == null || _isAddingMember) return;
    if (_isSearchedUserAlreadyMember()) return;

    final userEmail = _searchedUser!['email']?.toString();
    if (userEmail == null || userEmail.isEmpty) return;

    setState(() {
      _isAddingMember = true;
    });

    try {
      await _groupsService.addMember(
        groupId: widget.groupId,
        userEmail: userEmail,
      );
      await _fetchGroup(preserveDrafts: true);
      setState(() {
        _searchController.clear();
        _searchedUser = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingMember = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return LoadingOverlay(
      isLoading: _loading || _saving,
      message: _loading ? 'Loading group...' : 'Saving changes...',
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body:
            _group == null
                ? Center(
                  child: Text(
                    'Group not found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Stack(
                          children: [
                            // Blue header
                            Container(
                              height: r.height(320),
                              width: double.infinity,
                              color: darkBlue,
                            ),
                            // Back and Save buttons
                            Padding(
                              padding: r.padding(
                                top: MediaQuery.of(context).padding.top + 10,
                                left: 15,
                                right: 15,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_ios,
                                      size: r.iconSize(32),
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    color: Colors.white,
                                    tooltip: 'Back',
                                  ),
                                  TextButton(
                                    onPressed: _saving ? null : _saveChanges,
                                    child: Text(
                                      'Save',
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(22),
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
                              top: r.height(240),
                              left: r.width(15),
                              right: r.width(15),
                              child: Material(
                                elevation: 3.0,
                                borderRadius: r.circularBorderRadius(16),
                                child: Container(
                                  padding: r.symmetricPadding(
                                    horizontal: 24,
                                    vertical: 50,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: r.circularBorderRadius(16),
                                    color: Colors.white,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 100),
                                        Center(
                                          child: Text(
                                            'Group Information',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: darkBlue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Group Name',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: darkBlue,
                                            ),
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
                                            hintText: 'Enter group name',
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
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: darkBlue,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                      BorderRadius.circular(12),
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
                                              return 'Group name cannot be empty';
                                            }
                                            if (value.trim().length < 2) {
                                              return 'Name must be at least 2 characters long';
                                            }
                                            if (value.trim().length > 50) {
                                              return 'Name must be less than 50 characters';
                                            }
                                            if (!RegExp(
                                              r"^[a-zA-ZÀ-ÿ0-9\s\-']+$",
                                            ).hasMatch(value.trim())) {
                                              return 'Name can only contain letters, numbers, spaces, hyphens, and apostrophes';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 40),
                                        // Members Section
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Text(
                                                'Members',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: darkBlue,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${_group!.members.length}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          constraints: BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: darkBlue.withValues(
                                                alpha: 0.3,
                                              ),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child:
                                              _group!.members.isEmpty
                                                  ? Center(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            24.0,
                                                          ),
                                                      child: Text(
                                                        'No members yet',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  : ListView.separated(
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        _group!.members.length,
                                                    separatorBuilder:
                                                        (context, index) =>
                                                            Divider(
                                                              height: 1,
                                                              color: darkBlue
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                            ),
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      final member =
                                                          _group!
                                                              .members[index];
                                                      return ListTile(
                                                        leading: AvatarWidget(
                                                          avatarUrl:
                                                              member.avatarUrl,
                                                          radius: 20,
                                                        ),
                                                        title: Text(
                                                          member.name ?? 'User',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: darkBlue,
                                                              ),
                                                        ),
                                                        subtitle: Text(
                                                          member.role,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                        ),
                                        const SizedBox(height: 18),
                                        SquadUpInput(
                                          controller: _searchController,
                                          label: 'Add Members',
                                          icon: Icons.search,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          onChanged: _searchUserByEmail,
                                          suffixIcon:
                                              _isSearchingMember
                                                  ? Padding(
                                                    padding: EdgeInsets.all(
                                                      r.width(12),
                                                    ),
                                                    child: SizedBox(
                                                      width: r.width(20),
                                                      height: r.width(20),
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            const Color.fromARGB(
                                                              255,
                                                              81,
                                                              163,
                                                              230,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  : _searchController
                                                      .text
                                                      .isNotEmpty
                                                  ? IconButton(
                                                    icon: Icon(
                                                      Icons.clear,
                                                      color: darkBlue,
                                                      size: r.iconSize(20),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _searchController
                                                            .clear();
                                                        _searchedUser = null;
                                                      });
                                                    },
                                                  )
                                                  : null,
                                        ),
                                        if (_searchedUser != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap:
                                                    _isAddingMember ||
                                                            _isSearchedUserAlreadyMember()
                                                        ? null
                                                        : _addMemberFromSearch,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      AvatarWidget(
                                                        avatarUrl:
                                                            _searchedUser!['avatar_url']
                                                                ?.toString(),
                                                        radius: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              _searchedUser!['name']
                                                                      ?.toString() ??
                                                                  'Unknown',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: darkBlue,
                                                              ),
                                                            ),
                                                            Text(
                                                              _searchedUser!['email']
                                                                      ?.toString() ??
                                                                  '',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (_isAddingMember)
                                                        SizedBox(
                                                          width: r.width(20),
                                                          height: r.width(20),
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                const Color.fromARGB(
                                                                  255,
                                                                  81,
                                                                  163,
                                                                  230,
                                                                ),
                                                          ),
                                                        )
                                                      else
                                                        Icon(
                                                          _isSearchedUserAlreadyMember()
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .add_circle_outline,
                                                          color:
                                                              _isSearchedUserAlreadyMember()
                                                                  ? Colors.green
                                                                  : const Color.fromARGB(
                                                                    255,
                                                                    81,
                                                                    163,
                                                                    230,
                                                                  ),
                                                          size: r.iconSize(24),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: AvatarGroupWidget(
                                  groupId: _group!.id,
                                  avatarUrl: _group!.avatarUrl,
                                  radius: 110,
                                  allowEdit: true,
                                  deferredUpload: true,
                                  onImageSelected: (localPath) {
                                    setState(() {
                                      _pendingAvatarPath = localPath;
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
