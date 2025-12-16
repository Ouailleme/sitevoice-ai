# 📱 Guide de Test Complet - SiteVoice AI

## ✅ CE QUI EST IMPLÉMENTÉ

### 🎤 **Enregistrement Audio**
- ✅ Interface RecordScreen avec boutons Play/Pause/Stop
- ✅ Timer en temps réel
- ✅ Animation onde sonore
- ✅ Sauvegarde locale immédiate (offline-first)
- ✅ Dialog de confirmation après enregistrement

### 🔄 **Synchronisation Offline-First**
- ✅ Queue de synchronisation Hive
- ✅ Upload automatique vers Supabase Storage
- ✅ Détection de connectivité
- ✅ Retry logic en cas d'échec
- ✅ Synchronisation périodique (toutes les 5 min)

### 🤖 **Traitement IA (Edge Function)**
- ✅ Edge Function TypeScript (`process-audio-job`)
- ✅ Transcription Whisper API
- ✅ Extraction structurée GPT-4
- ✅ Reconnaissance clients/produits existants
- ✅ Score de confiance

### 📋 **Gestion des Jobs**
- ✅ Liste des interventions (JobsListScreen)
- ✅ Statuts (En attente, Traitement, Traité, Erreur)
- ✅ Détail d'une intervention (JobDetailScreen)
- ✅ Player audio intégré
- ✅ Affichage transcription
- ✅ Affichage données extraites

### 🎨 **Interface**
- ✅ Design Material 3
- ✅ Navigation bottom tabs
- ✅ Animations et feedback visuel
- ✅ Pull-to-refresh
- ✅ Indicateurs de confiance IA

---

## 🧪 **PLAN DE TEST COMPLET**

### **Phase 1 : Test Enregistrement Audio**

#### Test 1.1 : Enregistrement Simple
1. Ouvrir l'app sur le téléphone
2. Cliquer sur le bouton **Mic** (en bas à droite de l'écran d'accueil)
3. Appuyer sur le bouton rouge pour démarrer
4. Parler pendant 10-15 secondes :
   ```
   "Intervention chez Monsieur Dupont, 12 rue de la Paix à Paris.
   J'ai posé 50 mètres carrés de carrelage à 30 euros le mètre carré.
   Le client est satisfait, tout s'est bien passé."
   ```
5. Cliquer sur **Terminer**
6. Vérifier que le dialog de confirmation s'affiche
7. Cliquer sur "Retour à l'accueil"

**✅ Résultat attendu** :
- Timer affiche la durée
- Le dialog confirme l'enregistrement
- Aucune erreur ne s'affiche

#### Test 1.2 : Pause/Resume
1. Démarrer un enregistrement
2. Cliquer sur **Pause**
3. Attendre 5 secondes
4. Cliquer sur **Resume**
5. Continuer à parler
6. Terminer l'enregistrement

**✅ Résultat attendu** :
- Le timer se met en pause puis reprend
- L'enregistrement est continu

#### Test 1.3 : Annulation
1. Démarrer un enregistrement
2. Parler 5 secondes
3. Cliquer sur **Annuler**
4. Confirmer l'annulation

**✅ Résultat attendu** :
- Le dialog de confirmation s'affiche
- L'enregistrement est supprimé
- Retour à l'écran précédent

---

### **Phase 2 : Test Synchronisation Offline**

#### Test 2.1 : Mode Offline
1. **Activer le mode avion** sur le téléphone
2. Faire un enregistrement vocal
3. Cliquer sur "Terminer"
4. Vérifier le message "sera synchronisé dès que possible"
5. Aller dans l'onglet **Jobs**
6. Vérifier que le job apparaît avec le statut "En attente" (orange)
7. **Désactiver le mode avion**
8. Attendre 10-20 secondes (la sync devrait se déclencher)
9. Rafraîchir la liste (pull-to-refresh)

**✅ Résultat attendu** :
- Le job est visible même en mode avion
- Après connexion, le statut passe à "Traitement..." puis "Traité"
- Le score de confiance IA apparaît

#### Test 2.2 : Multi-enregistrements Offline
1. Activer le mode avion
2. Faire 3 enregistrements audio différents
3. Vérifier que les 3 apparaissent dans la liste Jobs
4. Désactiver le mode avion
5. Attendre la synchronisation automatique

**✅ Résultat attendu** :
- Les 3 jobs sont synchronisés un par un
- Tous passent au statut "Traité"

---

### **Phase 3 : Test Traitement IA**

#### Test 3.1 : Extraction Simple
1. Faire un enregistrement avec des infos claires :
   ```
   "Intervention chez Monsieur Martin, 45 avenue des Champs à Lyon.
   Pose de 30 mètres carrés de parquet à 40 euros le mètre carré.
   Plus 2 heures de main d'œuvre à 50 euros l'heure.
   Le chantier est terminé, le client est content."
   ```
