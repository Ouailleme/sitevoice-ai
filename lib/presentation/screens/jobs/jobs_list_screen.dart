import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/services/telemetry_service.dart';

class JobsListScreen extends StatefulWidget {
  const JobsListScreen({super.key});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs.where((job) {
          final status = job['status']?.toString().toLowerCase() ?? '';
          final transcription = job['transcription_text']?.toString().toLowerCase() ?? '';
          return status.contains(query) || transcription.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(response);
        _filteredJobs = _jobs;
        _isLoading = false;
      });
    } catch (e) {
      TelemetryService.logError('Erreur chargement jobs', e);
      setState(() {
        _errorMessage = 'Impossible de charger les interventions';
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_audio':
        return 'En attente';
      case 'processing':
        return 'Traitement';
      case 'review_needed':
        return 'À valider';
      case 'validated':
        return 'Validé';
      case 'invoiced':
        return 'Facturé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_audio':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'review_needed':
        return Colors.purple;
      case 'validated':
        return Colors.green;
      case 'invoiced':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Interventions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadJobs,
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
                hintText: 'Rechercher une intervention...',
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
          
          // Liste des jobs
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
                              onPressed: _loadJobs,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredJobs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.work_outline
                                      : Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Aucune intervention'
                                      : 'Aucun résultat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_searchController.text.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enregistrez votre premier rapport vocal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadJobs,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredJobs.length,
                              itemBuilder: (context, index) {
                                final job = _filteredJobs[index];
                                return _buildJobCard(job);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'pending_audio';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final createdAt = DateTime.parse(job['created_at']);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    
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
            // TODO: Ouvrir les détails du job
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Statut
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                if (job['transcription_text'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    job['transcription_text'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                if (job['total_amount'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${job['total_amount']}€',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
