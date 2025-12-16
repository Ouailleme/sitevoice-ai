import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/job_repository.dart';
import '../../../data/services/telemetry_service.dart';
import '../../widgets/confidence_score_indicator.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobRepository _jobRepository = JobRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Map<String, dynamic>? _job;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      setState(() {
        _job = job;
        _isLoading = false;
      });

      // Charger l'audio si disponible
      final audioPath = job?['audio_file_path'] as String?;
      if (audioPath != null && audioPath.isNotEmpty) {
        _loadAudio(audioPath);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du job: $e';
        _isLoading = false;
      });
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<void> _loadAudio(String audioPath) async {
    try {
      if (audioPath.startsWith('http')) {
        // URL Supabase
        await _audioPlayer.setUrl(audioPath);
      } else {
        // Fichier local
        await _audioPlayer.setFilePath(audioPath);
      }
    } catch (e) {
      TelemetryService.logError('Error loading audio', e);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _generatePDF() async {
    if (_job == null) return;

    // TODO: Implémenter la génération PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération PDF - À venir'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Détail de l\'intervention'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Générer PDF',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJob,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_job == null) {
      return const Center(
        child: Text('Job introuvable'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildAudioPlayer(),
          const SizedBox(height: 16),
          _buildClientInfo(),
          const SizedBox(height: 16),
          _buildTranscription(),
          const SizedBox(height: 16),
          _buildProducts(),
          const SizedBox(height: 16),
          _buildNotes(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final confidenceScore = _job!['confidence_score'] as int?;
    final status = _job!['status'] as String? ?? 'draft';
    final isSynced = _job!['is_synced'] as bool? ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel(status),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (confidenceScore != null)
                  ConfidenceScoreIndicator(score: confidenceScore),
              ],
            ),
            if (!isSynced) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En attente de synchronisation',
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final audioPath = _job!['audio_file_path'] as String?;
    
    if (audioPath == null || audioPath.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Enregistrement audio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Bouton Play/Pause
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 48,
                  ),
                  onPressed: _togglePlayPause,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                // Barre de progression
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: _currentPosition.inSeconds.toDouble(),
                          max: _totalDuration.inSeconds.toDouble() > 0 
                            ? _totalDuration.inSeconds.toDouble() 
                            : 1,
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    final clientName = _job!['client_name'] as String?;
    final address = _job!['address'] as String?;
    final isNewClient = _job!['is_new_client'] as bool? ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 8),
                Text(
                  'Client',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (clientName != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (isNewClient)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NOUVEAU',
                        style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranscription() {
    final transcription = _job!['transcription'] as String?;
    
    if (transcription == null || transcription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.text_fields, size: 20),
                SizedBox(width: 8),
                Text(
                  'Transcription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transcription,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts() {
    final products = _job!['products'] as List?;
    
    if (products == null || products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, size: 20),
                SizedBox(width: 8),
                Text(
                  'Produits/Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...products.map((product) => _buildProductItem(product as Map<String, dynamic>)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    final name = product['nom'] as String?;
    final quantity = product['quantite'] as num?;
    final unit = product['unite'] as String?;
    final unitPrice = product['prix_unitaire'] as num?;
    final isNew = product['produit_nouveau'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name ?? 'Produit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOUVEAU',
                    style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${quantity ?? 0} $unit',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              if (unitPrice != null) ...[
                const Text(' × ', style: TextStyle(fontSize: 13)),
                Text(
                  '${unitPrice.toStringAsFixed(2)} €',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const Spacer(),
                Text(
                  '${((quantity ?? 0) * unitPrice).toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    final notes = _job!['notes'] as String?;
    
    if (notes == null || notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, size: 20),
                SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notes,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'pending_sync':
        return 'En attente';
      case 'synced':
        return 'Synchronisé';
      case 'error':
        return 'Erreur';
      default:
        return status;
    }
  }
}

