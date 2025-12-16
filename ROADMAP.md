# 🗺️ Roadmap - SiteVoice AI

Plan d'implémentation des fonctionnalités par ordre de priorité.

---

## 📊 **Vue d'Ensemble**

### **Statut Actuel (v1.0.0)** ✅
- Authentification complète
- CRUD Clients/Produits/Jobs
- Dashboard avec statistiques
- Bottom Navigation
- Material 3 Design
- Recherche en temps réel

### **Prochaines Versions**
- **v1.1.0** - Fonctionnalités Audio & IA (Priorité HAUTE) 🔴
- **v1.2.0** - Mode Offline & Synchronisation (Priorité MOYENNE) 🟡
- **v1.3.0** - Génération PDF & Documents (Priorité MOYENNE) 🟡
- **v1.4.0** - Améliorations UX (Priorité BASSE) 🟢
- **v2.0.0** - Features Avancées (Futur) 🔵

---

## 🔴 **v1.1.0 - AUDIO & IA** (PRIORITÉ HAUTE)

### **📅 Durée estimée : 2 semaines**

### **Features**

#### **1. 🎤 Enregistrement Audio**

**Objectif** : Permettre aux techniciens d'enregistrer leurs rapports vocaux

**Fichier** : `lib/presentation/screens/record/record_screen.dart`

**Étapes d'implémentation** :

```dart
// 1. Permissions audio
import 'package:permission_handler/permission_handler.dart';

Future<bool> _requestMicrophonePermission() async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    status = await Permission.microphone.request();
  }
  return status.isGranted;
}

// 2. Enregistrement avec record package
import 'package:record/record.dart';

final audioRecorder = AudioRecorder();

Future<void> _startRecording() async {
  if (await audioRecorder.hasPermission()) {
    await audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: 'path/to/audio.m4a',
    );
  }
}

Future<String?> _stopRecording() async {
  return await audioRecorder.stop();
}

// 3. UI avec animation d'onde audio
// Utiliser : lib/presentation/widgets/audio_wave_animation.dart
```

**Packages à ajouter** :
```yaml
dependencies:
  record: ^5.0.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.4
```

**Tests à faire** :
- ✅ Permission accordée/refusée
- ✅ Enregistrement démarre
- ✅ Enregistrement s'arrête correctement
- ✅ Fichier audio créé
- ✅ Animation visible pendant l'enregistrement

---

#### **2. ☁️ Upload Audio vers Supabase Storage**

**Objectif** : Stocker les fichiers audio dans Supabase Storage

**Étapes d'implémentation** :

```dart
// 1. Configuration Supabase Storage (côté Supabase)
// Créer un bucket "audio-recordings" avec RLS

// 2. Upload du fichier
import 'dart:io';

Future<String> _uploadAudioToSupabase(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
  
  final path = await Supabase.instance.client
    .storage
    .from('audio-recordings')
    .uploadBinary(
      'company_id/$fileName',
      bytes,
      fileOptions: const FileOptions(
        contentType: 'audio/m4a',
      ),
    );
    
  // Retourner l'URL publique
  return Supabase.instance.client
    .storage
    .from('audio-recordings')
    .getPublicUrl(path);
}
```

**Configuration Supabase** :
```sql
-- Créer le bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('audio-recordings', 'audio-recordings', false);

-- RLS Policy pour upload
CREATE POLICY "Users can upload own audio"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'audio-recordings' AND
  (storage.foldername(name))[1] IN (
    SELECT company_id::text FROM users WHERE id = auth.uid()
  )
);

-- RLS Policy pour lecture
CREATE POLICY "Users can read own audio"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'audio-recordings' AND
  (storage.foldername(name))[1] IN (
    SELECT company_id::text FROM users WHERE id = auth.uid()
  )
);
```

**Tests à faire** :
- ✅ Upload réussi
- ✅ URL publique générée
- ✅ RLS fonctionne (isolation par company)
- ✅ Fichier accessible après upload

---

#### **3. 🗣️ Transcription avec Whisper API**

**Objectif** : Convertir l'audio en texte avec Whisper d'OpenAI

**Fichier** : `lib/data/services/openai_service.dart` (à créer)

