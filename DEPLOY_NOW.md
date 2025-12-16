# 🚀 DÉPLOYER MAINTENANT - Guide Ultra-Rapide

## ✅ Prérequis OK

- ✅ Node.js : **v24.12.0**
- ✅ npm : **v11.6.2**
- ✅ npx supabase : **v2.67.1**

**Vous êtes prêt à déployer !** 💪

---

## 🎯 Option 1 : Déploiement Automatique (Recommandé)

### Étape 1 : Créer le Projet Supabase (5 min)

**Si vous n'avez pas encore de projet** :

1. Aller sur : **https://supabase.com**
2. **Sign Up** / **Login**
3. **New Project** :
   - Organization : Créer si besoin
   - Name : `SiteVoice AI`
   - Database Password : `gr0sc4c4k1pu3` 📝
   - Region : `Europe West (Ireland)`
   - Plan : Free
4. **Create new project**
5. ⏳ Attendre 2-3 minutes...

### Étape 2 : Récupérer le Reference ID (1 min)

Dans le Dashboard Supabase :
1. **Settings** (icône engrenage) → **General**
2. Copier le **Reference ID** (format : `abcdefghijklmnop`)

### Étape 3 : Lancer le Script (10 min)

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
.\scripts\deploy_backend_npx.ps1
```

**Le script va** :
1. ✅ Vérifier Node.js et npm
2. 🔗 Vous demander le Reference ID (coller celui copié)
3. 📊 Déployer le schéma SQL V1.5
4. 🔌 Déployer le schéma SQL V2.0 (Webhooks)
5. ⚡ Déployer les 4 Edge Functions
6. 🔐 Vous rappeler de configurer les secrets

### Étape 4 : Configurer les Secrets (3 min)

Dans le Dashboard Supabase :
1. **Settings** → **Edge Functions** → **Secrets**
2. Ajouter :
   - `OPENAI_API_KEY` : `sk-proj-...` (votre clé OpenAI)
   - `STRIPE_SECRET_KEY` : `sk_test_...` (votre clé Stripe)
   - `STRIPE_WEBHOOK_SECRET` : `whsec_...` (webhook Stripe)

### Étape 5 : Créer les Storage Buckets (2 min)

Dashboard → **Storage** → **Create bucket**

Créer 3 buckets :
1. `audio-recordings` (Public, 50 MB)
2. `photos` (Public, 10 MB)
3. `signatures` (Private, 1 MB)

### Étape 6 : Créer le fichier .env (1 min)

À la racine du projet :

```env
SUPABASE_URL=https://VOTRE_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
OPENAI_API_KEY=sk-proj-...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

(Remplacer avec vos vraies valeurs depuis Dashboard → Settings → API)

### Étape 7 : Tester ! 🎉

```powershell
flutter run
```

---

## 🎯 Option 2 : Déploiement Manuel (Backup)

Si le script ne fonctionne pas, voir `DEPLOY_MANUAL_DASHBOARD.md`

---

## ⚡ ACTION IMMÉDIATE

**MAINTENANT** :

1. **Ouvrir** : https://supabase.com
2. **Créer** un projet "SiteVoice AI"
3. **Copier** le Reference ID
4. **Lancer** : `.\scripts\deploy_backend_npx.ps1`

**Temps total** : 20 minutes chrono ! ⏱️

---

## ❓ Troubleshooting

### "npx demande d'installer supabase à chaque fois"
✅ **Normal !** C'est le comportement de npx. Ça met en cache après.

### "Error: Not authorized"
→ Vérifiez votre Reference ID et mot de passe

### "Function deployment failed"
→ Vérifiez que vous avez bien créé le projet Supabase

### "Schema already exists"
✅ **Normal !** Si vous avez déjà déployé le schéma avant

---

## 🎬 LANCEZ LE SCRIPT MAINTENANT

```powershell
.\scripts\deploy_backend_npx.ps1
```

**Et suivez les instructions !** 🚀

---

## 📞 Besoin d'Aide ?

Dites-moi où vous êtes bloqué :
- "J'ai créé le projet Supabase"
- "Le script est lancé"
- "Ça ne marche pas à l'étape X"

Je vous guide étape par étape ! 🤝

