# Guide de Déploiement des Edge Functions Supabase

## 📋 Prérequis

1. **Installer Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Se connecter à Supabase**
   ```bash
   supabase login
   ```

3. **Lier le projet**
   ```bash
   supabase link --project-ref dndjtcxypqnsyjzlzbxh
   ```

## 🚀 Déployer l'Edge Function

### 1. Configurer les variables d'environnement

Dans Supabase Dashboard → Project Settings → Edge Functions → Secrets, ajouter :

- `OPENAI_API_KEY` : Votre clé API OpenAI
- `SUPABASE_URL` : (Déjà défini automatiquement)
- `SUPABASE_SERVICE_ROLE_KEY` : (Déjà défini automatiquement)

### 2. Déployer la fonction

```bash
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
supabase functions deploy process-audio-job
```

### 3. Vérifier le déploiement

```bash
supabase functions list
```

Vous devriez voir `process-audio-job` dans la liste.

## 🧪 Tester l'Edge Function

### Test manuel via curl

```bash
curl -i --location --request POST 'https://dndjtcxypqnsyjzlzbxh.supabase.co/functions/v1/process-audio-job' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"jobId":"EXISTING_JOB_ID"}'
```

### Test depuis l'app Flutter

L'Edge Function sera automatiquement appelée par le `SyncService` lors de la synchronisation d'un job.

## 🔄 Intégration avec l'app

### Modifier `SyncService._syncJob()` pour appeler l'Edge Function

Dans `lib/data/services/sync_service.dart`, ajouter :

```dart
/// Appeler l'Edge Function pour traiter l'audio
Future<void> _processJobWithAI(String jobId) async {
  try {
    final response = await _supabase.functions.invoke(
      'process-audio-job',
      body: {'jobId': jobId},
    );

    if (response.status != 200) {
      throw ServerException(
        message: 'Erreur Edge Function: ${response.data}',
        code: 'EDGE_FUNCTION_ERROR',
      );
    }

    TelemetryService.logInfo('Job $jobId traité par l\'IA avec succès');
  } catch (e, stack) {
    TelemetryService.logError('Erreur traitement IA job $jobId', e, stack);
    rethrow;
  }
}
```

### Appeler depuis `_syncJob()`

```dart
Future<void> _syncJob(SyncQueueItem item) async {
  switch (item.operation) {
    case 'create':
      // Upload audio, créer le job dans Supabase
      await _supabase.from('jobs').insert(item.payload);
      
      // Appeler l'Edge Function pour le traitement IA
      await _processJobWithAI(item.entityId);
      break;
    // ...
  }
}
```

## 📊 Monitoring

### Voir les logs de l'Edge Function

```bash
supabase functions logs process-audio-job
```

### Dashboard Supabase

- Allez dans **Edge Functions** → **process-audio-job**
- Cliquez sur **Logs** pour voir l'historique d'exécution

## 🔐 Sécurité

- L'Edge Function utilise la `SERVICE_ROLE_KEY` qui contourne les RLS
- Assurez-vous de valider le `jobId` et que l'utilisateur a les droits
- L'Edge Function est appelée côté serveur, donc les clés API sont sécurisées

## 💡 Optimisations futures

1. **Rate limiting** : Limiter le nombre d'appels par utilisateur
2. **Retry logic** : Réessayer automatiquement en cas d'échec
3. **Webhooks** : Notifier l'app quand le traitement est terminé
4. **Caching** : Mettre en cache les clients/produits existants

## 🆘 Dépannage

### Erreur "Function not found"

```bash
supabase functions deploy process-audio-job --no-verify-jwt
```

### Erreur CORS

Vérifier que `corsHeaders` est bien retourné dans toutes les réponses.

### Erreur OpenAI API

- Vérifier que `OPENAI_API_KEY` est bien configuré dans les secrets
- Vérifier les crédits OpenAI restants

### Timeout

Par défaut, les Edge Functions ont un timeout de 2 minutes. Pour les fichiers audio longs :

```bash
supabase functions deploy process-audio-job --timeout 300
```

---

**✅ Une fois déployé, l'app Flutter appellera automatiquement cette fonction lors de la synchronisation d'un nouveau job audio !**

