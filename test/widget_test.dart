import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resuma/main.dart';
import 'package:resuma/service/auth_service.dart';
import 'package:resuma/database/app_database.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Créer la DB et AuthService factices
    final database = AppDatabase();
    final authService = AuthService(database);

    // Construire l'app
    await tester.pumpWidget(MyApp(authService: authService, isDarkMode: false));

    // Ici tu peux tester des widgets de Home, SplashScreen, etc.
    // Exemple simple pour vérifier qu'un texte existe
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
