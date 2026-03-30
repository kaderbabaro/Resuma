import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../database/app_database.dart';

class HistoryService {
  static final ValueNotifier<int> summariesNotifier = ValueNotifier(0);
  final AppDatabase db;
  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;

  HistoryService(this.db);

  // ─── Get local user id ────────────────────────────────────────────────────
  Future<int?> _getLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('local_user_id');
  }

  // ─── Save summary ─────────────────────────────────────────────────────────
  Future<void> saveSummary({
    required String title,
    required String content,
    required String type, // 'photo' | 'document' | 'batch'
  }) async {
    final userId = await _getLocalUserId();
    if (userId == null) return;

    try {
      // 1️⃣ Crée un document source
      final docId = await db.createDocument(
        DocumentsCompanion.insert(
          userId: userId,
          title: title,
          originalText: content,
          filePath: Value(type), // réutilise filePath pour stocker le type
        ),
      );

      // 2️⃣ Crée le résumé lié
      await db.createSummary(
        SummariesCompanion.insert(
          documentId: docId,
          userId: userId,
          summaryText: content,
          summaryLevel: 1,
          aiModel: 'gemini-2.0-flash',
        ),
      );

      // 3️⃣ Sync Supabase en arrière-plan
      _syncToSupabase(title: title, content: content, type: type);

      HistoryService.summariesNotifier.value++;
    } catch (e) {
      debugPrint("SaveSummary error: $e");
    }
  }

  // ─── Sync local → Supabase ────────────────────────────────────────────────
  Future<void> _syncToSupabase({
    required String title,
    required String content,
    required String type,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      await _supabase.from('summaries_history').insert({
        'user_id': session.user.id,
        'title': title,
        'content': content,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Sync to Supabase failed: $e");
    }
  }

  // ─── Get all summaries ────────────────────────────────────────────────────
  Future<List<HistorySummary>> getAllSummaries() async {
    final userId = await _getLocalUserId();
    if (userId == null) return [];

    try {
      final docs = await (db.select(db.documents)
            ..where((d) => d.userId.equals(userId))
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .get();

      final List<HistorySummary> result = [];

      for (final doc in docs) {
        final summary = await (db.select(db.summaries)
              ..where((s) => s.documentId.equals(doc.id)))
            .getSingleOrNull();

        if (summary != null) {
          result.add(HistorySummary(
            id: summary.id,
            documentId: doc.id,
            title: doc.title,
            content: summary.summaryText,
            type: doc.filePath ?? 'document',
            createdAt: doc.createdAt,
          ));
        }
      }

      return result;
    } catch (e) {
      debugPrint("GetAllSummaries error: $e");
      return [];
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  Future<List<HistorySummary>> searchSummaries(String query) async {
    final all = await getAllSummaries();
    final q = query.toLowerCase();
    return all
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.content.toLowerCase().contains(q))
        .toList();
  }

  // ─── Delete one ───────────────────────────────────────────────────────────
  Future<void> deleteSummary(HistorySummary summary) async {
    try {
      await (db.delete(db.summaries)
            ..where((s) => s.id.equals(summary.id)))
          .go();
      await (db.delete(db.documents)
            ..where((d) => d.id.equals(summary.documentId)))
          .go();

      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase
            .from('summaries_history')
            .delete()
            .eq('user_id', session.user.id)
            .eq('title', summary.title);
      }
    } catch (e) {
      debugPrint("DeleteSummary error: $e");
    }
  }

  // ─── Delete all ───────────────────────────────────────────────────────────
  Future<void> deleteAll() async {
    final userId = await _getLocalUserId();
    if (userId == null) return;

    try {
      await (db.delete(db.summaries)
            ..where((s) => s.userId.equals(userId)))
          .go();
      await (db.delete(db.documents)
            ..where((d) => d.userId.equals(userId)))
          .go();

      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase
            .from('summaries_history')
            .delete()
            .eq('user_id', session.user.id);
      }
    } catch (e) {
      debugPrint("DeleteAll error: $e");
    }
  }
}

// ─── Modèle léger pour l'UI ───────────────────────────────────────────────────
class HistorySummary {
  final int id;
  final int documentId;
  final String title;
  final String content;
  final String type;
  final DateTime createdAt;

  const HistorySummary({
    required this.id,
    required this.documentId,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
  });
}
