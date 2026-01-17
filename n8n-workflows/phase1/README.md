# Workflows N8N - Phase 1

## Vue d'ensemble

Ce dossier contient les 4 workflows essentiels de la Phase 1 (MVP) pour l'agent IA OuiGlass.

## Liste des workflows

1. **01-reception-lead-website.json** - Réception lead depuis chatbot web
2. **02-conversation-multi-tours.json** - Gestion conversation avec contexte
3. **03-creation-rdv.json** - Validation et création rendez-vous
4. **04-notifications-whatsapp.json** - Notifications propriétaire

## Import dans N8N

### Méthode 1 : Import manuel (Recommandé pour débutants)

Au lieu d'importer les JSON (qui peuvent nécessiter des ajustements), suivez ces instructions pour **recréer les workflows manuellement** dans N8N :

1. Ouvrir N8N
2. Créer nouveau workflow
3. Suivre les diagrammes ci-dessous pour ajouter les nodes
4. Configurer chaque node selon les specs

### Méthode 2 : Import fichier JSON

1. N8N > Workflows > Import from File
2. Sélectionner le fichier JSON
3. **Important** : Vous devrez reconfigurer les credentials (Supabase, Claude API, etc.)
4. Tester chaque node individuellement

## Workflow 1 : Réception Lead Website

### Objectif
Recevoir message du chatbot, créer/récupérer conversation, appeler LLM, sauvegarder réponse.

### Diagramme
```
[Webhook Trigger]
    ↓
[Function: Extract & Validate Input]
    ↓
[Supabase: Get or Create Conversation] ←─┐
    ↓                                     │
[Function: Load System Prompt]            │
    ↓                                     │
[HTTP Request: Claude API]                │
    ↓                                     │
[Function: Parse LLM Response]            │
    ↓                                     │
[Supabase: Save User Message]             │
    ↓                                     │
[Supabase: Save Assistant Message]        │
    ↓                                     │
[Function: Update Lead if needed] ────────┘
    ↓
[Webhook Response]
```

### Nodes à créer

#### 1. Webhook Trigger
```
Type: Webhook
HTTP Method: POST
Path: chat
Response Mode: Respond to Webhook
```

**Input attendu** :
```json
{
  "session_id": "uuid-or-client-identifier",
  "message": "Bonjour, j'ai mon pare-brise fissuré"
}
```

#### 2. Function: Extract & Validate Input
```javascript
// Valide et nettoie l'input
const sessionId = $input.item.json.session_id;
const message = $input.item.json.message;

if (!sessionId || !message) {
  throw new Error('session_id et message sont obligatoires');
}

return {
  json: {
    session_id: sessionId,
    message: message.trim(),
    timestamp: new Date().toISOString()
  }
};
```

#### 3. Supabase: Get or Create Conversation
```
Operation: Execute Query
Query:
  INSERT INTO conversations (id, lead_source, status, language)
  VALUES ('{{$json.session_id}}', 'website', 'active', 'fr')
  ON CONFLICT (id) DO UPDATE SET updated_at = NOW()
  RETURNING *;
```

**Alternative** (2 nodes) :
- Node 1 : SELECT * FROM conversations WHERE id = '{{$json.session_id}}'
- Node 2 : IF (pas de résultat) → INSERT

#### 4. Function: Load System Prompt
```javascript
// Charge le prompt système (à customiser selon vos besoins)
const systemPrompt = `Tu es l'assistant virtuel de OuiGlass Suisse, spécialiste du remplacement de vitrage automobile.

TON RÔLE :
1. Convertir chaque lead en RDV confirmé
2. Collecter TOUTES les informations nécessaires pour l'assurance
3. Être ultra-efficace : pas de blabla, aller à l'essentiel

INFOS OBLIGATOIRES À COLLECTER :
- Nom complet
- Téléphone
- Email
- Adresse exacte intervention
- Marque et modèle véhicule
- Année véhicule
- Numéro VIN
- Type vitrage endommagé
- Photos du vitrage
- Caméra/capteur ADAS présent ?
- Compagnie d'assurance
- Numéro de sinistre
- Numéro de police d'assurance

RÈGLES :
- Messages COURTS (2-3 phrases max)
- Poser 1-2 questions max par message
- Ton amical et professionnel
- Toujours répondre en français

FORMAT DE RÉPONSE :
Retourne UNIQUEMENT un JSON valide avec cette structure :
{
  "message": "Ton message au client",
  "infos_collectees": {"vehicle_make": "BMW", ...},
  "checklist_completion": 25,
  "next_action": "demander_photos"
}`;

return {
  json: {
    system_prompt: systemPrompt,
    user_message: $input.item.json.message
  }
};
```

