import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resuma/Pages/summary_detail_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


import '../main.dart';
import '../service/ad_service.dart';
import '../service/credit_service.dart';
import '../service/history_service.dart';
import '../widget/ad_widgets.dart';
import 'premium.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late HistoryService _historyService;
  List<HistorySummary> _summaries = [];
  List<HistorySummary> _filtered = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(database);
    _loadSummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSummaries() async {
    setState(() => _isLoading = true);
    final data = await _historyService.getAllSummaries();
    setState(() {
      _summaries = data;
      _filtered = data;
      _isLoading = false;
    });
  }

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _filtered = _summaries);
      return;
    }
    final results = await _historyService.searchSummaries(query);
    setState(() => _filtered = results);
  }

  Future<void> _deleteSummary(HistorySummary summary) async {
    final confirm = await _showDeleteDialog(summary.title);
    if (!confirm) return;
    await _historyService.deleteSummary(summary);
    _loadSummaries();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Summary deleted"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteAll() async {
    final confirm = await _showDeleteDialog("all summaries");
    if (!confirm) return;
    await _historyService.deleteAll();
    _loadSummaries();
  }

  Future<bool> _showDeleteDialog(String title) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text("Delete",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        content: Text('Are you sure you want to delete "$title"?',
            style: GoogleFonts.inter(
                color: isDark ? Colors.white54 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _exportPdf(HistorySummary summary) async {
    final plan = CreditService().currentPlan;

    // ✅ Bloque si free
    if (plan == UserPlan.free) {
      _showPremiumRequiredDialog();
      return;
    }

    try {
      final document = PdfDocument();
      final page = document.pages.add();

      page.graphics.drawString(
        summary.title,
        PdfStandardFont(PdfFontFamily.helvetica, 18,
            style: PdfFontStyle.bold),
        bounds: const Rect.fromLTWH(0, 0, 500, 30),
      );

      page.graphics.drawString(
        _formatDate(summary.createdAt),
        PdfStandardFont(PdfFontFamily.helvetica, 10),
        brush: PdfSolidBrush(PdfColor(150, 150, 150)),
        bounds: const Rect.fromLTWH(0, 35, 500, 20),
      );

      page.graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200)),
        const Offset(0, 60),
        const Offset(500, 60),
      );

      page.graphics.drawString(
        summary.content,
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: const Rect.fromLTWH(0, 70, 500, 700),
        format: PdfStringFormat(
          wordWrap: PdfWordWrapType.word,
          lineAlignment: PdfVerticalAlignment.top,
        ),
      );

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${summary.title.replaceAll(' ', '_')}.pdf';
      final file = File(path);
      await file.writeAsBytes(await document.save());
      document.dispose();

      await Share.shareXFiles([XFile(path)], subject: summary.title);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ Dialog premium requis pour export PDF
  void _showPremiumRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FF7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: Color(0xFF7B2FF7), size: 36),
            ),
            const SizedBox(height: 16),
            Text("Premium Feature",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              "PDF export is available for Basic and Pro plan members.",
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PremiumPage()));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text("Upgrade to Premium",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Maybe later",
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white38 : Colors.black38)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSummary(HistorySummary summary) async {
    final plan = CreditService().currentPlan;

    // ✅ Premium → partage direct
    if (plan != UserPlan.free) {
      await Share.share("${summary.title}\n\n${summary.content}",
          subject: summary.title);
      return;
    }

    // ✅ Free → pub rewarded avant le partage
    await AdService().showRewarded(
      onRewarded: () async {
        // Pub regardée → partage autorisé
        await Share.share("${summary.title}\n\n${summary.content}",
            subject: summary.title);
      },
      onNotReady: () {
        // Pub pas prête → affiche dialog
        showDialog(
          context: context,
          builder: (_) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor:
              isDark ? const Color(0xFF1C1C2E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text("Ad not ready",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color:
                      isDark ? Colors.white : const Color(0xFF1A1A2E))),
              content: Text(
                "Please wait a moment and try again.\nOr upgrade to Premium for instant sharing.",
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Colors.black54,
                    height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
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
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return "${diff.inMinutes}m ago";
      return "${diff.inHours}h ago";
    }
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'photo': return Icons.camera_alt_rounded;
      case 'batch': return Icons.photo_library_rounded;
      default: return Icons.description_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'photo': return const Color(0xFF7B2FF7);
      case 'batch': return const Color(0xFF4A90E2);
      default: return const Color(0xFF00C58E);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'photo': return "Photo";
      case 'batch': return "Batch";
      default: return "Document";
    }
  }

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
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearch,
          style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Search summaries...",
            hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.white38 : Colors.black38),
            border: InputBorder.none,
          ),
        )
            : Text(
          "History",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: !_isSearching,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filtered = _summaries;
                }
              });
            },
          ),
          if (!_isSearching && _summaries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: "Delete all",
              onPressed: _deleteAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? _emptyState(isDark)
          : RefreshIndicator(
        onRefresh: _loadSummaries,
        color: const Color(0xFF7B2FF7),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          // ✅ itemCount inclut les native ads
          itemCount: _filtered.length +
              (_filtered.length / 5).floor(),
          itemBuilder: (_, i) {
            // ✅ Insère une native ad toutes les 5 entrées
            // Position réelle = i - nombre d'ads déjà insérées
            final adCount = i ~/ 6; // 1 ad tous les 6 items
            final realIndex = i - adCount;

            // ✅ Affiche la native ad à position 5, 11, 17...
            if (i > 0 && (i + 1) % 6 == 0 &&
                CreditService().currentPlan == UserPlan.free) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NativeAdWidget(height: 100),
              );
            }

            if (realIndex >= _filtered.length) {
              return const SizedBox.shrink();
            }

            return _summaryCard(_filtered[realIndex], isDark);
          },
        ),
      ),
    );
  }

  Widget _summaryCard(HistorySummary summary, bool isDark) {
    final color = _typeColor(summary.type);
    final isPremium = CreditService().currentPlan != UserPlan.free;

    return Dismissible(
      key: Key('${summary.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) => _showDeleteDialog(summary.title),
      onDismissed: (_) async {
        await _historyService.deleteSummary(summary);
        _loadSummaries();
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SummaryDetailPage(
              title: summary.title,
              summary: summary.content,
              type: summary.type,
              createdAt: summary.createdAt,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(summary.type), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_typeLabel(summary.type),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(summary.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color:
                            isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                icon: Icon(Icons.more_vert,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20),
                onSelected: (value) async {
                  switch (value) {
                    case 'view':
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SummaryDetailPage(
                          title: summary.title,
                          summary: summary.content,
                          type: summary.type,
                          createdAt: summary.createdAt,
                        ),
                      ));
                      break;
                    case 'share':
                      await _shareSummary(summary);
                      break;
                    case 'pdf':
                      await _exportPdf(summary); // ✅ vérifie le plan
                      break;
                    case 'delete':
                      await _deleteSummary(summary);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  _menuItem('view', Icons.visibility_outlined, "View", isDark),
                  _menuItem(
                      'share', Icons.share_outlined, "Share", isDark),
                  // ✅ Icône cadenas si free
                  _menuItem(
                    'pdf',
                    isPremium
                        ? Icons.picture_as_pdf_outlined
                        : Icons.lock_outline_rounded,
                    isPremium ? "Export PDF" : "Export PDF 🔒",
                    isDark,
                  ),
                  const PopupMenuDivider(),
                  _menuItem('delete', Icons.delete_outline, "Delete", isDark,
                      isDestructive: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, bool isDark,
      {bool isDestructive = false}) {
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white70 : Colors.black87);
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 13)),
      ]),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FF7).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 52, color: Color(0xFF7B2FF7)),
          ),
          const SizedBox(height: 20),
          Text(
            _isSearching ? "No results found" : "No summaries yet",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? "Try a different keyword"
                : "Start by scanning a course or importing a document",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}