# 🛠️ Guide d'Implémentation - Audio & IA

Guide pas à pas pour implémenter les fonctionnalités d'enregistrement audio et d'extraction IA.

---

## 🎯 **OBJECTIF**

Permettre aux techniciens de :
1. **Enregistrer** un rapport vocal (ex: "J'ai fait une intervention chez Monsieur Dupont, 12 rue de la Paix. J'ai posé 50m2 de carrelage et 10ml de plinthes")
2. **Transcrire** automatiquement avec Whisper
3. **Extraire** les données structurées avec GPT-4 (client, produits, quantités)
4. **Valider** et corriger si nécessaire
5. **Créer** le job automatiquement

---

## 📋 **PHASE 1 : ENREGISTREMENT AUDIO** (Jour 1-2)

### **Étape 1.1 : Ajouter les Packages**

```yaml
# pubspec.yaml
dependencies:
  record: ^5.0.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.4
```

Puis exécuter :
```bash
flutter pub get
```

### **Étape 1.2 : Configurer les Permissions**

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSMicrophoneUsageDescription</key>
<string>SiteVoice AI a besoin d'accéder au microphone pour enregistrer vos rapports vocaux</string>
```

### **Étape 1.3 : Créer le Service Audio**

Créer `lib/data/services/audio_recording_service.dart` :

```dart
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  
  // Demander la permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  // Vérifier la permission
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  // Démarrer l'enregistrement
  Future<bool> startRecording() async {
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) return false;
    }
    
    // Créer le chemin du fichier
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';
    
    // Démarrer l'enregistrement
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentRecordingPath!,
    );
    
    return true;
  }
  
  // Arrêter l'enregistrement
  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    return path;
  }
  
  // Vérifier si en cours d'enregistrement
  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }
  
  // Annuler l'enregistrement
  Future<void> cancelRecording() async {
    await _audioRecorder.stop();
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
  
  // Obtenir l'amplitude (pour animation)
  Stream<double> getAmplitudeStream() async* {
    while (await isRecording()) {
      final amplitude = await _audioRecorder.getAmplitude();
      yield amplitude.current;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
```

### **Étape 1.4 : Mettre à Jour le RecordScreen**

Modifier `lib/presentation/screens/record/record_screen.dart` :

```dart
import 'package:flutter/material.dart';
import '../../data/services/audio_recording_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _audioService = AudioRecordingService();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer un Rapport'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation d'onde audio
            if (_isRecording) _buildWaveAnimation(),
            
            const SizedBox(height: 40),
            
            // Durée d'enregistrement
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Bouton d'enregistrement
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : const Color(0xFF3B82F6))
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Bouton Annuler (si en cours d'enregistrement)
            if (_isRecording)
              TextButton(
                onPressed: _cancelRecording,
                child: const Text('Annuler'),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Arrêter et traiter
      final audioPath = await _audioService.stopRecording();
      if (audioPath != null) {
        // TODO: Passer à l'étape suivante (transcription)
        _processAudio(audioPath);
      }
      setState(() => _isRecording = false);
    } else {
      // Démarrer
      final success = await _audioService.startRecording();
      if (success) {
        setState(() => _isRecording = true);
        _startTimer();
      } else {
        _showPermissionError();
      }
    }
  }
  
  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }
  
  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
      return _isRecording;
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }
  
  Widget _buildWaveAnimation() {
    return StreamBuilder<double>(
      stream: _audioService.getAmplitudeStream(),
      builder: (context, snapshot) {
        final amplitude = snapshot.data ?? 0.0;
        return Container(
          height: 100,
          width: 300,
          child: CustomPaint(
            painter: WavePainter(amplitude: amplitude),
          ),
        );
      },
    );
  }
  
  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permission microphone refusée'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Future<void> _processAudio(String audioPath) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // TODO: Upload + Transcription + Extraction
    // Pour l'instant, juste fermer le loader
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();
  }
}

// Painter pour l'animation d'onde
class WavePainter extends CustomPainter {
  final double amplitude;
  
