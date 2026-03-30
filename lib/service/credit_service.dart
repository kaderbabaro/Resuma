import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// ─── Constantes crédits ───────────────────────────────────────────────────────
class CreditCosts {
  static const int photo = 1;
  static const int document = 2;
  static const int batch = 3;
}

class CreditRewards {
  static const int watchAd = 1;
}

class PlanCredits {
  static const int free = 0;       // doit regarder des pubs
  static const int basic = 50;     // 50 crédits/mois
  static const int pro = -1;       // illimité (-1 = infini)
}

// ─── Plan types ───────────────────────────────────────────────────────────────
enum UserPlan { free, basic, pro }

class CreditService {
  static const String _creditsKey = 'user_credits';
  static const String _planKey = 'user_plan';
  static const String _lastResetKey = 'credits_last_reset';

  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;
  final ValueNotifier<int> creditsNotifier = ValueNotifier(0);


  // ─── Singleton ───────────────────────────────────────────────────────────
  static final CreditService _instance = CreditService._internal();
  // ─── Cache synchrone du plan ─────────────────────────────────
  UserPlan _cachedPlan = UserPlan.free;
  UserPlan get currentPlan => _cachedPlan;
  // ─── Notifier pour rebuild automatique des widgets ────────────────
  final ValueNotifier<UserPlan> planNotifier = ValueNotifier(UserPlan.free);

  factory CreditService() => _instance;
  CreditService._internal();

  // ─── Get current plan ────────────────────────────────────────────────────
  Future<UserPlan> getUserPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planStr = prefs.getString(_planKey) ?? 'free';
    switch (planStr) {
      case 'basic': return UserPlan.basic;
      case 'pro': return UserPlan.pro;
      default: return UserPlan.free;
    }
  }

  UserPlan _planFromString(String? s) {
    switch (s) {
      case 'basic': return UserPlan.basic;
      case 'pro': return UserPlan.pro;
      default: return UserPlan.free;
    }
  }

  // ─── Set plan (après achat Stripe) ───────────────────────────────────────
  Future<void> setPlan(UserPlan plan, {int months = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan.name);
    _cachedPlan = plan;
    planNotifier.value = plan;

    // ✅ Calcule et sauvegarde la date d'expiration
    final expiresAt = DateTime.now().add(Duration(days: 30 * months));
    await prefs.setString('plan_expires_at', expiresAt.toIso8601String());

    if (plan == UserPlan.basic) {
      await setCredits(PlanCredits.basic);
    } else if (plan == UserPlan.pro) {
      await setCredits(PlanCredits.pro);
    }

    _syncPlanToSupabase(plan, expiresAt);
  }

  // ─── Get credits ─────────────────────────────────────────────────────────
  Future<int> getCredits() async {
    final plan = await getUserPlan();
    if (plan == UserPlan.pro) return -1; // illimité

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditsKey) ?? 0;
  }

  // ─── Set credits ─────────────────────────────────────────────────────────
  Future<void> setCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    creditsNotifier.value = amount;
    await prefs.setInt(_creditsKey, amount);
    _syncCreditsToSupabase(amount);
  }

  // ─── Can summarize ? ─────────────────────────────────────────────────────
  Future<bool> canSummarize(String type) async {
    final plan = await getUserPlan();
    if (plan == UserPlan.pro) return true;

    final credits = await getCredits();
    final cost = _getCost(type);
    return credits >= cost;
  }

  // ─── Consume credits ─────────────────────────────────────────────────────
  Future<bool> consumeCredits(String type) async {
    final plan = await getUserPlan();
    if (plan == UserPlan.pro) return true;

    final credits = await getCredits();
    final cost = _getCost(type);

    if (credits < cost) return false;

    await setCredits(credits - cost);
    return true;
  }

  // ─── Add credits (after watching ad) ─────────────────────────────────────
  Future<void> addCredits(int amount) async {
    final plan = await getUserPlan();
    if (plan == UserPlan.pro) return; // pro n'a pas besoin

    final current = await getCredits();
    await setCredits(current + amount);
  }

  // ─── Reward for watching ad ───────────────────────────────────────────────
  Future<void> rewardWatchAd() async {
    await addCredits(CreditRewards.watchAd);
    debugPrint("Credit rewarded: +${CreditRewards.watchAd} (ad watched)");
  }

  // ─── Cost per type ────────────────────────────────────────────────────────
  int _getCost(String type) {
    switch (type) {
      case 'photo': return CreditCosts.photo;
      case 'batch': return CreditCosts.batch;
      default: return CreditCosts.document;
    }
  }

  // ─── Monthly reset for Basic plan ────────────────────────────────────────
  Future<void> checkMonthlyReset() async {
    final plan = await getUserPlan();
    if (plan != UserPlan.basic) return;

    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_lastResetKey);

    final now = DateTime.now();

    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      // Reset si nouveau mois
      if (now.month != lastReset.month || now.year != lastReset.year) {
        await setCredits(PlanCredits.basic);
        await prefs.setString(_lastResetKey, now.toIso8601String());
      }
    } else {
      await prefs.setString(_lastResetKey, now.toIso8601String());
    }
  }

  // ─── Sync Supabase ────────────────────────────────────────────────────────
  Future<void> _syncCreditsToSupabase(int credits) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      await _supabase.from('users').update({
        'credits': credits,
      }).eq('id', session.user.id);
    } catch (e) {
      debugPrint("Sync credits failed: $e");
    }
  }

  Future<void> _syncPlanToSupabase(UserPlan plan, DateTime expiresAt) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      await _supabase.from('users').update({
        'plan': plan.name,
        'plan_updated_at': DateTime.now().toIso8601String(),
        'plan_expires_at': expiresAt.toIso8601String(), // ✅
      }).eq('id', session.user.id);
    } catch (e) {
      debugPrint("Sync plan failed: $e");
    }
  }

  Future<void> checkPlanExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = await getUserPlan();

    // Free → rien à vérifier
    if (plan == UserPlan.free) return;

    final expiresStr = prefs.getString('plan_expires_at');
    if (expiresStr == null) return;

    final expiresAt = DateTime.parse(expiresStr);

    // ✅ Plan expiré → repasse en free
    if (DateTime.now().isAfter(expiresAt)) {
      debugPrint("Plan expired → downgrade to free");
      await prefs.setString(_planKey, 'free');
      await prefs.setInt(_creditsKey, 0);
      _cachedPlan = UserPlan.free;
      planNotifier.value = UserPlan.free;
      creditsNotifier.value = 0;
      _syncPlanToSupabase(UserPlan.free, DateTime.now());
    }
  }
  // ─── Load from Supabase (on app start) ───────────────────────────────────
  Future<void> loadFromSupabase() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      final data = await _supabase
          .from('users')
          .select('credits, plan')
          .eq('id', session.user.id)
          .maybeSingle();

      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();

      if (data['plan'] != null) {
        await prefs.setString(_planKey, data['plan']);
        _cachedPlan = _planFromString(data['plan']);
        planNotifier.value = _cachedPlan;
      }


      if (data['credits'] != null) {
        final credits = data['credits'] as int;
        await prefs.setInt(_creditsKey, credits);
        creditsNotifier.value = credits;
      }
    } catch (e) {
      debugPrint("Load from Supabase failed: $e");
    }
  }

  int getCost(String type) => _getCost(type);

  // ─── Get label for UI ─────────────────────────────────────────────────────
  String getCostLabel(String type) {
    final cost = _getCost(type);
    return '$cost crédit${cost > 1 ? 's' : ''}';
  }
}
