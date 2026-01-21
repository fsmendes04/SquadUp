import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/squadup_button.dart';
import '../config/responsive_utils.dart';

class EmailConfirmationScreen extends StatelessWidget {
  const EmailConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: r.symmetricPadding(horizontal: 30, vertical: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                r.verticalSpace(60),
                
                SizedBox(
                  height: r.height(220),
                  child: Center(
                    child: Image.asset(
                      'lib/images/logo_v3.png',
                      height: r.height(220),
                      width: r.width(220),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                r.verticalSpace(67),

                Text(
                  "Verify Your Email",
                  style: GoogleFonts.poppins(
                    fontSize: r.fontSize(28),
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(221, 0, 0, 0),
                  ),
                  textAlign: TextAlign.center,
                ),

                r.verticalSpace(40),

                Text(
                  "Please confirm your email address to complete the registration.",
                  style: GoogleFonts.poppins(
                    fontSize: r.fontSize(16),
                    color: const Color.fromARGB(255, 130, 130, 130),
                  ),
                  textAlign: TextAlign.center,
                ),

                r.verticalSpace(50),


                SquadUpButton(
                  text: "Login",
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  backgroundColor: const Color.fromARGB(255, 19, 85, 146),
                  textColor: Colors.white,
                ),

                r.verticalSpace(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
