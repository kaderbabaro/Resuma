import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemePage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const ThemePage({super.key, required this.onThemeChanged});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleTheme(bool val) {
    setState(() => _isDarkMode = val);
    widget.onThemeChanged(val);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(val ? "Dark mode enabled" : "Light mode enabled"),
        backgroundColor:
        val ? const Color(0xFF7B2FF7) : const Color(0xFF4A90E2),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

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
          "Appearance",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── Preview card ───────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                    colors: [Color(0xFF1C1C2E), Color(0xFF0D0D1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : const LinearGradient(
                    colors: [Color(0xFFE8EEFF), Color(0xFFF4F6FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.07),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFF7B2FF7).withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: 20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : const Color(0xFF4A90E2).withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Icon(
                              isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              key: ValueKey(isDark),
                              size: 48,
                              color: isDark
                                  ? const Color(0xFF7B2FF7)
                                  : Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isDark ? "Dark Mode" : "Light Mode",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            isDark
                                ? "Easy on the eyes at night"
                                : "Clean and bright interface",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Theme",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // ─── Toggle card ────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C2E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF7B2FF7).withOpacity(0.15)
                            : Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark
                            ? const Color(0xFF7B2FF7)
                            : Colors.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dark Mode",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            isDark ? "Enabled" : "Disabled",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom switch
                    GestureDetector(
                      onTap: () => _toggleTheme(!_isDarkMode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: _isDarkMode
                              ? const LinearGradient(
                            colors: [
                              Color(0xFF7B2FF7),
                              Color(0xFF4A90E2)
                            ],
                          )
                              : null,
                          color: _isDarkMode
                              ? null
                              : (isDark
                              ? Colors.white12
                              : Colors.black12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: _isDarkMode
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Info ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4A90E2).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF4A90E2), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your theme preference is saved automatically.",
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
            ],
          ),
        ),
      ),
    );
  }
}