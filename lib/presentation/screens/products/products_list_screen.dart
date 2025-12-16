import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/telemetry_service.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          final reference = product['reference']?.toString().toLowerCase() ?? '';
          final category = product['category']?.toString().toLowerCase() ?? '';
          return name.contains(query) || 
                 reference.contains(query) || 
                 category.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _filteredProducts = _products;
        _isLoading = false;
      });
    } catch (e) {
      TelemetryService.logError('Erreur chargement produits', e);
      setState(() {
        _errorMessage = 'Impossible de charger les produits';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddProductDialog() async {
    final formKey = GlobalKey<FormState>();
    final referenceController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController(text: 'unité');
    final categoryController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_box_rounded,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Nouveau Produit',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: 'Référence *',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) =>
                        value?.trim().isEmpty ?? true ? 'Référence requise' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) =>
                        value?.trim().isEmpty ?? true ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Prix unitaire (€) *',
                      prefixIcon: const Icon(Icons.euro_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Prix requis';
                      if (double.tryParse(value!) == null) {
                        return 'Prix invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'Unité',
                            prefixIcon: const Icon(Icons.straighten_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: categoryController,
                          decoration: InputDecoration(
                            labelText: 'Catégorie',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              final userId = _supabase.auth.currentUser?.id;
                              final userResponse = await _supabase
                                  .from('users')
                                  .select('company_id')
                                  .eq('id', userId!)
                                  .single();

                              final companyId = userResponse['company_id'];

                              await _supabase.from('products').insert({
                                'company_id': companyId,
                                'reference': referenceController.text.trim(),
                                'name': nameController.text.trim(),
                                'description': descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                'unit_price': double.parse(priceController.text.trim()),
                                'unit': unitController.text.trim(),
                                'category': categoryController.text.trim().isEmpty
                                    ? null
                                    : categoryController.text.trim(),
                              });

                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              TelemetryService.logError('Erreur création produit', e);
                              if (context.mounted) {
                                // Détecter l'erreur de cache Supabase
                                final errorMessage = e.toString();
                                final isCacheError = errorMessage.contains('PGRST204') || 
                                                    errorMessage.contains('schema cache') ||
                                                    errorMessage.contains('company_id') ||
                                                    errorMessage.contains('category');
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCacheError
                                          ? '⚠️ Erreur de cache Supabase\n'
                                            'Va sur le Dashboard Supabase et redémarre le projet'
                                          : 'Erreur: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                    action: isCacheError
                                        ? SnackBarAction(
                                            label: 'Plus d\'info',
                                            textColor: Colors.white,
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Erreur de cache Supabase'),
                                                  content: const Text(
                                                    'Le cache de Supabase doit être rechargé.\n\n'
                                                    '1. Va sur supabase.com/dashboard\n'
                                                    '2. Sélectionne ton projet\n'
                                                    '3. Project Settings > General\n'
                                                    '4. Clique sur "Pause project"\n'
                                                    '5. Attends 30 secondes\n'
                                                    '6. Clique sur "Resume project"\n'
                                                    '7. Réessaie dans l\'app',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        : null,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Créer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le produit'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$productName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('products').delete().eq('id', productId);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$productName supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        TelemetryService.logError('Erreur suppression produit', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Produits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.inventory_2_outlined
                                      : Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Aucun produit'
                                      : 'Aucun résultat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_searchController.text.isEmpty) ...[
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _showAddProductDialog,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Ajouter un produit'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau'),
        elevation: 4,
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final price = product['unit_price'];
    final unit = product['unit'] ?? 'unité';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Ouvrir les détails du produit
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      product['reference'][0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Réf: ${product['reference']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$price€ / $unit',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          if (product['category'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product['category'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Bouton supprimer
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red,
                  onPressed: () => _deleteProduct(product['id'], product['name']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