**Étapes d'implémentation** :

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class OpenAIService {
  static const String whisperApiUrl = 'https://api.openai.com/v1/audio/transcriptions';
  static const String apiKey = 'YOUR_API_KEY'; // Utiliser env variable

  Future<String> transcribeAudio(String audioFilePath) async {
    final file = File(audioFilePath);
    
    var request = http.MultipartRequest('POST', Uri.parse(whisperApiUrl));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = 'fr'; // Français
    request.fields['response_format'] = 'json';
    
    request.files.add(
      await http.MultipartFile.fromPath('file', audioFilePath),
    );
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final json = jsonDecode(responseData);
      return json['text'] as String;
    } else {
      throw Exception('Erreur transcription: $responseData');
    }
  }
}
```

**Configuration** :
```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'your-key-here', // À remplacer
  );
}
```

**Tests à faire** :
- ✅ Transcription réussie (texte retourné)
- ✅ Gestion d'erreur si API down
- ✅ Timeout géré
- ✅ Langue française détectée
- ✅ Ponctuation correcte

---

#### **4. 🤖 Extraction de Données avec GPT-4**

**Objectif** : Extraire les informations structurées depuis la transcription

**Étapes d'implémentation** :

```dart
class OpenAIService {
  static const String chatApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  Future<Map<String, dynamic>> extractJobData({
    required String transcription,
    required List<String> existingClients,
    required List<String> existingProducts,
  }) async {
    final prompt = '''
Tu es un assistant qui extrait des informations structurées depuis des rapports vocaux de techniciens BTP.

CLIENTS EXISTANTS :
${existingClients.join(', ')}

PRODUITS EXISTANTS :
${existingProducts.join(', ')}

TRANSCRIPTION :
"$transcription"

EXTRACTION :
Extrait les informations suivantes au format JSON strict :
{
  "client": "nom du client (utilise la liste CLIENTS EXISTANTS si possible)",
  "adresse_intervention": "adresse complète",
  "produits": [
    {
      "nom": "nom produit (utilise la liste PRODUITS EXISTANTS si possible)",
      "quantite": nombre,
      "unite": "unité (m2, ml, unité, etc.)",
      "prix_unitaire": nombre ou null si pas mentionné
    }
  ],
  "notes": "observations et détails supplémentaires",
  "confiance": score de 0 à 100 sur la qualité de l'extraction
}

Réponds UNIQUEMENT avec le JSON, rien d'autre.
''';

    final response = await http.post(
      Uri.parse(chatApiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': 'Tu es un assistant d\'extraction de données.'},
          {'role': 'user', 'content': prompt}
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content = json['choices'][0]['message']['content'];
      return jsonDecode(content);
    } else {
      throw Exception('Erreur extraction: ${response.body}');
    }
  }
}
```

**Tests à faire** :
- ✅ Extraction réussie
- ✅ JSON valide retourné
- ✅ Clients existants reconnus
- ✅ Produits existants reconnus
- ✅ Score de confiance calculé
- ✅ Gestion des cas ambigus

---

#### **5. ✅ Page de Validation Job**

**Objectif** : Permettre au technicien de valider/corriger les données extraites

**Fichier** : `lib/presentation/screens/jobs/job_validation_screen.dart`

**UI à implémenter** :
```dart
class JobValidationScreen extends StatefulWidget {
  final String jobId;
  const JobValidationScreen({required this.jobId});
}

// Sections :
// 1. Transcription (éditable)
// 2. Client sélectionné (dropdown + création rapide)
// 3. Produits extraits (liste éditable)
// 4. Notes/Observations
// 5. Boutons : Valider / Corriger / Supprimer
```

**Fonctionnalités** :
- ✅ Afficher les données extraites
- ✅ Permettre l'édition de chaque champ
- ✅ Ajouter/Retirer des produits
- ✅ Calculer le total automatiquement
- ✅ Créer un nouveau client si besoin
- ✅ Sauvegarder les modifications
- ✅ Mettre à jour le statut du job

---

### **📦 Packages Nécessaires**

```yaml
dependencies:
  # Audio
  record: ^5.0.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.4
  
  # HTTP
  http: ^1.2.2
  
  # JSON
  json_annotation: ^4.9.0

dev_dependencies:
  json_serializable: ^6.8.0
