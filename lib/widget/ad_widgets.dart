import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../service/ad_service.dart';


// ─── Banner Ad Widget ─────────────────────────────────────────────────────────
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _banner = AdService().createBanner(
      onFailed: (ad, error) {
        ad.dispose();
        if (mounted) setState(() => _loaded = false);
      },
    );
    // Écoute le chargement
    _banner = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();

    return Container(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _banner!),
    );
  }
}

// ─── Native Ad Widget ─────────────────────────────────────────────────────────
class NativeAdWidget extends StatefulWidget {
  final double height;
  const NativeAdWidget({super.key, this.height = 120});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _nativeAd = NativeAd(
      adUnitId: AdIds.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Native ad failed: $error");
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF7B2FF7),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white60,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