#### 5. HTTP Request: Claude API
```
Method: POST
URL: https://api.anthropic.com/v1/messages
Authentication: Header Auth (credentials Claude API)

Headers:
{
  "anthropic-version": "2023-06-01",
  "content-type": "application/json"
}

Body (JSON):
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "system": "{{$json.system_prompt}}",
  "messages": [
    {
      "role": "user",
      "content": "{{$json.user_message}}"
    }
  ]
}
```

#### 6. Function: Parse LLM Response
```javascript
// Extrait le texte de la réponse Claude
const response = $input.item.json;
const messageText = response.content[0].text;

// Tenter de parser le JSON
let parsed;
try {
  parsed = JSON.parse(messageText);
} catch (e) {
  // Si pas JSON, fallback
  parsed = {
    message: messageText,
    infos_collectees: {},
    checklist_completion: 0,
    next_action: 'continue'
  };
}

return { json: parsed };
```

#### 7. Supabase: Save User Message
```
Operation: Insert
Table: messages

Data:
{
  "conversation_id": "{{$node['Webhook'].json.session_id}}",
  "role": "user",
  "content": "{{$node['Webhook'].json.message}}"
}
```

#### 8. Supabase: Save Assistant Message
```
Operation: Insert
Table: messages

Data:
{
  "conversation_id": "{{$node['Webhook'].json.session_id}}",
  "role": "assistant",
  "content": "{{$node['Function: Parse LLM Response'].json.message}}"
}
```

#### 9. Supabase: Update Lead (optionnel)
```
Operation: Execute Query
Query:
  INSERT INTO leads (conversation_id, status)
  VALUES ('{{$node['Webhook'].json.session_id}}', 'collecting_info')
  ON CONFLICT (conversation_id) DO UPDATE
  SET
    updated_at = NOW(),
    -- Ajouter les infos collectées ici selon JSON LLM
    status = CASE
      WHEN {{$json.checklist_completion}} >= 100 THEN 'info_complete'
      ELSE 'collecting_info'
    END;
```

#### 10. Webhook Response
```
Response Mode: Using Respond to Webhook Node
Response Code: 200
Response Body:
{
  "message": "{{$json.message}}",
  "completion": {{$json.checklist_completion}},
  "session_id": "{{$node['Webhook'].json.session_id}}"
}
```

---

## Workflow 2 : Conversation Multi-Tours

### Objectif
Maintenir le contexte en récupérant l'historique de conversation avant d'appeler le LLM.

### Modifications par rapport au Workflow 1

**Ajouter après "Get or Create Conversation"** :

#### Node: Supabase Get Message History
```
Operation: Select
Table: messages
Filter: conversation_id = {{$json.session_id}}
Sort: created_at ASC
Limit: 50 (derniers 50 messages max)
```

#### Node: Function: Build Context
```javascript
// Construit l'historique pour Claude
const messages = $input.all();
const history = [];

messages.forEach(msg => {
  history.push({
    role: msg.json.role,
    content: msg.json.content
  });
});

// Ajouter le nouveau message user
history.push({
  role: 'user',
  content: $node['Webhook'].json.message
});

return {
  json: {
    messages: history,
    session_id: $node['Webhook'].json.session_id
  }
};
```

#### Node: HTTP Request Claude (modifié)
```json
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "system": "{{$node['Function: Load System Prompt'].json.system_prompt}}",
  "messages": {{$json.messages}}
}
```

---

## Workflow 3 : Création RDV

### Objectif
Quand toutes les infos sont collectées, calculer créneaux optimaux et créer RDV.

### Trigger
**Webhook** (appelé par Workflow 2 quand completion = 100%)

### Nodes

#### 1. Webhook Trigger
```
Path: create-appointment
Method: POST
Input: { "lead_id": "uuid" }
```

#### 2. Supabase: Get Lead Full Info
```
Operation: Select
Table: leads
Filter: id = {{$json.lead_id}}
```

#### 3. Function: Calculate Available Slots
```javascript
// Voir code dans SETUP-N8N.md section "Function Node : Calculer créneaux RDV"
// Retourne 3 créneaux proposés
```

#### 4. HTTP Request: LLM Generate Proposal
```javascript
// Demander à Claude de formuler la proposition de créneaux
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 512,
  "system": "Tu es l'assistant OuiGlass. Formule une proposition de 3 créneaux de manière amicale et claire.",
  "messages": [
    {
      "role": "user",
      "content": "Voici 3 créneaux disponibles : {{$json.proposed_slots}}. Formule un message pour proposer au client."
    }
  ]
}
```

#### 5. Webhook Response: Send Slots
```json
{
  "message": "{{$json.llm_message}}",
  "slots": {{$node['Function: Calculate Available Slots'].json.proposed_slots}},
  "action": "choose_slot"
}
```

**Note** : La confirmation du créneau se fait via le Workflow 2 (le client répond avec son choix).

#### 6. When Client Chooses (nouveau webhook)

