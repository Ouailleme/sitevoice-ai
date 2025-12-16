# 🔐 Configuration des Variables d'Environnement

## 📋 Variables Nécessaires

### 1. OpenAI API Key

**Où l'obtenir ?**
1. Créer un compte sur https://platform.openai.com
2. Aller dans **API Keys**
3. Créer une nouvelle clé (format: `sk-proj-...`)
4. **Important** : Ajouter des crédits (minimum 5€) dans **Billing**

**Coûts estimés** :
- Whisper (transcription) : ~0.006$ / minute d'audio
- GPT-4 (extraction) : ~0.01$ / requête
- **Budget moyen** : 10€ = ~1000 transcriptions

### 2. Supabase Credentials

**Déjà configurées** dans `lib/main.dart` :
```dart
await Supabase.initialize(
  url: 'https://votreprojet.supabase.co',
  anonKey: 'eyJ...',
);
```

Optionnel : Ajouter aussi dans les env vars pour plus de flexibilité.

---

## 🚀 Méthodes de Configuration

### **Méthode 1 : Fichier `.env.local`** (Recommandé pour dev)

1. Créer un fichier `.env.local` à la racine du projet :

```env
OPENAI_API_KEY=sk-proj-VOTRE_VRAIE_CLE_ICI
WHISPER_MODEL=whisper-1
GPT_MODEL=gpt-4
```

2. Ajouter `.env.local` dans `.gitignore` (déjà fait ✅)

3. Charger avec `--dart-define-from-file` :

```bash
flutter run --dart-define-from-file=.env.local
flutter build apk --dart-define-from-file=.env.local
```

### **Méthode 2 : CLI** (Rapide pour test)

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-proj-...
```

### **Méthode 3 : Android Studio / VS Code**

**Android Studio** :
1. Run → Edit Configurations
2. Additional run args : `--dart-define=OPENAI_API_KEY=sk-proj-...`

**VS Code** (`launch.json`) :
```json
{
  "name": "SiteVoice AI",
  "request": "launch",
  "type": "dart",
  "args": [
    "--dart-define=OPENAI_API_KEY=sk-proj-..."
  ]
}
```

---

## ✅ Vérifier la Configuration

### Dans `main.dart`, ajouter :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Afficher la config (sans exposer les clés)
  EnvConfig.printConfig();
  
  // Valider que tout est OK
  try {
    EnvConfig.validate();
    print('✅ Configuration valide');
  } catch (e) {
    print('❌ Configuration invalide: $e');
  }
  
  // ... reste du code
}
```

### Résultat attendu :

```
🔧 Configuration Environnement:
  - APP_ENV: development
  - OPENAI_API_KEY: sk-proj...1234
  - WHISPER_MODEL: whisper-1
  - GPT_MODEL: gpt-4
  - SUPABASE_URL: https://***co
✅ Configuration valide
```

---

## 🔒 Sécurité

### ✅ Ce qui est fait

- `.env.local` dans `.gitignore`
- Clés jamais exposées dans le code
- Masquage des clés dans les logs
- Validation au démarrage

### ⚠️ À NE PAS FAIRE

- ❌ Commiter les vraies clés dans Git
- ❌ Hardcoder les clés dans le code
- ❌ Logger les clés complètes
- ❌ Partager les clés publiquement

### 💡 Bonnes Pratiques

- ✅ Utiliser `.env.local` pour dev
- ✅ Utiliser des variables d'environnement CI/CD pour prod
- ✅ Rotate les clés régulièrement
- ✅ Monitorer l'usage OpenAI (quota)

---

## 🧪 Tester

### Test 1 : Vérifier que la clé est chargée

```dart
import 'package:sitevoice_ai/core/config/env_config.dart';

void testConfig() {
  print('OpenAI configuré: ${EnvConfig.isOpenAiConfigured}');
  print('Clé (masquée): ${EnvConfig.openAiApiKey.substring(0, 10)}...');
}
```

### Test 2 : Appel Whisper

```dart
final openAiService = OpenAIService();
final transcription = await openAiService.transcribeAudio(audioFile);
print('Transcription: $transcription');
```

Si erreur `401 Unauthorized` → Clé invalide ou quota dépassé.

---

## 🎯 Prochaines Étapes

Maintenant que les variables d'environnement sont configurées :

1. ✅ Créer `EnvConfig`
2. ✅ Documenter `.env.local`
3. 🔜 Implémenter `OpenAIService.transcribeAudio()`
4. 🔜 Implémenter `OpenAIService.extractData()`

**Voir** : `lib/data/services/openai_service.dart`

