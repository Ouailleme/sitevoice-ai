# 🚀 ROADMAP - PROCHAINES ÉTAPES

## 📊 Vue d'Ensemble

**Objectif** : Transformer SiteVoice AI en une app voice-to-invoice complète et fonctionnelle offline-first.

**Temps estimé total** : 15-20 heures de développement

---

## 🎯 PHASE 1 : AUDIO RECORDING (Priorité Haute)

### ✅ Déjà Fait
- [x] Configuration Gradle/Java pour compilation locale
- [x] Services Audio créés (AudioService, AudioRecordingService)
- [x] UI RecordScreen avec animations
- [x] AudioWaveAnimation widget

### 📝 À Faire

#### 1.1 Réactiver flutter_sound
**Temps estimé** : 30 min

```yaml
# pubspec.yaml
flutter_sound: ^9.10.4  # Décommenter cette ligne
```

**Commandes** :
```bash
flutter clean
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

#### 1.2 Tester l'Enregistrement Audio
**Temps estimé** : 1h

**Checklist** :
- [ ] Permission microphone accordée
- [ ] Enregistrement démarre/pause/reprend
- [ ] Fichier audio créé (vérifier avec explorateur)
- [ ] Durée correcte
- [ ] Amplitude/waveform fonctionne
- [ ] Annulation supprime le fichier

#### 1.3 Upload vers Supabase Storage
**Temps estimé** : 2h

**Tâches** :
- Créer le bucket `audio-recordings` dans Supabase
- Configurer les RLS policies
- Implémenter l'upload dans `StorageService`
- Compression audio avant upload (optionnel)
- Afficher la progression d'upload

**Code à ajouter** :
```dart
// lib/data/services/storage_service.dart
Future<String> uploadAudioRecording(File audioFile, String jobId) async {
  final fileName = 'job_${jobId}_${DateTime.now().millisecondsSinceEpoch}.aac';
  final path = 'recordings/$fileName';
  
  await _supabase.storage
    .from('audio-recordings')
    .upload(path, audioFile);
  
  return path;
}
```

---

## 🤖 PHASE 2 : IA - TRANSCRIPTION & EXTRACTION (Priorité Haute)

### 2.1 Configuration OpenAI
**Temps estimé** : 30 min

**Créer** : `.env` (à ajouter dans `.gitignore`)
```env
OPENAI_API_KEY=sk-proj-...
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=eyJ...
```

**Charger** :
```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
}
```

### 2.2 Implémenter Transcription Whisper
**Temps estimé** : 2h

**Fonctionnalités** :
- Envoyer le fichier audio à Whisper API
- Gérer les erreurs (timeout, quota dépassé)
- Afficher un loader avec progression
- Sauvegarder la transcription en BDD

**Code** :
```dart
// lib/data/services/openai_service.dart
Future<String> transcribeAudio(File audioFile) async {
  try {
    final response = await _dio.post(
      'https://api.openai.com/v1/audio/transcriptions',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(audioFile.path),
        'model': 'whisper-1',
        'language': 'fr', // Français
      }),
      options: Options(
        headers: {'Authorization': 'Bearer ${EnvConfig.openAiApiKey}'},
      ),
    );
    
    return response.data['text'];
  } catch (e) {
    throw TranscriptionException('Erreur transcription: $e');
  }
}
```

### 2.3 Créer les Prompts GPT-4
**Temps estimé** : 3h

**Prompt pour Extraction Structurée** :
```dart
const extractionPrompt = '''
Tu es un assistant IA spécialisé dans l'extraction de données de chantiers BTP.

CONTEXTE :
- Clients existants : [liste des noms de clients]
- Produits existants : [liste des produits avec prix]

TRANSCRIPTION À ANALYSER :
{transcription}

INSTRUCTIONS :
1. Identifie le client mentionné (utilise UNIQUEMENT un client existant ou indique "NOUVEAU")
2. Extraie les produits/services avec quantités
3. Calcule le total
4. Note les remarques importantes

RÉPONDS EN JSON STRICT :
{
  "confidence_score": 0-100,
  "client": {
    "name": "...",
    "is_existing": true/false
  },
  "items": [
    {"product": "...", "quantity": 10, "unit_price": 50, "total": 500}
  ],
  "total_ht": 500,
  "notes": "..."
}
''';
```

### 2.4 Implémenter Extraction GPT-4
**Temps estimé** : 2h

**Fonctionnalités** :
- Charger la liste des clients/produits depuis Supabase
- Injecter dans le prompt
- Appeler GPT-4 avec JSON Mode
- Parser et valider la réponse
- Calculer un score de confiance

---

## 🎨 PHASE 3 : UI VALIDATION (Priorité Moyenne)

### 3.1 Écran de Validation des Données
**Temps estimé** : 4h

**Composants** :
- Header avec score de confiance (vert/orange/rouge)
- Section Client (modifiable)
- Liste des produits (ajout/suppression/modification)
- Total automatique
- Champ notes
- Boutons : Valider / Corriger / Annuler

**Design** :
```dart
ValidationScreen(
  extraction: ExtractionResult,
  onValidate: (correctedData) { /* Sauvegarder */ },
  onRetry: () { /* Relancer IA */ },
)
```

### 3.2 Indicateurs Visuels Score de Confiance
**Temps estimé** : 1h

- Score > 80% : Vert ✅ "Données fiables"
- Score 50-80% : Orange ⚠️ "Vérifiez les données"
- Score < 50% : Rouge ❌ "Correction nécessaire"

---

## 💾 PHASE 4 : OFFLINE-FIRST (Priorité Haute)

### 4.1 Stockage Local avec Hive
**Temps estimé** : 3h

**Boxes à créer** :
```dart
@HiveType(typeId: 0)
class LocalJob {
  @HiveField(0) String id;
  @HiveField(1) String clientId;
  @HiveField(2) List<LocalJobItem> items;
  @HiveField(3) bool isSynced;
  @HiveField(4) DateTime createdAt;
}
```

**Repositories** :
```dart
class JobRepository {
  Future<void> saveLocally(Job job) async { /* Hive */ }
  Future<void> syncToSupabase(Job job) async { /* API */ }
  Future<List<Job>> getAllPendingSync() async { /* Queue */ }
}
```

### 4.2 Queue de Synchronisation
**Temps estimé** : 2h

**Fonctionnalités** :
- Détection de connectivité (connectivity_plus)
- Queue FIFO pour les opérations en attente
- Retry automatique en cas d'échec
- Indicateur visuel "X tâches en attente"

### 4.3 SyncService
**Temps estimé** : 2h

```dart
class SyncService {
  Stream<SyncStatus> get syncStatus;
  
