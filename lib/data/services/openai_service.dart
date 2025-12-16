import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

/// Service pour interagir avec l'API OpenAI
/// Gère la transcription (Whisper) et l'extraction de données (GPT-4)
class OpenAIService {
  static const String _whisperApiUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _chatApiUrl =
      'https://api.openai.com/v1/chat/completions';

  final String _apiKey = AppConstants.openaiApiKey;

  /// Transcrire un fichier audio en texte avec Whisper
  ///
  /// [audioFilePath] : Chemin local du fichier audio
  /// [language] : Langue de l'audio (par défaut: français)
  ///
  /// Retourne le texte transcrit
  Future<String> transcribeAudio(
    String audioFilePath, {
    String language = 'fr',
  }) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw AppStorageException(
          message: 'Fichier audio introuvable',
          code: 'FILE_NOT_FOUND',
        );
      }

      var request = http.MultipartRequest('POST', Uri.parse(_whisperApiUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = language;
      request.fields['response_format'] = 'json';
      request.fields['temperature'] = '0.2'; // Précision maximale

      request.files.add(
        await http.MultipartFile.fromPath('file', audioFilePath),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        final text = json['text'] as String?;

        if (text == null || text.isEmpty) {
          throw ServerException(
            message: 'Transcription vide',
            code: 'EMPTY_TRANSCRIPTION',
          );
        }

        return text;
      } else {
        final errorJson = jsonDecode(responseData);
        throw NetworkException(
          message: 'Erreur Whisper: ${errorJson['error']?['message'] ?? responseData}',
          code: 'WHISPER_API_ERROR',
        );
      }
    } on SocketException {
      throw NetworkException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erreur transcription: $e',
        code: 'TRANSCRIPTION_ERROR',
      );
    }
  }

  /// Extraire les données structurées depuis une transcription avec GPT-4
  ///
  /// [transcription] : Texte transcrit à analyser
  /// [existingClients] : Liste des clients existants (pour reconnaissance)
  /// [existingProducts] : Liste des produits existants (pour reconnaissance)
  ///
  /// Retourne un Map contenant les données extraites au format:
  /// ```json
  /// {
  ///   "client": "nom du client",
  ///   "client_nouveau": true/false,
  ///   "adresse_intervention": "adresse",
  ///   "produits": [
  ///     {
  ///       "nom": "nom produit",
  ///       "quantite": 10,
  ///       "unite": "m2",
  ///       "prix_unitaire": 50.0
  ///     }
  ///   ],
  ///   "notes": "observations",
  ///   "confiance": 85
  /// }
  /// ```
  Future<Map<String, dynamic>> extractJobData({
    required String transcription,
    required List<String> existingClients,
    required List<String> existingProducts,
  }) async {
    try {
      final prompt = _buildExtractionPrompt(
        transcription,
        existingClients,
        existingProducts,
      );

      final response = await http.post(
        Uri.parse(_chatApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Tu es un assistant expert en extraction de données depuis des rapports vocaux de techniciens BTP. Tu dois extraire les informations de manière structurée et précise.',
            },
            {'role': 'user', 'content': prompt}
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['choices'][0]['message']['content'] as String;
        final extractedData = jsonDecode(content) as Map<String, dynamic>;

        // Validation basique
        _validateExtractedData(extractedData);

        return extractedData;
      } else {
        final errorJson = jsonDecode(response.body);
        throw NetworkException(
          message: 'Erreur GPT-4: ${errorJson['error']?['message'] ?? response.body}',
          code: 'GPT_API_ERROR',
        );
      }
    } on SocketException {
      throw NetworkException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erreur extraction: $e',
        code: 'EXTRACTION_ERROR',
      );
    }
  }

  /// Construire le prompt pour l'extraction de données
  String _buildExtractionPrompt(
    String transcription,
    List<String> existingClients,
    List<String> existingProducts,
  ) {
    return '''
CONTEXTE :
Tu analyses un rapport vocal d'un technicien BTP qui décrit son intervention.

CLIENTS EXISTANTS (utilise ces noms SI le client est reconnu) :
${existingClients.isNotEmpty ? existingClients.join(', ') : 'Aucun client existant'}

PRODUITS/SERVICES EXISTANTS (utilise ces noms SI le produit est reconnu) :
${existingProducts.isNotEmpty ? existingProducts.join(', ') : 'Aucun produit existant'}

TRANSCRIPTION DU RAPPORT VOCAL :
"$transcription"

TÂCHE :
Extrais les informations suivantes au format JSON STRICT :

{
  "client": "nom du client (utilise CLIENTS EXISTANTS si possible, sinon le nom mentionné)",
  "client_nouveau": true ou false (true si le client n'est pas dans CLIENTS EXISTANTS),
  "adresse_intervention": "adresse complète de l'intervention (rue, code postal, ville)",
  "produits": [
    {
      "nom": "nom du produit/service (utilise PRODUITS EXISTANTS si possible)",
      "quantite": nombre (obligatoire),
      "unite": "unité (m2, ml, unité, forfait, heure, etc.)",
      "prix_unitaire": nombre ou null si pas mentionné,
      "produit_nouveau": true ou false (true si pas dans PRODUITS EXISTANTS)
    }
  ],
  "notes": "observations, détails supplémentaires, état des lieux, etc.",
  "confiance": score de 0 à 100 (qualité de l'extraction, précision des informations)
}

RÈGLES IMPORTANTES :
1. Si un client existant est proche du nom mentionné, utilise-le (ex: "Dupont" = "M. Dupont")
2. Si un produit existant correspond, utilise exactement le même nom
3. Toujours inclure la quantité et l'unité pour chaque produit
4. Le score de confiance doit refléter l'ambiguïté et la clarté de la transcription
5. Si l'adresse n'est pas mentionnée, mets une chaîne vide
6. Les notes doivent contenir TOUS les détails non structurés

Réponds UNIQUEMENT avec le JSON, rien d'autre.
''';
  }

  /// Valider les données extraites
  void _validateExtractedData(Map<String, dynamic> data) {
    if (data['client'] == null || (data['client'] as String).isEmpty) {
      throw ValidationException(
        message: 'Client manquant dans les données extraites',
        code: 'MISSING_CLIENT',
      );
    }

    if (data['produits'] == null || (data['produits'] as List).isEmpty) {
      throw ValidationException(
        message: 'Aucun produit extrait',
        code: 'MISSING_PRODUCTS',
      );
    }

    final confiance = data['confiance'] as int?;
    if (confiance == null || confiance < 0 || confiance > 100) {
      throw ValidationException(
        message: 'Score de confiance invalide',
        code: 'INVALID_CONFIDENCE',
      );
    }
  }
}

