import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/squadup_input.dart';
import '../widgets/bubble_page_route.dart';
import 'home_screen.dart';

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
        if (mounted) setState(() => _message = '');

        final profile = await _userService.getProfile();
        final data = profile['data'] ?? {};
        String? name = data['name'];
        if ((name == null || name.toString().trim().isEmpty) &&
            data['user_metadata'] != null) {
          name = data['user_metadata']['name'];
        }

        if (mounted) {
          if (name == null || name.toString().trim().isEmpty) {
            Navigator.pushReplacementNamed(context, '/add-name');
          } else {
            // Bubble transition to HomeScreen
            final RenderBox? buttonBox =
                _loginButtonKey.currentContext?.findRenderObject()
                    as RenderBox?;
            final Offset bubbleCenter =
                buttonBox != null
                    ? buttonBox.localToGlobal(
                      buttonBox.size.center(Offset.zero),
                    )
                    : (MediaQuery.of(context).size.center(Offset.zero));
            Navigator.of(context).pushReplacement(
              BubblePageRoute(
                page: const HomeScreen(),
                bubbleCenter: bubbleCenter,
                bubbleColor: const Color.fromARGB(255, 17, 80, 138),
              ),
            );
          }
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
          _message = 'Invalid credentials.';
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

  final GlobalKey _loginButtonKey = GlobalKey();

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
                // Valores fixos alterados para responsivos (.w e .h)
                padding: EdgeInsets.only(right: 30.w, left: 30.w, top: 50.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo principal - usando o logotipo da empresa
                      SizedBox(
                        // Altura fixa alterada para responsiva (.h)
                        height: 190.h,
                        child: Center(
                          child: Image.asset(
                            'lib/images/logo_v3.png',
                            // Altura e largura fixas alteradas para responsivas (.h e .w)
                            height: 150.h,
                            width: 290.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 10.h,
                      ), // Altura fixa alterada para responsiva (.h)

                      Text(
                        "Welcome Back",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          // Tamanho de fonte fixo alterado para responsivo (.sp)
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),

                      SizedBox(
                        height: 10.h,
                      ), // Altura fixa alterada para responsiva (.h)

                      Text(
                        "Log in to your Account",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          // Tamanho de fonte fixo alterado para responsivo (.sp)
                          fontSize: 16.sp,
                          color: const Color.fromARGB(255, 130, 130, 130),
                        ),
                      ),
                      SizedBox(
                        height: 40.h,
                      ), // Altura fixa alterada para responsiva (.h)
                      // SquadUpInput (O componente customizado deve usar .w/.h internamente)
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

                      SizedBox(
                        height: 4.h,
                      ), // Altura fixa alterada para responsiva (.h)
                      // SquadUpInput para Password
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
                          // Padding fixo alterado para responsivo (.w)
                          padding: EdgeInsets.only(right: 8.w),
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
                        SizedBox(
                          height: 4.h,
                        ), // Altura fixa alterada para responsiva (.h)
                        Center(
                          child: Container(
                            // Padding fixo alterado para responsivo (.w e .h)
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 4.h,
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
                                      // Tamanho de fonte fixo alterado para responsivo (.sp)
                                      fontSize: 13.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      SizedBox(
                        height: 8.h,
                      ), // Altura fixa alterada para responsiva (.h)

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          // Padding fixo alterado para responsivo (.w)
                          padding: EdgeInsets.only(left: 10.w),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/forgot-password',
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                // Tamanho de fonte fixo alterado para responsivo (.sp)
                                fontSize: 14.sp,
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 40.h,
                      ), // Altura fixa alterada para responsiva (.h)
                      // Botão de login
                      SizedBox(
                        // Largura e altura fixas alteradas para responsivas (.w e .h)
                        width: 175.w,
                        height: 55.h,
                        child: ElevatedButton(
                          key: _loginButtonKey,
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
                                  ? SizedBox(
                                    // Largura e altura fixas alteradas para responsivas (.w e .h)
                                    width: 20.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    "Log In",
                                    style: GoogleFonts.poppins(
                                      // Tamanho de fonte fixo alterado para responsivo (.sp)
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),

                      SizedBox(
                        height: 40.h,
                      ), // Altura fixa alterada para responsiva (.h)
                      // Link para registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              // Tamanho de fonte fixo alterado para responsivo (.sp)
                              fontSize: 16.sp,
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
                                // Tamanho de fonte fixo alterado para responsivo (.sp)
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 19, 85, 146),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 16.h,
                      ), // Altura fixa alterada para responsiva (.h)
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
