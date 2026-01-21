# 📋 Guide d'Installation - OuiGlass Suisse MVP Phase 1

Ce guide vous accompagne étape par étape pour déployer le chatbot conversationnel OuiGlass.

---

## ✅ PRÉREQUIS

Avant de commencer, assurez-vous d'avoir :

1. **Compte Supabase** (gratuit) : [supabase.com](https://supabase.com)
2. **Compte n8n Cloud** (gratuit) : [n8n.io](https://n8n.io)
3. **Clé API Claude** (payant) : [console.anthropic.com](https://console.anthropic.com)
   - Ou clé API OpenAI si vous préférez : [platform.openai.com](https://platform.openai.com)

---

## 📦 ÉTAPE 1 : CONFIGURATION SUPABASE

### 1.1 Créer un projet Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous ou créez un compte
3. Cliquez sur **New Project**
4. Remplissez :
   - **Name** : `ouiglass-suisse` (ou autre nom)
   - **Database Password** : choisissez un mot de passe fort (notez-le)
   - **Region** : choisissez la région la plus proche (ex : Europe West)
5. Cliquez **Create new project** et attendez 2-3 minutes

### 1.2 Exécuter le SQL

1. Une fois le projet créé, allez dans **SQL Editor** (menu latéral gauche)
2. Ouvrez le fichier `supabase-schema.sql` de ce repository
3. Copiez tout le contenu du fichier
4. Collez-le dans l'éditeur SQL de Supabase
5. Cliquez sur **RUN** (ou appuyez sur Ctrl+Enter)
6. Vous devriez voir : **Success. No rows returned**

### 1.3 Vérifier les tables

1. Allez dans **Table Editor** (menu latéral gauche)
2. Vous devriez voir 2 tables :
   - `conversations`
   - `messages`
3. Si vous les voyez, c'est bon ✅

### 1.4 Récupérer les credentials

1. Allez dans **Project Settings** (icône engrenage en bas du menu)
2. Allez dans l'onglet **API**
3. Notez ces 2 informations :
   - **Project URL** : exemple `https://abcdefgh.supabase.co`
   - **service_role** key : cliquez sur "Reveal" et copiez la clé (commence par `eyJ...`)

> ⚠️ IMPORTANT : Ne partagez JAMAIS votre service_role key publiquement

---

## 🔧 ÉTAPE 2 : CONFIGURATION N8N

### 2.1 Créer un compte n8n Cloud

1. Allez sur [n8n.io](https://n8n.io)
2. Cliquez **Start Free** et créez un compte
3. Choisissez le plan gratuit (Cloud Starter)
4. Connectez-vous à votre instance n8n

### 2.2 Ajouter les credentials Supabase

1. Dans n8n, cliquez sur votre nom (en haut à droite) → **Settings** → **Credentials**
2. Cliquez **+ New Credential**
3. Cherchez et sélectionnez **Supabase**
4. Remplissez :
   - **Credential Name** : `Supabase OuiGlass`
   - **Host** : collez votre Project URL Supabase (ex : `https://abcdefgh.supabase.co`)
   - **Service Role Secret** : collez votre service_role key
5. Cliquez **Save**

### 2.3 Ajouter les credentials Claude API

1. Toujours dans **Credentials**, cliquez **+ New Credential**
2. Cherchez et sélectionnez **Header Auth**
3. Remplissez :
   - **Credential Name** : `Claude API Key`
   - **Name** : `x-api-key`
   - **Value** : collez votre clé API Claude (trouvable sur [console.anthropic.com](https://console.anthropic.com))
4. Cliquez **Save**

> **Alternative OpenAI** : Si vous utilisez OpenAI au lieu de Claude :
> - Credential Type : **Header Auth**
> - Name : `Authorization`
> - Value : `Bearer YOUR_OPENAI_API_KEY`
> - Et modifiez l'URL du node HTTP Request vers `https://api.openai.com/v1/chat/completions`

### 2.4 Importer le workflow

**Option A : Import automatique (recommandé)**

1. Dans n8n, cliquez sur **Workflows** (menu de gauche)
2. Cliquez sur **+ Add workflow** → **Import from File**
3. Sélectionnez le fichier `workflow-ouiglass-mvp.json` de ce repository
4. Le workflow s'ouvre avec tous les nodes configurés
5. Passez à l'étape 2.5

**Option B : Création manuelle (si l'import échoue)**

1. Cliquez **+ Add workflow**
2. Suivez la section 3 du README.md pour créer chaque node manuellement

### 2.5 Vérifier les credentials dans le workflow

1. Ouvrez le node **Get or Create Conversation**
2. Vérifiez que le credential **Supabase OuiGlass** est bien sélectionné
3. Répétez pour tous les nodes Supabase :
   - Insert User Message
   - Get Last N Messages
   - Insert Assistant Message
4. Ouvrez le node **Call LLM**
5. Vérifiez que le credential **Claude API Key** (ou votre nom) est bien sélectionné

### 2.6 Sauvegarder et activer le workflow

1. En haut à droite, donnez un nom au workflow : `OuiGlass Suisse MVP`
2. Cliquez **Save**
3. Activez le workflow avec le toggle **Inactive** → **Active** (en haut à droite)
4. Le workflow est maintenant en ligne ✅

### 2.7 Récupérer l'URL du webhook

1. Ouvrez le node **Webhook Chat** (premier node)
2. En haut du panneau, vous verrez **Production URL**
3. Copiez cette URL (exemple : `https://your-instance.app.n8n.cloud/webhook/chat`)
4. Notez-la, vous en aurez besoin pour les tests

---

## 🧪 ÉTAPE 3 : TESTER LE WORKFLOW

### 3.1 Test rapide avec curl (Linux/Mac)

Ouvrez un terminal et exécutez :

```bash
curl -X POST https://VOTRE_URL_WEBHOOK \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-001",
    "message": "Bonjour"
  }'
```

Remplacez `https://VOTRE_URL_WEBHOOK` par l'URL du webhook de l'étape 2.7.

**Réponse attendue** :
```json
{
  "reply": "Bonjour ! 👋 Je suis là pour t'aider avec ton vitrage auto. Pour commencer, quelle est la marque de ton véhicule ?"
}
```

### 3.2 Test rapide avec PowerShell (Windows)

Ouvrez PowerShell et exécutez :

```powershell
$body = @{
    session_id = "test-001"
    message = "Bonjour"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://VOTRE_URL_WEBHOOK" -Method Post -Body $body -ContentType "application/json"
```

### 3.3 Tests complets

#### Linux/Mac :
```bash
# Remplacez YOUR_WEBHOOK_URL_HERE dans le fichier
nano tests-curl.sh
# Puis exécutez
chmod +x tests-curl.sh
./tests-curl.sh
```

#### Windows :
```powershell
# Remplacez YOUR_WEBHOOK_URL_HERE dans le fichier
notepad tests-powershell.ps1
# Puis exécutez
.\tests-powershell.ps1
```

---

## ✅ ÉTAPE 4 : VÉRIFICATIONS

### 4.1 Vérifier dans Supabase

1. Allez dans Supabase → **Table Editor** → table `conversations`
2. Vous devriez voir vos session_id de test
3. Allez dans la table `messages`
4. Vous devriez voir tous les messages user et assistant

### 4.2 Vérifier dans n8n

1. Dans n8n, allez dans votre workflow
2. Cliquez sur **Executions** (en haut à droite)
3. Vous devriez voir toutes les exécutions (une par message reçu)
4. Cliquez sur une exécution pour voir le détail du flow

---

## 🚨 DÉPANNAGE

### Erreur "session_id manquant ou invalide"
**Cause** : Le JSON envoyé ne contient pas `session_id` ou il est vide.
**Solution** : Vérifiez votre payload JSON.

### Erreur "relation conversations does not exist"
**Cause** : Les tables Supabase n'ont pas été créées.
**Solution** : Retournez à l'étape 1.2 et exécutez le SQL.

### Erreur "Could not connect to Supabase"
**Cause** : Les credentials Supabase sont incorrects.
**Solution** : Vérifiez le Host et la Service Role Key dans les credentials n8n.

### Erreur "Invalid API key" ou "Authentication failed"
**Cause** : La clé API Claude/OpenAI est incorrecte.
**Solution** : Vérifiez votre clé API dans les credentials n8n.

### Le LLM répond en texte brut au lieu de JSON
**Cause** : Le prompt système n'est pas bien passé.
**Solution** : Vérifiez le node "Build LLM Context" et assurez-vous que le `systemPrompt` est correctement défini.

### Le workflow ne répond pas
**Cause** : Le workflow n'est pas actif ou l'URL est incorrecte.
**Solution** : Vérifiez que le toggle est sur **Active** et que vous utilisez la **Production URL**.

---

## 📞 SUPPORT

Pour toute question ou problème :

1. Vérifiez la section **Troubleshooting** du README.md
2. Consultez les logs d'exécution dans n8n (Executions)
3. Vérifiez les données dans Supabase (Table Editor)

---

## 🎉 FÉLICITATIONS !

Votre chatbot OuiGlass Suisse MVP Phase 1 est opérationnel ! 🚀

**Prochaines étapes** :
- Intégrez ce webhook dans votre site web
- Testez avec de vrais clients
- Collectez les feedbacks

**Rappel** : Cette Phase 1 est un MVP minimal. Les fonctionnalités avancées (RDV, assurance, photos, etc.) seront ajoutées dans les phases suivantes.
