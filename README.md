# 🚗 OuiGlass Suisse - Agent Conversationnel MVP (Phase 1)

## 1) ARCHITECTURE

Ce MVP consiste en un **workflow n8n unique** qui expose un webhook POST pour gérer des conversations multi-tours avec historique. Chaque message reçu (avec `session_id` + `message`) déclenche : validation, récupération/création de conversation dans Supabase, insertion du message utilisateur, récupération de l'historique (10 derniers messages), appel HTTP au LLM (Claude/OpenAI), parsing de la réponse JSON, insertion de la réponse assistant, et retour au client. Les données conversationnelles sont stockées dans 2 tables Supabase (`conversations`, `messages`). Le LLM collecte progressivement 6 champs : marque/modèle/année du véhicule, type de vitre, ville, nom complet. Pas de RDV, pas d'intégrations externes, pas d'optimisations.

---

## 2) SQL SUPABASE

Connectez-vous à votre projet Supabase → **SQL Editor** → collez et exécutez :

```sql
-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

-- Index for faster queries
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_conversations_session_id ON conversations(session_id);
```

**Vérification** : allez dans **Table Editor**, vous devriez voir `conversations` et `messages`.

---

## 3) CONFIGURATION N8N NODE PAR NODE

### PRÉREQUIS : Credentials Supabase

1. Dans n8n, allez dans **Credentials** → **New Credential** → cherchez **Supabase**
2. Remplissez :
   - **Host** : `https://VOTRE-PROJET.supabase.co` (trouvable dans Project Settings → API)
   - **Service Role Key** : votre `service_role` key (API Settings → service_role secret)
3. Nommez-la `Supabase OuiGlass` et **Save**

### WORKFLOW : 9 NODES

#### Node 1 : WEBHOOK
- **Type** : Webhook
- **Name** : `Webhook Chat`
- **HTTP Method** : POST
- **Path** : `chat`
- **Authentication** : None (ou ajoutez un Bearer token si vous voulez)
- **Response Mode** : `Last Node`

#### Node 2 : FUNCTION "Validate Input"
- **Type** : Code (Function)
- **Name** : `Validate Input`
- **Language** : JavaScript
- **Code** :

```javascript
// Récupère le body du webhook
const body = $input.item.json.body;

// Valide session_id et message
if (!body || !body.session_id || typeof body.session_id !== 'string' || body.session_id.trim() === '') {
  throw new Error('session_id manquant ou invalide');
}

if (!body.message || typeof body.message !== 'string' || body.message.trim() === '') {
  throw new Error('message manquant ou invalide');
}

// Retourne les données validées
return {
  session_id: body.session_id.trim(),
  message: body.message.trim()
};
```

#### Node 3 : SUPABASE "Get or Create Conversation"
- **Type** : Supabase
- **Name** : `Get or Create Conversation`
- **Credential** : `Supabase OuiGlass`
- **Operation** : `Execute SQL`
- **SQL Query** :

```sql
INSERT INTO conversations (session_id)
VALUES ('{{ $json.session_id }}')
ON CONFLICT (session_id) DO UPDATE SET updated_at = now()
RETURNING id, session_id, created_at, updated_at;
```

#### Node 4 : SUPABASE "Insert User Message"
- **Type** : Supabase
- **Name** : `Insert User Message`
- **Credential** : `Supabase OuiGlass`
- **Operation** : `Execute SQL`
- **SQL Query** :

```sql
INSERT INTO messages (conversation_id, role, content)
VALUES (
  '{{ $json.id }}',
  'user',
  '{{ $('Validate Input').item.json.message }}'
)
RETURNING id, conversation_id, role, content, created_at;
```

#### Node 5 : SUPABASE "Get Last N Messages"
- **Type** : Supabase
- **Name** : `Get Last N Messages`
- **Credential** : `Supabase OuiGlass`
- **Operation** : `Execute SQL`
- **SQL Query** :

```sql
SELECT role, content, created_at
FROM messages
WHERE conversation_id = '{{ $('Get or Create Conversation').item.json.id }}'
ORDER BY created_at ASC
LIMIT 10;
```

#### Node 6 : FUNCTION "Build LLM Context"
- **Type** : Code (Function)
- **Name** : `Build LLM Context`
- **Code** :

```javascript
// Récupère l'historique des messages
const history = $('Get Last N Messages').all();

// Construit le tableau de messages pour le LLM
const messages = history.map(item => ({
  role: item.json.role,
  content: item.json.content
}));

// Prompt système
const systemPrompt = `Tu es l'assistant virtuel de OuiGlass Suisse, spécialiste du remplacement de vitrage automobile.