Webhook Path: `confirm-appointment`
Input: `{ "lead_id": "uuid", "chosen_slot": "2025-01-20T10:00:00Z" }`

#### 7. Google Calendar: Create Event
```
Calendar: [Votre calendrier OuiGlass]
Summary: RDV {{$json.client_name}} - {{$json.vehicle_make}} {{$json.vehicle_model}}
Start: {{$json.chosen_slot}}
Duration: 90 (minutes)
Description: Toutes les infos du lead
Location: {{$json.client_address}}
```

#### 8. Supabase: Create Appointment
```
Operation: Insert
Table: appointments

Data:
{
  "lead_id": "{{$json.lead_id}}",
  "scheduled_at": "{{$json.chosen_slot}}",
  "zone": "{{$json.zone}}",
  "status": "scheduled",
  "duration_minutes": 90
}
```

#### 9. Send Confirmation Email (optionnel)
```
Node: Gmail / Send Email
To: {{$json.client_email}}
Subject: Votre RDV OuiGlass confirmé
Body: [Template avec récap]
```

#### 10. Trigger Notification Workflow
```
HTTP Request:
POST https://votre-instance.app.n8n.cloud/webhook/notification
Body: {
  "type": "new_appointment",
  "client_name": "{{$json.client_name}}",
  "datetime": "{{$json.chosen_slot}}",
  "zone": "{{$json.zone}}"
}
```

---

## Workflow 4 : Notifications WhatsApp

### Objectif
Envoyer notifications au propriétaire OuiGlass.

### Trigger
```
Webhook
Path: notification
Method: POST
```

### Input types
```json
{
  "type": "new_appointment|confirmation|rebooking|escalade",
  "client_name": "Jean Dupont",
  "datetime": "2025-01-20T10:00:00Z",
  "zone": "lausanne",
  "message": "Details supplémentaires..."
}
```

### Nodes

#### 1. Switch: Type de notification
```
Mode: Expression
Expression: {{$json.type}}

Routes:
  - new_appointment
  - confirmation
  - rebooking
  - escalade
```

#### 2a. Function: Format New Appointment
```javascript
const emoji = '🎯';
const client = $input.item.json.client_name;
const datetime = new Date($input.item.json.datetime).toLocaleString('fr-CH');
const zone = $input.item.json.zone;

return {
  json: {
    message: `${emoji} Nouveau RDV : ${client} - ${datetime} - ${zone}`
  }
};
```

#### 2b. Function: Format Confirmation
```javascript
return {
  json: {
    message: `✅ ${$input.item.json.client_name} a confirmé son RDV du ${new Date($input.item.json.datetime).toLocaleString('fr-CH')}`
  }
};
```

#### 2c. Function: Format Rebooking
```javascript
return {
  json: {
    message: `⚠️ RDV reporté : ${$input.item.json.client_name} - ${$input.item.json.message}`
  }
};
```

#### 2d. Function: Format Escalade
```javascript
return {
  json: {
    message: `🚨 ESCALADE : ${$input.item.json.client_name} demande intervention humaine - ${$input.item.json.message}`
  }
};
```

#### 3. HTTP Request: WhatsApp Business API
```
Method: POST
URL: https://graph.facebook.com/v18.0/{{PHONE_NUMBER_ID}}/messages

Headers:
{
  "Authorization": "Bearer {{ACCESS_TOKEN}}",
  "Content-Type": "application/json"
}

Body:
{
  "messaging_product": "whatsapp",
  "to": "{{$env.NOTIFICATION_WHATSAPP}}",
  "type": "text",
  "text": {
    "body": "{{$json.message}}"
  }
}
```

**Alternative sans WhatsApp (Phase 1)** :
Remplacer par node **Send Email** avec Gmail/SMTP.

---

## Configuration des credentials

Voir [SETUP-N8N.md](../../docs/SETUP-N8N.md) pour :
- Supabase credentials
- Claude API credentials
- Google Calendar OAuth2
- WhatsApp Business API (optionnel)

---

## Tests

Voir [TESTING.md](../../docs/TESTING.md) pour scénarios de test complets.

---

## Tips & Astuces

### Debug
- Toujours activer "Save execution data" dans workflow settings
- Utiliser "Execute Node" pour tester individuellement
- Vérifier les logs dans Executions

### Performance
- Limiter historique messages à 50 max (sinon tokens LLM explosent)
- Cacher réponses FAQ (éviter appels LLM inutiles)
- Utiliser Error Trigger workflow pour gérer failures

### Sécurité
- Ne JAMAIS exposer service_role key publiquement
- Valider tous les inputs (session_id, message, etc.)
- Rate limit sur webhooks (settings N8N)

---

**Prochaine étape** : [Configuration Chatbot](../../docs/SETUP-CHATBOT.md)
