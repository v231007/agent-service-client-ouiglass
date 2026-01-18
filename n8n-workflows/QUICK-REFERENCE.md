# 🚀 N8N Workflows - Guide Rapide Copier-Coller

## Vue d'ensemble

Ce fichier contient TOUS les codes JavaScript à copier-coller dans N8N.
Pour chaque workflow, créez les nodes dans l'ordre et copiez les codes indiqués.

---

## WORKFLOW 1 : Réception Lead Website

### Node 1 : Webhook Trigger
**Type** : Webhook
**Config** :
- HTTP Method : POST
- Path : chat
- Response Mode : Respond to Webhook

### Node 2 : Function - Extract & Validate Input

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

### Node 3 : Supabase - Get or Create Conversation
**Type** : Supabase
**Operation** : Execute Query
**Query** :
```sql
INSERT INTO conversations (id, lead_source, status, language)
VALUES ('{{$json.session_id}}', 'website', 'active', 'fr')
ON CONFLICT (id) DO UPDATE SET updated_at = NOW()
RETURNING *;
```

### Node 4 : Function - Load System Prompt

```javascript
// Charge le prompt système
const systemPrompt = `Tu es l'assistant virtuel de OuiGlass Suisse, spécialiste du remplacement de vitrage automobile.

TON RÔLE :
1. Convertir chaque lead en RDV confirmé
2. Collecter TOUTES les informations nécessaires pour l'assurance
3. Être ultra-efficace : pas de blabla, aller à l'essentiel

INFOS OBLIGATOIRES À COLLECTER :
- Nom complet, téléphone, email, adresse exacte
- Marque, modèle, année véhicule, numéro VIN
- Type vitrage, photos, ADAS ?
- Compagnie assurance, n° sinistre, n° police

RÈGLES :
- Messages COURTS (2-3 phrases max)
- Poser 1-2 questions max par message
- Ton amical et professionnel
- Toujours en français
- Insister : "Zéro avance de frais"

FORMAT RÉPONSE JSON OBLIGATOIRE :
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

**NOTE** : Pour le prompt complet (recommandé), copiez depuis `prompts/system-prompt-main.md`

### Node 5 : HTTP Request - Claude API
**Type** : HTTP Request
**Method** : POST
**URL** : `https://api.anthropic.com/v1/messages`
**Authentication** : Header Auth (credentials Claude API)

**Headers** :
```json
{
  "anthropic-version": "2023-06-01",
  "content-type": "application/json"
}
```

**Body (JSON)** :
```json
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "system": "={{$json.system_prompt}}",
  "messages": [
    {
      "role": "user",
      "content": "={{$json.user_message}}"
    }
  ]
}
```

### Node 6 : Function - Parse LLM Response

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

### Node 7 : Supabase - Save User Message
**Type** : Supabase
**Operation** : Insert
**Table** : messages

**Data** :
```json
{
  "conversation_id": "={{$node['Webhook'].json.session_id}}",
  "role": "user",
  "content": "={{$node['Webhook'].json.message}}"
}
```

### Node 8 : Supabase - Save Assistant Message
**Type** : Supabase
**Operation** : Insert
**Table** : messages

**Data** :
```json
{
  "conversation_id": "={{$node['Webhook'].json.session_id}}",
  "role": "assistant",
  "content": "={{$node['Function: Parse LLM Response'].json.message}}"
}
```

### Node 9 : Webhook Response
**Type** : Respond to Webhook
**Response Body** :
```json
{
  "message": "={{$json.message}}",
  "completion": "={{$json.checklist_completion}}",
  "session_id": "={{$node['Webhook'].json.session_id}}"
}
```

---

## WORKFLOW 2 : Conversation Multi-Tours

**Modification du Workflow 1** : Ajouter récupération de l'historique

### Node ajouté après "Get or Create Conversation" :

**Node : Supabase - Get Message History**
**Type** : Supabase
**Operation** : Select
**Table** : messages

**Filter** :
```
conversation_id = {{$json.session_id}}
```

**Sort** : created_at ASC
**Limit** : 50

### Node : Function - Build Context

```javascript
// Construit l'historique pour Claude
const messages = $input.all();
const history = [];

// Parcourir messages existants
messages.forEach(msg => {
  if (msg.json.role && msg.json.content) {
    history.push({
      role: msg.json.role,
      content: msg.json.content
    });
  }
});

// Ajouter nouveau message user
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

### Modifier Node HTTP Request Claude :

**Body (JSON)** devient :
```json
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "system": "={{$node['Function: Load System Prompt'].json.system_prompt}}",
  "messages": "={{$json.messages}}"
}
```

---

## WORKFLOW 3 : Création RDV

### Node 1 : Webhook Trigger
**Path** : create-appointment
**Method** : POST

### Node 2 : Supabase - Get Lead Full Info
**Type** : Supabase
**Operation** : Select
**Table** : leads
**Filter** : `id = {{$json.lead_id}}`

### Node 3 : Function - Calculate Available Slots

```javascript
// Calcule 3 créneaux optimaux
const canton = $input.item.json.canton;

// Mapping canton → zone
const cantonToZone = {
  'Genève': 'geneve',
  'Vaud': 'lausanne',
  'Valais': 'valais',
  'Fribourg': 'fribourg',
  'Neuchâtel': 'neuchatel',
  'Jura': 'jura'
};

