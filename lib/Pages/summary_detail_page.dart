import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resuma/Pages/premium.dart';
import 'package:share_plus/share_plus.dart';

import '../service/ad_service.dart';
import '../service/credit_service.dart';

class SummaryDetailPage extends StatefulWidget {
  final String title;
  final String summary;
  final String type;
  final DateTime createdAt;

  const SummaryDetailPage({
    super.key,
    required this.title,
    required this.summary,
    required this.type,
    required this.createdAt,
  });

  @override
  State<SummaryDetailPage> createState() => _SummaryDetailPageState();
}

class _SummaryDetailPageState extends State<SummaryDetailPage> {
  bool _isSharing = false;

  // ✅ Pas d'auto-save — lecture seule
  // Pas de HistoryService — pas de sauvegarde
  // Pas de summariesNotifier — pas d'impact sur les stats

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'photo': return "Photo";
      case 'batch': return "Batch";
      default: return "Document";
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'photo': return const Color(0xFF7B2FF7);
      case 'batch': return const Color(0xFF4A90E2);
      default: return const Color(0xFF00C58E);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'photo': return Icons.camera_alt_rounded;
      case 'batch': return Icons.photo_library_rounded;
      default: return Icons.description_rounded;
    }
  }

  // ✅ Partage avec pub rewarded pour les users free
  Future<void> _handleShare() async {
    final plan = CreditService().currentPlan;

    if (plan != UserPlan.free) {
      await Share.share("${widget.title}\n\n${widget.summary}",
          subject: widget.title);
      return;
    }

    setState(() => _isSharing = true);

    await AdService().showRewarded(
      onRewarded: () async {
        await Share.share("${widget.title}\n\n${widget.summary}",
            subject: widget.title);
        if (mounted) setState(() => _isSharing = false);
      },
      onNotReady: () {
        if (mounted) setState(() => _isSharing = false);
        _showAdNotReadyDialog();
      },
    );

    if (mounted) setState(() => _isSharing = false);
  }

  void _showAdNotReadyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Ad not ready",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        content: Text(
          "Please wait a moment and try again.\nOr upgrade to Premium for instant sharing.",
          style: GoogleFonts.inter(
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
              fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK",
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PremiumPage()));
            },
            child: const Text("Go Premium",
                style: TextStyle(color: Color(0xFF7B2FF7))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFree = CreditService().currentPlan == UserPlan.free;
    final color = _typeColor(widget.type);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Summary",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ Partager — pub rewarded si free
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF7B2FF7)))
                : Stack(
                    children: [
                      Icon(Icons.share_rounded,
                          color: isDark ? Colors.white70 : Colors.black54),
                      if (isFree)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
            tooltip: isFree ? "Share (watch ad)" : "Share",
            onPressed: _isSharing ? null : _handleShare,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Infos résumé ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // Badge type
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_typeIcon(widget.type), color: color, size: 13),
                      const SizedBox(width: 5),
                      Text(_typeLabel(widget.type),
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Date
                Text(
                  _formatDate(widget.createdAt),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38),
                ),
              ],
            ),
          ),

          // ─── Titre ──────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),

          // ─── Info pub si free ────────────────────────────────────────────
          if (isFree)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline_rounded,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Watch a short ad to share",
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PremiumPage())),
                      child: Text("Go Premium",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF7B2FF7),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Contenu résumé ──────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  widget.summary,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.7,
                    color: isDark
                        ? Colors.white.withOpacity(0.87)
                        : const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
