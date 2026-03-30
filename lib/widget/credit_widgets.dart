import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resuma/Pages/premium.dart';

import '../service/ad_service.dart';
import '../service/credit_service.dart';

// ─── Dialog affiché quand pas assez de crédits ────────────────────────────────
class NoCreditDialog extends StatelessWidget {
  final String summaryType;
  final VoidCallback onWatchAd;

  const NoCreditDialog({
    super.key,
    required this.summaryType,
    required this.onWatchAd,
  });

  static Future<bool> show(
      BuildContext context, {
        required String summaryType,
        required VoidCallback onWatchAd,
      }) async {
    return await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NoCreditDialog(
        summaryType: summaryType,
        onWatchAd: onWatchAd,
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cost = CreditService().getCost(summaryType);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.orange, size: 40),
          ),

          const SizedBox(height: 16),

          Text(
            "Not enough credits",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "This summary costs $cost credit${cost > 1 ? 's' : ''}.\nWatch a short ad to earn 1 credit.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // ✅ Watch ad
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await AdService().showRewarded(
                onRewarded: () {
                  // ✅ AdService a déjà fait rewardWatchAd() → +1 crédit
                  // onWatchAd() dans scan/file_picker vérifie canSummarize()
                  // et relance SEULEMENT si assez de crédits
                  onWatchAd.call();
                },
                onNotReady: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ad not ready, try again in a moment"),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Watch ad  (+1 credit)",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.pop(context, false);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PremiumPage()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Go Premium — Unlimited",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CreditBadge — se met à jour automatiquement via ValueNotifier ────────────
class CreditBadge extends StatefulWidget {
  const CreditBadge({super.key});

  @override
  State<CreditBadge> createState() => _CreditBadgeState();
}

class _CreditBadgeState extends State<CreditBadge> {
  @override
  void initState() {
    super.initState();
    CreditService().creditsNotifier.addListener(_rebuild);
    CreditService().planNotifier.addListener(_rebuild);
    _initLoad();
  }

  @override
  void dispose() {
    CreditService().creditsNotifier.removeListener(_rebuild);
    CreditService().planNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _initLoad() async {
    final credits = await CreditService().getCredits();
    if (!mounted) return;
    CreditService().creditsNotifier.value = credits;
  }

  @override
  Widget build(BuildContext context) {
    final plan = CreditService().currentPlan;
    final credits = CreditService().creditsNotifier.value;

    if (plan == UserPlan.pro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 13),
            SizedBox(width: 4),
            Text("Pro",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _initLoad,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: credits == 0
              ? Colors.red.withOpacity(0.15)
              : Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: credits == 0
                ? Colors.red.withOpacity(0.4)
                : Colors.orange.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: credits == 0 ? Colors.red : Colors.orange,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              credits == 0 ? "0 credits" : "$credits credits",
              style: TextStyle(
                color: credits == 0 ? Colors.red : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}