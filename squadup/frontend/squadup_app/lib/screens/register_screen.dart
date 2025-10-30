import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../widgets/squadup_input.dart';

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
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Backend retorna sucesso mas sem sessão (precisa confirmar email)
        setState(() {
          _message =
              response['message'] ??
              'Conta criada! Verifique seu email para ativar a conta.';
          _isSuccessMessage = true;
        });

        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite seu email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, digite um email válido';
    }

    if (value.length > 254) {
      return 'Email muito longo';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite sua senha';
    }

    if (value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres';
    }

    // Validação de senha forte (deve corresponder ao backend)
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);

    if (!hasUppercase) {
      return 'Senha deve conter letra maiúscula';
    }

    if (!hasLowercase) {
      return 'Senha deve conter letra minúscula';
    }

    if (!hasDigit) {
      return 'Senha deve conter número';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirme sua senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }

    return null;
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
                padding: const EdgeInsets.only(left: 30, right: 30, top: 50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 190,
                        child: Center(
                          child: Image.asset(
                            'lib/images/logo_v3.png',
                            height: 150,
                            width: 290,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Join SquadUp",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Create your Account",
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
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: 4),

                      SquadUpInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
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

                      const SizedBox(height: 4),

                      SquadUpInput(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        validator: _validateConfirmPassword,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
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
                                      color:
                                          _isSuccessMessage
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
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

                      const SizedBox(height: 40),

                      SizedBox(
                        width: 175,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              19,
                              85,
                              146,
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
                                    "Sign Up",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Log In",
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
