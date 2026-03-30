import 'dart:async';

import 'package:flutter/material.dart';
import 'package:resuma/Pages/documents.dart';
import 'package:resuma/login/reset_passeword.dart';
import 'package:resuma/service/ad_service.dart';
import 'package:resuma/service/credit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resuma/Home.dart';
import 'package:resuma/Pages/Account/aide.dart';
import 'package:resuma/Pages/Account/langues.dart';
import 'package:resuma/Pages/Account/theme.dart';
import 'package:resuma/Pages/Scan.dart';
import 'package:resuma/Pages/Account/compte.dart';
import 'package:resuma/Pages/premium.dart';
import 'package:resuma/login/connexion.dart';
import 'package:resuma/login/Register.dart';
import 'package:resuma/service/auth_service.dart';
import 'package:resuma/database/app_database.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'Pages/history_page.dart';
import 'Pages/payment_confirm_page.dart';

late AppDatabase database;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://numerodeprojet.supabase.co',
    anonKey: 'votre anon key',
  );

  database = AppDatabase();
  final authService = AuthService(database);
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;

  await dotenv.load(fileName: ".env");
  await CreditService().loadFromSupabase();
  await CreditService().checkMonthlyReset();
  await CreditService().checkPlanExpiry();

  await AdService.initialize();
  AdService().loadInterstitial();
  AdService().loadRewarded();

  runApp(MyApp(
    authService: authService,
    isDarkMode: isDark,
  ));
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  final bool isDarkMode;

  const MyApp({
    super.key,
    required this.authService,
    required this.isDarkMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  StreamSubscription<AuthState>? _authSubscription;
  Locale _locale = const Locale('fr');

  @override
  void initState() {
    super.initState();

    _themeMode =
    widget.isDarkMode ? ThemeMode.dark : ThemeMode.light;

    _loadSavedLanguage();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
              (data) {
            final event = data.event;

            print("Auth event: $event");

            if (event == AuthChangeEvent.passwordRecovery) {
              Navigator.pushNamed(context, '/new-password');
            }
          },
        );
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language') ?? 'fr';

    setState(() {
      _locale = Locale(langCode);
    });
  }

  void _updateLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);

    setState(() {
      _locale = Locale(langCode);
    });
  }


  void _updateTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);

    setState(() {
      _themeMode =
      isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,

      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      debugShowCheckedModeBanner: false,
      title: 'Resuma',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),

      darkTheme: ThemeData.dark(),

      themeMode: _themeMode,

      home: SplashScreen(
        authService: widget.authService,
      ),

      routes: {
        '/home': (context) => const HomePage1(),
        '/login': (context) =>
            LoginPage(authService: widget.authService),
        '/register': (context) => RegisterPage(),
        "/Scan": (context) => ScanPageWidget(),
        "/premium": (context) => PremiumPage(),
        "/documents": (context) => UniversalFilePickerPage(),
        "/Account": (context) => AccountPage(),
        "/langue": (context) =>
            LanguagesPage(onLanguageChanged: _updateLanguage),
        "/theme": (context) =>
            ThemePage(onThemeChanged: _updateTheme),
        "/aide": (context) => HelpPage(),
        "/resetpass": (context) =>
            NewPasswordPage(authService: widget.authService),
        '/history': (context) => const HistoryPage(),
        '/payment-confirm': (context) {
          final args = ModalRoute
              .of(context)!
              .settings
              .arguments as UserPlan;
          return PaymentConfirmPage(plan: args);
        },
      });
  }
}


/// ================= SplashScreen =================
class SplashScreen extends StatefulWidget {
  final AuthService authService;

  const SplashScreen({required this.authService, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    final currentUser = await widget.authService.getCurrentUser();

    if (currentUser != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo centré
            Image.asset(
              'assets/Logos/img.png',
              height: 150,
            ),
            const SizedBox(height: 24),
            // Circular loading
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
