# 🔧 Guide : Résoudre le Problème Gradle avec le Package `record`

**Problème** : `jlink.exe` échoue lors de la compilation du package `record_android`

---

## 🎯 **SOLUTION RECOMMANDÉE : Mise à Jour Gradle**

### **Étape 1 : Mettre à Jour `android/build.gradle`**

```bash
# Ouvrir le fichier
code android/build.gradle
```

Modifier :

```gradle
buildscript {
    ext.kotlin_version = '1.9.0' // Avant: 1.7.x
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0' // Avant: 7.x.x
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

### **Étape 2 : Mettre à Jour `android/gradle/wrapper/gradle-wrapper.properties`**

```bash
# Ouvrir le fichier
code android/gradle/wrapper/gradle-wrapper.properties
```

Modifier :

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

(Avant: `gradle-7.5-all.zip` ou inférieur)

### **Étape 3 : Mettre à Jour `android/app/build.gradle`**

Vérifier que `compileSdkVersion` et `targetSdkVersion` sont à jour :

```gradle
android {
    compileSdkVersion 34 // Ou plus récent
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### **Étape 4 : Nettoyer et Rebuilder**

```powershell
# Nettoyer le projet
cd android
.\gradlew clean
cd ..
flutter clean

# Réinstaller les dépendances
flutter pub get

# Rebuild
flutter build apk --debug
```

---

## 🔄 **SOLUTION ALTERNATIVE 1 : Changer de JDK**

Si la mise à jour Gradle ne fonctionne pas :

### **Installer JDK 17**

1. Télécharger : https://adoptium.net/temurin/releases/?version=17
2. Installer dans `C:\Program Files\Java\jdk-17`
3. Configurer `JAVA_HOME` :

```powershell
# PowerShell (Temporaire)
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"

# Vérifier
java -version
```

4. Mettre à jour les variables d'environnement système (Permanent) :
   - Ouvrir "Modifier les variables d'environnement système"
   - Modifier `JAVA_HOME` → `C:\Program Files\Java\jdk-17`
   - Redémarrer le terminal

5. Rebuild :

```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 🔄 **SOLUTION ALTERNATIVE 2 : Utiliser `flutter_sound`**

Si les problèmes persistent, changer de package :

### **Étape 1 : Remplacer le Package**

```yaml
# pubspec.yaml
dependencies:
  # record: ^5.1.2  # Remplacer par flutter_sound
  flutter_sound: ^9.5.0
```

### **Étape 2 : Adapter le Code**

Créer `lib/data/services/audio_recording_service_sound.dart` :

```dart
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AudioRecordingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording(String path) async {
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }

    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) return false;
    }

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
      bitRate: 128000,
      sampleRate: 44100,
    );

    return true;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stopRecorder();
  }

  Future<void> pauseRecording() async {
    await _recorder.pauseRecorder();
  }

  Future<void> resumeRecording() async {
    await _recorder.resumeRecorder();
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}
```

### **Étape 3 : Mettre à Jour les Imports**

Dans `lib/data/services/audio_service.dart` :

```dart
import 'audio_recording_service_sound.dart'; // Au lieu de audio_recording_service.dart
```

### **Étape 4 : Rebuild**

```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 🔄 **SOLUTION ALTERNATIVE 3 : Build sur Linux/Mac**

Le problème `jlink.exe` est spécifique à Windows.

### **Option A : WSL (Windows Subsystem for Linux)**

1. Installer WSL :
   ```powershell
   wsl --install
   ```

2. Installer Flutter dans WSL :
   ```bash
   sudo snap install flutter --classic
   ```

3. Cloner le projet et builder :
   ```bash
   cd /mnt/c/Users/yvesm/Desktop/
   flutter build apk --debug
   ```

### **Option B : VM Linux**

Utiliser une VM (VirtualBox, VMware) avec Ubuntu.

### **Option C : CI/CD**

Utiliser GitHub Actions ou GitLab CI avec un runner Linux.

---

## 🧪 **VÉRIFIER LA CONFIGURATION**

### **Vérifier la Version Gradle**

```powershell
cd android
.\gradlew -v
```

**Attendu** : Gradle 8.0 ou supérieur

### **Vérifier le JDK**

```powershell
java -version
```

**Attendu** : JDK 17 ou supérieur

### **Vérifier Flutter Doctor**

```powershell
flutter doctor -v
```

**Attendu** : Aucune erreur Android

---

## 📊 **MATRICE DE COMPATIBILITÉ**

| Gradle | JDK | Flutter | `record` | Statut |
|--------|-----|---------|----------|--------|
| 7.5 | 11 | 3.16+ | 5.x | ⚠️ Problème |
| 8.0 | 17 | 3.16+ | 5.x | ✅ OK |
| 8.0 | 21 | 3.16+ | 5.x | ✅ OK |
| 7.5 | 17 | 3.16+ | - | ⚠️ Instable |

---

## 🆘 **SI RIEN NE FONCTIONNE**

### **Option : Temporairement Désactiver l'Audio**

Comme fait précédemment, commenter le package `record` et utiliser un placeholder :

```yaml
# pubspec.yaml
# record: ^5.1.2  # Temporairement désactivé
```

Puis remplacer `AudioRecordingService` par un mock qui retourne des erreurs explicites.

**⚠️ Ceci est une solution temporaire pour continuer le développement des autres features.**

---

## 📞 **SUPPORT**

- **Issue GitHub du package `record`** : https://github.com/llfbandit/record/issues
- **Flutter Doctor** : `flutter doctor -v`
- **Logs détaillés** : `flutter build apk --debug --verbose`

---

**🎯 Recommandation : Essayer Solution 1 (Mise à Jour Gradle) en premier**