```

---

## 🟡 **v1.2.0 - MODE OFFLINE** (PRIORITÉ MOYENNE)

### **📅 Durée estimée : 1.5 semaines**

### **Features**

#### **1. 📴 Stockage Local avec Hive**

**Objectif** : Permettre l'utilisation de l'app sans connexion

**Étapes d'implémentation** :

```dart
// 1. Initialiser Hive
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  
  // Enregistrer les adapters
  Hive.registerAdapter(ClientModelAdapter());
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(JobModelAdapter());
  
  // Ouvrir les boxes
  await Hive.openBox<ClientModel>('clients');
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<JobModel>('jobs');
  await Hive.openBox('sync_queue');
}

// 2. Créer des adapters
// Exemple pour ClientModel
@HiveType(typeId: 0)
class ClientModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  // ... autres champs
}

// Générer les adapters
// flutter packages pub run build_runner build
```

**Architecture** :
```dart
// Repository pattern avec fallback local
class ClientRepository {
  final clientsBox = Hive.box<ClientModel>('clients');
  
  Future<List<ClientModel>> getClients() async {
    // Essayer de récupérer depuis Supabase
    try {
      final remoteClients = await _fetchFromSupabase();
      // Mettre à jour le cache local
      await _updateLocalCache(remoteClients);
      return remoteClients;
    } catch (e) {
      // En cas d'erreur, utiliser le cache local
      return clientsBox.values.toList();
    }
  }
  
  Future<void> createClient(ClientModel client) async {
    // Sauvegarder en local d'abord
    await clientsBox.put(client.id, client);
    
    // Ajouter à la queue de sync
    await _addToSyncQueue({
      'type': 'CREATE_CLIENT',
      'data': client.toJson(),
    });
    
    // Essayer de sync immédiatement
    await _trySyncNow();
  }
}
```

---

#### **2. 🔄 Queue de Synchronisation**

**Objectif** : Synchroniser les actions offline une fois reconnecté

**Étapes d'implémentation** :

```dart
class SyncService {
  final syncQueue = Hive.box('sync_queue');
  
  Future<void> processSyncQueue() async {
    if (!await _hasInternetConnection()) return;
    
    final items = syncQueue.values.toList();
    
    for (final item in items) {
      try {
        await _processItem(item);
        await syncQueue.delete(item['id']);
      } catch (e) {
        // Logger l'erreur mais continuer
        TelemetryService.logError('Sync failed', e);
      }
    }
  }
  
