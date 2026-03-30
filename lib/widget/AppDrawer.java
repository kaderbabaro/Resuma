import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Pages/premium.dart';
import '../database/app_database.dart';
import '../main.dart';
import '../service/auth_service.dart';
import '../service/credit_service.dart';
import '../Pages/Account/compte.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
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
    final user = await auth.getCurrentUser();
    await CreditService().loadFromSupabase();
    if (!mounted) return;
    setState(() {
      currentUser = user;
      _plan = CreditService().currentPlan;
      loading = false;
    });
  }

  String _getInitials() {
    final name = currentUser?.name ?? "";
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return name[0].toUpperCase();
  }

  // ✅ Badge plan dynamique
  Widget _planBadge() {
    switch (_plan) {
      case UserPlan.pro:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 11),
              SizedBox(width: 4),
              Text("Plan Pro", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case UserPlan.basic:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: Color(0xFF4A90E2), size: 11),
              SizedBox(width: 4),
              Text("Plan Basic", style: TextStyle(color: Color(0xFF4A90E2), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white38),
          ),
          child: const Text("✦ Plan Gratuit",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6FB),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── Header ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 24,
                    left: 20,
                    right: 20,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF4A90E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()));
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: Center(
                            child: Text(_getInitials(),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentUser?.name ?? "Utilisateur",
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(currentUser?.email ?? "",
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              _planBadge(), // ✅ plan réel
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Navigation ────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _drawerItem(icon: Icons.home_rounded, label: "Accueil", color: const Color(0xFF7B2FF7), isDark: isDark,
                            onTap: () { Navigator.pop(context); Navigator.pushReplacementNamed(context, '/home'); }),
                        _drawerItem(icon: Icons.camera_alt_rounded, label: "Scanner", color: const Color(0xFF4A90E2), isDark: isDark,
                            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/Scan'); }),
                        _drawerItem(icon: Icons.upload_file_rounded, label: "Mes documents", color: const Color(0xFF00C58E), isDark: isDark,
                            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/documents'); }),
                        _drawerItem(icon: Icons.history_rounded, label: "Historique", color: const Color(0xFFFF6B35), isDark: isDark,
                            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/history'); }),

                        const SizedBox(height: 8),
                        Divider(color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 8),

                        // ✅ Card Premium / Mon abonnement
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()))
                                .then((_) => _loadUser()); // refresh au retour
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                const Color(0xFF7B2FF7).withOpacity(0.15),
                                const Color(0xFF4A90E2).withOpacity(0.1),
                              ]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF7B2FF7).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B2FF7).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _plan == UserPlan.free ? "Passer Premium" : "Mon abonnement",
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                                      ),
                                      Text(
                                        _plan == UserPlan.free
                                            ? "Résumés illimités dès 2.99€/mois"
                                            : _plan == UserPlan.pro ? "Plan Pro actif ✓" : "Plan Basic actif ✓",
                                        style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF7B2FF7)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Logout ────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                      left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 16),
                  child: GestureDetector(
                    onTap: () async {
                      await auth.logout();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text("Déconnexion",
                              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          ],
        ),
      ),
    );
  }
}