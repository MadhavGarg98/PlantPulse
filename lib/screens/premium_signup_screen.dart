import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'dashboard.dart';

class PremiumSignupScreen extends StatefulWidget {
  const PremiumSignupScreen({super.key});

  @override
  State<PremiumSignupScreen> createState() => _PremiumSignupScreenState();
}

class _PremiumSignupScreenState extends State<PremiumSignupScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1;
  bool _isLoading = false;
  bool _isSuccess = false;

  String _displayedText = "";
  String? _errorText;
  Timer? _typingTimer;

  final List<String> _questions = [
    "What should we call you?",
    "",
    "Create a secure password",
    "Confirm your password"
  ];

  @override
  void initState() {
    super.initState();
    _startTyping(_questions[0]);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTyping(String text) {
    _typingTimer?.cancel();
    _displayedText = "";
    int index = 0;

    _typingTimer =
        Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (index < text.length) {
        setState(() => _displayedText += text[index]);
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  String _getDynamicQuestion() {
    if (_currentStep == 2) {
      final name =
          _nameController.text.isEmpty ? "there" : _nameController.text;
      return "Nice to meet you, $name.\nWhat's your email?";
    }
    return _questions[_currentStep - 1];
  }

  TextEditingController _getController() {
    switch (_currentStep) {
      case 1:
        return _nameController;
      case 2:
        return _emailController;
      case 3:
        return _passwordController;
      case 4:
        return _confirmPasswordController;
      default:
        return _nameController;
    }
  }

  String? _validate() {
    switch (_currentStep) {
      case 1:
        if (_nameController.text.trim().isEmpty) {
          return "Name cannot be empty";
        }
        break;
      case 2:
        final email = _emailController.text.trim();
        if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
            .hasMatch(email)) {
          return "Enter a valid email address";
        }
        break;
      case 3:
        if (_passwordController.text.length < 6) {
          return "Password must be at least 6 characters";
        }
        break;
      case 4:
        if (_passwordController.text !=
            _confirmPasswordController.text) {
          return "Passwords do not match";
        }
        break;
    }
    return null;
  }

  Future<void> _handleNext() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _errorText = validation);
      return;
    }

    setState(() => _errorText = null);

    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _startTyping(_getDynamicQuestion());
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });

        await Future.delayed(const Duration(seconds: 1));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: user),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = _mapFirebaseError(e.code);
      });
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'weak-password':
        return "Password is too weak.";
      default:
        return "Authentication failed.";
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _startTyping(_getDynamicQuestion());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildCard(),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEAF6EF),
            Color(0xFFD6EBDD),
            Color(0xFFC3E2CF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Welcome Section
              _buildWelcomeSection(),
              
              const SizedBox(height: 32),

              if (_currentStep > 1)
                IconButton(
                  onPressed: _handleBack,
                  icon: const Icon(Icons.arrow_back),
                ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                      position: offsetAnimation, child: child);
                },
                child: Text(
                  _displayedText,
                  key: ValueKey(_currentStep),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _getController(),
                obscureText: _currentStep >= 3,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSuccess
                      ? const Icon(Icons.check, color: Colors.white)
                      : Text(
                          _currentStep == 4
                              ? "Create Account"
                              : "Continue",
                        ),
                ),
              ),

              const SizedBox(height: 20),

              if (_currentStep == 2) ...[
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.login),
                    label: const Text("Continue with Google"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Plant Image Section
              if (_currentStep == 1) _buildPlantImageSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.eco,
            color: Colors.white,
            size: 40,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Welcome Message
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to PlantPulse",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B5E20),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              "Your personal plant care companion",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlantImageSection() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/plant_3d.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B5E20).withOpacity(0.1),
                        const Color(0xFF4CAF50).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 80,
                    color: Color(0xFF1B5E20),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.2),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}