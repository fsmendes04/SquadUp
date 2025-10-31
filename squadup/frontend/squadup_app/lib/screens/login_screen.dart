import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../widgets/squadup_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrorMessage);
    _passwordController.addListener(_clearErrorMessage);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorMessage);
    _passwordController.removeListener(_clearErrorMessage);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrorMessage() {
    if (_message.isNotEmpty) {
      setState(() {
        _message = '';
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await _userService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _message = '';
          });
        }
        final userData = response['data']?['user'];
        final userName = userData?['user_metadata']?['name'];

        if (mounted) {
          Future.microtask(() {
            if (userName == null || userName.toString().trim().isEmpty) {
              Navigator.pushReplacementNamed(context, '/add-name');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _message = response['message'] ?? 'Invalid email or password.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Invalid email or password.';
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
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 30.0,
                  left: 30.0,
                  top: 50,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo principal - usando o logotipo da empresa
                      SizedBox(
                        height: 190,
                        child: Center(
                          child: Image.asset(
                            'lib/images/logo_v3.png',
                            height: 150, // Reduced height
                            width: 290, // Reduced width
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Welcome Back",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Log in to your Account",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color.fromARGB(255, 130, 130, 130),
                        ),
                      ),
                      const SizedBox(height: 40),

                      SquadUpInput(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Por favor, digite um email válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 4),

                      SquadUpInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua senha';
                          }
                          return null;
                        },
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
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

                      if (_message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _message,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Botão de login
                      SizedBox(
                        width: 175,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              17,
                              80,
                              138,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: const Color.fromARGB(
                              255,
                              19,
                              85,
                              146,
                            ),
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
                                  : Text(
                                    "Log In",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Link para registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/register',
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 19, 85, 146),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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