2. Attendre la synchronisation (20-30 secondes)
3. Aller dans **Jobs**
4. Cliquer sur le job
5. Vérifier :
   - Client : "Monsieur Martin"
   - Adresse : "45 avenue des Champs à Lyon"
   - Produits : 2 lignes (parquet + main d'œuvre)
   - Notes : "Le chantier est terminé, le client est content"
   - Score de confiance > 80%

**✅ Résultat attendu** :
- Toutes les données sont correctement extraites
- Le score de confiance est élevé (vert)

#### Test 3.2 : Extraction Complexe
1. Faire un enregistrement avec des infos floues :
   ```
   "Euh, j'étais chez un client, je crois que c'est Durand ou Dupont,
   rue quelque chose à Paris, j'ai mis du carrelage, peut-être 20 ou 30 mètres,
   je sais plus trop. Ça a coûté environ 600 euros."
   ```
2. Vérifier que le score de confiance est bas (orange ou rouge)
3. Vérifier que les notes contiennent les informations ambiguës

**✅ Résultat attendu** :
- Score de confiance < 60% (orange)
- Les données sont extraites mais avec des incertitudes

---

### **Phase 4 : Test Interface Jobs**

#### Test 4.1 : Liste des Jobs
1. Aller dans l'onglet **Jobs**
2. Vérifier que tous les jobs apparaissent
3. Vérifier les statuts (badges colorés)
4. Vérifier les scores de confiance (pourcentages)
5. Faire un **pull-to-refresh**

**✅ Résultat attendu** :
- Liste affichée avec cards design
- Statuts clairs et colorés
- Refresh fonctionne

#### Test 4.2 : Détail d'un Job
1. Cliquer sur un job "Traité"
2. Vérifier les sections :
   - **Statut** (avec score de confiance)
   - **Player audio** (tester Play/Pause)
   - **Client** (nom + adresse)
   - **Transcription** (texte complet)
   - **Produits** (liste avec quantités et prix)
   - **Notes**

**✅ Résultat attendu** :
- Toutes les sections s'affichent
- Le player audio fonctionne
- Les données sont lisibles

#### Test 4.3 : Audio Player
1. Dans le détail d'un job, cliquer sur **Play**
2. Vérifier que la barre de progression avance
3. Vérifier que le temps s'affiche (00:15 / 00:30)
4. Cliquer sur **Pause**
5. Déplacer le curseur de la barre de progression
6. Reprendre la lecture

**✅ Résultat attendu** :
- L'audio se lit correctement
- La barre de progression est synchronisée
- Le seek fonctionne

---

### **Phase 5 : Test Edge Function** (optionnel, nécessite Supabase CLI)

#### Prérequis
```bash
npm install -g supabase
supabase login
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
supabase link --project-ref dndjtcxypqnsyjzlzbxh
```

#### Déploiement
```bash
supabase functions deploy process-audio-job
```

#### Test Edge Function
```bash
# Récupérer un jobId depuis l'app
curl -i --location --request POST 'https://dndjtcxypqnsyjzlzbxh.supabase.co/functions/v1/process-audio-job' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuZGp0Y3h5cHFuc3lqemx6YnhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MzcwNzUsImV4cCI6MjA4MTMxMzA3NX0.t_WPgNs15d5bBmfoAzNBnfFdQABgoDKL_oeNaVKe0N4' \
  --header 'Content-Type: application/json' \
  --data '{"jobId":"VOTRE_JOB_ID"}'
```

#### Voir les logs
```bash
supabase functions logs process-audio-job
```

**✅ Résultat attendu** :
- La fonction retourne `200 OK`
- Le job est mis à jour avec la transcription et les données extraites

---

## 🐛 **PROBLÈMES CONNUS & SOLUTIONS**

### Problème 1 : Téléphone non détecté par ADB
**Solution** : Installer l'APK manuellement
1. Copier `build\app\outputs\flutter-apk\app-debug.apk` sur le téléphone
2. Ouvrir le fichier depuis le téléphone
3. Autoriser l'installation depuis sources inconnues

### Problème 2 : Edge Function ne s'exécute pas
**Causes possibles** :
- `OPENAI_API_KEY` non configurée dans Supabase
- Fichier audio trop volumineux (timeout)
- Crédits OpenAI épuisés

**Solution** :
1. Vérifier les secrets dans Supabase Dashboard → Project Settings → Edge Functions
2. Vérifier les logs : `supabase functions logs process-audio-job`
3. Vérifier les crédits OpenAI : https://platform.openai.com/usage

### Problème 3 : Jobs ne se synchronisent pas
**Solution** :
1. Vérifier la connexion internet
2. Forcer la synchronisation :
   - Aller dans Jobs
   - Pull-to-refresh
3. Vérifier les logs de l'app (logcat)

### Problème 4 : Score de confiance toujours bas
**Causes** :
- Enregistrement trop court
- Bruit de fond
- Informations manquantes (client, produits, quantités)

**Solution** :
- Parler clairement et lentement
- Mentionner explicitement : client, adresse, produits, quantités, prix

---

## 📊 **MÉTRIQUES DE SUCCÈS**

| Test | Objectif | Statut |
|------|----------|--------|
| Enregistrement audio | Fichier créé en local | ⏳ À tester |
| Synchronisation | Upload vers Supabase | ⏳ À tester |
| Transcription | Texte lisible | ⏳ À tester |
| Extraction | Données structurées | ⏳ À tester |
| Score confiance | > 80% pour infos claires | ⏳ À tester |
| Mode offline | Jobs visibles hors ligne | ⏳ À tester |
| Player audio | Lecture fluide | ⏳ À tester |

---

## 🚀 **PROCHAINES ÉTAPES APRÈS LES TESTS**

### ✅ Si tout fonctionne :
1. **Améliorer l'UX** :
   - Animations de chargement
   - Notifications push
   - Compression audio avant upload

2. **Optimisations** :
   - Cache des clients/produits
   - Pagination des listes
   - Génération PDF

3. **Features avancées** :
   - Signature du client
   - Photos du chantier
   - Export comptable

### ❌ Si problèmes :
1. Noter les erreurs précises
2. Capturer les logs
3. Partager les screenshots
4. On débogue ensemble ! 🐛

---

**🎉 BONNE CHANCE POUR LES TESTS ! 🎉**

