import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/telemetry_service.dart';

/// Repository générique pour la pagination par curseur (V2.2)
/// 
/// Règles :
/// - Utilise la pagination par curseur (plus efficace que offset)
/// - Lazy loading : Charge seulement ce qui est nécessaire
/// - Compatible avec toutes les tables Supabase
/// - Gère les erreurs gracieusement
/// 
/// Exemple d'utilisation :
/// ```dart
/// final jobsRepo = PaginatedRepository<Job>(
///   tableName: 'jobs',
///   fromJson: (json) => Job.fromJson(json),
///   orderColumn: 'created_at',
/// );
/// 
/// final page1 = await jobsRepo.fetchPage();
/// final page2 = await jobsRepo.fetchNextPage();
/// ```
class PaginatedRepository<T> {
  final _supabase = Supabase.instance.client;
  
  final String tableName;
  final T Function(Map<String, dynamic>) fromJson;
  final String orderColumn;
  final bool ascending;
  final int pageSize;
  
  // État de la pagination
  dynamic _lastCursor;
  bool _hasMore = true;
  
  PaginatedRepository({
    required this.tableName,
    required this.fromJson,
    this.orderColumn = 'created_at',
    this.ascending = false,
    this.pageSize = 20,
  });
  
  /// Récupère la première page
  Future<PagedResult<T>> fetchFirstPage({
    Map<String, dynamic>? filters,
  }) async {
    _lastCursor = null;
    _hasMore = true;
    
    return fetchNextPage(filters: filters);
  }
  
  /// Récupère la page suivante
  Future<PagedResult<T>> fetchNextPage({
    Map<String, dynamic>? filters,
  }) async {
    if (!_hasMore) {
      return PagedResult<T>(
        items: [],
        hasMore: false,
        cursor: _lastCursor,
      );
    }
    
    try {
      TelemetryService.logInfo(
        'Fetching page from $tableName (cursor: $_lastCursor, pageSize: $pageSize)',
      );
      
      // Construire la requête
      var query = _supabase
          .from(tableName)
          .select()
          .order(orderColumn, ascending: ascending)
          .limit(pageSize + 1); // +1 pour savoir s'il y a une page suivante
      
      // Appliquer les filtres
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      // Appliquer le curseur (pagination)
      if (_lastCursor != null) {
        if (ascending) {
          query = query.gt(orderColumn, _lastCursor);
        } else {
          query = query.lt(orderColumn, _lastCursor);
        }
      }
      
      // Exécuter la requête
      final response = await query;
      
      final List<dynamic> data = response as List;
      
      // Déterminer s'il y a plus de résultats
      final hasNextPage = data.length > pageSize;
      
      // Retirer l'élément supplémentaire
      final items = hasNextPage ? data.sublist(0, pageSize) : data;
      
      // Mettre à jour le curseur
      if (items.isNotEmpty) {
        _lastCursor = items.last[orderColumn];
      }
      
      _hasMore = hasNextPage;
      
      // Convertir en objets typés
      final typedItems = items.map((json) => fromJson(json)).toList();
      
      TelemetryService.logInfo(
        'Page fetched: ${typedItems.length} items, hasMore: $hasNextPage',
      );
      
      return PagedResult<T>(
        items: typedItems,
        hasMore: hasNextPage,
        cursor: _lastCursor,
      );
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Error fetching page from $tableName',
        error: e,
        stackTrace: stackTrace,
      );
      
      rethrow;
    }
  }
  
  /// Réinitialise la pagination
  void reset() {
    _lastCursor = null;
    _hasMore = true;
  }
  
  /// Indique s'il y a potentiellement plus de pages
  bool get hasMore => _hasMore;
  
  /// Récupère le curseur actuel
  dynamic get currentCursor => _lastCursor;
}

/// Résultat d'une page
class PagedResult<T> {
  final List<T> items;
  final bool hasMore;
  final dynamic cursor;
  
  const PagedResult({
    required this.items,
    required this.hasMore,
    this.cursor,
  });
  
  /// Nombre d'éléments dans cette page
  int get length => items.length;
  
  /// La page est-elle vide ?
  bool get isEmpty => items.isEmpty;
  
  /// La page contient-elle des éléments ?
  bool get isNotEmpty => items.isNotEmpty;
}

/// Extension pour faciliter l'utilisation avec Flutter
extension PagedResultExtension<T> on PagedResult<T> {
  /// Combine cette page avec une autre
  PagedResult<T> combine(PagedResult<T> other) {
    return PagedResult<T>(
      items: [...items, ...other.items],
      hasMore: other.hasMore,
      cursor: other.cursor,
    );
  }
}

/// Exemple d'utilisation dans un ViewModel :
/// 
/// ```dart
/// class JobsViewModel extends ChangeNotifier {
///   final _repository = PaginatedRepository<Job>(
///     tableName: 'jobs',
///     fromJson: (json) => Job.fromJson(json),
///     orderColumn: 'created_at',
///   );
///   
///   List<Job> _jobs = [];
///   bool _isLoading = false;
///   bool _hasMore = true;
///   
///   List<Job> get jobs => _jobs;
///   bool get isLoading => _isLoading;
///   bool get hasMore => _hasMore;
///   
///   Future<void> loadFirstPage() async {
///     _isLoading = true;
///     notifyListeners();
///     
///     try {
///       final result = await _repository.fetchFirstPage();
///       _jobs = result.items;
///       _hasMore = result.hasMore;
///     } catch (e) {
///       // Handle error
///     } finally {
///       _isLoading = false;
///       notifyListeners();
///     }
///   }
///   
///   Future<void> loadNextPage() async {
///     if (_isLoading || !_hasMore) return;
///     
///     _isLoading = true;
///     notifyListeners();
///     
///     try {
///       final result = await _repository.fetchNextPage();
///       _jobs.addAll(result.items);
///       _hasMore = result.hasMore;
///     } catch (e) {
///       // Handle error
///     } finally {
///       _isLoading = false;
///       notifyListeners();
///     }
///   }
/// }
/// 
/// // Dans le Widget :
/// ListView.builder(
///   itemCount: jobs.length + (hasMore ? 1 : 0),
///   itemBuilder: (context, index) {
///     if (index == jobs.length) {
///       // Charger la page suivante
///       WidgetsBinding.instance.addPostFrameCallback((_) {
///         viewModel.loadNextPage();
///       });
///       return CircularProgressIndicator();
///     }
///     
///     return JobCard(job: jobs[index]);
///   },
/// );
/// ```




