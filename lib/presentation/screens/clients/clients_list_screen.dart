import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/telemetry_service.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          final name = client['name']?.toString().toLowerCase() ?? '';
          final email = client['email']?.toString().toLowerCase() ?? '';
          final phone = client['phone']?.toString().toLowerCase() ?? '';
          return name.contains(query) || 
                 email.contains(query) || 
                 phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('clients')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _clients = List<Map<String, dynamic>>.from(response);
        _filteredClients = _clients;
        _isLoading = false;
      });
    } catch (e) {
      TelemetryService.logError('Erreur chargement clients', e);
      setState(() {
        _errorMessage = 'Impossible de charger les clients';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddClientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

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
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Nouveau Client',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom complet *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) =>
                        value?.trim().isEmpty ?? true ? 'Nom requis' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
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

                              await _supabase.from('clients').insert({
                                'company_id': companyId,
                                'name': nameController.text.trim(),
                                'email': emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                'phone': phoneController.text.trim().isEmpty
                                    ? null
                                    : phoneController.text.trim(),
                                'address': addressController.text.trim().isEmpty
                                    ? null
                                    : addressController.text.trim(),
                                'created_by': userId,
                              });

                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              TelemetryService.logError('Erreur création client', e);
                              if (context.mounted) {
                                // Détecter l'erreur de cache Supabase
                                final errorMessage = e.toString();
                                final isCacheError = errorMessage.contains('PGRST204') || 
                                                    errorMessage.contains('schema cache') ||
                                                    errorMessage.contains('company_id');
                                
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
      _loadClients();
    }
  }

  Future<void> _deleteClient(String clientId, String clientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le client'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$clientName" ?'),
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
        await _supabase.from('clients').delete().eq('id', clientId);
        _loadClients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$clientName supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        TelemetryService.logError('Erreur suppression client', e);
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
          'Clients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadClients,
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
                hintText: 'Rechercher un client...',
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
          
          // Liste des clients
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
                              onPressed: _loadClients,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredClients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.people_outline
                                      : Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Aucun client'
                                      : 'Aucun résultat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_searchController.text.isEmpty) ...[
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _showAddClientDialog,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Ajouter un client'),
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
                            onRefresh: _loadClients,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredClients.length,
                              itemBuilder: (context, index) {
                                final client = _filteredClients[index];
                                return _buildClientCard(client);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau'),
        elevation: 4,
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
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
            // TODO: Ouvrir les détails du client
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      client['name'][0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
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
                        client['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (client['email'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client['email'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (client['phone'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              client['phone'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Bouton supprimer
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red,
                  onPressed: () => _deleteClient(client['id'], client['name']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
