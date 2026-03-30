import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/auth_service.dart';
import '../main.dart';
import '../Home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool passwordVisible = false;

  bool _nameFocused = false;
  bool _phoneFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _logoScaleAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _logoScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final auth = AuthService(database);
        await auth.register(
          nameController.text.trim(),
          emailController.text.trim(),
          phoneController.text.trim(),
          passwordController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Account created successfully!",
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00C58E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage1()),
        );
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF080810),
        body: Stack(
          children: [
            // ── Background decorative elements ──────────────────────────
            Positioned(
              top: -60,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A90E2).withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7B2FF7).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),

                        // ── Logo ────────────────────────────────────────
                        Center(
                          child: ScaleTransition(
                            scale: _logoScaleAnim,
                            child: Column(
                              children: [
                                // ✅ Remet ton image
                                Image.asset(
                                  'assets/Logos/Resuma-logo.png',
                                  height: 70,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "RESUMA",
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Heading ──────────────────────────────────────
                        Text(
                          "Create your\naccount.",
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Start summarizing smarter today",
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: Colors.white38,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Form ─────────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Name
                              Focus(
                                onFocusChange: (f) =>
                                    setState(() => _nameFocused = f),
                                child: _buildField(
                                  controller: nameController,
                                  hint: "Full name",
                                  icon: Icons.person_outline_rounded,
                                  isFocused: _nameFocused,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Enter your name";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Phone
                              Focus(
                                onFocusChange: (f) =>
                                    setState(() => _phoneFocused = f),
                                child: _buildField(
                                  controller: phoneController,
                                  hint: "Phone number",
                                  icon: Icons.phone_outlined,
                                  isFocused: _phoneFocused,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Enter your phone number";
                                    }
                                    if (v.length < 8) {
                                      return "Phone number too short";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Email
                              Focus(
                                onFocusChange: (f) =>
                                    setState(() => _emailFocused = f),
                                child: _buildField(
                                  controller: emailController,
                                  hint: "Email address",
                                  icon: Icons.mail_outline_rounded,
                                  isFocused: _emailFocused,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Enter your email";
                                    }
                                    if (!v.contains("@")) {
                                      return "Invalid email";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Password
                              Focus(
                                onFocusChange: (f) =>
                                    setState(() => _passwordFocused = f),
                                child: _buildField(
                                  controller: passwordController,
                                  hint: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  isFocused: _passwordFocused,
                                  obscure: !passwordVisible,
                                  suffix: IconButton(
                                    icon: Icon(
                                      passwordVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                            () => passwordVisible =
                                        !passwordVisible),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return "Minimum 6 characters";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Register button ───────────────────────
                              _RegisterButton(
                                isLoading: isLoading,
                                onTap: _register,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Divider ──────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Text(
                                "or",
                                style: GoogleFonts.dmSans(
                                  color: Colors.white24,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Back to login ─────────────────────────────────
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: GoogleFonts.dmSans(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, '/login'),
                                child: Text(
                                  "Sign in",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                    const Color(0xFF4A90E2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isFocused,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF7B2FF7).withOpacity(0.7)
              : Colors.white.withOpacity(0.08),
          width: isFocused ? 1.5 : 1,
        ),
        color: isFocused
            ? const Color(0xFF7B2FF7).withOpacity(0.06)
            : Colors.white.withOpacity(0.04),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: const Color(0xFF7B2FF7).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 15,
        ),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
            color: Colors.white24,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused
                ? const Color(0xFF7B2FF7)
                : Colors.white24,
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          errorStyle: GoogleFonts.dmSans(
            color: const Color(0xFFE53935),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Animated register button ───────────────────────────────────────────────
class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _RegisterButton({required this.isLoading, required this.onTap});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FF7).withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              "Create account",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subtle grid background painter ────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}