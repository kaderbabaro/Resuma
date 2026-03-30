import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../service/ad_service.dart';
import '../service/credit_service.dart';
import '../service/openai_service.dart';
import '../widget/credit_widgets.dart';
import 'result_page.dart';

class UniversalFilePickerPage extends StatefulWidget {
  const UniversalFilePickerPage({super.key});

  @override
  State<UniversalFilePickerPage> createState() =>
      _UniversalFilePickerPageState();
}

class _UniversalFilePickerPageState extends State<UniversalFilePickerPage> {
  String _extractedText = "";
  String _fileName = "";
  bool _isLoading = false;
  bool _isAnalyzing = false;

  final OpenAIService _openAI = OpenAIService();

  // ─── Sélection et extraction du fichier ──────────────────────────────────
  Future<void> pickAndProcessFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      allowMultiple: false,
    );

    if (result == null) return;

    final file = result.files.single;
    final filePath = file.path;

    if (filePath == null) return;

    // Validation de l'extension
    final extension = filePath.split('.').last.toLowerCase();
    if (!['pdf', 'docx', 'txt'].contains(extension)) {
      setState(() {
        _extractedText =
        "❌ Format non supporté. Veuillez choisir un fichier PDF, DOCX ou TXT.";
        _fileName = file.name;
      });
      return;
    }

    setState(() {
      _fileName = file.name;
      _isLoading = true;
      _extractedText = "";
    });

    try {
      final fileObj = File(filePath);

      if (extension == 'docx') {
        _extractedText = await _extractDocxText(fileObj);
      } else if (extension == 'txt') {
        _extractedText = await fileObj.readAsString();
      } else if (extension == 'pdf') {
        _extractedText = await _extractPdfText(fileObj);
      }

      // Vérifier si le texte extrait est vide
      if (_extractedText.trim().isEmpty) {
        _extractedText = "❌ Aucun texte détecté dans ce fichier.";
      }
    } catch (e) {
      debugPrint("Erreur extraction: $e");
      _extractedText = "❌ Erreur lors du traitement du fichier : $e";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Extraction PDF → texte (Syncfusion) ─────────────────────────────────
  Future<String> _extractPdfText(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);

    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final pageText = extractor.extractText(
        startPageIndex: i,
        endPageIndex: i,
      );
      if (pageText.trim().isNotEmpty) {
        buffer.writeln("--- Page ${i + 1} ---");
        buffer.writeln(pageText.trim());
        buffer.writeln();
      }
    }

    document.dispose();
    return buffer.toString();
  }

  // ─── Extraction DOCX → texte ──────────────────────────────────────────────
  Future<String> _extractDocxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final f in archive) {
      if (f.name == "word/document.xml") {
        final content = const Utf8Decoder().convert(f.content as List<int>);
        final document = XmlDocument.parse(content);
        return document
            .findAllElements('w:t')
            .map((e) => e.text)
            .join(' ');
      }
    }
    return "";
  }

  // ─── Envoi à OpenAI pour résumé ───────────────────────────────────────────
  Future<void> _analyzeWithOpenAI() async {
    if (_extractedText.isEmpty || _extractedText.startsWith("❌")) return;

    setState(() => _isAnalyzing = true);

    try {
      final canSummarize = await CreditService().canSummarize('document');
      if (!canSummarize) {
        setState(() => _isAnalyzing = false);
        await NoCreditDialog.show(
          context,
          summaryType: 'document',
          onWatchAd: () async {
            await Future.delayed(const Duration(seconds: 2));
            await CreditService().rewardWatchAd();
            final canNow = await CreditService().canSummarize('document');
            if (canNow && mounted) _analyzeWithOpenAI();
          },
        );
        return;
      }

      await CreditService().consumeCredits('document');

      final result = await _openAI.summarizeDocumentText(
        _extractedText,
        _fileName,
      );

      if (!mounted) return;

      // ✅ Interstitial uniquement pour les users free
      if (CreditService().currentPlan == UserPlan.free) {
        AdService().showInterstitial();
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(summary: result),
        ),
      );

    } catch (e) {
      // ✅ Rembourse les crédits si erreur
      await CreditService().addCredits(CreditService().getCost('document'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          'Import de fichier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.upload_file, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "Importer un document",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "PDF • DOCX • TXT",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bouton choisir fichier
            ElevatedButton.icon(
              onPressed:
              _isLoading || _isAnalyzing ? null : pickAndProcessFile,
              icon: const Icon(Icons.folder_open),
              label: const Text("Choisir un fichier"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nom du fichier avec icône selon le type
            if (_fileName.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileName.endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : _fileName.endsWith('.docx')
                          ? Icons.description
                          : Icons.text_snippet,
                      color: _fileName.endsWith('.pdf')
                          ? Colors.red
                          : Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Aperçu du texte extrait
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: _isLoading
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        "Extraction en cours...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : _extractedText.isEmpty
                    ? const Center(
                  child: Text(
                    "Le contenu extrait apparaîtra ici.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : SingleChildScrollView(
                  child: Text(
                    _extractedText,
                    style: const TextStyle(
                        fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton Résumer avec OpenAI
            if (_extractedText.isNotEmpty &&
                !_extractedText.startsWith("❌"))
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeWithOpenAI,
                icon: _isAnalyzing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isAnalyzing
                      ? "Analyse en cours..."
                      : "Résumer le cours",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}