  Future<void> syncAll() async {
    final pendingJobs = await _jobRepo.getAllPendingSync();
    for (var job in pendingJobs) {
      await _syncJob(job);
    }
  }
}
```

---

## 📄 PHASE 5 : GÉNÉRATION PDF (Priorité Moyenne)

### 5.1 Intégrer pdf & printing
**Temps estimé** : 1h

```yaml
dependencies:
  pdf: ^3.10.7
  printing: ^5.12.0
```

### 5.2 Template PDF Facture
**Temps estimé** : 3h

**Éléments** :
- Logo entreprise (en-tête)
- Infos entreprise (SIRET, adresse)
- Infos client
- Tableau des produits/services
- Total HT / TVA / TTC
- Conditions de paiement (pied de page)

### 5.3 Partage PDF
**Temps estimé** : 1h

```dart
Future<void> sharePdf(Uint8List pdfBytes) async {
  await Share.shareXFiles([
    XFile.fromData(pdfBytes, name: 'facture.pdf', mimeType: 'application/pdf')
  ]);
}
```

---

## 🧪 PHASE 6 : TESTS & POLISH (Priorité Basse)

### 6.1 Tests End-to-End
**Temps estimé** : 2h

**Scénarios** :
1. Enregistrement → Transcription → Extraction → Validation → PDF
2. Mode offline → Synchronisation automatique
3. Gestion d'erreurs (pas de réseau, quota IA dépassé)

### 6.2 Polish & UX
**Temps estimé** : 2h

- Animations fluides (Hero, SlideTransition)
- Haptic feedback (vibrations)
- Messages d'erreur clairs
- Loading states élégants

---

## 📚 PHASE 7 : DOCUMENTATION

### 7.1 README Complet
**Contenu** :
- Architecture du projet
- Setup (env vars, Supabase config)
- Guide de développement
- Commandes utiles

### 7.2 Guide Utilisateur
**Contenu** :
- Comment enregistrer un chantier
- Comment valider les données IA
- Comment générer une facture
- FAQ & Troubleshooting

---

## 🎯 ORDRE RECOMMANDÉ D'IMPLÉMENTATION

1. **Audio** (Phases 1) - 4h
2. **IA Transcription** (Phase 2.1-2.2) - 3h
3. **Offline-First** (Phase 4.1) - 2h
4. **IA Extraction** (Phase 2.3-2.4) - 5h
5. **UI Validation** (Phase 3) - 5h
6. **Sync** (Phase 4.2-4.3) - 4h
7. **PDF** (Phase 5) - 5h
8. **Tests & Polish** (Phase 6) - 4h

**Total** : ~32 heures de développement

---

## 💡 CONSEILS

### Performance
- Compresser l'audio avant upload (AAC 128kbps max)
- Pagination pour les listes longues
- Cache les réponses IA pour éviter les appels inutiles

### Sécurité
- JAMAIS de clés API dans le code
- RLS activé sur toutes les tables Supabase
- Validation côté serveur ET client

### UX
- Feedback immédiat sur toutes les actions
- Messages d'erreur actionnables ("Réessayer", "Vérifier connexion")
- Mode offline transparent pour l'utilisateur

---

## 🚀 COMMANDE RAPIDE POUR DÉVELOPPER

```bash
# Terminal 1 : Hot reload
flutter run

# Terminal 2 : Watcher logs
adb logcat | grep -i flutter

# Rebuild & Install
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

**Prêt à commencer ? 🔥**

Par quelle phase veux-tu commencer ?

