import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database/firestore_service.dart';
import '../exhibitor/exhibitor_home_screen.dart';
import '../organizer/organizer_home_screen.dart';
import '../admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  // REMOVED: final String role; (We don't need this anymore)
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ADDED: State to hold the selected role
  String _selectedRole = 'Exhibitor';
  final List<String> _roles = ['Exhibitor', 'Organizer', 'Administrator'];

  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Email/Password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Check User Role in Database
      final user = await FirestoreService.instance.getCurrentUser();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 3. Verify the role matches what they selected
      if (user != null && user.role == _selectedRole) {

        Widget targetScreen;
        if (_selectedRole == 'Exhibitor') targetScreen = ExhibitorHomeScreen(user: user);
        else if (_selectedRole == 'Organizer') targetScreen = OrganizerHomeScreen(user: user);
        else targetScreen = AdminHomeScreen(user: user);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
              (r) => false,
        );
      } else {
        // Role mismatch or user not found
        FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful, but role mismatch. Please check your selection.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Welcome Back!", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // ADDED: Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "I am logging in as...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: _roles.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                )).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Log In", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}