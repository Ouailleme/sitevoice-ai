import 'package:flutter/material.dart';
import '../../data/repositories/paginated_repository.dart';

/// Widget générique pour afficher une liste paginée avec lazy loading
/// 
/// V2.2 : Lazy Loading automatique
/// - Détecte quand l'utilisateur atteint le bas de la liste
/// - Charge automatiquement la page suivante
/// - Affiche un indicateur de chargement
/// - Gère les états : Loading, Empty, Error
/// 
/// Usage :
/// ```dart
/// PaginatedListView<Job>(
///   repository: jobsRepository,
///   itemBuilder: (context, job) => JobCard(job: job),
///   emptyMessage: 'Aucune intervention',
/// )
/// ```
class PaginatedListView<T> extends StatefulWidget {
  final PaginatedRepository<T> repository;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyMessage;
  final Map<String, dynamic>? filters;
  final EdgeInsets? padding;
  
  const PaginatedListView({
    super.key,
    required this.repository,
    required this.itemBuilder,
    this.emptyMessage = 'Aucun élément',
    this.filters,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    
    // Écouter le scroll pour le lazy loading
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    
    // Détecter si on est proche du bas (80% scrollé)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;
    
    if (currentScroll >= threshold) {
      _loadNextPage();
    }
  }
  
  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      widget.repository.reset();
      final result = await widget.repository.fetchFirstPage(
        filters: widget.filters,
      );
      
      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger les données';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final result = await widget.repository.fetchNextPage(
        filters: widget.filters,
      );
      
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // État : Loading initial
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // État : Erreur
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFirstPage,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    // État : Liste vide
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // État : Liste avec données
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Dernier élément : Indicateur de chargement
          if (index == _items.length) {
            return _buildLoadingIndicator();
          }
          
          // Élément normal
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const CircularProgressIndicator()
          : const SizedBox.shrink(),
    );
  }
}

/// Widget pour afficher une grille paginée
/// 
/// Similaire à PaginatedListView mais en mode grille
class PaginatedGridView<T> extends StatefulWidget {
  final PaginatedRepository<T> repository;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyMessage;
  final Map<String, dynamic>? filters;
  final EdgeInsets? padding;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  
  const PaginatedGridView({
    super.key,
    required this.repository,
    required this.itemBuilder,
    this.emptyMessage = 'Aucun élément',
    this.filters,
    this.padding,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;
    
    if (currentScroll >= threshold) {
      _loadNextPage();
    }
  }
  
  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      widget.repository.reset();
      final result = await widget.repository.fetchFirstPage(
        filters: widget.filters,
      );
      
      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger les données';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final result = await widget.repository.fetchNextPage(
        filters: widget.filters,
      );
      
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFirstPage,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding ?? const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}




