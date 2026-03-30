import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'credit_service.dart';

// ─── Ad Unit IDs ──────────────────────────────────────────────────────────────
// 🔧 Remplace par tes vrais IDs après validation AdMob
class AdIds {
  // ── Test IDs (officiels Google) ──────────────────────────────────────────
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-NUMBER'
      : 'ca-app-pub-NUMBER';

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-NUMBER'
      : 'ca-app-pub-NUMBER';

  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-NUMBER'
      : 'ca-app-pub-NUMBER';

  static String get native => Platform.isAndroid
      ? 'ca-app-pub-NUMBER'
      : 'ca-app-pub-NUMBER';
}

// ─── AdMob Service ────────────────────────────────────────────────────────────
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  // ─── Initialize ────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint("✅ AdMob initialized");
  }

  // ── BANNER ─────────────────────────────────────────────────────────────────
  BannerAd createBanner({required void Function(Ad, LoadAdError) onFailed}) {
    final banner = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint("Banner loaded"),
        onAdFailedToLoad: onFailed,
      ),
    );
    banner.load();
    return banner;
  }

  // ── INTERSTITIAL ───────────────────────────────────────────────────────────
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          debugPrint("Interstitial loaded");

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              loadInterstitial(); // précharge le suivant
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint("Interstitial failed: $error");
          _isInterstitialReady = false;
        },
      ),
    );
  }

  void showInterstitial() {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      debugPrint("Interstitial not ready");
      loadInterstitial();
    }
  }

  // ── REWARDED ───────────────────────────────────────────────────────────────
  void loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          debugPrint("Rewarded loaded");

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedReady = false;
              loadRewarded(); // précharge le suivant
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint("Rewarded failed: $error");
          _isRewardedReady = false;
        },
      ),
    );
  }

  // ✅ Affiche la pub et donne +1 crédit si regardée jusqu'au bout
  Future<void> showRewarded({
    required VoidCallback onRewarded,
    required VoidCallback onNotReady,
  }) async {
    if (!_isRewardedReady || _rewardedAd == null) {
      onNotReady();
      loadRewarded();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint("Reward earned: ${reward.amount} ${reward.type}");
        await CreditService().rewardWatchAd(); // +1 crédit
        onRewarded();
      },
    );
  }

  bool get isRewardedReady => _isRewardedReady;
  bool get isInterstitialReady => _isInterstitialReady;

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
