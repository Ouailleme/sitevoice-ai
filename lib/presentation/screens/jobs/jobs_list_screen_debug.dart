import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Écran de debug pour vérifier le contenu de Hive
class JobsListDebugScreen extends StatelessWidget {
  const JobsListDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Hive Jobs'),
      ),
      body: FutureBuilder(
        future: _loadHiveData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final data = snapshot.data as Map<String, dynamic>;
          final jobsBox = data['jobs'] as List;
          final syncBox = data['sync'] as List;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Jobs Box (${jobsBox.length} items)',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...jobsBox.map((job) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    job.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
              const SizedBox(height: 32),
              Text(
                'Sync Queue Box (${syncBox.length} items)',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...syncBox.map((item) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadHiveData() async {
    try {
      final jobsBox = Hive.box('jobs');
      final syncBox = Hive.box('sync_queue');

      final jobs = <Map<String, dynamic>>[];
      for (var key in jobsBox.keys) {
        final jobJson = jobsBox.get(key) as String?;
        if (jobJson != null) {
          jobs.add(jsonDecode(jobJson) as Map<String, dynamic>);
        }
      }

      final syncItems = <Map<String, dynamic>>[];
      for (var key in syncBox.keys) {
        final item = syncBox.get(key);
        if (item != null) {
          syncItems.add(Map<String, dynamic>.from(item as Map));
        }
      }

      return {
        'jobs': jobs,
        'sync': syncItems,
      };
    } catch (e) {
      return {
        'jobs': [],
        'sync': [],
        'error': e.toString(),
      };
    }
  }
}

