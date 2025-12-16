import 'package:flutter/material.dart';
import '../../widgets/confidence_score_indicator.dart';

/// Écran de validation des données extraites par l'IA
/// 
/// Permet à l'utilisateur de vérifier et corriger les données
/// avant de les sauvegarder définitivement
class JobValidationScreen extends StatefulWidget {
  final Map<String, dynamic> extractedData;
  final String transcription;
  final Function(Map<String, dynamic>) onValidate;
  final VoidCallback? onRetry;

  const JobValidationScreen({
    super.key,
    required this.extractedData,
    required this.transcription,
    required this.onValidate,
    this.onRetry,
  });

  @override
  State<JobValidationScreen> createState() => _JobValidationScreenState();
}

class _JobValidationScreenState extends State<JobValidationScreen> {
  late TextEditingController _clientController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late List<Map<String, dynamic>> _products;
  late int _confidenceScore;

  @override
  void initState() {
    super.initState();
    
    _clientController = TextEditingController(text: widget.extractedData['client'] ?? '');
    _addressController = TextEditingController(text: widget.extractedData['adresse_intervention'] ?? '');
    _notesController = TextEditingController(text: widget.extractedData['notes'] ?? '');
    _products = List<Map<String, dynamic>>.from(widget.extractedData['produits'] ?? []);
    _confidenceScore = widget.extractedData['confiance'] ?? 0;
  }

  @override
  void dispose() {
    _clientController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addProduct() {
    setState(() {
      _products.add({
        'nom': '',
        'quantite': 1.0,
        'unite': 'unité',
        'prix_unitaire': null,
      });
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _validate() {
    final validatedData = {
      'client': _clientController.text,
      'client_nouveau': widget.extractedData['client_nouveau'] ?? false,
      'adresse_intervention': _addressController.text,
      'produits': _products,
      'notes': _notesController.text,
      'confiance': _confidenceScore,
    };
    
    widget.onValidate(validatedData);
  }

  double _calculateTotal() {
    return _products.fold(0.0, (sum, product) {
      final quantity = product['quantite'] as num? ?? 0;
      final unitPrice = product['prix_unitaire'] as num? ?? 0;
      return sum + (quantity * unitPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Données'),
        actions: [
          if (widget.onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRetry,
              tooltip: 'Relancer l\'extraction IA',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score de confiance
            ConfidenceScoreIndicator(
              score: _confidenceScore,
              size: ConfidenceScoreSize.large,
            ),
            
            const SizedBox(height: 24),
            
            // Transcription (lecture seule)
            ExpansionTile(
              title: const Text('📝 Transcription audio'),
              subtitle: Text(
                widget.transcription.length > 50 
                    ? '${widget.transcription.substring(0, 50)}...'
                    : widget.transcription,
                style: theme.textTheme.bodySmall,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    widget.transcription,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Client
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Client',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.extractedData['client_nouveau'] == true) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('NOUVEAU'),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _clientController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du client',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse d\'intervention',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Produits/Services
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Produits/Services',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addProduct,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Produit',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _products[index]['nom'] = value;
                                        });
                                      },
                                      controller: TextEditingController(text: product['nom']),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: theme.colorScheme.error,
                                    onPressed: () => _removeProduct(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Quantité',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          _products[index]['quantite'] = double.tryParse(value) ?? 0;
                                        });
                                      },
                                      controller: TextEditingController(
                                        text: product['quantite'].toString(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Unité',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _products[index]['unite'] = value;
                                        });
                                      },
                                      controller: TextEditingController(text: product['unite']),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Prix unit.',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        suffixText: '€',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          _products[index]['prix_unitaire'] = double.tryParse(value);
                                        });
                                      },
                                      controller: TextEditingController(
                                        text: product['prix_unitaire']?.toString() ?? '',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    // Total
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total HT',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_calculateTotal().toStringAsFixed(2)} €',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Notes & Observations',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter des notes, observations...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.check),
                    label: const Text('Valider & Sauvegarder'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

