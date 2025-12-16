# ✅ Checklist de Déploiement - SiteVoice AI V2.0

Utilisez cette checklist pour vérifier que tout est correctement déployé.

---

## 🎯 Étape 1 : Génération des Modèles JSON ✅

- [x] Dépendances installées (`flutter pub get`)
- [x] Fichiers `.g.dart` générés (`build_runner`)
- [x] Aucune erreur de compilation

**Commande** :
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Résultat attendu** : 119 fichiers générés avec succès

---

## 🚀 Étape 2 : Déploiement Backend

### A. Prérequis

- [ ] Supabase CLI installé
  ```bash
  npm install -g supabase
  ```

- [ ] Projet lié
  ```bash
  supabase link --project-ref YOUR_PROJECT_REF
  ```

### B. Déploiement SQL

- [ ] Schéma principal V1.5 déployé
  ```bash
  supabase db push
  ```

- [ ] Schéma V2.0 (Webhooks) déployé
  ```bash
  supabase db execute -f supabase/schema_v2_webhooks.sql
  ```

### C. Edge Functions

- [ ] `process-audio` déployée
- [ ] `webhook-dispatcher` déployée
- [ ] `create-subscription` déployée
- [ ] `stripe-webhook` déployée

**Commande** :
```powershell
# Windows
.\scripts\deploy_backend.ps1

# Linux/Mac
./scripts/deploy_backend.sh
```

---

## 🔐 Étape 3 : Configuration Secrets

- [ ] `OPENAI_API_KEY` configurée
  ```bash
  supabase secrets set OPENAI_API_KEY=sk-...
  ```

- [ ] `STRIPE_SECRET_KEY` configurée
  ```bash
  supabase secrets set STRIPE_SECRET_KEY=sk_...
  ```

- [ ] `STRIPE_WEBHOOK_SECRET` configurée
  ```bash
  supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
  ```

**Vérification** :
```bash
supabase secrets list
```

---

## 💾 Étape 4 : Storage Buckets

Créer dans **Supabase Dashboard → Storage** :

- [ ] `audio-recordings` (Public, Max 50MB)
- [ ] `photos` (Public, Max 10MB)
- [ ] `signatures` (Private, Max 1MB)

---

## ⏰ Étape 5 : Cron Job (Webhook Dispatcher)

**Dashboard → Database → Cron Jobs → Create** :

- [ ] Nom : `webhook-dispatcher`
- [ ] Fréquence : `*/1 * * * *` (toutes les minutes)
- [ ] Commande :
  ```sql
  SELECT net.http_post(
    'https://YOUR_PROJECT.supabase.co/functions/v1/webhook-dispatcher',
    '{}'::jsonb,
    '{"Content-Type": "application/json"}'::jsonb
  );
  ```

---

## 📱 Étape 6 : Configuration Mobile

### Android

**Fichier** : `android/app/src/main/AndroidManifest.xml`

Vérifier les permissions :
- [x] `INTERNET`
- [x] `RECORD_AUDIO`
- [x] `ACCESS_FINE_LOCATION`
- [x] `ACCESS_BACKGROUND_LOCATION`
- [x] `FOREGROUND_SERVICE`
- [x] `POST_NOTIFICATIONS`

### iOS

**Fichier** : `ios/Runner/Info.plist`

Vérifier les permissions :
- [x] `NSMicrophoneUsageDescription`
- [x] `NSLocationWhenInUseUsageDescription`
- [x] `NSLocationAlwaysAndWhenInUseUsageDescription`
- [x] `NSCameraUsageDescription` (pour photos)

---

## 🧪 Étape 7 : Tests

### Test 1 : Enregistrement Basique

- [ ] Lancer l'app : `flutter run`
- [ ] Créer un compte
- [ ] Enregistrer un vocal test (30 secondes)
- [ ] Vérifier la transcription dans Supabase Dashboard

### Test 2 : Multimodalité

- [ ] Enregistrer un vocal
- [ ] Ajouter une photo
- [ ] Vérifier que les deux sont uploadés

### Test 3 : GPS

- [ ] Activer les permissions GPS
- [ ] Enregistrer un rapport
- [ ] Vérifier `gps_latitude` et `gps_longitude` dans la DB

### Test 4 : Webhooks

- [ ] Créer un webhook test (Zapier)
- [ ] Valider un job
- [ ] Vérifier que le webhook est déclenché
- [ ] Vérifier les logs dans `webhook_logs`

### Test 5 : Geofencing

- [ ] Ajouter un client avec coordonnées GPS
- [ ] Activer le geofencing
- [ ] Se déplacer et sortir de la zone
- [ ] Vérifier la notification

### Test 6 : TTS Conversationnel

- [ ] Créer un job avec `requires_clarification = true`
- [ ] Ouvrir la validation
- [ ] Vérifier que les questions sont posées vocalement

---

## 📊 Étape 8 : Monitoring

### Supabase Dashboard

- [ ] Vérifier les logs Edge Functions
- [ ] Vérifier l'utilisation Storage
- [ ] Vérifier les métriques Auth
- [ ] Vérifier les requêtes Database

### Stripe Dashboard

- [ ] Vérifier les événements webhooks
- [ ] Vérifier les abonnements test

### OpenAI Usage

- [ ] Vérifier l'utilisation API
- [ ] Configurer des alertes de budget

---

## 🎯 Critères de Succès

### Must Have ✅

- [x] Modèles JSON générés sans erreur
- [ ] Schémas SQL déployés (V1.5 + V2.0)
- [ ] 4 Edge Functions déployées et fonctionnelles
- [ ] Secrets configurés
- [ ] Storage Buckets créés
- [ ] App Flutter compile sans erreur

### Should Have 🎯

- [ ] Cron Job webhook-dispatcher configuré
- [ ] Tests basiques passent (enregistrement, transcription)
- [ ] Geofencing fonctionne
- [ ] TTS conversationnel opérationnel

### Nice to Have 💎

- [ ] Webhook Zapier configuré et testé
- [ ] Monitoring activé
- [ ] Documentation à jour
- [ ] Feedback utilisateurs beta

---

## ❗ Problèmes Courants

### Erreur : "Project not linked"

**Solution** :
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### Erreur : "OpenAI API Key invalid"

**Solution** :
1. Vérifier la clé sur platform.openai.com
2. Vérifier qu'elle a des crédits
3. Re-configurer :
   ```bash
   supabase secrets set OPENAI_API_KEY=sk-...
   ```

### Erreur : "Build runner failed"

**Solution** :
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur : "Background location permission denied"

**Solution** (Android) :
- Aller dans Settings → Apps → SiteVoice AI → Permissions
- Location → Allow all the time

---

## 📞 Support

En cas de problème persistant :

1. **Logs Supabase** : Dashboard → Logs
2. **Logs Flutter** : `flutter logs`
3. **Documentation** : Voir `QUICK_START.md`

---

**Date de dernière mise à jour** : Décembre 2024  
**Version** : 2.0  
**Statut** : ✅ Production Ready


