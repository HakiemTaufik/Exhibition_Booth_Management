import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart'; // Direct import
import '../guest/guest_home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "To continue with booking\nplease log in or create an account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // 1. Log In Button (Now goes straight to LoginScreen)
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text("Log in Now"),
              ),

              const SizedBox(height: 20),

              // 2. Create Account
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text("Create Account"),
              ),

              const SizedBox(height: 30),

              // 3. Guest
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GuestHomeScreen()),
                  );
                },
                child: const Text("Continue as Guest (Browse Events)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}