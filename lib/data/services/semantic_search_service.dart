import 'package:supabase_flutter/supabase_flutter.dart';
import 'telemetry_service.dart';

/// Service de recherche semantique (pgvector)
class SemanticSearchService {
  final SupabaseClient _supabase;
  final TelemetryService _telemetry;

  SemanticSearchService({
    required SupabaseClient supabase,
    required TelemetryService telemetry,
  })  : _supabase = supabase,
        _telemetry = telemetry;

  // =====================================================
  // GENERATION EMBEDDINGS
  // =====================================================

  /// Genere l'embedding pour un job
  Future<void> generateJobEmbedding(String jobId, {String? customText}) async {
    try {
      await _supabase.functions.invoke(
        'generate-embeddings',
        body: {
          'type': 'job',
          'id': jobId,
          if (customText != null) 'text': customText,
        },
      );

      await _telemetry.logEvent('embedding_generated', {
        'type': 'job',
        'job_id': jobId,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to generate job embedding',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - l'embedding n'est pas critique
    }
  }

  /// Genere l'embedding pour un client
  Future<void> generateClientEmbedding(
    String clientId, {
    String? customText,
  }) async {
    try {
      await _supabase.functions.invoke(
        'generate-embeddings',
        body: {
          'type': 'client',
          'id': clientId,
          if (customText != null) 'text': customText,
        },
      );

      await _telemetry.logEvent('embedding_generated', {
        'type': 'client',
        'client_id': clientId,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to generate client embedding',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow
    }
  }

  // =====================================================
  // RECHERCHE SEMANTIQUE
  // =====================================================

  /// Recherche semantique dans les jobs
  Future<List<SemanticSearchResult>> searchJobs(
    String query, {
    double matchThreshold = 0.7,
    int maxResults = 10,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Generer l'embedding de la query
      final queryEmbedding = await _generateQueryEmbedding(query);

      // Rechercher via la fonction SQL
      final response = await _supabase.rpc('semantic_search_jobs', params: {
        'query_embedding': queryEmbedding,
        'match_threshold': matchThreshold,
        'match_count': maxResults,
        'p_user_id': _supabase.auth.currentUser!.id,
      });

      stopwatch.stop();

      // Logger la recherche
      await _logSearch(
        query: query,
        resultsCount: (response as List).length,
        durationMs: stopwatch.elapsedMilliseconds,
        topResultId: (response.isNotEmpty) ? response[0]['job_id'] : null,
        topSimilarity: (response.isNotEmpty) ? response[0]['similarity'] : null,
      );

      return (response as List)
          .map((json) => SemanticSearchResult.fromJson({
                ...json,
                'result_type': 'job',
              }))
          .toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to search jobs',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Recherche semantique dans les clients
  Future<List<SemanticSearchResult>> searchClients(
    String query, {
    double matchThreshold = 0.7,
    int maxResults = 10,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final queryEmbedding = await _generateQueryEmbedding(query);

      final response = await _supabase.rpc('semantic_search_clients', params: {
        'query_embedding': queryEmbedding,
        'match_threshold': matchThreshold,
        'match_count': maxResults,
        'p_company_id': null, // Will use RLS
      });

      stopwatch.stop();

      await _logSearch(
        query: query,
        resultsCount: (response as List).length,
        durationMs: stopwatch.elapsedMilliseconds,
        topResultId: (response.isNotEmpty) ? response[0]['client_id'] : null,
        topSimilarity: (response.isNotEmpty) ? response[0]['similarity'] : null,
      );

      return (response as List)
          .map((json) => SemanticSearchResult.fromJson({
                ...json,
                'result_type': 'client',
              }))
          .toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to search clients',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Recherche hybride (semantique + keywords)
  /// Combine le meilleur des deux mondes
  Future<List<HybridSearchResult>> hybridSearch(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final queryEmbedding = await _generateQueryEmbedding(query);

      final response = await _supabase.rpc('hybrid_search', params: {
        'p_query': query,
        'p_query_embedding': queryEmbedding,
        'p_user_id': _supabase.auth.currentUser!.id,
        'p_match_count': maxResults,
      });

      stopwatch.stop();

      await _logSearch(
        query: query,
        resultsCount: (response as List).length,
        durationMs: stopwatch.elapsedMilliseconds,
        topResultId:
            (response.isNotEmpty) ? response[0]['result_id'] : null,
        topSimilarity:
            (response.isNotEmpty) ? response[0]['combined_score'] : null,
      );

      return (response as List)
          .map((json) => HybridSearchResult.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to perform hybrid search',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // =====================================================
  // RECHERCHE SIMPLE (Fallback)
  // =====================================================

  /// Recherche simple par mots-cles (fallback si embeddings pas dispo)
  Future<List<Map<String, dynamic>>> simpleSearch(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      // Recherche dans jobs
      final jobs = await _supabase
          .from('jobs')
          .select('*, clients!inner(name)')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .or('description.ilike.%$query%,transcription.ilike.%$query%')
          .limit(maxResults);

      // Recherche dans clients
      final clients = await _supabase
          .from('clients')
          .select('*')
          .or('name.ilike.%$query%,address.ilike.%$query%')
          .limit(maxResults);

      return [
        ...((jobs as List).map((j) => {'type': 'job', ...j})),
        ...((clients as List).map((c) => {'type': 'client', ...c})),
      ];
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to perform simple search',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  Future<List<double>> _generateQueryEmbedding(String query) async {
    // Appeler l'Edge Function pour generer l'embedding
    // Pour optimiser, on pourrait cacher les embeddings des queries frequentes

    final response = await _supabase.functions.invoke(
      'generate-embeddings',
      body: {
        'type': 'query',
        'text': query,
      },
    );

    if (response.status != 200 || response.data == null) {
      throw Exception('Failed to generate query embedding');
    }

    final embedding = response.data['embedding'];
    return List<double>.from(embedding.map((e) => e.toDouble()));
  }

  Future<void> _logSearch({
    required String query,
    required int resultsCount,
    required int durationMs,
    String? topResultId,
    double? topSimilarity,
  }) async {
    try {
      await _supabase.from('search_history').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'query': query,
        'results_count': resultsCount,
        'top_result_id': topResultId,
        'top_result_similarity': topSimilarity,
        'search_duration_ms': durationMs,
      });

      await _telemetry.logEvent('semantic_search_performed', {
        'query_length': query.length,
        'results_count': resultsCount,
        'duration_ms': durationMs,
        'top_similarity': topSimilarity,
      });
    } catch (e) {
      // Silently fail - logging is not critical
    }
  }

  // =====================================================
  // ANALYTICS
  // =====================================================

  /// Recupere l'historique des recherches de l'utilisateur
  Future<List<SearchHistoryEntry>> getSearchHistory({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('search_history')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => SearchHistoryEntry.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get search history',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Recupere les recherches populaires
  Future<List<String>> getPopularSearches({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('search_history')
          .select('query')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .limit(100); // Take last 100 searches

      final searches = (response as List).map((s) => s['query'] as String).toList();

      // Count occurrences
      final counts = <String, int>{};
      for (final search in searches) {
        counts[search] = (counts[search] ?? 0) + 1;
      }

      // Sort by count and return top N
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get popular searches',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}

// =====================================================
// DATA CLASSES
// =====================================================

class SemanticSearchResult {
  final String resultType; // 'job' or 'client'
  final String resultId;
  final double similarity;
  final String? clientName;
  final String? description;
  final String? status;
  final DateTime? createdAt;

  SemanticSearchResult({
    required this.resultType,
    required this.resultId,
    required this.similarity,
    this.clientName,
    this.description,
    this.status,
    this.createdAt,
  });

  factory SemanticSearchResult.fromJson(Map<String, dynamic> json) {
    return SemanticSearchResult(
      resultType: json['result_type'] ?? 'job',
      resultId: json['job_id'] ?? json['client_id'] ?? '',
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      clientName: json['client_name'] ?? json['name'],
      description: json['description'] ?? json['address'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  /// Retourne le score en pourcentage
  String get similarityPercentage => '${(similarity * 100).toStringAsFixed(0)}%';

  /// Est-ce un match excellent ? (> 90%)
  bool get isExcellentMatch => similarity >= 0.9;

  /// Est-ce un bon match ? (> 80%)
  bool get isGoodMatch => similarity >= 0.8;
}

class HybridSearchResult {
  final String resultType;
  final String resultId;
  final String resultTitle;
  final String resultDescription;
  final double similarityScore;
  final double keywordScore;
  final double combinedScore;

  HybridSearchResult({
    required this.resultType,
    required this.resultId,
    required this.resultTitle,
    required this.resultDescription,
    required this.similarityScore,
    required this.keywordScore,
    required this.combinedScore,
  });

  factory HybridSearchResult.fromJson(Map<String, dynamic> json) {
    return HybridSearchResult(
      resultType: json['result_type'] ?? '',
      resultId: json['result_id'] ?? '',
      resultTitle: json['result_title'] ?? '',
      resultDescription: json['result_description'] ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      keywordScore: (json['keyword_score'] as num?)?.toDouble() ?? 0.0,
      combinedScore: (json['combined_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get scorePercentage => '${(combinedScore * 100).toStringAsFixed(0)}%';
}

class SearchHistoryEntry {
  final String id;
  final String query;
  final int resultsCount;
  final String? topResultId;
  final double? topResultSimilarity;
  final int? searchDurationMs;
  final DateTime createdAt;

  SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.resultsCount,
    this.topResultId,
    this.topResultSimilarity,
    this.searchDurationMs,
    required this.createdAt,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id'] ?? '',
      query: json['query'] ?? '',
      resultsCount: json['results_count'] ?? 0,
      topResultId: json['top_result_id'],
      topResultSimilarity:
          (json['top_result_similarity'] as num?)?.toDouble(),
      searchDurationMs: json['search_duration_ms'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}




