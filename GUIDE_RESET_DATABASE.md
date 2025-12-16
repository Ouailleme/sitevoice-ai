# 🔄 GUIDE : Reset Complet de la Base de Données

## 🎯 **OBJECTIF**

Résoudre les problèmes de connexion/inscription en recréant la base de données avec le **schéma exact** attendu par le code Flutter.

---

## ⚠️ **ATTENTION**

**Ce script supprime TOUTES les données existantes !**

Si tu as des données importantes :
1. Fais un backup via Supabase Dashboard
2. Ou crée un nouveau projet Supabase

---

## 📋 **ÉTAPES**

### **1️⃣ Ouvre Supabase Dashboard**

1. Va sur https://supabase.com/dashboard
2. Sélectionne ton projet **SiteVoice AI**
3. Va dans **SQL Editor** (icône `<>` dans la sidebar)

---

### **2️⃣ Exécute le Script de Reset**

1. Ouvre le fichier `supabase/RESET_DATABASE.sql` (dans ce repo)
2. **Copie TOUT le contenu**
3. **Colle-le** dans le SQL Editor
4. **Clique sur "Run"** (en bas à droite)

⏱️ **Durée :** ~5-10 secondes

---

### **3️⃣ Vérifie que tout s'est bien passé**

Tu devrais voir :

```
✅ Base de données réinitialisée avec succès !
📋 Toutes les tables ont été créées
🔒 RLS activé avec policies correctes
🤖 Trigger auto-create profile activé
```

---

### **4️⃣ Teste l'Inscription**

1. **Désinstalle l'app** du téléphone (pour vider le cache)

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
& "C:\Users\yvesm\AppData\Local\Android\sdk\platform-tools\adb.exe" uninstall com.sitevoice.sitevoice_ai
```

2. **Réinstalle l'app**

```powershell
& "C:\Users\yvesm\AppData\Local\Android\sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-debug.apk"
```

3. **Lance l'app sur ton téléphone**
4. **Clique sur "S'inscrire"**
5. **Remplis le formulaire** :
   - Nom complet : `Yves Martin`
   - Nom de l'entreprise : `Test Company`
   - Email : `test@example.com` (ou ton vrai email)
   - Mot de passe : `Test1234!`
6. **Valide**

---

### **5️⃣ Vérifie dans Supabase**

Retourne dans **SQL Editor** et exécute :

```sql
SELECT 
    au.id as auth_id,
    au.email,
    u.full_name,
    u.role,
    c.name as company_name,
    CASE 
        WHEN u.id IS NULL THEN '❌ PROFIL MANQUANT'
        ELSE '✅ TOUT OK'
    END as status
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
LEFT JOIN companies c ON c.id = u.company_id
ORDER BY au.created_at DESC;
```

Tu devrais voir :
- ✅ `auth_id` : ton ID utilisateur
- ✅ `email` : ton email
- ✅ `full_name` : ton nom
- ✅ `role` : `admin`
- ✅ `company_name` : `Test Company`
- ✅ `status` : `✅ TOUT OK`

---

### **6️⃣ Teste la Connexion**

1. **Déconnecte-toi** de l'app (si connecté)
2. **Clique sur "Se connecter"**
3. **Entre ton email et mot de passe**
4. **Valide**

✅ **Tu devrais être connecté et voir l'écran d'accueil !**

---

## 🧪 **SCRIPT DE TEST**

Si tu veux tester plus en détail, exécute le fichier `supabase/TEST_AUTH.sql` :

1. Ouvre `supabase/TEST_AUTH.sql`
2. Copie/colle dans SQL Editor
3. Run

Tu verras :
- 👥 Liste des users auth
- 👤 Liste des profils users
- 🔒 Policies RLS
- 📊 Statistiques

---

## 🆘 **EN CAS DE PROBLÈME**

### **Problème 1 : "Email already registered"**

**Solution :** Supprime l'ancien user

```sql
DELETE FROM auth.users WHERE email = 'ton-email@example.com';
```

Puis réessaye l'inscription.

---

### **Problème 2 : "Profil manquant après signup"**

**Solution :** Crée le profil manuellement

```sql
DO $$
DECLARE
    v_user_id UUID := 'COPIE_TON_USER_ID_ICI'; -- Depuis la requête de vérif
    v_company_id UUID;
BEGIN
    INSERT INTO companies (name, subscription_status)
    VALUES ('Ma Société', 'trial')
    RETURNING id INTO v_company_id;
    
    INSERT INTO users (id, email, full_name, role, company_id)
    VALUES (
        v_user_id,
        'ton-email@example.com',
        'Ton Nom',
        'admin',
        v_company_id
    );
END $$;
```

---

### **Problème 3 : "Access denied" ou erreurs RLS**

**Solution temporaire :** Désactive RLS le temps de tester

```sql
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
```

**⚠️ N'OUBLIE PAS DE LE RÉACTIVER APRÈS !**

```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
```

---

## 📊 **CE QUI A ÉTÉ CRÉÉ**

### **Tables**
- ✅ `companies` : Entreprises
- ✅ `users` : Profils utilisateurs
- ✅ `clients` : Clients BTP
- ✅ `products` : Produits/Services
- ✅ `jobs` : Chantiers (avec IA)
- ✅ `job_items` : Lignes de chantier

### **Triggers**
- ✅ `update_updated_at` : Met à jour `updated_at` automatiquement
- ✅ `on_auth_user_created` : Crée le profil + company après signup

### **Policies RLS**
- ✅ Users peuvent voir leur company
- ✅ Users peuvent voir les members de leur company
- ✅ Users peuvent gérer clients/produits/jobs de leur company
- ✅ Admins ont plus de droits (delete, etc.)

---

## ✅ **RÉCAPITULATIF**

1. ✅ Script de reset exécuté
2. ✅ App désinstallée/réinstallée
3. ✅ Signup testé
4. ✅ Profil créé automatiquement
5. ✅ Login fonctionne
6. ✅ App accessible

---

## 🎯 **PROCHAINES ÉTAPES**

Une fois connecté, tu devrais pouvoir :
1. ✅ Créer des clients
2. ✅ Créer des produits
3. ✅ Enregistrer un audio (RecordScreen)
4. ✅ Tester l'extraction IA

---

**DIS-MOI OÙ TU EN ES ! 📱**

