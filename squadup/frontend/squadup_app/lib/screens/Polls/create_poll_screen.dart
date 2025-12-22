import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/squadup_input.dart';
import '../../widgets/squadup_button.dart';
import '../../widgets/squadup_date_picker.dart';
import '../../services/polls_service.dart';
import '../../widgets/header.dart';
import '../../services/groups_service.dart';
import '../../widgets/avatar_widget.dart';

class CreatePollScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const CreatePollScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class PollOptionData {
  final TextEditingController textController;
  final TextEditingController proposerRewardAmountController;
  final TextEditingController proposerRewardTextController;
  final TextEditingController challengerRewardAmountController;
  final TextEditingController challengerRewardTextController;
  
  String proposerRewardType = 'amount';
  String challengerRewardType = 'amount';
  String? challengerUserId;

  PollOptionData({
    required this.textController,
    required this.proposerRewardAmountController,
    required this.proposerRewardTextController,
    required this.challengerRewardAmountController,
    required this.challengerRewardTextController,
  });

  void dispose() {
    textController.dispose();
    proposerRewardAmountController.dispose();
    proposerRewardTextController.dispose();
    challengerRewardAmountController.dispose();
    challengerRewardTextController.dispose();
  }
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  List<PollOptionData> _options = [];

  DateTime? _endDate;
  String _pollType = 'voting'; // 'voting' or 'betting'

  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final PollsService _pollsService = PollsService();
  final GroupsService _groupsService = GroupsService();
  bool _isCreating = false;
  List<Map<String, dynamic>> _groupMembers = [];

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _loadGroupMembers();
  }

  void _initializeOptions() {
    _options = [
      _createOptionData(),
      _createOptionData(),
    ];
  }

  Future<void> _loadGroupMembers() async {
    try {
      final response = await _groupsService.getGroupById(widget.groupId);
      if (response['success'] == true) {
        setState(() {
          _groupMembers = List<Map<String, dynamic>>.from(
            response['data']['members'] ?? [],
          );
        });
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  PollOptionData _createOptionData() {
    return PollOptionData(
      textController: TextEditingController(),
      proposerRewardAmountController: TextEditingController(),
      proposerRewardTextController: TextEditingController(),
      challengerRewardAmountController: TextEditingController(),
      challengerRewardTextController: TextEditingController(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length < 10) {
      setState(() {
        _options.add(_createOptionData());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum of 10 options allowed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _removeOption(int index) {
    if (_options.length > 2) {
      setState(() {
        _options[index].dispose();
        _options.removeAt(index);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _createPoll() async {
    if (_formKey.currentState!.validate()) {
      if (_endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select an end date'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      setState(() => _isCreating = true);

      try {
        final List<Map<String, dynamic>> options = [];
        
        for (var option in _options) {
          if (option.textController.text.trim().isEmpty) continue;

          final Map<String, dynamic> optionData = {
            'text': option.textController.text.trim(),
          };

          // Se for betting poll, adicionar rewards
          if (_pollType == 'betting') {
            // Proposer reward
            if (option.proposerRewardType == 'amount') {
              final proposerRewardAmount = option.proposerRewardAmountController.text.trim();
              if (proposerRewardAmount.isNotEmpty) {
                optionData['proposer_reward'] = {
                  'amount': num.tryParse(proposerRewardAmount),
                };
              }
            } else if (option.proposerRewardType == 'other') {
              final proposerRewardText = option.proposerRewardTextController.text.trim();
              if (proposerRewardText.isNotEmpty) {
                optionData['proposer_reward'] = {
                  'text': proposerRewardText,
                };
              }
            }

            // Challenger reward
            if (option.challengerRewardType == 'amount') {
              final challengerRewardAmount = option.challengerRewardAmountController.text.trim();
              if (challengerRewardAmount.isNotEmpty) {
                optionData['challenger_reward'] = {
                  'amount': num.tryParse(challengerRewardAmount),
                };
              }
            } else if (option.challengerRewardType == 'other') {
              final challengerRewardText = option.challengerRewardTextController.text.trim();
              if (challengerRewardText.isNotEmpty) {
                optionData['challenger_reward'] = {
                  'text': challengerRewardText,
                };
              }
            }

            // Challenger user ID
            if (option.challengerUserId != null) {
              optionData['challenger_user_id'] = option.challengerUserId;
            }
          }

          options.add(optionData);
        }

        final pollData = {
          'group_id': widget.groupId,
          'title': _titleController.text.trim(),
          'type': _pollType,
          'options': options,
          'closed_at': _endDate!.toIso8601String(),
        };

        final response = await _pollsService.createPoll(pollData);

        if (mounted) {
          if (response.statusCode == 201 && response.data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Poll created successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            Navigator.pop(context, true);
          } else {
            throw Exception(response.data['message'] ?? 'Failed to create poll');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCreating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              darkBlue: darkBlue,
              title: 'New Poll',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Ex: Who arrives in Porto first?',
                      maxLines: 1,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Poll Type'),
                    const SizedBox(height: 12),
                    _buildPollTypeSelector(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Answer Options'),
                    const SizedBox(height: 16),
                    ..._buildOptionFields(),
                    const SizedBox(height: 12),
                    _buildAddOptionButton(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('End Date'),
                    const SizedBox(height: 12),
                    _buildDateSelector(),
                    const SizedBox(height: 32),
                    _buildCreateButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkBlue,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return SquadUpInput(
      controller: controller,
      label: label,
      icon: Icons.description,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      validator: validator,
      onChanged: (_) {},
    );
  }


  List<Widget> _buildOptionFields() {
    return List.generate(_options.length, (index) {
      final option = _options[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: SquadUpInput(
                controller: option.textController,
                label: 'Option ${index + 1}',
                icon: Icons.list,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an option';
                  }
                  return null;
                },
              ),
            ),
            if (_options.length > 2)
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                onPressed: () => _removeOption(index),
              ),
            if (_pollType == 'betting')
              IconButton(
                icon: Icon(Icons.settings, color: primaryBlue),
                onPressed: () => _showRewardSettings(index),
              ),
          ],
        ),
      );
    });
  }

  void _showRewardSettings(int optionIndex) {
    final option = _options[optionIndex];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RewardSettingsScreen(
          optionIndex: optionIndex,
          option: option,
          darkBlue: darkBlue,
          primaryBlue: primaryBlue,
          groupMembers: _groupMembers,
          onUpdate: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildPollTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text(
              'Voting',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkBlue,
              ),
            ),
            value: 'voting',
            groupValue: _pollType,
            activeColor: primaryBlue,
            onChanged: (value) {
              setState(() {
                _pollType = value!;
              });
            },
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          RadioListTile<String>(
            title: Text(
              'Betting',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkBlue,
              ),
            ),
            value: 'betting',
            groupValue: _pollType,
            activeColor: primaryBlue,
            onChanged: (value) {
              setState(() {
                _pollType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddOptionButton() {
    final bool canAddMore = _options.length < 10;
    return SquadUpButton(
      text: canAddMore 
          ? 'Add Option' 
          : 'Maximum options reached',
      onPressed: canAddMore ? _addOption : () {},
      backgroundColor: canAddMore ? primaryBlue : Colors.grey,
      textColor: Colors.white,
      borderRadius: 12,
      width: double.infinity,
      height: 48,
      buttonKey: const Key('add_option_button'),
    );
  }

  Widget _buildDateSelector() {
    return _endDate == null
        ? SquadUpDatePicker(
            label: 'Date',
            selectedDate: DateTime.now().add(const Duration(days: 7)),
            onDateSelected: _selectEndDate,
            icon: Icons.calendar_today,
          )
        : SquadUpDatePicker(
            label: 'End date',
            selectedDate: _endDate!,
            onDateSelected: _selectEndDate,
            icon: Icons.calendar_today,
          );
  }

  Widget _buildCreateButton() {
    return SquadUpButton(
      text: _isCreating ? 'Creating...' : 'Create Poll',
      onPressed: _isCreating ? () {} : _createPoll,
      backgroundColor: darkBlue,
      width: double.infinity,
      height: 55,
      borderRadius: 12,
    );
  }
}

class _RewardSettingsScreen extends StatefulWidget {
  final int optionIndex;
  final PollOptionData option;
  final Color darkBlue;
  final Color primaryBlue;
  final List<Map<String, dynamic>> groupMembers;
  final VoidCallback onUpdate;

  const _RewardSettingsScreen({
    required this.optionIndex,
    required this.option,
    required this.darkBlue,
    required this.primaryBlue,
    required this.groupMembers,
    required this.onUpdate,
  });

  @override
  State<_RewardSettingsScreen> createState() => _RewardSettingsScreenState();
}

class _RewardSettingsScreenState extends State<_RewardSettingsScreen> {
  bool _isChallengerExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              darkBlue: widget.darkBlue,
              title: '',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proposer',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: widget.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRewardTypeButton(
                            label: 'Amount',
                            icon: Icons.attach_money,
                            isSelected: widget.option.proposerRewardType == 'amount',
                            onTap: () {
                              setState(() {
                                widget.option.proposerRewardType = 
                                  widget.option.proposerRewardType == 'amount' ? 'none' : 'amount';
                                widget.onUpdate();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRewardTypeButton(
                            label: 'Other',
                            icon: Icons.text_fields,
                            isSelected: widget.option.proposerRewardType == 'other',
                            onTap: () {
                              setState(() {
                                widget.option.proposerRewardType = 
                                  widget.option.proposerRewardType == 'other' ? 'none' : 'other';
                                widget.onUpdate();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (widget.option.proposerRewardType == 'amount') ...[
                      const SizedBox(height: 12),
                      SquadUpInput(
                        controller: widget.option.proposerRewardAmountController,
                        label: 'Amount',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (widget.option.proposerRewardType == 'other') ...[
                      const SizedBox(height: 12),
                      SquadUpInput(
                        controller: widget.option.proposerRewardTextController,
                        label: 'Reward',
                        icon: Icons.text_fields,
                      ),
                    ],
                    
                    const SizedBox(height: 10),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        cardColor: Colors.white,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: _isChallengerExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isChallengerExpanded = expanded;
                          });
                        },
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          'Challenger',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: widget.darkBlue,
                          ),
                        ),
                        iconColor: widget.darkBlue,
                        collapsedIconColor: widget.darkBlue,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                widget.groupMembers.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Loading members...',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: widget.groupMembers.length,
                                        itemBuilder: (context, index) {
                                          final member = widget.groupMembers[index];
                                          final isSelected = widget.option.challengerUserId == member['id'];
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                widget.option.challengerUserId = 
                                                  isSelected ? null : member['id'];
                                                widget.onUpdate();
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? widget.primaryBlue.withValues(alpha: 0.1)
                                                    : Colors.white,
                                                border: Border.all(
                                                  color: isSelected 
                                                      ? widget.primaryBlue 
                                                      : Colors.grey.shade300,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  UserAvatarDisplay(
                                                    avatarUrl: member['avatar_url'],
                                                    radius: 20,
                                                    onTap: null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      member['name'] ?? 'User',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        fontWeight: isSelected 
                                                            ? FontWeight.w600 
                                                            : FontWeight.w500,
                                                        color: widget.darkBlue,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: widget.primaryBlue,
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildRewardTypeButton(
                            label: 'Amount',
                            icon: Icons.attach_money,
                            isSelected: widget.option.challengerRewardType == 'amount',
                            onTap: () {
                              setState(() {
                                widget.option.challengerRewardType = 
                                  widget.option.challengerRewardType == 'amount' ? 'none' : 'amount';
                                widget.onUpdate();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRewardTypeButton(
                            label: 'Other',
                            icon: Icons.text_fields,
                            isSelected: widget.option.challengerRewardType == 'other',
                            onTap: () {
                              setState(() {
                                widget.option.challengerRewardType = 
                                  widget.option.challengerRewardType == 'other' ? 'none' : 'other';
                                widget.onUpdate();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (widget.option.challengerRewardType == 'amount') ...[
                      const SizedBox(height: 12),
                      SquadUpInput(
                        controller: widget.option.challengerRewardAmountController,
                        label: 'Amount',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (widget.option.challengerRewardType == 'other') ...[
                      const SizedBox(height: 12),
                      SquadUpInput(
                        controller: widget.option.challengerRewardTextController,
                        label: 'Reward',
                        icon: Icons.text_fields,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    SquadUpButton(
                      text: 'Done',
                      onPressed: () {
                        widget.onUpdate();
                        Navigator.pop(context);
                      },
                      backgroundColor: widget.darkBlue,
                      width: double.infinity,
                      height: 48,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryBlue : Colors.white,
          border: Border.all(
            color: isSelected ? widget.primaryBlue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
