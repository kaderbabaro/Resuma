import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
as supabase;

import '../database/app_database.dart';

class AuthService {
  final AppDatabase db;

  AuthService(this.db);

  // ======================
  // HASH PASSWORD (PRIVATE)
  // ======================
  String _hash(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }
  // ======================
  // PUBLIC HASH (for update)
  // ======================
  String hashPassword(String password) {
    return _hash(password);
  }

  // ======================
  // VERIFY PASSWORD
  // ======================
  bool verifyPassword(String password, String hashed) {
    return BCrypt.checkpw(password, hashed);
  }

  // ======================
  // REGISTER
  // ======================
  Future<bool> register(
      String name,
      String email,
      String phone,
      String password,
      ) async {
    final client = supabase.Supabase.instance.client;

    try {
      // =====================================================
      // 1️⃣ Vérifier si utilisateur existe en ligne
      // =====================================================
      final remoteExisting = await client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      // =====================================================
      // 2️⃣ Si existe en ligne → on sync local et on STOP
      // =====================================================
      if (remoteExisting != null) {
        await _syncLocalFromRemote(remoteExisting);
        throw Exception("Utilisateur déjà enregistré en ligne");
      }

      // =====================================================
      // 3️⃣ Créer compte Auth
      // =====================================================
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
      );

      final authUser = authResponse.user;

      if (authUser == null) {
        throw Exception("Erreur création utilisateur");
      }

      // =====================================================
      // 4️⃣ Créer profil users table
      // =====================================================
      await client.from('users').insert({
        'id': authUser.id,
        'email': email,
        'name': name,
        'phone_number': phone,
        'created_at': DateTime.now().toIso8601String(),
      });

      // =====================================================
      // 5️⃣ Sync local (overwrite local)
      // =====================================================
      await _overwriteLocalUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      return true;
    }

    // ================= ERROR HANDLING =================

    on supabase.AuthException catch (e) {
      if (e.message.contains("already")) {
        throw Exception("Utilisateur déjà existant");
      }
      if (e.message.contains("rate")) {
        throw Exception("Rate limit — réessayez plus tard");
      }
      throw Exception("Erreur auth");
    }

    on supabase.PostgrestException catch (e) {
      throw Exception("Erreur base distante : ${e.message}");
    }

    catch (e) {
      throw Exception("Erreur inconnue : $e");
    }
  }

// fonction secondaire
  Future<void> _syncLocalFromRemote(Map<String, dynamic> remote) async {
    await db.delete(db.users).go();

    await db.into(db.users).insert(
      UsersCompanion.insert(
        name: remote['name'] ?? '',
        email: remote['email'],
        phoneNumber: remote['phone_number'] ?? '',
        passwordHash: '', // on ne stocke pas hash remote
      ),
    );
  }

  Future<void> _overwriteLocalUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await db.delete(db.users).go();

    await db.into(db.users).insert(
      UsersCompanion.insert(
        name: name,
        email: email,
        phoneNumber: phone,
        passwordHash: _hash(password),
      ),
    );
  }
