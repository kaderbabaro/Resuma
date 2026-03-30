import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  // ✅ Groq API — compatible format OpenAI
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  // ✅ llama-3.2-90b-vision — pour les images (scan de cours)
  static const String _visionModel = "meta-llama/llama-4-scout-17b-16e-instruct";

  // ✅ llama-3.3-70b-versatile — pour les documents texte
  static const String _textModel = "llama-3.3-70b-versatile";

  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  String get _apiKey => dotenv.env['GROQ_API_KEY']!;

  // ─── Résumer une photo de cours (1 page) ─────────────────────────────────
  Future<String> summarizeImagePage(File image) async {
    final base64Image = await _convertToBase64(image);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        "model": _visionModel,
        "max_tokens": 1500,
        "messages": [
          {"role": "system", "content": _systemPrompt},
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                "Voici une photo d'une page de cours. "
                    "Lis attentivement tout le texte visible sur cette image, "
                    "puis fais-en un résumé clair, structuré et précis.",
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image",
                },
              },
            ],
          }
        ],
      }),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception("Délai dépassé. Vérifie ta connexion."),
    );

    return _handleResponse(response);
  }

  // ─── Résumer plusieurs photos de cours (batch) ───────────────────────────
  Future<String> summarizeBatchPages(List<File> images) async {
    final List<Map<String, dynamic>> contentParts = [
      {
        "type": "text",
        "text":
        "Voici ${images.length} photo(s) de pages d'un cours. "
            "Lis tout le texte visible sur chaque page dans l'ordre, "
            "puis génère un résumé complet, structuré et précis du cours entier. "
            "Regroupe les idées par thème si possible.",
      },
    ];

    for (final image in images) {
      final base64Image = await _convertToBase64(image);
      contentParts.add({
        "type": "image_url",
        "image_url": {
          "url": "data:image/jpeg;base64,$base64Image",
        },
      });
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        "model": _visionModel,
        "max_tokens": 4000,
        "messages": [
          {"role": "system", "content": _systemPrompt},
          {"role": "user", "content": contentParts},
        ],
      }),
    ).timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw Exception("Délai dépassé. Vérifie ta connexion."),
    );

    return _handleResponse(response);
  }

  // ─── Résumer un document texte (PDF/DOCX/TXT) ────────────────────────────
  Future<String> summarizeDocumentText(String extractedText, String fileName) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        "model": _textModel, // ✅ texte pur — modèle plus rapide
        "max_tokens": 4000,
        "messages": [
          {"role": "system", "content": _systemPrompt},
          {
            "role": "user",
            "content":
            "Voici le contenu complet du document \"$fileName\".\n\n"
                "$extractedText\n\n"
                "Fais-en un résumé clair, structuré et précis. "
                "Regroupe les idées par thème et mets en avant les points clés.",
          },
        ],
      }),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception("Délai dépassé. Vérifie ta connexion."),
    );

    return _handleResponse(response);
  }

  // ─── Résumer un mix image(s) + texte ─────────────────────────────────────
  Future<String> summarizeMixed({
    required List<File> images,
    required String documentText,
    required String fileName,
  }) async {
    final List<Map<String, dynamic>> contentParts = [
      {
        "type": "text",
        "text":
        "J'ai un cours composé de :\n"
            "- ${images.length} photo(s) de pages manuscrites ou imprimées\n"
            "- Un document texte : \"$fileName\"\n\n"
            "Contenu du document :\n$documentText\n\n"
            "Analyse le tout et génère un résumé complet, structuré et précis "
            "du cours entier en combinant toutes les informations.",
      },
    ];

    for (final image in images) {
      final base64Image = await _convertToBase64(image);
      contentParts.add({
        "type": "image_url",
        "image_url": {
          "url": "data:image/jpeg;base64,$base64Image",
        },
      });
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        "model": _visionModel,
        "max_tokens": 4000,
        "messages": [
          {"role": "system", "content": _systemPrompt},
          {"role": "user", "content": contentParts},
        ],
      }),
    ).timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw Exception("Délai dépassé. Vérifie ta connexion."),
    );

    return _handleResponse(response);
  }

  // ─── Prompt système ───────────────────────────────────────────────────────
  static const String _systemPrompt =
      "Tu es un assistant spécialisé dans le résumé de cours scolaires et universitaires. "
      "Ton rôle est de lire attentivement le contenu fourni (texte ou image) "
      "et de produire un résumé structuré, clair et précis. "
      "Utilise des titres, sous-titres et points clés pour organiser le résumé. "
      "Garde le vocabulaire technique du cours. "
      "Ne saute aucune notion importante.";

  // ─── Headers ──────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $_apiKey",
  };

  // ─── Base64 ───────────────────────────────────────────────────────────────
  Future<String> _convertToBase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  // ─── Handle response ──────────────────────────────────────────────────────
  String _handleResponse(http.Response response) {
    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final choices = data['choices'];
      if (choices == null || choices.isEmpty) {
        throw Exception("Réponse vide de l'API.");
      }

      final message = choices[0]['message'];
      if (message == null) throw Exception("Message introuvable.");

      final content = message['content'];
      if (content == null) throw Exception("Contenu introuvable.");

      return content as String;
    } else if (response.statusCode == 401) {
      throw Exception("Clé API invalide ou expirée.");
    } else if (response.statusCode == 429) {
      throw Exception("Limite de requêtes atteinte. Réessaie dans quelques secondes.");
    } else {
      final error = jsonDecode(response.body);
      final message = error['error']?['message'] ?? response.body;
      throw Exception("Erreur API ${response.statusCode}: $message");
    }
  }
}