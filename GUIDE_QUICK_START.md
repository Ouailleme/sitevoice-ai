# 🚀 QUICK START - Solution Rapide

## 🎯 **PROBLÈME**

L'inscription ne fonctionne pas et la base de données est vide.

---

## ✅ **SOLUTION RAPIDE (2 OPTIONS)**

### **OPTION A : Reset Complet** ⏱️ ~2 minutes

Cette option recrée toute la base de données proprement.

#### **Étape 1 : Diagnostic**

1. Va sur **Supabase Dashboard** : https://supabase.com/dashboard
2. Connecte-toi et sélectionne ton projet **SiteVoice AI**
3. Va dans **SQL Editor** (icône `<>` dans la sidebar)
4. Crée une **nouvelle requête** (bouton "New query")
5. **Copie/colle** le contenu de `supabase/DIAGNOSTIC.sql`
6. **Clique sur "Run"**

📊 **Tu verras :**
- Nombre de tables créées (doit être 6/6)
- État du trigger (doit être ✅)
- État de la fonction (doit être ✅)

#### **Étape 2 : Reset (si diagnostic montre des problèmes)**

1. **Nouvelle requête** dans SQL Editor
2. **Copie/colle** TOUT le contenu de `supabase/RESET_DATABASE.sql`
3. **Clique sur "Run"** (⏱️ ~5-10 secondes)

✅ **Résultat attendu :**
```
✅ Base de données réinitialisée avec succès !
📋 Toutes les tables ont été créées
🔒 RLS activé avec policies correctes
🤖 Trigger auto-create profile activé
```

#### **Étape 3 : Teste l'inscription**

1. **Lance l'app** sur ton téléphone
2. **Clique sur "S'inscrire"**
3. **Remplis le formulaire**
4. **Valide**

✅ **Devrait fonctionner maintenant !**

---

### **OPTION B : Créer un User de Test** ⏱️ ~30 secondes

Cette option crée un utilisateur directement dans la base pour tester rapidement.

#### **Étape 1 : Créer le user dans Auth Dashboard**

1. Va sur **Supabase Dashboard** → Ton projet **SiteVoice AI**
2. Clique sur **Authentication** (icône clé dans la sidebar)
3. Clique sur **Users**
4. Clique sur **"Add user"** → **"Create new user"**
5. Remplis :
   - **Email** : `test@example.com`
   - **Password** : `Test1234!`
   - **Auto Confirm User** : ✅ (coche la case)
6. **Clique sur "Create user"**

📋 **COPIE L'ID DU USER** (format UUID)
Exemple : `12345678-1234-1234-1234-123456789abc`

#### **Étape 2 : Créer le profil + company**

1. Va dans **SQL Editor**
2. **Nouvelle requête**
3. **Copie/colle** le contenu de `supabase/CREATE_TEST_USER.sql`
4. **MODIFIE LES VALEURS** :
   ```sql
   v_user_id UUID := 'COLLE_TON_USER_ID_ICI'; -- ⚠️ Colle l'ID copié à l'étape 1
   v_email TEXT := 'test@example.com'; -- Ton email
   v_full_name TEXT := 'Yves Martin'; -- Ton nom
   v_company_name TEXT := 'Ma Société BTP'; -- Nom de ta société
   ```
5. **Clique sur "Run"**

✅ **Résultat attendu :**
```
✅ Company créée : Ma Société BTP
✅ Profil créé pour : test@example.com
🎉 USER DE TEST CRÉÉ !
```

#### **Étape 3 : Teste la connexion**

1. **Lance l'app** sur ton téléphone
2. **Clique sur "Se connecter"**
3. **Entre** :
   - Email : `test@example.com`
   - Password : `Test1234!`
4. **Valide**

✅ **Tu devrais être connecté !**

---

## 🧪 **VÉRIFICATIONS**

### **Vérifier que tout est OK dans Supabase**

Exécute dans SQL Editor :

```sql
-- Voir tous les users
SELECT 
    au.email as auth_email,
    u.full_name,
    u.role,
    c.name as company_name,
    CASE 
        WHEN u.id IS NOT NULL AND c.id IS NOT NULL THEN '✅ OK'
        ELSE '❌ PROBLÈME'
    END as status
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
LEFT JOIN companies c ON c.id = u.company_id
ORDER BY au.created_at DESC;
```

**Résultat attendu :**
| auth_email | full_name | role | company_name | status |
|------------|-----------|------|--------------|--------|
| test@example.com | Yves Martin | admin | Ma Société BTP | ✅ OK |

---

## 🆘 **AIDE**

### **"Les tables n'existent pas"**

👉 Exécute **OPTION A** (RESET_DATABASE.sql)

### **"Le trigger n'existe pas"**

👉 Exécute **OPTION A** (RESET_DATABASE.sql)

### **"User ID introuvable"**

👉 Vérifie que tu as bien **copié l'ID** depuis Auth Dashboard → Users

### **"Email already exists"**

👉 Change l'email ou supprime l'ancien user :
```sql
DELETE FROM auth.users WHERE email = 'test@example.com';
```

---

## 📊 **RÉCAPITULATIF**

| Méthode | Temps | Complexité | Recommandé |
|---------|-------|------------|------------|
| **Option A : Reset** | 2 min | Moyen | ✅ Oui (propre) |
| **Option B : Test User** | 30 sec | Facile | ✅ Oui (rapide) |

---

## 🎯 **APRÈS AVOIR CRÉÉ TON USER**

Une fois connecté, tu peux :
1. ✅ Créer des clients
2. ✅ Créer des produits
3. ✅ Enregistrer un audio (RecordScreen)
4. ✅ Tester l'extraction IA

---

**CHOISIS UNE OPTION ET SUIS LES ÉTAPES ! 🚀**