// Update Local Password
  Future<bool> updateLocalPassword(int userId, String newHash) async {
    try {
      final result = await (db.update(db.users)
        ..where((u) => u.id.equals(userId)))
          .write(
        UsersCompanion(
          passwordHash: Value(newHash),
        ),
      );

      return result > 0;
    } catch (_) {
      return false;
    }
  }

  //reset password

  Future<void> sendResetEmail(String email) async {
    await supabase.Supabase.instance.client.auth
        .resetPasswordForEmail(email);
  }

  Future<void> syncNewPassword(
      String email,
      String newPassword,
      ) async {
    final user = await db.getUserByEmail(email);

    if (user != null) {
      await (db.update(db.users)
        ..where((u) => u.id.equals(user.id)))
          .write(
        UsersCompanion(
          passwordHash: Value(hashPassword(newPassword)),
        ),
      );
    }
  }

  // ======================
  // LOGIN
  // ======================
  Future<User?> login(String identifier, String password) async {
    final client = supabase.Supabase.instance.client;

    try {
      // =============================
      // 1️⃣ LOGIN AUTH SUPABASE
      // =============================
      final authResponse = await client.auth.signInWithPassword(
        email: identifier.contains("@") ? identifier : null,
        password: password,
      );

      final authUser = authResponse.user;

      if (authUser == null) {
        return null;
      }

      // =============================
      // 2️⃣ RECUP PROFIL ONLINE
      // =============================
      final onlineProfile = await client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (onlineProfile == null) {
        return null;
      }

      // =============================
      // 3️⃣ SYNC LOCAL
      // =============================
      final localUser = await db.getUserByEmail(authUser.email!);

      if (localUser == null) {
        await db.into(db.users).insert(
          UsersCompanion.insert(
            name: onlineProfile['name'],
            email: onlineProfile['email'],
            phoneNumber: onlineProfile['phone_number'] ?? '',
            passwordHash: '', // On ne stocke PAS le hash remote
          ),
        );
      }

      await _saveSessionByEmail(authUser.email!);

      return await db.getUserByEmail(authUser.email!);
    }

    // =============================
    // 🔥 GESTION ERREURS PRO
    // =============================
    on supabase.AuthException catch (e) {
      if (e.message.contains("Invalid login credentials")) {
        throw Exception("Email ou mot de passe incorrect");
      }

      if (e.message.contains("Email not confirmed")) {
        throw Exception("Email non confirmé");
      }

      if (e.message.contains("rate limit")) {
        throw Exception("Trop de tentatives. Réessayez plus tard.");
      }

      throw Exception("Erreur d'authentification");
    }

    catch (e) {
      throw Exception("Problème connexion serveur");
    }
  }

  Future<void> _saveSessionByEmail(String email) async {
    final user = await db.getUserByEmail(email);

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('local_user_id', user.id);
    }
  }

  // ======================
  // SESSION
  // ======================
  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  Future<String?> getSession() async {
    final client = supabase.Supabase.instance.client;

    // =====================================================
    // 1️⃣ Vérifier session Supabase (ONLINE PRIORITY)
    // =====================================================
    final session = client.auth.currentSession;

    if (session != null) {
      final userId = session.user.id;

      //sync local si pas encore stocké
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_uid', userId);

      return userId;
    }

    // =====================================================
    // 2️⃣ Fallback session locale (OFFLINE)
    // =====================================================
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> logout() async {
    final client = supabase.Supabase.instance.client;

    try {
      // =====================================================
      // 1️⃣ Déconnecter Supabase
      // =====================================================
      await client.auth.signOut();

      // =====================================================
      // 2️⃣ Supprimer session locale
      // =====================================================
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');

      // =====================================================
      // 3️⃣ OPTIONNEL — Nettoyer local DB
      // =====================================================
      // 🔥 Si tu veux sécurité maximale :
      // await db.delete(db.users).go();

    } catch (e) {
      print("Logout error: $e");
    }
  }

  // ======================
  // CURRENT USER
  // ======================
  Future<User?> getCurrentUser() async {
    // 🔹 1️⃣ Lire utilisateur local immédiatement
    final localUser = await db.select(db.users).getSingleOrNull();

    // 🔹 2️⃣ Synchronisation en arrière-plan (sans bloquer l’UI)
    _syncWithRemote();

    // 🔹 3️⃣ Retourner local (même sans internet)
    return localUser;
  }
  Future<void> _syncWithRemote() async {
    try {
      final client = supabase.Supabase.instance.client;

      final session = client.auth.currentSession;
      if (session == null) return;

      final userId = session.user.id;

      final remote = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (remote == null) return;

      // 🔥 Insert ou Update propre (pas de delete total)
      await db.into(db.users).insertOnConflictUpdate(
        UsersCompanion(
          name: Value(remote['name'] ?? ''),
          email: Value(remote['email'] ?? ''),
          phoneNumber: Value(remote['phone_number'] ?? ''),
          passwordHash: const Value(''),
        ),
      );
    } catch (e) {
      // ⚠️ On ignore les erreurs réseau pour rester offline-first
      debugPrint('Sync error: $e');
    }
  }
}