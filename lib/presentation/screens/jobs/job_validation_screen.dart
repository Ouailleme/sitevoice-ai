import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../view_models/job_validation_view_model.dart';

class JobValidationScreen extends StatelessWidget {
  final String jobId;

  const JobValidationScreen({
    super.key,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JobValidationViewModel(
        jobId: jobId,
        authService: context.read<AuthService>(),
      ),
      child: const _JobValidationContent(),
    );
  }
}

class _JobValidationContent extends StatelessWidget {
  const _JobValidationContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Validation Intervention'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<JobValidationViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.aiConfidence != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: _buildConfidenceBadge(viewModel.aiConfidence!),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<JobValidationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return _buildErrorState(context, viewModel);
          }

          return Column(
            children: [
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transcription
                      if (viewModel.transcription != null)
                        _buildTranscriptionCard(viewModel.transcription!),

                      const SizedBox(height: 16),

                      // Informations générales
                      _buildGeneralInfoCard(context, viewModel),

                      const SizedBox(height: 16),

                      // Liste des items
                      _buildItemsSection(context, viewModel),

                      const SizedBox(height: 16),

                      // Notes
                      _buildNotesCard(context, viewModel),

                      const SizedBox(height: 100), // Espace pour le bouton flottant
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<JobValidationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: ThemeConstants.mediumShadow,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total HT',
                        style: ThemeConstants.heading3,
                      ),
                      Text(
                        '${viewModel.totalHT.toStringAsFixed(2)} €',
                        style: ThemeConstants.heading3.copyWith(
                          color: ThemeConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total TTC',
                        style: ThemeConstants.bodyTextSecondary,
                      ),
                      Text(
                        '${viewModel.totalTTC.toStringAsFixed(2)} €',
                        style: ThemeConstants.bodyTextSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bouton valider
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isSaving
                          ? null
                          : () => _validateJob(context, viewModel),
                      child: viewModel.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Valider l\'intervention'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color;
    String label;

    if (confidence >= 0.8) {
      color = ThemeConstants.successColor;
      label = 'Haute';
    } else if (confidence >= 0.6) {
      color = ThemeConstants.warningColor;
      label = 'Moyenne';
    } else {
      color = ThemeConstants.errorColor;
      label = 'Faible';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard(String transcription) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.record_voice_over, color: ThemeConstants.primaryColor),
        title: const Text('Transcription audio'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              transcription,
              style: ThemeConstants.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard(BuildContext context, JobValidationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: ThemeConstants.heading3,
            ),
            const SizedBox(height: 16),
            
            // Client
            TextFormField(
              initialValue: viewModel.clientName,
              decoration: const InputDecoration(
                labelText: 'Client',
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: viewModel.updateClientName,
            ),
            
            const SizedBox(height: 12),
            
            // Adresse
            TextFormField(
              initialValue: viewModel.clientAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on),
              ),
              onChanged: viewModel.updateClientAddress,
            ),
            
            const SizedBox(height: 12),
            
            // Date
            InkWell(
              onTap: () => _selectDate(context, viewModel),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date d\'intervention',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  viewModel.interventionDate != null
                      ? DateFormat('dd/MM/yyyy').format(viewModel.interventionDate!)
                      : 'Non définie',
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Durée
            TextFormField(
              initialValue: viewModel.duration?.toString(),
              decoration: const InputDecoration(
                labelText: 'Durée (heures)',
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final duration = double.tryParse(value);
                viewModel.updateDuration(duration);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, JobValidationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produits / Services',
                  style: ThemeConstants.heading3,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: ThemeConstants.primaryColor),
                  onPressed: () => _addItem(context, viewModel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (viewModel.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun produit ajouté',
                    style: ThemeConstants.bodyTextSecondary,
                  ),
                ),
              )
            else
              ...viewModel.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildItemTile(context, viewModel, index, item);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    JobValidationViewModel viewModel,
    int index,
    JobItemValidation item,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: ThemeConstants.backgroundColor,
      child: ListTile(
        title: Text(item.description),
        subtitle: Text(
          'Quantité: ${item.quantity} • Prix unitaire: ${item.unitPrice?.toStringAsFixed(2) ?? '-'} €',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.totalPrice?.toStringAsFixed(2) ?? '-'} €',
              style: ThemeConstants.heading3.copyWith(
                color: ThemeConstants.primaryColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: ThemeConstants.errorColor),
              onPressed: () => viewModel.removeItem(index),
            ),
          ],
        ),
        onTap: () => _editItem(context, viewModel, index, item),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, JobValidationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes additionnelles',
              style: ThemeConstants.heading3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: viewModel.notes,
              decoration: const InputDecoration(
                hintText: 'Ajoutez des notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: viewModel.updateNotes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, JobValidationViewModel viewModel) {
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
              style: ThemeConstants.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage ?? 'Une erreur est survenue',
              style: ThemeConstants.bodyTextSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.reload(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, JobValidationViewModel viewModel) async {
    final date = await showDatePicker(
      context: context,
      initialDate: viewModel.interventionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      viewModel.updateInterventionDate(date);
    }
  }

  void _addItem(BuildContext context, JobValidationViewModel viewModel) {
    // TODO: Implémenter un dialog pour ajouter un item
    final item = JobItemValidation(
      productReference: '',
      description: 'Nouveau produit',
      quantity: 1,
      unitPrice: 0,
      totalPrice: 0,
    );
    viewModel.addItem(item);
  }

  void _editItem(
    BuildContext context,
    JobValidationViewModel viewModel,
    int index,
    JobItemValidation item,
  ) {
    // TODO: Implémenter un dialog pour éditer un item
  }

  Future<void> _validateJob(BuildContext context, JobValidationViewModel viewModel) async {
    final success = await viewModel.validateAndSave();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervention validée avec succès !'),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
      context.pop();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Erreur lors de la validation'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    }
  }
}

