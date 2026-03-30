import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          "Help & Support",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          // ─── Hero banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "How can we help?",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Browse the FAQ or contact us directly.",
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ─── FAQ section ──────────────────────────────────────────────────
          _sectionLabel("Frequently Asked Questions", isDark),
          const SizedBox(height: 12),

          _faqCard(isDark, [
            _FaqItem(
              question: "How do I change my password?",
              answer:
              "Go to My Account → Change Password and follow the instructions to update your password securely.",
              icon: Icons.lock_outline_rounded,
              color: const Color(0xFF7B2FF7),
            ),
            _FaqItem(
              question: "How do I enable dark mode?",
              answer:
              "Go to My Account → Dark Mode and toggle the switch to enable or disable dark mode.",
              icon: Icons.dark_mode_outlined,
              color: const Color(0xFF4A90E2),
            ),
            _FaqItem(
              question: "How does the scanner work?",
              answer:
              "Tap the scan button, point your camera at a course page, and Résuma will automatically extract and summarize the content using AI.",
              icon: Icons.camera_alt_outlined,
              color: const Color(0xFF00C58E),
            ),
            _FaqItem(
              question: "What file formats are supported?",
              answer:
              "Résuma supports PDF, DOCX, and TXT files. Simply import your document and tap 'Summarize with AI'.",
              icon: Icons.description_outlined,
              color: const Color(0xFFFF6B35),
            ),
            _FaqItem(
              question: "What is Batch Mode?",
              answer:
              "Batch Mode lets you scan multiple pages of the same course in a row, then send them all at once for a complete summary.",
              icon: Icons.photo_library_outlined,
              color: const Color(0xFF7B2FF7),
            ),
            _FaqItem(
              question: "What are the Premium benefits?",
              answer:
              "Premium gives you unlimited summaries, full history, PDF export, no ads, and priority AI processing. Plans start at 2.99€/month.",
              icon: Icons.auto_awesome,
              color: Colors.amber,
            ),
          ]),

          const SizedBox(height: 28),

          // ─── Contact section ──────────────────────────────────────────────
          _sectionLabel("Contact Us", isDark),
          const SizedBox(height: 12),

          _contactCard(
            isDark: isDark,
            icon: Icons.email_outlined,
            label: "Send us an email",
            subtitle: "support@resuma.app",
            color: const Color(0xFF4A90E2),
            onTap: () => _launchUrl("mailto:support@resuma.app"),
          ),

          const SizedBox(height: 10),

          _contactCard(
            isDark: isDark,
            icon: Icons.language_rounded,
            label: "Visit our website",
            subtitle: "www.resuma.app",
            color: const Color(0xFF00C58E),
            onTap: () => _launchUrl("https://resuma.app"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white38 : Colors.black38,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── FAQ card ─────────────────────────────────────────────────────────────
  Widget _faqCard(bool isDark, List<_FaqItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
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
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Theme(
                data: ThemeData(
                  dividerColor: Colors.transparent,
                  splashColor: item.color.withOpacity(0.05),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 14),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  title: Text(
                    item.question,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  iconColor:
                  isDark ? Colors.white38 : Colors.black38,
                  collapsedIconColor:
                  isDark ? Colors.white24 : Colors.black26,
                  children: [
                    Text(
                      item.answer,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                        isDark ? Colors.white54 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 54,
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Contact card ─────────────────────────────────────────────────────────
  Widget _contactCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    }
  }
}

// ─── FAQ Item model ───────────────────────────────────────────────────────────
class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;
  final Color color;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.color,
  });
}