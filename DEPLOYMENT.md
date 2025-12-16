# 🚀 Guide de Déploiement - SiteVoice AI

Ce document explique comment déployer SiteVoice AI en production.

## 📋 Prérequis

- [ ] Compte Supabase (avec projet créé)
- [ ] Compte OpenAI (avec API Key)
- [ ] Compte Stripe (avec clés API)
- [ ] Compte développeur Apple (pour iOS)
- [ ] Compte développeur Google Play (pour Android)

---

## 1️⃣ Configuration Supabase

### A. Créer le projet

1. Allez sur [supabase.com](https://supabase.com)
2. Créez un nouveau projet
3. Notez l'URL et les clés API

### B. Déployer le schéma SQL

```bash
# Se connecter au projet
supabase link --project-ref YOUR_PROJECT_REF

# Exécuter le schéma
supabase db push
```

Ou manuellement via le SQL Editor dans Supabase :
- Copier le contenu de `supabase/schema.sql`
- Exécuter dans l'éditeur SQL

### C. Créer le bucket Storage

1. Aller dans **Storage** > **Create Bucket**
2. Nom : `audio-recordings`
3. Public : **Oui**
4. File size limit : 50MB

### D. Déployer les Edge Functions

```bash
# Déployer process-audio
supabase functions deploy process-audio --no-verify-jwt

# Déployer create-subscription
supabase functions deploy create-subscription --no-verify-jwt

# Déployer stripe-webhook
supabase functions deploy stripe-webhook --no-verify-jwt
```

### E. Configurer les secrets

```bash
# OpenAI
supabase secrets set OPENAI_API_KEY=sk-...

# Stripe
supabase secrets set STRIPE_SECRET_KEY=sk_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## 2️⃣ Configuration OpenAI

1. Créer une API Key sur [platform.openai.com](https://platform.openai.com)
2. Ajouter des crédits (minimum 10$)
3. Copier la clé dans les secrets Supabase

**Coûts estimés :**
- Whisper : ~0.006$ par minute d'audio
- GPT-4o : ~0.01$ par requête
- **Budget mensuel recommandé** : 50-100$ pour 1000 interventions/mois

---

## 3️⃣ Configuration Stripe

### A. Créer le compte

1. Créer un compte sur [stripe.com](https://stripe.com)
2. Activer les paiements en EUR
3. Récupérer les clés API (Test + Production)

### B. Créer le produit d'abonnement

1. **Produits** > **Ajouter un produit**
2. Nom : `SiteVoice AI - Abonnement Mensuel`
3. Prix : 29€/mois
4. Récurrent : Oui
5. Période : Mensuel

### C. Configurer les Webhooks

1. **Développeurs** > **Webhooks** > **Ajouter un endpoint**
2. URL : `https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook`
3. Événements à écouter :
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
4. Copier le **Signing Secret** dans les secrets Supabase

---

## 4️⃣ Configuration Flutter

### A. Variables d'environnement

Créer un fichier `.env` à la racine :

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
STRIPE_PUBLISHABLE_KEY=pk_live_...
```

### B. Build Release

**Android :**
```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

**iOS :**
```bash
flutter build ios --release
```

---

## 5️⃣ Déploiement App Store & Google Play

### A. Google Play Store

1. Créer une application dans la Console Google Play
2. Remplir les informations (titre, description, captures)
3. Uploader l'APK/AAB
4. Soumettre pour review

**Checklist :**
- [ ] Package name unique
- [ ] Icône 512x512
- [ ] Captures d'écran (5 minimum)
- [ ] Description complète
- [ ] Politique de confidentialité

### B. Apple App Store

1. Créer une application dans App Store Connect
2. Uploader via Xcode ou Transporter
3. Remplir les métadonnées
4. Soumettre pour review

**Checklist :**
- [ ] Bundle ID unique
- [ ] Certificats de développement/distribution
- [ ] Provisioning profiles
- [ ] Icône 1024x1024
- [ ] Captures d'écran pour tous les devices
- [ ] Privacy Policy URL

---

## 6️⃣ Monitoring & Maintenance

### A. Supabase Dashboard

- **Database** : Surveiller les requêtes lentes
- **Storage** : Vérifier l'utilisation de l'espace
- **Auth** : Suivre les connexions
- **Edge Functions** : Logs et erreurs

### B. Stripe Dashboard

- **Paiements** : Suivre les transactions
- **Abonnements** : Taux de churn
- **Disputes** : Gérer les litiges

### C. OpenAI Usage

- **Dashboard** > **Usage** : Suivre les coûts
- Mettre en place des alertes si > budget

### D. Sentry (optionnel)

Si activé, suivre les erreurs en temps réel.

---

## 7️⃣ Checklist de Déploiement

### Avant le lancement

- [ ] Tests E2E passent
- [ ] Base de données migrée
- [ ] Edge Functions déployées et testées
- [ ] Secrets configurés
- [ ] Stripe en mode Production
- [ ] App signée et prête
- [ ] Privacy Policy publiée
- [ ] Terms of Service publiés

### Le jour du lancement

- [ ] Désactiver les logs de debug
- [ ] Activer le monitoring (Sentry)
- [ ] Préparer le support client
- [ ] Communiquer aux utilisateurs beta

### Après le lancement

- [ ] Surveiller les erreurs
- [ ] Répondre aux reviews
- [ ] Collecter les feedbacks
- [ ] Planifier les updates

---

## 🆘 Support & Contact

En cas de problème :
1. Vérifier les logs Supabase
2. Vérifier les logs Stripe
3. Consulter la documentation

**Ressources utiles :**
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Docs](https://docs.flutter.dev)
- [Stripe Docs](https://stripe.com/docs)


