import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../service/ad_service.dart';
import '../service/credit_service.dart';
import '../service/history_service.dart';
import '../Pages/premium.dart';

class ResultPage extends StatefulWidget {
  final String summary;
  final String? title;
  final String? type;

  const ResultPage({
    super.key,
    required this.summary,
    this.title,
    this.type,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _isSaved = false;
  bool _isSaving = false;
  bool _isSharing = false;
  late HistoryService _historyService;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(database);
    _autoSave();
  }

  String _generateTitle() {
    if (widget.title != null && widget.title!.isNotEmpty) return widget.title!;
    final words = widget.summary.replaceAll('\n', ' ').trim().split(' ');
    final titleWords = words.take(6).join(' ');
    return titleWords.length > 40
        ? '${titleWords.substring(0, 40)}...'
        : titleWords;
  }

  Future<void> _autoSave() async {
    if (_isSaved) return;
    setState(() => _isSaving = true);
    try {
      await _historyService.saveSummary(
        title: _generateTitle(),
        content: widget.summary,
        type: widget.type ?? 'photo',
      );
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Future<void> _manualSave() async {
    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Already saved ✓"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _historyService.saveSummary(
        title: _generateTitle(),
        content: widget.summary,
        type: widget.type ?? 'photo',
      );
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saved to history ✓"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save failed: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ Partage avec pub rewarded pour les users free
  Future<void> _handleShare() async {
    final plan = CreditService().currentPlan;

    // ✅ Premium → partage direct
    if (plan != UserPlan.free) {
      await Share.share(widget.summary);
      return;
    }

    // ✅ Free → pub rewarded avant le partage
    setState(() => _isSharing = true);

    await AdService().showRewarded(
      onRewarded: () async {
        // Pub regardée → partage autorisé
        await Share.share(widget.summary);
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
        title: Text(
          "Ad not ready",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        content: Text(
          "Please wait a moment and try again.\nOr upgrade to Premium for instant sharing.",
          style: GoogleFonts.inter(
            color: isDark ? Colors.white54 : Colors.black54,
            height: 1.5,
            fontSize: 13,
          ),
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PremiumPage()));
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
          // ✅ Bouton partager — pub rewarded si free
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
                // ✅ Petit badge pub si free
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
          // ─── Badge modèle + statut sauvegarde ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FF7).withOpacity(0.1),
                    border: Border.all(
                        color: const Color(0xFF7B2FF7).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Color(0xFF7B2FF7), size: 14),
                      SizedBox(width: 6),
                      Text(
                        "Generated by Groq",
                        style: TextStyle(
                            color: Color(0xFF7B2FF7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_isSaving)
                  Row(
                    children: [
                      const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF00C58E))),
                      const SizedBox(width: 6),
                      Text("Saving...",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38)),
                    ],
                  )
                else if (_isSaved)
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF00C58E), size: 14),
                      const SizedBox(width: 4),
                      Text("Saved",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF00C58E),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
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
                      "Watch a short ad to share this summary",
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

          // ─── Contenu du résumé ───────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
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

          // ─── Boutons bas ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.camera_alt_rounded,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF7B2FF7)),
                    label: Text(
                      "New scan",
                      style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF7B2FF7)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFF7B2FF7).withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _manualSave,
                    icon: _isSaving
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Icon(
                        _isSaved
                            ? Icons.bookmark_added
                            : Icons.bookmark_add,
                        color: Colors.white),
                    label: Text(
                      _isSaved ? "Saved ✓" : "Save",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved
                          ? const Color(0xFF00C58E)
                          : const Color(0xFF7B2FF7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}