  Future<void> _processItem(Map item) async {
    switch (item['type']) {
      case 'CREATE_CLIENT':
        await _supabase.from('clients').insert(item['data']);
        break;
      case 'UPDATE_PRODUCT':
        await _supabase.from('products').update(item['data']).eq('id', item['id']);
        break;
      // ... autres cas
    }
  }
  
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
```

**UI Indicator** :
```dart
// Afficher un badge "Offline" en haut de l'écran
// Afficher le nombre d'actions en attente de sync
```

---

## 🟡 **v1.3.0 - GÉNÉRATION PDF** (PRIORITÉ MOYENNE)

### **📅 Durée estimée : 1 semaine**

### **Features**

#### **1. 📄 Génération de Factures PDF**

**Objectif** : Créer des factures PDF professionnelles

**Package** : `pdf` ^3.10.0

**Étapes d'implémentation** :

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<File> generateInvoicePDF(JobModel job) async {
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FACTURE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('N° ${job.id.substring(0, 8)}'),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Informations entreprise
            pw.Text('Mon Entreprise BTP', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Adresse...'),
            pw.Text('SIRET: ...'),
            pw.SizedBox(height: 20),
            
            // Informations client
            pw.Text('Client: ${job.clientName}'),
            pw.Text('Adresse: ${job.address}'),
            pw.SizedBox(height: 20),
            
            // Tableau des produits
            pw.Table.fromTextArray(
              headers: ['Désignation', 'Quantité', 'P.U.', 'Total'],
              data: job.items.map((item) => [
                item.description,
                '${item.quantity} ${item.unit}',
                '${item.unitPrice}€',
                '${item.totalPrice}€',
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            
            // Total
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL: ${job.totalAmount}€',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
  
  // Sauvegarder le PDF
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/facture_${job.id}.pdf');
  await file.writeAsBytes(await pdf.save());
  
  return file;
}
```

**Fonctionnalités** :
- ✅ Génération PDF A4
- ✅ Logo entreprise
- ✅ Informations client
- ✅ Tableau des produits
- ✅ Calcul TVA
- ✅ Total TTC
- ✅ Partage par email/SMS
- ✅ Stockage dans Supabase Storage

---

## 🟢 **v1.4.0 - AMÉLIORATIONS UX** (PRIORITÉ BASSE)

### **Features**

#### **1. 👤 Page Détails Client**
- Historique des interventions
- Statistiques (CA total, nb jobs, etc.)
- Édition rapide des infos
- Appel/Email direct

#### **2. 📦 Page Détails Produit**
- Statistiques d'utilisation
- Jobs où le produit a été utilisé
- Édition du prix
- Historique des modifications

#### **3. 📋 Page Détails Job**
- Timeline de l'intervention
- Photos avant/après
- Signature client
- Géolocalisation
- Partage du rapport

#### **4. 📸 Photos et Signature**
- Prise de photos pendant l'intervention
- Signature du client sur tablette
- Stockage dans Supabase Storage

#### **5. 📍 Géolocalisation**
- Position GPS de l'intervention
- Affichage sur carte
- Traçabilité des déplacements

#### **6. 🔔 Notifications Push**
- Job validé
- Client ajouté
- Rappels

---

## 🔵 **v2.0.0 - FEATURES AVANCÉES** (FUTUR)

### **Features**

#### **1. 📊 Analytics Avancées**
- Dashboard complet
- Graphiques de CA
- Prévisions IA
- Rapports personnalisés

#### **2. 📤 Export de Données**
- Export CSV
- Export Excel
- Backup complet
- Import de données

#### **3. 🌍 Support Multilingue**
- Français (par défaut)
- Anglais
- Espagnol
- Détection automatique

#### **4. 🌙 Dark Mode**
- Thème sombre complet
- Switch dans settings
- Sauvegarde préférence

#### **5. 🤝 Collaboration**
- Plusieurs techniciens par company
- Assignation de jobs
- Chat interne
- Notifications d'équipe

---

## 📋 **CHECKLIST PAR FEATURE**

### **Audio & IA (v1.1.0)**
- [ ] Permissions audio configurées
- [ ] Enregistrement audio fonctionnel
- [ ] UI avec animation d'onde
- [ ] Upload vers Supabase Storage
- [ ] Bucket Supabase créé avec RLS
- [ ] Intégration Whisper API
- [ ] Transcription française testée
- [ ] Prompt GPT-4 optimisé
- [ ] Extraction de données fonctionnelle
- [ ] Score de confiance calculé
- [ ] Page de validation complète
- [ ] Édition des données possible
- [ ] Création rapide client/produit
- [ ] Tests E2E complets

### **Mode Offline (v1.2.0)**
- [ ] Hive initialisé
- [ ] Adapters générés
- [ ] Repository pattern implémenté
- [ ] Cache local fonctionnel
- [ ] Queue de synchronisation
- [ ] Détection connexion internet
- [ ] Sync automatique au retour online
- [ ] UI indicator offline/online
- [ ] Gestion des conflits
- [ ] Tests offline complets

### **PDF (v1.3.0)**
- [ ] Package PDF installé
- [ ] Template facture créé
- [ ] Logo intégré
- [ ] Calcul TVA correct
- [ ] Génération testée
- [ ] Partage par email/SMS
- [ ] Stockage Supabase
- [ ] Preview avant génération

---

## 🎯 **PRIORITÉS**

### **🔴 URGENT (Semaine 1-2)**
1. Enregistrement audio
2. Upload Supabase
3. Transcription Whisper
4. Extraction GPT-4
5. Validation job

### **🟡 IMPORTANT (Semaine 3-4)**
1. Mode offline
2. Queue de sync
3. Génération PDF

### **🟢 PEUT ATTENDRE (Semaine 5+)**
1. Détails entités
2. Photos/Signature
3. Notifications
4. Analytics

---

## 📚 **RESSOURCES**

### **Documentation**
- [Whisper API](https://platform.openai.com/docs/api-reference/audio)
- [GPT-4 JSON Mode](https://platform.openai.com/docs/guides/structured-outputs)
- [Hive Documentation](https://docs.hivedb.dev/)
- [PDF Package](https://pub.dev/packages/pdf)

### **Exemples de Code**
- Voir `/lib/presentation/screens/record/record_screen.dart` (déjà en place)
- Voir `/lib/data/services/audio_service.dart` (déjà en place)

---

**📝 Dernière mise à jour : 2025-12-16**

