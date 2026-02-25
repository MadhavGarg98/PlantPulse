import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../services/firebase_service.dart';
import 'dashboard.dart';

class CurvedStemPainter extends CustomPainter {
  final double progress;
  final double sway;

  CurvedStemPainter(this.progress, this.sway);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF1B5E20),
          Color(0xFF2E7D32),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    final start = Offset(size.width / 2, size.height);
    final control =
        Offset(size.width / 2 - 20 + sway, size.height / 2);
    final end =
        Offset(size.width / 2 + sway, size.height * (1 - progress));

    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvedStemPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sway != sway;
  }
}

class PremiumLoginScreen extends StatefulWidget {
  const PremiumLoginScreen({super.key});

  @override
  State<PremiumLoginScreen> createState() =>
      _PremiumLoginScreenState();
}

class _PremiumLoginScreenState
    extends State<PremiumLoginScreen>
    with TickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _growController;
  late AnimationController _bloomController;
  late AnimationController _shakeController;
  late AnimationController _breathController;
  late AnimationController _swayController;
  late AnimationController _sparkleController;

  late Animation<double> _grow;
  late Animation<double> _leaf;
  late Animation<double> _flowerScale;
  late Animation<double> _flowerOpacity;
  late Animation<double> _shake;
  late Animation<double> _breath;
  late Animation<double> _sway;
  late Animation<double> _sparkle;

  @override
  void initState() {
    super.initState();

    _growController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));

    _bloomController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800));

    _shakeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400));

    _breathController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _swayController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    _sparkleController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));

    _grow = CurvedAnimation(
        parent: _growController,
        curve: Curves.easeInOut);

    _leaf = CurvedAnimation(
        parent: _growController,
        curve: Curves.easeOutBack);

    _flowerScale = CurvedAnimation(
        parent: _bloomController,
        curve: Curves.elasticOut);

    _flowerOpacity = CurvedAnimation(
        parent: _bloomController,
        curve: Curves.easeIn);

    _shake = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(
            parent: _shakeController,
            curve: Curves.easeInOut));

    _breath = Tween<double>(begin: 1.0, end: 1.05)
        .animate(_breathController);

    _sway = Tween<double>(begin: -6, end: 6)
        .animate(_swayController);

    _sparkle = CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.easeOut);

    _emailFocus.addListener(_handleFocus);
    _passwordFocus.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (_emailFocus.hasFocus) {
      _growController.animateTo(0.5);
    } else if (_passwordFocus.hasFocus) {
      _growController.forward();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _growController.dispose();
    _bloomController.dispose();
    _shakeController.dispose();
    _breathController.dispose();
    _swayController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      await _growController.forward();
      await _bloomController.forward();
      _sparkleController.forward(from: 0);

      await Future.delayed(
          const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DashboardScreen(user: user),
        ),
      );
    } else {
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _growController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                      const Color(0xFFF6F8F7),
                      const Color(0xFFE8F5E9),
                      _growController.value)!,
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildPlant(),
                const SizedBox(height: 60),
                _buildLoginForm(),
                const SizedBox(height: 40),
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlant() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _growController,
        _bloomController,
        _shakeController,
        _breathController,
        _swayController,
        _sparkleController
      ]),
      builder: (context, child) {

        final shakeOffset =
            _shakeController.isAnimating
                ? _shake.value
                : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: _breath.value,
            child: Column(
              children: [

                /// ✨ Sparkle Burst
                if (_sparkleController.isAnimating)
                  ...List.generate(12, (index) {
                    final angle =
                        index * 30 * pi / 180;
                    final radius =
                        60 * _sparkle.value;
                    return Transform.translate(
                      offset: Offset(
                          radius * cos(angle),
                          radius * sin(angle)),
                      child: Opacity(
                        opacity:
                            1 - _sparkle.value,
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),

                /// 🌸 Flower
                Opacity(
                  opacity: _flowerOpacity.value,
                  child: Transform.scale(
                    scale: _flowerScale.value,
                    child: const Icon(
                      Icons.local_florist,
                      size: 48,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                /// 🍃 Layered Leaves
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.8,
                      child: Transform.scale(
                        scale: _leaf.value,
                        child: const Icon(
                          Icons.eco,
                          size: 36,
                          color:
                              Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: 0.8,
                      child: Transform.scale(
                        scale: _leaf.value,
                        child: const Icon(
                          Icons.eco,
                          size: 36,
                          color:
                              Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// 🌿 Stem
                SizedBox(
                  width: 100,
                  height: 140,
                  child: CustomPaint(
                    painter:
                        CurvedStemPainter(
                            _grow.value,
                            _sway.value),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "PlantPulse",
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [

            Text(
              "Welcome Back",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            _buildField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              focusNode: _emailFocus,
            ),

            const SizedBox(height: 20),

            _buildField(
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              focusNode: _passwordFocus,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() =>
                        _obscurePassword =
                            !_obscurePassword),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : _login,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1B5E20),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text("Sign In"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty
              ? "Required field"
              : null,
    );
  }

  Widget _buildBottomSection() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(
            context, "/signup");
      },
      child: Text(
        "Don't have an account? Sign Up",
        style: GoogleFonts.inter(
          fontWeight:
              FontWeight.w600,
          color: const Color(0xFF1B5E20),
        ),
      ),
    );
  }
}