import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../widgets/squadup_button.dart';
import '../widgets/squadup_input.dart';
import '../config/responsive_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _message = '';
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrorMessage);
    _passwordController.addListener(_clearErrorMessage);
    _confirmPasswordController.addListener(_clearErrorMessage);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorMessage);
    _passwordController.removeListener(_clearErrorMessage);
    _confirmPasswordController.removeListener(_clearErrorMessage);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await _userService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/email-confirmation');
      } else {
        setState(() {
          _message = response['message'] ?? 'Falha no registro';
          _isSuccessMessage = false;
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
        _isSuccessMessage = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Erro inesperado. Tente novamente.';
        _isSuccessMessage = false;
      });
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
    final r = context.responsive;
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: r.padding(left: 30, right: 30, top: 50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: r.height(190),
                        child: Center(
                          child: Image.asset(
                            'lib/images/logo_v3.png',
                            height: r.height(150),
                            width: r.width(290),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      r.verticalSpace(10),

                      Text(
                        "Join SquadUp",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(30),
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),

                      r.verticalSpace(10),

                      Text(
                        "Create your Account",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(16),
                          color: const Color.fromARGB(255, 130, 130, 130),
                        ),
                      ),
                      r.verticalSpace(40),

                      SquadUpInput(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      r.verticalSpace(4),

                      SquadUpInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: Padding(
                          padding: r.padding(right: 8),
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color.fromARGB(255, 19, 85, 146),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      r.verticalSpace(4),

                      SquadUpInput(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: Padding(
                          padding: r.padding(right: 8),
                          child: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color.fromARGB(255, 19, 85, 146),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ),

                      if (_message.isNotEmpty) ...[
                        r.verticalSpace(4),
                        Center(
                          child: Container(
                            padding: r.symmetricPadding(horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _message,
                                    style: GoogleFonts.poppins(
                                      color:
                                          _isSuccessMessage
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: r.fontSize(13),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (!_message.isNotEmpty) ...[r.verticalSpace(20)],

                      r.verticalSpace(20),

                      SquadUpButton(
                        text: "Sign Up",
                        onPressed: _register,
                        isLoading: _isLoading,
                        backgroundColor: const Color.fromARGB(255, 19, 85, 146),
                        disabledColor: const Color.fromARGB(255, 19, 85, 146),
                        textColor: Colors.white,
                      ),

                      r.verticalSpace(40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.poppins(
                              fontSize: r.fontSize(16),
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Log In",
                              style: GoogleFonts.poppins(
                                fontSize: r.fontSize(16),
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 19, 85, 146),
                              ),
                            ),
                          ),
                        ],
                      ),

                      r.verticalSpace(16),
                    ],
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
