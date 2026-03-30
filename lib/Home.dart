import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resuma/Pages/history_page.dart';
import 'package:resuma/widget/ad_widgets.dart';
import 'package:resuma/widget/app_drawer.dart';
import 'package:resuma/service/credit_service.dart';
import 'package:resuma/service/history_service.dart';
import 'package:resuma/main.dart';

import 'Pages/Scan.dart';
import 'widget/credit_widgets.dart';
import 'Pages/documents.dart';
import 'Pages/premium.dart';

class HomePage1 extends StatefulWidget {
  const HomePage1({Key? key}) : super(key: key);

  @override
  State<HomePage1> createState() => _HomePage1State();
}

class _HomePage1State extends State<HomePage1>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ✅ Vraies stats
  int _summariesCount = 0;
  int _documentsCount = 0;
  int _streakDays = 0;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // ✅ Écoute les changements de plan → rebuild automatique
    CreditService().planNotifier.addListener(_onPlanChanged);

    HistoryService.summariesNotifier.addListener(_loadStats);
    _loadStats();
  }

  @override
  void dispose() {
    CreditService().planNotifier.removeListener(_onPlanChanged);
    HistoryService.summariesNotifier.removeListener(_loadStats);
    _animController.dispose();
    super.dispose();
  }

  void _onPlanChanged() {
    if (mounted) setState(() => _isPremium = CreditService().currentPlan != UserPlan.free);
  }


  Future<void> _loadStats() async {
    await CreditService().loadFromSupabase();

    final historyService = HistoryService(database);
    final summaries = await historyService.getAllSummaries();

    // ✅ Compte résumés et documents
    final total = summaries.length;
    final docs = summaries.where((s) => s.type == 'document').length;

    // ✅ Calcule le streak — jours consécutifs avec au moins 1 résumé
    final streak = _calculateStreak(summaries);

    if (!mounted) return;
    setState(() {
      _summariesCount = total;
      _documentsCount = docs;
      _streakDays = streak;
      _isPremium = CreditService().currentPlan != UserPlan.free;
    });
  }

  // ✅ Calcule le streak basé sur les dates des résumés
  int _calculateStreak(List<HistorySummary> summaries) {
    if (summaries.isEmpty) return 0;

    // Extrait les dates uniques (sans l'heure)
    final dates = summaries
        .map((s) => DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // tri décroissant

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Si pas de résumé aujourd'hui ni hier → streak = 0
    if (dates.first.isBefore(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ✅ Refresh au retour de PremiumPage
  void _goToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PremiumPage()),
    ).then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6FB),
      drawer: const AppDrawer(),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── AppBar ────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded,
                        color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Text(
                  "Resuma",
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                actions: [
                  const CreditBadge(),
                  const SizedBox(width: 8),
                  // ✅ Badge plan dynamique
                  if (!_isPremium)
                    GestureDetector(
                      onTap: _goToPremium,
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text("Premium",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  if (_isPremium)
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2FF7).withOpacity(0.15),
                        border: Border.all(
                            color: const Color(0xFF7B2FF7).withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFF7B2FF7), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            CreditService().currentPlan == UserPlan.pro
                                ? "Pro"
                                : "Basic",
                            style: const TextStyle(
                                color: Color(0xFF7B2FF7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ─── Greeting ──────────────────────────────────────
                      Text(_getGreeting(),
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38)),
                      const SizedBox(height: 4),
                      Text("Ready to summarize?",
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E))),

                      const SizedBox(height: 24),

                      // ─── Stats ─────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              icon: Icons.auto_awesome,
                              label: "Summaries",
                              value: _summariesCount.toString(),
                              color: const Color(0xFF7B2FF7),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              icon: Icons.description_outlined,
                              label: "Documents",
                              value: _documentsCount.toString(),
                              color: const Color(0xFF4A90E2),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              icon: Icons.local_fire_department,
                              label: "Streak",
                              // ✅ Affiche le vrai streak
                              value: _streakDays == 0
                                  ? "0d"
                                  : "${_streakDays}d 🔥",
                              color: const Color(0xFFFF6B35),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ─── Quick Actions ─────────────────────────────────
                      Text("Quick Actions",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E))),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _actionCard(
                              icon: Icons.camera_alt_outlined,
                              label: "Scan\na course",
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7B2FF7),
                                  Color(0xFF4A90E2)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ScanPageWidget())).then((_) => _loadStats()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionCard(
                              icon: Icons.upload_file_outlined,
                              label: "Import\na file",
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00C58E),
                                  Color(0xFF00A3FF)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const UniversalFilePickerPage()))
                                  .then((_) => _loadStats()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _actionCard(
                              icon: Icons.history_rounded,
                              label: "Summary\nHistory",
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF6B35),
                                  const Color(0xFFFF6B35).withOpacity(0.7)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const HistoryPage()))
                                  .then((_) => _loadStats()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionCard(
                              icon: Icons.auto_awesome,
                              label: _isPremium
                                  ? "My active\nplan"
                                  : "Go\nPremium",
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade600,
                                  Colors.orange.shade400
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: _goToPremium,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ─── Tip card ──────────────────────────────────────
                      _buildTipCard(isDark),

                      const SizedBox(height: 16),

                      // ✅ Banner ad uniquement pour free
                      if (!_isPremium) const BannerAdWidget(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7B2FF7).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ScanPageWidget()))
              .then((_) => _loadStats()),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text("Scan a course",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(bool isDark) {
    final tips = [
      {
        'icon': Icons.lightbulb_outline,
        'title': "Tip of the day",
        'text':
        "Use Batch mode to scan multiple pages of the same course at once!",
        'color': const Color(0xFF7B2FF7)
      },
      {
        'icon': Icons.school_outlined,
        'title': "Did you know?",
        'text':
        "Structured summaries with titles and key points improve memorization by 40%.",
        'color': const Color(0xFF00C58E)
      },
      {
        'icon': Icons.tips_and_updates_outlined,
        'title': "Pro tip",
        'text':
        "Import your course PDFs directly for a complete summary in seconds.",
        'color': const Color(0xFFFF6B35)
      },
    ];
    final tip = tips[DateTime.now().day % tips.length];
    final color = tip['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(tip['icon'] as IconData, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip['title'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(tip['text'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning 👋";
    if (hour < 18) return "Good afternoon 👋";
    return "Good evening 👋";
  }
}