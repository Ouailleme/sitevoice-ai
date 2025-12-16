# 📦 Configuration Supabase Storage pour Audio

## 🎯 Objectif

Créer un bucket Supabase Storage pour stocker les enregistrements audio avec les bonnes politiques de sécurité (RLS).

---

## 📝 Étapes de Configuration

### 1. Créer le Bucket `audio-recordings`

**Dashboard Supabase** → **Storage** → **New bucket**

```
Name: audio-recordings
Public: No (privé)
File size limit: 50 MB
Allowed MIME types: audio/*, audio/aac, audio/m4a, audio/mpeg
```

---

### 2. Configurer les RLS Policies

**Dashboard Supabase** → **Storage** → `audio-recordings` → **Policies**

#### Policy 1 : Upload (INSERT)

```sql
CREATE POLICY "Users can upload own company audio recordings"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'audio-recordings'
  AND (storage.foldername(name))[1] IN (
    SELECT company_id::text 
    FROM public.users 
    WHERE id = auth.uid()
  )
);
```

**Explication** : Un utilisateur peut uploader uniquement dans le dossier de sa company.

#### Policy 2 : Lecture (SELECT)

```sql
CREATE POLICY "Users can view own company audio recordings"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'audio-recordings'
  AND (storage.foldername(name))[1] IN (
    SELECT company_id::text 
    FROM public.users 
    WHERE id = auth.uid()
  )
);
```

**Explication** : Un utilisateur peut lire uniquement les fichiers de sa company.

#### Policy 3 : Suppression (DELETE)

```sql
CREATE POLICY "Users can delete own company audio recordings"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'audio-recordings'
  AND (storage.foldername(name))[1] IN (
    SELECT company_id::text 
    FROM public.users 
    WHERE id = auth.uid()
  )
);
```

**Explication** : Un utilisateur peut supprimer uniquement les fichiers de sa company.

---

## 🧪 Test de Configuration

### Test 1 : Upload

```dart
final storageService = StorageService();
final audioPath = '/path/to/recording.aac';
final storagePath = await storageService.uploadAudio(audioPath);
print('Fichier uploadé: $storagePath'); // company_id/timestamp.aac
```

### Test 2 : URL Signée

```dart
final url = await storageService.getSignedUrl(storagePath);
print('URL signée (valide 1h): $url');
```

### Test 3 : Suppression

```dart
await storageService.deleteAudio(storagePath);
print('Fichier supprimé');
```

---

## 📊 Structure des Dossiers

```
audio-recordings/
├── {company_id_1}/
│   ├── 1702834856123.aac
│   ├── 1702834921456.aac
│   └── ...
├── {company_id_2}/
│   ├── 1702835012789.aac
│   └── ...
```

**Avantages** :
- Isolation par company
- Facile de lister/supprimer tous les fichiers d'une company
- RLS basé sur company_id

---

## 🔒 Sécurité

### ✅ Ce qui est protégé

- ✅ Un utilisateur ne peut pas uploader dans le dossier d'une autre company
- ✅ Un utilisateur ne peut pas lire les fichiers d'une autre company
- ✅ Un utilisateur ne peut pas supprimer les fichiers d'une autre company

### ⚠️ Points d'attention

- Le `company_id` doit être présent dans la table `users`
- L'utilisateur doit être authentifié (`auth.uid()` ne doit pas être null)
- Les fichiers sont stockés avec leur timestamp → facile à retrouver

---

## 💡 Utilisation dans l'App

### Flow Complet : Enregistrement → Upload → Transcription

```dart
// 1. Enregistrer l'audio
final audioService = AudioService();
await audioService.startRecording();
// ... utilisateur enregistre ...
final localPath = await audioService.stopRecording();

// 2. Upload vers Supabase Storage
final storageService = StorageService();
final storagePath = await storageService.uploadAudio(localPath);

// 3. Sauvegarder le chemin dans la BDD (table jobs)
await supabase.from('jobs').insert({
  'audio_file_path': storagePath,
  'status': 'pending_transcription',
  // ... autres champs
});

// 4. Optionnel : Supprimer le fichier local
await File(localPath).delete();
```

---

## 🚀 Prochaine Étape

Maintenant que l'upload fonctionne, on peut :

1. ✅ Uploader l'audio vers Supabase
2. 🔜 Récupérer l'URL signée
3. 🔜 Envoyer à OpenAI Whisper pour transcription
4. 🔜 Traiter avec GPT-4 pour extraction

**Voir** : `OPENAI_SETUP.md` pour la configuration des clés API.

