import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/credit_service.dart';
import 'payment_confirm_page.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage>
    with SingleTickerProviderStateMixin {
  bool _isAnnual = false;
  bool _isLoading = false;
  String? _selectedPlan;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final Map<String, Map<String, dynamic>> _plans = {
    'basic': {
      'name': 'Basic',
      'monthly_price': 2.99,
      'annual_price': 24.99,
      'annual_monthly': 2.08,
      'color': const Color(0xFF4A90E2),
      'icon': Icons.bolt,
      'plan': UserPlan.basic,
      'features': ['20 summaries / month','30-day history','PDF export','No ads'],
      'stripe_monthly': 'https://buy.stripe.com/test_aFa4gyars3TZfujcBHg3600',
      'stripe_annual':  'https://buy.stripe.com/test_dRmaEWgPQ8af0zpgRXg3601',
    },
    'pro': {
      'name': 'Pro',
      'monthly_price': 5.99,
      'annual_price': 49.99,
      'annual_monthly': 4.16,
      'color': const Color(0xFF7B2FF7),
      'icon': Icons.auto_awesome,
      'plan': UserPlan.pro,
      'features': ['Unlimited summaries','Unlimited history','PDF export','No ads','Priority AI','Priority support'],
      'stripe_monthly': 'https://buy.stripe.com/test_7sY8wOfLM76bdmbeJPg3602',
      'stripe_annual':  'https://buy.stripe.com/test_3cIaEW0QS1LR95VfNTg3603',
    },
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _purchaseWithStripe(String planKey) async {
    setState(() { _isLoading = true; _selectedPlan = planKey; });
    try {
      final plan = _plans[planKey]!;
      final url = _isAnnual ? plan['stripe_annual'] as String : plan['stripe_monthly'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentConfirmPage(
            plan: planKey == 'pro' ? UserPlan.pro : UserPlan.basic,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentChoiceDialog(String planKey) {
    final plan = _plans[planKey]!;
    final price = _isAnnual ? plan['annual_price'] as double : plan['monthly_price'] as double;
    final period = _isAnnual ? 'year' : 'month';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("${plan['name']} — ${price.toStringAsFixed(2)}€/$period",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Choose your payment method",
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            _paymentButton(
              icon: Icons.credit_card,
              label: "Pay by card",
              subtitle: "Via Stripe — secure payment",
              color: const Color(0xFF00C58E),
              onTap: () { Navigator.pop(context); _purchaseWithStripe(planKey); },
            ),
            const SizedBox(height: 12),
            _paymentButton(
              icon: Platform.isIOS ? Icons.apple : Icons.android,
              label: Platform.isIOS ? "App Store (coming soon)" : "Play Store (coming soon)",
              subtitle: "In-app purchase — available soon",
              color: Colors.white24,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Coming soon! Use Stripe for now."),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _paymentButton({required IconData icon, required String label, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            )),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF0D0D1A),
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                Container(decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2), Color(0xFF0D0D1A)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                Positioned(top: -30, right: -30,
                    child: Container(width: 150, height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
                const Positioned(bottom: 30, left: 20, right: 20,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text("RÉSUMA PREMIUM", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ]),
                      SizedBox(height: 8),
                      Text("Learn\nwithout limits", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
                    ])),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFF1C1C2E), borderRadius: BorderRadius.circular(30)),
                  child: Row(children: [
                    _toggleButton("Monthly", !_isAnnual, () => setState(() => _isAnnual = false)),
                    _toggleButton("Annual", _isAnnual, () => setState(() => _isAnnual = true), badge: "-30%"),
                  ]),
                ),
                const SizedBox(height: 24),
                _buildPlanCard('basic'),
                const SizedBox(height: 16),
                _buildPlanCard('pro'),
                const SizedBox(height: 32),
                _buildFeatureComparison(),
                const SizedBox(height: 24),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                        "Subscription renews automatically. Cancel anytime from Stripe settings.",
                        style: TextStyle(color: Colors.white24, fontSize: 11), textAlign: TextAlign.center)),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap, {String? badge}) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: active ? const Color(0xFF7B2FF7) : Colors.transparent,
            borderRadius: BorderRadius.circular(26)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
          ]
        ]),
      ),
    ));
  }

  Widget _buildPlanCard(String planKey) {
    final plan = _plans[planKey]!;
    final isPro = planKey == 'pro';
    final color = plan['color'] as Color;
    final price = _isAnnual ? plan['annual_price'] as double : plan['monthly_price'] as double;
    final monthlyEquiv = _isAnnual ? plan['annual_monthly'] as double : null;
    final period = _isAnnual ? 'year' : 'month';

    return GestureDetector(
      onTap: () => _showPaymentChoiceDialog(planKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPro ? LinearGradient(colors: [
            const Color(0xFF7B2FF7).withOpacity(0.3),
            const Color(0xFF4A90E2).withOpacity(0.2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: isPro ? null : const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPro ? const Color(0xFF7B2FF7) : const Color(0xFF2A2A3E), width: isPro ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(plan['icon'] as IconData, color: color, size: 20)),
              const SizedBox(width: 10),
              Text(plan['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            if (isPro) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(20)),
                child: const Text("⭐ Popular", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${price.toStringAsFixed(2)}€", style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Text("/$period", style: const TextStyle(color: Colors.white38, fontSize: 14))),
            if (monthlyEquiv != null) ...[
              const SizedBox(width: 10),
              Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Text("= ${monthlyEquiv.toStringAsFixed(2)}€/mo",
                      style: TextStyle(color: color.withOpacity(0.7), fontSize: 12))),
            ]
          ]),
          const SizedBox(height: 16),
          ...(plan['features'] as List<String>).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(Icons.check_circle, color: color, size: 16),
                const SizedBox(width: 8),
                Text(f, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]))),
          const SizedBox(height: 16),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: _isLoading && _selectedPlan == planKey
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Choose ${plan['name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
        ]),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    final features = [
      {'label': 'Summaries / month', 'free': 'Watch ads',  'basic': '20', 'pro': '∞'},
      {'label': 'History',           'free': false, 'basic': '30d','pro': '∞'},
      {'label': 'PDF export',        'free': false,'basic': true, 'pro': true},
      {'label': 'No ads',            'free': false,'basic': true, 'pro': true},
      {'label': 'Priority AI',       'free': false,'basic': false,'pro': true},
    ];
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1C1C2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A3E))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Expanded(flex: 3, child: SizedBox()),
              _comparisonHeader("Free",  Colors.white38),
              _comparisonHeader("Basic", const Color(0xFF4A90E2)),
              _comparisonHeader("Pro",   const Color(0xFF7B2FF7)),
            ])),
        const Divider(color: Color(0xFF2A2A3E), height: 1),
        ...features.asMap().entries.map((entry) {
          final i = entry.key; final f = entry.value;
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(f['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  _comparisonCell(f['free']!,  Colors.white38),
                  _comparisonCell(f['basic']!, const Color(0xFF4A90E2)),
                  _comparisonCell(f['pro']!,   const Color(0xFF7B2FF7)),
                ])),
            if (i < features.length - 1) const Divider(color: Color(0xFF2A2A3E), height: 1),
          ]);
        }),
      ]),
    );
  }

  Widget _comparisonHeader(String label, Color color) => Expanded(flex: 2,
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)));

  Widget _comparisonCell(dynamic value, Color color) => Expanded(flex: 2,
      child: Center(child: value is bool
          ? Icon(value ? Icons.check_circle : Icons.cancel, color: value ? color : Colors.white12, size: 18)
          : Text(value as String, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))));
}