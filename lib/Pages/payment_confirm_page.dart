import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../service/credit_service.dart';

class PaymentConfirmPage extends StatefulWidget {
  final UserPlan plan;

  const PaymentConfirmPage({super.key, required this.plan});

  @override
  State<PaymentConfirmPage> createState() => _PaymentConfirmPageState();
}

class _PaymentConfirmPageState extends State<PaymentConfirmPage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _confirmPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = sb.Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        setState(() => _error = "You must be logged in.");
        return;
      }

      final email = session.user.email!;

      // ✅ Prend le paiement le plus récent pour cet email/plan
      // (peu importe activated: true ou false)
      final result = await supabase
          .from('stripe_payments')
          .select()
          .eq('email', email)
          .eq('plan', widget.plan.name)
          .eq('status', 'paid')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null) {
        // ✅ Paiement trouvé → activer le plan
        await CreditService().setPlan(widget.plan);

        // Marque comme activé
        await supabase
            .from('stripe_payments')
            .update({'activated': true})
            .eq('email', email)
            .eq('plan', widget.plan.name);

        if (!mounted) return;
        _showSuccess();
      } else {
        setState(() {
          _error =
          "No payment found for this email.\nMake sure you used the same email as your account.\nIf you just paid, wait a few seconds and try again.";
        });
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C58E).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00C58E), size: 52),
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome to ${widget.plan == UserPlan.pro ? 'Pro' : 'Basic'}! 🎉",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.plan == UserPlan.pro
                    ? "You now have unlimited summaries."
                    : "You now have 50 credits per month.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // ferme dialog
                  // ✅ Retour home propre
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      "Let's go! 🚀",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planColor = widget.plan == UserPlan.pro
        ? const Color(0xFF7B2FF7)
        : const Color(0xFF4A90E2);

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
        title: Text(
          "Confirm Payment",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: planColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.plan == UserPlan.pro
                    ? Icons.auto_awesome
                    : Icons.bolt_rounded,
                color: widget.plan == UserPlan.pro ? Colors.amber : planColor,
                size: 48,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Activate your ${widget.plan == UserPlan.pro ? 'Pro' : 'Basic'} plan",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              "Once your payment is complete on Stripe,\ntap the button below to activate your plan.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            GestureDetector(
              onTap: _isLoading ? null : _confirmPayment,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? null
                      : LinearGradient(
                    colors: widget.plan == UserPlan.pro
                        ? [
                      const Color(0xFF7B2FF7),
                      const Color(0xFF4A90E2)
                    ]
                        : [planColor, planColor.withOpacity(0.8)],
                  ),
                  color: _isLoading
                      ? (isDark ? Colors.white12 : Colors.black12)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                    BoxShadow(
                      color: planColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "I've paid — Activate my plan",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}