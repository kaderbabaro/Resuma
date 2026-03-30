import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/auth_service.dart';

class NewPasswordPage extends StatefulWidget {
  final AuthService authService;
  const NewPasswordPage({super.key, required this.authService});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool isLoading = false;
  bool _passwordObscure = true;
  bool _confirmObscure = true;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  // ── Password strength ──────────────────────────────────────────────────
  double _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(
        const Duration(milliseconds: 100), () => _slideController.forward());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _checkStrength(String value) {
    double strength = 0;
    if (value.length >= 6) strength += 0.25;
    if (value.length >= 10) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[0-9!@#\$%^&*]'))) strength += 0.25;

    String label;
    Color color;
    if (strength <= 0.25) {
      label = 'Weak';
      color = const Color(0xFFE53935);
    } else if (strength <= 0.5) {
      label = 'Fair';
      color = Colors.orange;
    } else if (strength <= 0.75) {
      label = 'Good';
      color = Colors.amber;
    } else {
      label = 'Strong';
      color = const Color(0xFF00C58E);
    }

    setState(() {
      _strength = strength;
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final newPassword = _passwordController.text.trim();

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        await widget.authService.syncNewPassword(user.email!, newPassword);
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
            style: GoogleFonts.dmSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF080810),
        body: Stack(
          children: [
            // ── Background decorative ────────────────────────────────────
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
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
            Positioned(
              bottom: 80,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A90E2).withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // ── Content ──────────────────────────────────────────────────
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
                        const SizedBox(height: 24),

                        // ── Back button ──────────────────────────────────
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Icon ─────────────────────────────────────────
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF7B2FF7).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Heading ──────────────────────────────────────
                        Text(
                          "New\npassword.",
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Choose a strong password to secure your account",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.white38,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Form ─────────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // New password
                              Focus(
                                onFocusChange: (f) =>
                                    setState(() => _passwordFocused = f),
                                child: _buildField(
                                  controller: _passwordController,
                                  hint: "New password",
                                  icon: Icons.lock_outline_rounded,
                                  isFocused: _passwordFocused,
                                  obscure: _passwordObscure,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _passwordObscure
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _passwordObscure = !_passwordObscure),
                                  ),
                                  onChanged: _checkStrength,
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return "Minimum 6 characters";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // ── Strength bar ──────────────────────────
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _strength,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.08),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _strengthColor),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _strengthLabel,
                                      style: GoogleFonts.dmSans(
                                        color: _strengthColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 14),

                              // Confirm password
                              Focus(
                                onFocusChange: (f) =>
                                    setState(() => _confirmFocused = f),
                                child: _buildField(
                                  controller: _confirmController,
                                  hint: "Confirm password",
                                  icon: Icons.lock_outline_rounded,
                                  isFocused: _confirmFocused,
                                  obscure: _confirmObscure,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _confirmObscure
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _confirmObscure = !_confirmObscure),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordController.text) {
                                      return "Passwords do not match";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Submit button ─────────────────────────
                              _SubmitButton(
                                isLoading: isLoading,
                                onTap: _updatePassword,
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
    Widget? suffix,
    void Function(String)? onChanged,
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
        onChanged: onChanged,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 15),
          prefixIcon: Icon(
            icon,
            color: isFocused ? const Color(0xFF7B2FF7) : Colors.white24,
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 18),
          errorStyle: GoogleFonts.dmSans(
              color: const Color(0xFFE53935), fontSize: 12),
        ),
      ),
    );
  }
}

// ── Animated submit button ─────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton({required this.isLoading, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
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
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    "Update password",
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

// ── Grid painter ───────────────────────────────────────────────────────────
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