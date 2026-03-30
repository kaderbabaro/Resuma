import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resuma/Pages/Account/changermotdepasse.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../../database/app_database.dart';
import '../../service/auth_service.dart';
import '../../service/credit_service.dart';
import '../../main.dart';
import '../premium.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late AuthService auth;
  User? currentUser;
  bool loading = true;
  UserPlan _plan = UserPlan.free;

  @override
  void initState() {
    super.initState();
    auth = AuthService(database);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final supabase = supabase_flutter.Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        setState(() { currentUser = null; loading = false; });
        return;
      }

      final response = await supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (response == null) {
        setState(() { currentUser = null; loading = false; });
        return;
      }

      await database.delete(database.users).go();
      await database.into(database.users).insert(
        UsersCompanion.insert(
          name: response['name'],
          email: response['email'],
          phoneNumber: response['phone_number'],
          passwordHash: '',
        ),
      );

      // ✅ Charge le plan réel depuis Supabase
      await CreditService().loadFromSupabase();

      setState(() {
        currentUser = User(
          id: session.user.id.hashCode,
          name: response['name'],
          email: response['email'],
          phoneNumber: response['phone_number'],
          passwordHash: '',
          createdAt: DateTime.now(),
        );
        _plan = CreditService().currentPlan;
        loading = false;
      });
    } catch (e) {
      debugPrint("Load user error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  String _getInitials() {
    final name = currentUser?.name ?? "";
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return name[0].toUpperCase();
  }

  // ✅ Badge dynamique selon plan réel
  Widget _planBadge() {
    switch (_plan) {
      case UserPlan.pro:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 13),
              SizedBox(width: 5),
              Text("Pro Plan",
                  style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case UserPlan.basic:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: Color(0xFF4A90E2), size: 13),
              SizedBox(width: 5),
              Text("Basic Plan",
                  style: TextStyle(color: Color(0xFF4A90E2), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
          ),
          child: const Text("✦ Free Plan",
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("My Account",
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : currentUser == null
          ? _notLogged(isDark)
          : _profile(isDark),
    );
  }

  Widget _notLogged(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined,
              size: 64, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text("No user logged in",
              style: GoogleFonts.inter(
                  fontSize: 18, color: isDark ? Colors.white54 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _profile(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ─── Hero header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  ),
                  child: Center(
                    child: Text(_getInitials(),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(currentUser!.name,
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(currentUser!.email,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                _planBadge(), // ✅ plan réel
              ],
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Settings",
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),

                _settingsCard(isDark, [
                  _settingItem(
                    icon: Icons.lock_outline_rounded,
                    label: "Change Password",
                    color: const Color(0xFF7B2FF7),
                    isDark: isDark,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ChangePasswordPage(database: database))),
                  ),
                  _divider(isDark),
                  _settingItem(
                    icon: Icons.dark_mode_outlined,
                    label: "Dark Mode",
                    color: const Color(0xFF4A90E2),
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, '/theme'),
                  ),
                  _divider(isDark),
                  _settingItem(
                    icon: Icons.help_outline_rounded,
                    label: "Help & Support",
                    color: const Color(0xFF00C58E),
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, '/aide'),
                  ),
                ]),

                const SizedBox(height: 20),

                Text("Account",
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),

                // ✅ Section premium dynamique
                _settingsCard(isDark, [
                  _plan == UserPlan.free
                      ? _settingItem(
                    icon: Icons.workspace_premium_outlined,
                    label: "Upgrade to Premium",
                    color: Colors.amber,
                    isDark: isDark,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PremiumPage()))
                        .then((_) => _loadUser()),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("From 2.99€",
                          style: TextStyle(
                              color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  )
                      : _settingItem(
                    icon: Icons.auto_awesome,
                    label: _plan == UserPlan.pro ? "Pro Plan — Active" : "Basic Plan — Active",
                    color: _plan == UserPlan.pro ? Colors.amber : const Color(0xFF4A90E2),
                    isDark: isDark,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PremiumPage()))
                        .then((_) => _loadUser()),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C58E).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("Active ✓",
                          style: TextStyle(
                              color: Color(0xFF00C58E),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Text("Sign Out",
                            style: GoogleFonts.inter(
                                color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 54,
      color: isDark ? Colors.white30 : Colors.black.withOpacity(0.06),
    );
  }
}