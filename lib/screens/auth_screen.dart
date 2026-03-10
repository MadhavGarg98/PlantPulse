import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> submitAuth() async {

    setState(() {
      isLoading = true;
    });

    try {

      if (isLogin) {

        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

      } else {

        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

      }

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Authentication error")),
      );

    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("PlantPulse Authentication")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 24),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitAuth,
                    child: Text(isLogin ? "Login" : "Sign Up"),
                  ),

            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(
                isLogin
                    ? "Create new account"
                    : "Already have an account? Login",
              ),
            )
          ],
        ),
      ),
    );
  }
}