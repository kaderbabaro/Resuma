import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../../database/app_database.dart';
import '../../service/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final AppDatabase database;

  const ChangePasswordPage({super.key, required this.database});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(widget.database);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Change password logic ────────────────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = supabase_flutter.Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        _showSnack("No user logged in", isError: true);
        return;
      }

      // Verify old password
      final loginTest = await supabase.auth.signInWithPassword(
        email: session.user.email!,
        password: _oldPasswordController.text,
      );

      if (loginTest.user == null) {
        _showSnack("Current password is incorrect", isError: true);
        return;
      }

      // Update on Supabase Auth
      await supabase.auth.updateUser(
        supabase_flutter.UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      // Update local hash
      final newHash = _authService.hashPassword(_newPasswordController.text);
      await _authService.updateLocalPassword(
        session.user.id.hashCode,
        newHash,
      );

      _showSnack("Password updated successfully ✓", isError: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF00C58E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Password strength ────────────────────────────────────────────────────
  double _getStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 10) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9!@#\$%^&*]'))) strength += 0.25;
    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return Colors.yellow;
    return const Color(0xFF00C58E);
  }

  String _getStrengthLabel(double strength) {
    if (strength <= 0.25) return "Weak";
    if (strength <= 0.5) return "Fair";
    if (strength <= 0.75) return "Good";
    return "Strong";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newPassword = _newPasswordController.text;
    final strength = _getStrength(newPassword);

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Change Password",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF4A90E2), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Choose a strong password with at least 8 characters, a number and an uppercase letter.",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4A90E2),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Section label
              _sectionLabel("Current Password", isDark),
              const SizedBox(height: 10),
              _passwordField(
                controller: _oldPasswordController,
                label: "Enter current password",
                icon: Icons.lock_outline_rounded,
                show: _showOld,
                onToggle: () => setState(() => _showOld = !_showOld),
                isDark: isDark,
                validator: (v) =>
                v == null || v.isEmpty ? "This field is required" : null,
              ),

              const SizedBox(height: 24),

              _sectionLabel("New Password", isDark),
              const SizedBox(height: 10),
              _passwordField(
                controller: _newPasswordController,
                label: "Enter new password",
                icon: Icons.lock_rounded,
                show: _showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
                isDark: isDark,
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.length < 6
                    ? "Minimum 6 characters"
                    : null,
              ),

              // Password strength bar
              if (newPassword.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: strength,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.black12,
                          color: _getStrengthColor(strength),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _getStrengthLabel(strength),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStrengthColor(strength),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              _sectionLabel("Confirm New Password", isDark),
              const SizedBox(height: 10),
              _passwordField(
                controller: _confirmPasswordController,
                label: "Confirm your new password",
                icon: Icons.lock_reset_rounded,
                show: _showConfirm,
                onToggle: () =>
                    setState(() => _showConfirm = !_showConfirm),
                isDark: isDark,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Submit button
              GestureDetector(
                onTap: _isLoading ? null : _changePassword,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? null
                        : const LinearGradient(
                      colors: [
                        Color(0xFF7B2FF7),
                        Color(0xFF4A90E2),
                      ],
                    ),
                    color: _isLoading
                        ? (isDark ? Colors.white12 : Colors.black12)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isLoading
                        ? []
                        : [
                      BoxShadow(
                        color:
                        const Color(0xFF7B2FF7).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "Update Password",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white54 : Colors.black45,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Password field ───────────────────────────────────────────────────────
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool show,
    required VoidCallback onToggle,
    required bool isDark,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.inter(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white38 : Colors.black38, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            show
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.07),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF7B2FF7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}