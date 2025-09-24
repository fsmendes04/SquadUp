import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/squadup_input.dart';
import '../services/auth_service.dart';

class AddNameScreen extends StatefulWidget {
  const AddNameScreen({super.key});

  @override
  State<AddNameScreen> createState() => _AddNameScreenState();
}

class _AddNameScreenState extends State<AddNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String _message = '';
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    // Clear error message when user types
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

  Future<void> _confirmName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final name = _nameController.text.trim();
      final success = await _authService.updateUserName(name);

      if (success) {
        if (mounted) {
          // Navigate to home screen after successful name update
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          setState(() {
            _message = 'Failed to update name. Please try again.';
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
    final backgroundColor = Colors.white;
    final buttonColor = const Color.fromARGB(255, 17, 80, 138);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 90),

                  // Logo
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Image.asset(
                        'lib/images/logo_v3.png',
                        height: 120,
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Welcome text
                  Text(
                    "Welcome to SquadUp!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Choose your name to get started.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 130, 130, 130),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Name input
                  SquadUpInput(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please choose your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters long';
                      }
                      if (value.trim().length > 30) {
                        return 'Name must be less than 30 characters';
                      }
                      return null;
                    },
                  ),

                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 16),
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
                        borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(width: 8),
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

                  const SizedBox(height: 50),

                  // Confirm button
                  SizedBox(
                    width: 175, // largura reduzida do botão
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: buttonColor.withValues(
                          alpha: 0.6,
                        ),
                        shadowColor: buttonColor.withValues(alpha: 0.3),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Get Started",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