**RÈGLES STRICTES :**
1. Réponds UNIQUEMENT en JSON valide, sans texte avant ou après
2. Pose UNE SEULE question à la fois
3. Ton : professionnel et sympathique, tutoiement
4. Messages très courts (2-3 phrases max)
5. Langue : français par défaut, anglais si le client écrit en anglais

**OBJECTIF :** Collecter progressivement ces 6 informations (dans l'ordre recommandé) :
1. vehicle_make (marque du véhicule : Renault, Peugeot, BMW, etc.)
2. vehicle_model (modèle : Clio, 208, Série 3, etc.)
3. vehicle_year (année : 2018, 2020, etc.)
4. glass_type (type de vitre : pare-brise, vitre latérale, lunette arrière, autre)
5. city (ville en Suisse : Genève, Lausanne, Zurich, etc.)
6. full_name (nom complet du client)

**FORMAT DE RÉPONSE (JSON STRICT) :**
{
  "message": "Ton message court pour le client",
  "lead": {
    "vehicle_make": "valeur ou null",
    "vehicle_model": "valeur ou null",
    "vehicle_year": "valeur ou null",
    "glass_type": "valeur ou null",
    "city": "valeur ou null",
    "full_name": "valeur ou null"
  },
  "missing_fields": ["lead.vehicle_make", "lead.vehicle_model", ...],
  "next_action": "ask_next"
}

**COMPORTEMENT :**
- Commence par saluer et demander la marque du véhicule si c'est le premier message
- Complète progressivement les champs en fonction des réponses du client
- Ne redemande JAMAIS un champ déjà collecté
- Liste tous les champs manquants dans "missing_fields"
- Si tous les champs sont remplis, félicite le client et indique qu'un conseiller le contactera

**INTERDIT :**
- Proposer un RDV
- Parler d'assurance
- Demander des photos
- Mentionner WhatsApp, email, téléphone
- Inventer des informations`;

return {
  messages: messages,
  systemPrompt: systemPrompt
};
```

#### Node 7 : HTTP REQUEST "Call LLM"
- **Type** : HTTP Request
- **Name** : `Call LLM`
- **Method** : POST
- **URL** : `https://api.anthropic.com/v1/messages`
- **Authentication** : Generic Credential Type
  - Créez un credential avec header `x-api-key` et votre clé API Claude
- **Headers** :
  ```
  anthropic-version: 2023-06-01
  content-type: application/json
  ```
- **Body** : JSON

```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "system": "={{ $json.systemPrompt }}",
  "messages": {{ $json.messages }}
}
```

#### Node 8 : FUNCTION "Parse LLM JSON"
- **Type** : Code (Function)
- **Name** : `Parse LLM JSON`
- **Code** :

```javascript
// Récupère la réponse du LLM
const llmResponse = $input.item.json;

// Pour Claude API
let content = '';
if (llmResponse.content && Array.isArray(llmResponse.content)) {
  content = llmResponse.content[0].text;
} else if (llmResponse.choices && llmResponse.choices[0]) {
  // Pour OpenAI API
  content = llmResponse.choices[0].message.content;
} else {
  content = llmResponse.content || llmResponse.text || '';
}

// Parse le JSON
try {
  const parsed = JSON.parse(content);
  return {
    reply: parsed.message,
    lead: parsed.lead || {},
    missing_fields: parsed.missing_fields || [],
    next_action: parsed.next_action || 'ask_next'
  };
} catch (error) {
  // Fallback si le JSON est invalide
  return {
    reply: "Désolé, j'ai eu un souci technique. Peux-tu répéter ton message ?",
    lead: {},
    missing_fields: [],
    next_action: 'error'
  };
}
```

#### Node 9 : SUPABASE "Insert Assistant Message"
- **Type** : Supabase
- **Name** : `Insert Assistant Message`
- **Credential** : `Supabase OuiGlass`
- **Operation** : `Execute SQL`
- **SQL Query** :

```sql
INSERT INTO messages (conversation_id, role, content)
VALUES (
  '{{ $('Get or Create Conversation').item.json.id }}',
  'assistant',
  '{{ $('Parse LLM JSON').item.json.reply }}'
)
RETURNING id, conversation_id, role, content, created_at;
```

#### Node 10 : RESPOND TO WEBHOOK
- **Type** : Respond to Webhook
- **Name** : `Respond to Webhook`
- **Response Mode** : `Using Fields Below`
- **Response Body** :

```json
{
  "reply": "={{ $('Parse LLM JSON').item.json.reply }}"
}
```

---

## 4) PROMPT SYSTÈME LLM (VERSION STANDALONE)

Le prompt système est intégré dans le node `Build LLM Context`. Voici la version complète :

```
Tu es l'assistant virtuel de OuiGlass Suisse, spécialiste du remplacement de vitrage automobile.

**RÈGLES STRICTES :**
1. Réponds UNIQUEMENT en JSON valide, sans texte avant ou après
2. Pose UNE SEULE question à la fois
3. Ton : professionnel et sympathique, tutoiement
4. Messages très courts (2-3 phrases max)
5. Langue : français par défaut, anglais si le client écrit en anglais

**OBJECTIF :** Collecter progressivement ces 6 informations (dans l'ordre recommandé) :
1. vehicle_make (marque du véhicule : Renault, Peugeot, BMW, etc.)
2. vehicle_model (modèle : Clio, 208, Série 3, etc.)
3. vehicle_year (année : 2018, 2020, etc.)
4. glass_type (type de vitre : pare-brise, vitre latérale, lunette arrière, autre)
5. city (ville en Suisse : Genève, Lausanne, Zurich, etc.)
6. full_name (nom complet du client)

**FORMAT DE RÉPONSE (JSON STRICT) :**
{
  "message": "Ton message court pour le client",
  "lead": {
    "vehicle_make": "valeur ou null",
    "vehicle_model": "valeur ou null",
    "vehicle_year": "valeur ou null",
    "glass_type": "valeur ou null",
    "city": "valeur ou null",
    "full_name": "valeur ou null"
  },
  "missing_fields": ["lead.vehicle_make", "lead.vehicle_model", ...],
  "next_action": "ask_next"
}

**COMPORTEMENT :**
- Commence par saluer et demander la marque du véhicule si c'est le premier message
- Complète progressivement les champs en fonction des réponses du client
- Ne redemande JAMAIS un champ déjà collecté
- Liste tous les champs manquants dans "missing_fields"
- Si tous les champs sont remplis, félicite le client et indique qu'un conseiller le contactera

**INTERDIT :**
- Proposer un RDV
- Parler d'assurance
- Demander des photos
- Mentionner WhatsApp, email, téléphone
- Inventer des informations
```

---

## 5) EXPORT JSON DU WORKFLOW N8N

Voir fichier `workflow-ouiglass-mvp.json` dans ce repository.

---

## 6) TESTS (CURL ET POWERSHELL)

**Note** : Remplacez `YOUR_WEBHOOK_URL` par l'URL du webhook n8n (visible après activation du workflow).

### Test 1 : Nouveau session_id (premier message)

**Curl (Linux/Mac)** :
```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "message": "Bonjour"
  }'
```

**PowerShell (Windows)** :
```powershell
$body = @{
    session_id = "test-session-001"
    message = "Bonjour"
} | ConvertTo-Json

Invoke-RestMethod -Uri "YOUR_WEBHOOK_URL" -Method Post -Body $body -ContentType "application/json"
```

**Réponse attendue** : JSON avec un message de salutation demandant la marque du véhicule.

---

### Test 2 : Même session_id (message 2)

**Curl** :
```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "message": "Renault"
  }'
```

**PowerShell** :
```powershell
$body = @{
    session_id = "test-session-001"
    message = "Renault"
} | ConvertTo-Json

Invoke-RestMethod -Uri "YOUR_WEBHOOK_URL" -Method Post -Body $body -ContentType "application/json"
```

**Réponse attendue** : L'assistant demande le modèle du véhicule.

---

### Test 3 : Message vide (doit erreur)

**Curl** :
```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-002",
    "message": ""
  }'
```

**PowerShell** :
```powershell
$body = @{
    session_id = "test-session-002"
    message = ""
} | ConvertTo-Json

Invoke-RestMethod -Uri "YOUR_WEBHOOK_URL" -Method Post -Body $body -ContentType "application/json"
```

**Réponse attendue** : Erreur 400 ou 500 avec message "message manquant ou invalide".

---

### Test 4 : session_id manquant (doit erreur)

**Curl** :
```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello"
  }'
```

**PowerShell** :
```powershell
$body = @{
    message = "Hello"
} | ConvertTo-Json

Invoke-RestMethod -Uri "YOUR_WEBHOOK_URL" -Method Post -Body $body -ContentType "application/json"
```

**Réponse attendue** : Erreur 400 ou 500 avec message "session_id manquant ou invalide".

---

### Test 5 : Message en anglais (doit répondre en anglais)

**Curl** :
```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-003",
    "message": "Hello, I need help with my car windshield"
  }'
```

**PowerShell** :
```powershell
$body = @{
    session_id = "test-session-003"
    message = "Hello, I need help with my car windshield"
} | ConvertTo-Json

Invoke-RestMethod -Uri "YOUR_WEBHOOK_URL" -Method Post -Body $body -ContentType "application/json"
```

**Réponse attendue** : L'assistant répond en anglais et demande la marque du véhicule.

---

## 7) GUIDE DE DÉPLOIEMENT PAS À PAS

### Étape 1 : Créer les tables Supabase
1. Allez sur [supabase.com](https://supabase.com) et connectez-vous
2. Sélectionnez votre projet (ou créez-en un nouveau)
3. Allez dans **SQL Editor** (menu latéral gauche)
4. Collez le SQL de la section 2
5. Cliquez sur **Run** (ou Ctrl+Enter)
6. Vérifiez dans **Table Editor** que `conversations` et `messages` existent

### Étape 2 : Configurer les credentials Supabase dans n8n
1. Connectez-vous à votre instance n8n Cloud
2. Allez dans **Credentials** (menu en haut à droite)
3. Cliquez **+ New Credential**
4. Cherchez et sélectionnez **Supabase**
5. Remplissez :
   - **Name** : `Supabase OuiGlass`
   - **Host** : trouvez-le dans Supabase → Project Settings → API → Project URL (ex: `https://abcdefgh.supabase.co`)
   - **Service Role Key** : trouvez-le dans Supabase → Project Settings → API → service_role (cliquez sur "Reveal" et copiez)
6. Cliquez **Create**

### Étape 3 : Créer le workflow n8n
**Option A : Import JSON (recommandé)**
1. Téléchargez le fichier `workflow-ouiglass-mvp.json`
2. Dans n8n, cliquez **+ Add workflow** → **Import from File**
3. Sélectionnez le fichier JSON
4. Tous les nodes seront créés automatiquement

**Option B : Manuel (si import échoue)**
1. Créez un nouveau workflow
2. Ajoutez les nodes un par un selon la section 3
3. Connectez-les dans l'ordre

### Étape 4 : Configurer l'API key du LLM
1. Ouvrez le node `Call LLM`
2. Dans **Authentication**, sélectionnez **Generic Credential Type**
3. Créez un nouveau credential :
   - **Name** : `Claude API Key`
   - **Credential Type** : Generic Credential Type
   - **Generic Auth Type** : Header Auth
   - **Header Name** : `x-api-key`
   - **Header Value** : `YOUR_CLAUDE_API_KEY`
4. Sauvegardez

### Étape 5 : Activer et tester le workflow
1. Cliquez **Save** en haut à droite du workflow
2. Cliquez **Active** (toggle en haut à droite)
3. Ouvrez le node `Webhook Chat`
4. Copiez l'URL du webhook (Production URL)
5. Testez avec les commandes de la section 6

---

## 8) TROUBLESHOOTING

**Erreur "session_id manquant"**
→ Vérifiez que le JSON envoyé contient bien `session_id` (sensible à la casse)

**Erreur "relation conversations does not exist"**
→ Vérifiez que le SQL a bien été exécuté dans Supabase

**Erreur "Could not connect to Supabase"**
→ Vérifiez le Host et la Service Role Key dans les credentials

**Erreur "Invalid API key"**
→ Vérifiez votre clé API Claude dans le node HTTP Request

**Le LLM répond en texte brut au lieu de JSON**
→ Vérifiez que le prompt système est bien passé et insiste sur JSON strict

**Le workflow ne répond pas**
→ Vérifiez que le workflow est bien **Active** et que vous utilisez la **Production URL**

---

## 9) PROCHAINES ÉTAPES (HORS SCOPE PHASE 1)

Ce MVP ne gère PAS (volontairement) :
- Prise de RDV
- Gestion d'assurance
- Upload de photos
- Notifications WhatsApp/Email
- Intégration Otovia/Google Calendar
- Dashboard analytics

Ces features seront ajoutées dans les phases suivantes si nécessaire.

---

**FIN DU MVP PHASE 1** ✅