const zone = cantonToZone[canton] || 'lausanne';

// Jours préférés par zone
const preferredDays = {
  'geneve': [1, 3, 5],      // Lun, Mer, Ven
  'lausanne': [2, 4],       // Mar, Jeu
  'valais': [3],            // Mer
  'fribourg': [2, 5],       // Mar, Ven
  'neuchatel': [1, 4],      // Lun, Jeu
  'jura': [5]               // Ven
};

// Générer 3 propositions
const now = new Date();
const slots = [];

for (let i = 1; i <= 14; i++) {
  const date = new Date(now);
  date.setDate(date.getDate() + i);
  const dayOfWeek = date.getDay();

  // Vérifier si jour préféré pour cette zone
  if (preferredDays[zone] && preferredDays[zone].includes(dayOfWeek)) {
    // Créneaux : 9h, 11h, 14h, 16h
    const times = ['09:00', '11:00', '14:00', '16:00'];

    times.forEach(time => {
      const slotDate = new Date(date);
      const [hour, minute] = time.split(':');
      slotDate.setHours(hour, minute, 0, 0);

      slots.push({
        datetime: slotDate.toISOString(),
        zone: zone,
        display: `${date.toLocaleDateString('fr-CH')} à ${time}`
      });
    });
  }

  if (slots.length >= 3) break;
}

return {
  json: {
    proposed_slots: slots.slice(0, 3),
    zone: zone
  }
};
```

### Node 4 : Google Calendar - Create Event (quand client choisit)
**Type** : Google Calendar
**Operation** : Create Event

**Config** :
- Calendar : [Votre calendrier OuiGlass]
- Summary : `RDV {{$json.client_name}} - {{$json.vehicle_make}}`
- Start : `{{$json.chosen_slot}}`
- Duration : 90 (minutes)
- Description : Toutes les infos
- Location : `{{$json.client_address}}`

### Node 5 : Supabase - Create Appointment
**Type** : Supabase
**Operation** : Insert
**Table** : appointments

**Data** :
```json
{
  "lead_id": "={{$json.lead_id}}",
  "scheduled_at": "={{$json.chosen_slot}}",
  "zone": "={{$json.zone}}",
  "status": "scheduled",
  "duration_minutes": 90
}
```

---

## WORKFLOW 4 : Notifications WhatsApp

### Node 1 : Webhook Trigger
**Path** : notification
**Method** : POST

### Node 2 : Switch - Type de notification
**Type** : Switch
**Mode** : Expression
**Expression** : `{{$json.type}}`

**Routes** :
- new_appointment
- confirmation
- rebooking
- escalade

### Node 3a : Function - Format New Appointment

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

### Node 3b : Function - Format Confirmation

```javascript
return {
  json: {
    message: `✅ ${$input.item.json.client_name} a confirmé son RDV du ${new Date($input.item.json.datetime).toLocaleString('fr-CH')}`
  }
};
```

### Node 3c : Function - Format Rebooking

```javascript
return {
  json: {
    message: `⚠️ RDV reporté : ${$input.item.json.client_name} - ${$input.item.json.message}`
  }
};
```

### Node 3d : Function - Format Escalade

```javascript
return {
  json: {
    message: `🚨 ESCALADE : ${$input.item.json.client_name} demande intervention humaine - ${$input.item.json.message}`
  }
};
```

### Node 4 : HTTP Request - WhatsApp API
**Type** : HTTP Request
**Method** : POST
**URL** : `https://graph.facebook.com/v18.0/{{PHONE_NUMBER_ID}}/messages`

**Headers** :
```json
{
  "Authorization": "Bearer {{ACCESS_TOKEN}}",
  "Content-Type": "application/json"
}
```

**Body** :
```json
{
  "messaging_product": "whatsapp",
  "to": "={{$env.NOTIFICATION_WHATSAPP}}",
  "type": "text",
  "text": {
    "body": "={{$json.message}}"
  }
}
```

**Alternative sans WhatsApp** : Utiliser node "Send Email" (Gmail/SMTP)

---

## ⚙️ Configuration Variables N8N

Dans N8N > Settings > Variables, créer :

```
BUSINESS_NAME = OuiGlass Suisse
BUSINESS_PHONE = +41791234567
BUSINESS_EMAIL = contact@ouiglass.ch
NOTIFICATION_WHATSAPP = +41791234567
```

---

## 🔑 Credentials à configurer

### 1. Supabase
- Name : Supabase OuiGlass
- Host : https://xxxxx.supabase.co
- Service Role Secret : eyJhbG...

### 2. Claude API
- Type : HTTP Header Auth
- Name : Claude API
- Header Name : x-api-key
- Value : sk-ant-api03-...

### 3. Google Calendar
- Type : Google Calendar OAuth2
- [Suivre guide OAuth Google Cloud]

---

## 📖 Documentation complète

Pour explications détaillées :
- **Setup complet** : `docs/SETUP-N8N.md`
- **Workflows détaillés** : `n8n-workflows/phase1/README.md`
- **Architecture** : `docs/ARCHITECTURE.md`

---

## 💡 Tips

1. **Tester chaque node** individuellement avec "Execute Node"
2. **Activer "Save execution data"** dans workflow settings
3. **Commencer par Workflow 1** avant les autres
4. **Vérifier les credentials** avant d'activer les workflows

---

Bonne chance ! 🚀
