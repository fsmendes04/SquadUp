import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/squadup_button.dart';

class EmailConfirmationScreen extends StatelessWidget {
  const EmailConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                SizedBox(
                  height: 220,
                  child: Center(
                    child: Image.asset(
                      'lib/images/logo_v3.png',
                      height: 220,
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 67),

                Text(
                  "Verify Your Email",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(221, 0, 0, 0),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                Text(
                  "Please confirm your email address to complete the registration.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 130, 130, 130),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),


                SquadUpButton(
                  text: "Login",
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  width: 175,
                  height: 55,
                  backgroundColor: const Color.fromARGB(255, 19, 85, 146),
                  textColor: Colors.white,
                  borderRadius: 15,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
