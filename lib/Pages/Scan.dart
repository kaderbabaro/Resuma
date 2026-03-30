import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resuma/Pages/result_page.dart';
import '../service/ad_service.dart';
import '../service/credit_service.dart';
import '../service/openai_service.dart';
import '../widget/credit_widgets.dart';



class ScanPageWidget extends StatefulWidget {
  const ScanPageWidget({super.key});

  @override
  State<ScanPageWidget> createState() => _ScanPageWidgetState();
}

class _ScanPageWidgetState extends State<ScanPageWidget>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isFlashOn = false;
  bool _isBatchMode = false;
  bool _autoCrop = true;
  bool _isCameraReady = false;
  bool _isTakingPicture = false;
  bool _isAnalyzing = false;

  // Batch mode: liste des photos capturées
  final List<File> _capturedImages = [];

  final ImagePicker _picker = ImagePicker();
  final OpenAIService _openAI = OpenAIService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ─── Init caméra avec permissions ───────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorSnackBar("Aucune caméra disponible.");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Erreur caméra: $e");
      _showErrorSnackBar("Impossible d'initialiser la caméra.");
    }
  }

  // ─── Flash ───────────────────────────────────────────────────────────────────
  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  // ─── Prise de photo ──────────────────────────────────────────────────────────
  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final xFile = await _controller!.takePicture();
      File imageFile = File(xFile.path);

      // Simule l'auto-crop (en production, utilise image_cropper)
      if (_autoCrop) {
        imageFile = await _simulateAutoCrop(imageFile);
      }

      if (_isBatchMode) {
        // Mode batch : ajoute à la liste et affiche miniature
        setState(() => _capturedImages.add(imageFile));
        _showBatchSnackBar();
      } else {
        // Mode normal : popup de prévisualisation
        if (mounted) {
          await _showPreviewPopup(imageFile);
        }
      }
    } catch (e) {
      debugPrint("Erreur capture: $e");
      _showErrorSnackBar("Error while taking.");
    } finally {
      setState(() => _isTakingPicture = false);
    }
  }

  // ─── Simule l'auto-crop (placeholder) ───────────────────────────────────────
  Future<File> _simulateAutoCrop(File file) async {
    // En production : utilise package image_cropper ou image
    // Ici on retourne le fichier tel quel comme placeholder
    await Future.delayed(const Duration(milliseconds: 200));
    return file;
  }

  // ─── Galerie ─────────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      File imageFile = File(image.path);
      if (_autoCrop) {
        imageFile = await _simulateAutoCrop(imageFile);
      }
      if (_isBatchMode) {
        setState(() => _capturedImages.add(imageFile));
        _showBatchSnackBar();
      } else {
        await _showPreviewPopup(imageFile);
      }
    }
  }

  // ─── Popup prévisualisation ──────────────────────────────────────────────────
  Future<void> _showPreviewPopup(File image) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PreviewSheet(
        image: image,
        autoCrop: _autoCrop,
        onSend: () {
          Navigator.pop(context);
          _handleSend([image]);
        },
        onRetake: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  // ─── Snackbar batch mode ─────────────────────────────────────────────────────
  void _showBatchSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "${_capturedImages.length} photo(s) captured"),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Envoi des images → OpenAI ───────────────────────────────────────────────
  Future<void> _handleSend(List<File> images) async {
    final type = images.length == 1 ? 'photo' : 'batch';

    // ✅ Vérifie les crédits
    final canSummarize = await CreditService().canSummarize(type);
    if (!canSummarize) {
      if (!mounted) return;
      await NoCreditDialog.show(
        context,
        summaryType: type,
        onWatchAd: () async {
          await Future.delayed(const Duration(seconds: 2)); // TODO: AdMob
          await CreditService().rewardWatchAd();
          final canNow = await CreditService().canSummarize(type);
          if (canNow && mounted) _handleSend(images);
        },
      );
      return;
    }

    // ✅ Consomme les crédits
    await CreditService().consumeCredits(type);

    setState(() => _isAnalyzing = true);
    try {
      final String result;
      if (images.length == 1) {
        result = await _openAI.summarizeImagePage(images.first);
      } else {
        result = await _openAI.summarizeBatchPages(images);
      }
      if (!mounted) return;

      // ✅ Interstitial avant le résultat (free seulement)
      if (CreditService().currentPlan == UserPlan.free) {
        AdService().showInterstitial();
      }

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultPage(summary: result),
      ));

    } catch (e) {
      await CreditService().addCredits(CreditService().getCost(type));
      _showErrorSnackBar(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ─── Envoi du batch ──────────────────────────────────────────────────────────
  Future<void> _sendBatch() async {
    if (_capturedImages.isEmpty) return;
    final images = List<File>.from(_capturedImages);
    setState(() => _capturedImages.clear());
    await _handleSend(images);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraReady
          ? Stack(
        children: [
          // Camera preview
          Positioned.fill(child: CameraPreview(_controller!)),

          // Overlay frame
          Center(
            child: Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _autoCrop
                  ? Stack(
                children: [
                  // Coins de crop stylisés
                  ..._buildCropCorners(),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Auto Crop active",
                        style: TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ),

          // TOP BAR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconButton(
                    Icons.close, () => Navigator.pop(context)),
                Row(
                  children: [
                    const CreditBadge(), // ✅ badge crédits visible
                    const SizedBox(width: 12),
                    _iconButton(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      _toggleFlash,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BOTTOM BAR
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Miniatures batch mode
                if (_isBatchMode && _capturedImages.isNotEmpty)
                  _buildBatchThumbnails(),

                const SizedBox(height: 16),

                // Boutons capture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: 0,
                      child: _smallButton(
                          Icons.photo_library, "Gallery", () {}),
                    ),
                    _cameraButton(),
                    _smallButton(
                        Icons.photo_library, "Gallery",
                        _pickFromGallery),
                  ],
                ),

                const SizedBox(height: 20),

                // Options Batch + AutoCrop
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _optionButton(
                      Icons.photo_library_outlined,
                      "Batch Mode",
                          () => setState(
                              () => _isBatchMode = !_isBatchMode),
                      _isBatchMode,
                    ),
                    const SizedBox(width: 16),
                    _optionButton(
                      Icons.crop_free,
                      "Auto-Cropped",
                          () =>
                          setState(() => _autoCrop = !_autoCrop),
                      _autoCrop,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FAB Envoyer batch (visible seulement en batch mode avec photos)
          if (_isBatchMode && _capturedImages.isNotEmpty)
            Positioned(
              bottom: 180,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _sendBatch,
                backgroundColor: Colors.blue,
                icon: const Icon(Icons.send, color: Colors.white),
                label: Text(
                  "Send (${_capturedImages.length})",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Flash indicator
          if (_isTakingPicture)
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.3)),
            ),

          // Analyzing overlay
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 20),
                    Text(
                      "Analysing...",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "AI is summarizing your course  📚",
                      style: TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  // ─── Miniatures batch ────────────────────────────────────────────────────────
  Widget _buildBatchThumbnails() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                  image: DecorationImage(
                    image: FileImage(_capturedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(
                          () => _capturedImages.removeAt(index)),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Coins crop ──────────────────────────────────────────────────────────────
  List<Widget> _buildCropCorners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = Colors.blue;

    Widget corner(
        {bool top = true, bool left = true}) {
      return Positioned(
        top: top ? 8 : null,
        bottom: top ? null : 8,
        left: left ? 8 : null,
        right: left ? null : 8,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
                top: top, left: left, color: color, thickness: thickness),
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }

  // ─── Widgets helpers ─────────────────────────────────────────────────────────
  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(22),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _smallButton(
      IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(text,
              style:
              const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cameraButton() {
    return GestureDetector(
      onTap: _isTakingPicture ? null : _takePicture,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: _isTakingPicture ? 70 : 80,
        height: _isTakingPicture ? 70 : 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: _isTakingPicture ? Colors.grey : Colors.blue,
          size: 32,
        ),
      ),
    );
  }

  Widget _optionButton(
      IconData icon, String text, VoidCallback onTap, bool active) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.black54,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: active ? Colors.blue : Colors.white38, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style:
                const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Preview Bottom Sheet ────────────────────────────────────────────────────
class _PreviewSheet extends StatelessWidget {
  final File image;
  final bool autoCrop;
  final VoidCallback onSend;
  final VoidCallback onRetake;

  const _PreviewSheet({
    required this.image,
    required this.autoCrop,
    required this.onSend,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Preview",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (autoCrop)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.crop_free,
                            color: Colors.blue, size: 14),
                        SizedBox(width: 4),
                        Text("Auto-croppé",
                            style: TextStyle(
                                color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Image preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // Boutons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Reprendre
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Retake",
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Envoyer FAB style
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onSend,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "Send",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.blue.withOpacity(0.5),
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

// ─── Corner Painter pour auto-crop ──────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double thickness;

  _CornerPainter(
      {required this.top,
        required this.left,
        required this.color,
        required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
