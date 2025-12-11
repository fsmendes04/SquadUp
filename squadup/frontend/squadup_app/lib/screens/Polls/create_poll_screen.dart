import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/squadup_input.dart';
import '../../widgets/squadup_button.dart';
import '../../widgets/squadup_date_picker.dart';
import '../../services/polls_service.dart';

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

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? _endDate;
  String _pollType = 'voting'; // 'voting' or 'betting'

  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final PollsService _pollsService = PollsService();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
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
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
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
        final options = _optionControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .map((controller) => controller.text.trim())
            .toList();

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 31),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New Poll',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
    return List.generate(_optionControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: SquadUpInput(
                controller: _optionControllers[index],
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
            if (_optionControllers.length > 2) ...[
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                onPressed: () => _removeOption(index),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildAddOptionButton() {
    final bool canAddMore = _optionControllers.length < 10;
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