  WavePainter({required this.amplitude});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(0, size.height / 2);
    
    for (var i = 0; i < size.width; i++) {
      final x = i.toDouble();
      final y = size.height / 2 + 
                (amplitude * 50) * 
                Math.sin((i / size.width) * 2 * Math.pi);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}
```

### **✅ Checkpoint Phase 1**

**Tests à faire** :
- [ ] App demande la permission microphone
- [ ] Enregistrement démarre au clic
- [ ] Timer s'incrémente
- [ ] Animation d'onde visible
- [ ] Enregistrement s'arrête au clic stop
- [ ] Fichier audio créé (vérifier avec explorateur de fichiers)
- [ ] Bouton Annuler fonctionne

---

## 📋 **PHASE 2 : UPLOAD SUPABASE** (Jour 2-3)

### **Étape 2.1 : Créer le Bucket Supabase**

Dans le **Dashboard Supabase** :
1. Aller dans **Storage**
2. Cliquer sur **New Bucket**
3. Nom : `audio-recordings`
4. Public : **Non** (coché)
5. Créer

### **Étape 2.2 : Configurer les RLS Policies**

Dans le **SQL Editor** :

```sql
-- Policy pour upload
CREATE POLICY "Users can upload own audio"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'audio-recordings' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] IN (
    SELECT company_id::text FROM users WHERE id = auth.uid()
  )
);

-- Policy pour lecture
CREATE POLICY "Users can read own audio"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'audio-recordings' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] IN (
    SELECT company_id::text FROM users WHERE id = auth.uid()
  )
);
```

### **Étape 2.3 : Créer le Service de Storage**

Créer `lib/data/services/storage_service.dart` :

```dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  
  Future<String> uploadAudio(String filePath) async {
    try {
      // Récupérer le company_id de l'utilisateur
      final userId = _supabase.auth.currentUser!.id;
      final userResponse = await _supabase
        .from('users')
        .select('company_id')
        .eq('id', userId)
        .single();
      
      final companyId = userResponse['company_id'];
      
      // Lire le fichier
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Créer un nom unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.m4a';
      final storagePath = '$companyId/$fileName';
      
      // Upload
      await _supabase.storage
        .from('audio-recordings')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/m4a',
            upsert: false,
          ),
        );
      
      // Retourner le chemin
      return storagePath;
    } catch (e) {
      throw Exception('Erreur upload audio: $e');
    }
  }
  
  Future<String> getPublicUrl(String path) {
    return _supabase.storage
      .from('audio-recordings')
      .createSignedUrl(path, 3600); // URL valide 1h
  }
}
```

### **Étape 2.4 : Intégrer dans RecordScreen**

Modifier la méthode `_processAudio` :

```dart
Future<void> _processAudio(String audioPath) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Upload en cours...'),
        ],
      ),
    ),
  );
  
  try {
    // Upload
    final storageService = StorageService();
    final storagePath = await storageService.uploadAudio(audioPath);
    
    // TODO: Passer à la transcription
    Navigator.of(context).pop(); // Fermer le loader
    
    // Pour l'instant, afficher succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio uploadé: $storagePath'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur upload: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### **✅ Checkpoint Phase 2**

**Tests à faire** :
- [ ] Upload réussit
- [ ] Fichier visible dans Storage Supabase
- [ ] Fichier dans le bon dossier (company_id/)
- [ ] RLS fonctionne (un user ne voit pas les fichiers d'un autre)

---

## 🎯 **PROCHAINES PHASES**

- **Phase 3** : Transcription Whisper (voir ROADMAP.md)
- **Phase 4** : Extraction GPT-4 (voir ROADMAP.md)
- **Phase 5** : Validation Job (voir ROADMAP.md)

---

## 📚 **RESSOURCES**

- [Record Package](https://pub.dev/packages/record)
- [Permission Handler](https://pub.dev/packages/permission_handler)
- [Supabase Storage](https://supabase.com/docs/guides/storage)

---

**📝 Dernière mise à jour : 2025-12-16**

