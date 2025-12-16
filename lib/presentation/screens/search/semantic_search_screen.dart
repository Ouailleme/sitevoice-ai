import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/semantic_search_service.dart';
import '../../../core/constants/theme_constants.dart';

/// Ecran de recherche semantique avancee
class SemanticSearchScreen extends StatefulWidget {
  const SemanticSearchScreen({Key? key}) : super(key: key);

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<HybridSearchResult> _results = [];
  List<String> _popularSearches = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPopularSearches();
    
    // Auto-focus sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPopularSearches() async {
    final searchService = context.read<SemanticSearchService>();
    final popular = await searchService.getPopularSearches(limit: 5);
    
    if (mounted) {
      setState(() {
        _popularSearches = popular;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final searchService = context.read<SemanticSearchService>();
      final results = await searchService.hybridSearch(query, maxResults: 20);

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          
          if (results.isEmpty) {
            _errorMessage = 'Aucun résultat trouvé pour "$query"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Erreur de recherche: ${e.toString()}';
        });
      }
    }
  }

  void _onSearchQueryChanged(String query) {
    // Debounce: attendre 500ms apres la derniere frappe
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _performSearch(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche Intelligente'),
        backgroundColor: ThemeConstants.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          
          // Resultats ou suggestions
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: ThemeConstants.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchQueryChanged,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: 'Rechercher un chantier, un client...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: ThemeConstants.primaryColor,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_results.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explications
          _buildExplanationCard(),
          
          const SizedBox(height: 24),
          
          // Recherches populaires
          if (_popularSearches.isNotEmpty) ...[
            const Text(
              'Recherches populaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: ThemeConstants.warningColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recherche Intelligente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cherchez par description, lieu, ou détails techniques. '
              'L\'IA comprend le contexte et trouve les chantiers similaires.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Exemples :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleChip('Le chantier avec la porte bleue'),
            _buildExampleChip('Chaudière Frisquet qui fuit'),
            _buildExampleChip('Intervention rue Victor Hugo'),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _searchController.text = example;
          _performSearch(example);
        },
        child: Row(
          children: [
            const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              example,
              style: TextStyle(
                fontSize: 13,
                color: ThemeConstants.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez des mots-clés différents',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(HybridSearchResult result) {
    final isJob = result.resultType == 'job';
    final icon = isJob ? Icons.work_outline : Icons.person_outline;
    final color = isJob ? ThemeConstants.primaryColor : ThemeConstants.successColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onResultTap(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.resultTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildScoreBadge(result.combinedScore),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.resultDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildScoreDetail('Similarité', result.similarityScore, Colors.blue),
                  const SizedBox(width: 16),
                  _buildScoreDetail('Mots-clés', result.keywordScore, Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    final percentage = (score * 100).toInt();
    Color color;
    
    if (percentage >= 90) {
      color = ThemeConstants.successColor;
    } else if (percentage >= 70) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildScoreDetail(String label, double score, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${(score * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  void _onResultTap(HybridSearchResult result) {
    // Navigation vers le detail du job ou client
    if (result.resultType == 'job') {
      // Navigator.push vers job detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouvrir job: ${result.resultId}')),
      );
    } else {
      // Navigator.push vers client detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouvrir client: ${result.resultId}')),
      );
    }
  }
}




