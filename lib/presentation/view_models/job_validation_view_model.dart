import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/job_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/telemetry_service.dart';

/// État de validation
enum ValidationState {
  loading,
  loaded,
  saving,
  saved,
  error,
}

/// Item d'intervention à valider
class JobItemValidation {
  String? id;
  String? productId;
  String productReference;
  String description;
  double quantity;
  double? unitPrice;
  double? totalPrice;
  bool isValidated;

  JobItemValidation({
    this.id,
    this.productId,
    required this.productReference,
    required this.description,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.isValidated = false,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'is_validated': isValidated,
      };
}

/// ViewModel pour la validation d'un job
class JobValidationViewModel extends ChangeNotifier {
  final String jobId;
  final AuthService _authService;
  final SupabaseClient _supabase = Supabase.instance.client;

  ValidationState _state = ValidationState.loading;
  JobModel? _job;
  String? _clientName;
  String? _clientAddress;
  DateTime? _interventionDate;
  double? _duration;
  String? _notes;
  List<JobItemValidation> _items = [];
  String? _errorMessage;

  JobValidationViewModel({
    required this.jobId,
    required AuthService authService,
  }) : _authService = authService {
    _loadJob();
  }

  // =====================================================
  // GETTERS
  // =====================================================

  ValidationState get state => _state;
  bool get isLoading => _state == ValidationState.loading;
  bool get isLoaded => _state == ValidationState.loaded;
  bool get isSaving => _state == ValidationState.saving;
  bool get isSaved => _state == ValidationState.saved;
  bool get hasError => _state == ValidationState.error;

  JobModel? get job => _job;
  String? get clientName => _clientName;
  String? get clientAddress => _clientAddress;
  DateTime? get interventionDate => _interventionDate;
  double? get duration => _duration;
  String? get notes => _notes;
  List<JobItemValidation> get items => _items;
  String? get errorMessage => _errorMessage;

  double? get aiConfidence => _job?.aiConfidenceScore;
  String? get transcription => _job?.transcriptionText;

  bool get needsReview => _job?.needsReview ?? false;
  bool get isProcessing => _job?.isProcessing ?? false;

  double get totalHT {
    return _items.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0));
  }

  double get totalTTC {
    return totalHT * 1.20; // TVA 20%
  }

  // =====================================================
  // CHARGEMENT
  // =====================================================

  Future<void> _loadJob() async {
    try {
      _setState(ValidationState.loading);

      TelemetryService.logInfo('Chargement job: $jobId');

      // Charger le job
      final jobData = await _supabase
          .from('jobs')
          .select()
          .eq('id', jobId)
          .single();

      _job = JobModel.fromJson(jobData);

      // Charger les données extraites par l'IA
      if (_job!.aiExtractedData != null) {
        final extracted = _job!.aiExtractedData!;
        
        _clientName = extracted['clientName'];
        _clientAddress = extracted['clientAddress'];
        
        if (extracted['interventionDate'] != null) {
          _interventionDate = DateTime.tryParse(extracted['interventionDate']);
        }
        
        _duration = extracted['duration']?.toDouble();
        _notes = extracted['notes'];

        // Charger les items
        if (extracted['items'] != null) {
          _items = (extracted['items'] as List).map((item) {
            return JobItemValidation(
              productReference: item['productReference'] ?? '',
              description: item['description'] ?? '',
              quantity: (item['quantity'] ?? 0).toDouble(),
              unitPrice: item['estimatedPrice']?.toDouble(),
              totalPrice: item['estimatedPrice'] != null
                  ? (item['estimatedPrice'] * item['quantity']).toDouble()
                  : null,
            );
          }).toList();
        }
      }

      // Charger les job_items de la base si présents
      final jobItemsData = await _supabase
          .from('job_items')
          .select()
          .eq('job_id', jobId);

      if (jobItemsData.isNotEmpty) {
        _items = jobItemsData.map((itemData) {
          return JobItemValidation(
            id: itemData['id'],
            productId: itemData['product_id'],
            productReference: itemData['description'], // À améliorer
            description: itemData['description'],
            quantity: (itemData['quantity'] ?? 0).toDouble(),
            unitPrice: itemData['unit_price']?.toDouble(),
            totalPrice: itemData['total_price']?.toDouble(),
            isValidated: itemData['is_validated'] ?? false,
          );
        }).toList();
      }

      _setState(ValidationState.loaded);
      TelemetryService.logInfo('Job chargé avec succès');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur chargement job', e, stackTrace);
      _errorMessage = 'Impossible de charger les données';
      _setState(ValidationState.error);
    }
  }

  // =====================================================
  // MODIFICATIONS
  // =====================================================

  void updateClientName(String? value) {
    _clientName = value;
    notifyListeners();
  }

  void updateClientAddress(String? value) {
    _clientAddress = value;
    notifyListeners();
  }

  void updateInterventionDate(DateTime? value) {
    _interventionDate = value;
    notifyListeners();
  }

  void updateDuration(double? value) {
    _duration = value;
    notifyListeners();
  }

  void updateNotes(String? value) {
    _notes = value;
    notifyListeners();
  }

  void updateItem(int index, JobItemValidation updatedItem) {
    if (index >= 0 && index < _items.length) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  void addItem(JobItemValidation item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // =====================================================
  // VALIDATION ET SAUVEGARDE
  // =====================================================

  Future<bool> validateAndSave() async {
    try {
      _setState(ValidationState.saving);

      TelemetryService.logInfo('Validation et sauvegarde job: $jobId');

      // Valider les données
      if (_items.isEmpty) {
        throw ValidationException(
          message: 'Ajoutez au moins un produit ou service',
        );
      }

      // Mettre à jour le job
      await _supabase.from('jobs').update({
        'status': 'validated',
        'intervention_date': _interventionDate?.toIso8601String(),
        'intervention_duration_hours': _duration,
        'notes': _notes,
        'total_ht': totalHT,
        'total_ttc': totalTTC,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Supprimer les anciens items
      await _supabase.from('job_items').delete().eq('job_id', jobId);

      // Insérer les nouveaux items
      final itemsData = _items.map((item) {
        final data = item.toJson();
        data['job_id'] = jobId;
        return data;
      }).toList();

      await _supabase.from('job_items').insert(itemsData);

      _setState(ValidationState.saved);
      TelemetryService.logInfo('Job validé et sauvegardé');

      return true;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur validation job', e, stackTrace);
      
      if (e is ValidationException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Impossible de sauvegarder les modifications';
      }
      
      _setState(ValidationState.error);
      return false;
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  void _setState(ValidationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> reload() async {
    await _loadJob();
  }
}


