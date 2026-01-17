# ⚙️ Guide Setup N8N - OuiGlass

## Vue d'ensemble

Ce guide vous explique **pas à pas** comment configurer N8N pour orchestrer votre agent IA OuiGlass.

**Durée estimée** : 30-45 minutes
**Niveau** : Débutant/Intermédiaire
**Prérequis** : Avoir complété [SETUP-SUPABASE.md](SETUP-SUPABASE.md)

## Qu'est-ce que N8N ?

**N8N** = Outil d'automation no-code/low-code (comme Zapier mais open-source et plus puissant)

**POURQUOI N8N ?**
- ✅ Interface visuelle (pas besoin de coder)
- ✅ 400+ intégrations natives (Supabase, OpenAI, Google Calendar, WhatsApp, etc.)
- ✅ Version Cloud hébergée (pas de serveur à gérer)
- ✅ Debugging facile avec logs visuels
- ✅ Exécutions illimitées (sur plan payant)

**ANALOGIE** : N8N = Chef d'orchestre qui coordonne tous vos outils (base de données, IA, calendrier, etc.)

---

## Étape 1 : Créer un compte N8N

### 1.1 Inscription

1. Aller sur [https://n8n.io](https://n8n.io)
2. Cliquer **"Get started for free"**
3. S'inscrire avec :
   - Email professionnel
   - Mot de passe fort
   - Accepter conditions

**IMPORTANT** : Vous devrez passer au **plan payant** pour production (à partir de $20/mois).
Le plan gratuit a des limites :
- 2,500 executions/mois (insuffisant pour production)
- Workflows désactivés après 7 jours d'inactivité

**RECOMMANDATION** : Commencer avec plan Starter ($20/mois) pour Phase 1.

### 1.2 Créer votre workspace

1. Nommer votre workspace : "OuiGlass Agent IA"
2. Timezone : Europe/Zurich
3. Confirmer

---

## Étape 2 : Comprendre l'interface N8N

### 2.1 Dashboard

Après login, vous arrivez sur le **Dashboard** :

**Menu gauche** :
- **Workflows** : Vos automations
- **Credentials** : Clés API (Supabase, Claude, etc.)
- **Executions** : Historique d'exécutions (logs)
- **Settings** : Configuration compte

### 2.2 Créer votre premier workflow (test)

1. Cliquer **"Workflows"** > **"Add Workflow"**
2. Vous voyez un canvas vide avec un bouton **"+"**

**Éléments de l'interface** :
```
┌─────────────────────────────────────────────┐
│  [Nom workflow]  [Save] [Test] [Execute]    │  <- Barre actions
├─────────────────────────────────────────────┤
│                                             │
│         [+] ← Cliquer pour ajouter node     │  <- Canvas
│                                             │
│                                             │
└─────────────────────────────────────────────┘
```

**Types de nodes** :
- **Trigger** : Démarre le workflow (Webhook, Schedule, Email)
- **Action** : Fait une action (Supabase Insert, HTTP Request)
- **Logic** : Logique (IF, Switch, Loop)
- **Function** : Code JavaScript custom

### 2.3 Test simple : Webhook Hello World

**Objectif** : Créer un webhook qui retourne "Hello World"

1. Cliquer **"+"** > Chercher **"Webhook"**
2. Sélectionner **"Webhook"** trigger
3. Configuration :
   ```
   HTTP Method: POST
   Path: test
   Response Mode: Respond to Webhook
   ```
4. Cliquer **"Execute Node"** (en bas à droite)
5. Copier l'URL générée : `https://votre-instance.app.n8n.cloud/webhook-test/test`

6. Tester dans un terminal :
   ```bash
   curl -X POST https://votre-instance.app.n8n.cloud/webhook-test/test \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello"}'
   ```

7. Vous devriez voir la réponse dans N8N

**FÉLICITATIONS !** Vous avez créé votre premier workflow ! 🎉

---

## Étape 3 : Configurer les Credentials

### 3.1 Credentials Supabase

1. Menu **"Credentials"** > **"Add Credential"**
2. Chercher **"Supabase"**
3. Remplir :
   ```
   Name: Supabase OuiGlass
   Host: https://xxxxxxxxxxxxx.supabase.co (votre URL Supabase)
   Service Role Secret: eyJhbG... (votre service_role key)
   ```
4. **"Save"**

**PIÈGE** :
- ❌ Ne PAS utiliser `anon` key (insuffisante pour N8N)
- ✅ Utiliser `service_role` key (accès complet)

### 3.2 Credentials Claude API (Anthropic)

1. **Obtenir clé API Claude** :
   - Aller sur [https://console.anthropic.com](https://console.anthropic.com)
   - Sign up / Login
   - API Keys > Create Key
   - Copier la clé `sk-ant-api03-...`

2. Dans N8N :
   - Credentials > Add Credential
   - Chercher **"HTTP Header Auth"** (pas de node Claude natif)
   - Configurer :
     ```
     Name: Claude API
     Header Name: x-api-key
     Value: sk-ant-api03-...
     ```
   - Save

**Alternative** : OpenAI
- Credentials > OpenAI
- API Key : `sk-...`

### 3.3 Credentials Cloudinary (photos)

1. **Obtenir credentials Cloudinary** :
   - [https://cloudinary.com/users/register/free](https://cloudinary.com/users/register/free)
   - Sign up gratuit
   - Dashboard > Account Details
   - Copier : Cloud Name, API Key, API Secret

2. Dans N8N :
   - Credentials > Add > **"Cloudinary API"**
   - Remplir :
     ```
     Cloud Name: ouiglass-suisse
     API Key: ...
     API Secret: ...
     ```

### 3.4 Credentials Google Calendar (Phase 1)

1. **Créer projet Google Cloud** (si pas déjà fait) :
   - [https://console.cloud.google.com](https://console.cloud.google.com)
   - Create Project : "OuiGlass Agent"

2. **Activer Google Calendar API** :
   - APIs & Services > Library
   - Chercher "Google Calendar API"
   - Enable

3. **Créer OAuth credentials** :
   - APIs & Services > Credentials
   - Create Credentials > OAuth 2.0 Client ID
   - Application type: Web application
   - Authorized redirect URIs:
     ```
     https://votre-instance.app.n8n.cloud/rest/oauth2-credential/callback
     ```
   - Create
   - Copier Client ID + Client Secret

4. **Dans N8N** :
   - Credentials > Add > **"Google Calendar OAuth2"**
   - Remplir Client ID + Secret
   - **Connect my account**
   - Autoriser accès

### 3.5 Credentials WhatsApp Business (Phase 2 - optionnel)

Voir [SETUP-WHATSAPP.md](SETUP-WHATSAPP.md) pour configuration complète.

**Pour Phase 1** : Vous pouvez sauter cette étape et utiliser email pour notifications.

---

## Étape 4 : Importer les workflows Phase 1

### 4.1 Liste des workflows à importer

Dans le dossier `n8n-workflows/phase1/` :

1. `01-reception-lead-website.json` - Réception lead chatbot
2. `02-conversation-multi-tours.json` - Gestion conversation
3. `03-creation-rdv.json` - Validation et création RDV
4. `04-notifications-whatsapp.json` - Notifications propriétaire

### 4.2 Import Workflow 1 : Réception Lead Website

1. Dans N8N, **Workflows** > **"Import from File"**
2. Sélectionner `n8n-workflows/phase1/01-reception-lead-website.json`
3. Le workflow s'ouvre dans l'éditeur

**Nodes présents** :
```
[Webhook Trigger]
    ↓
[Function: Détection langue]
    ↓
[Supabase: Chercher conversation]
    ↓
[IF: Conversation existe?]
    ├─ OUI → [Supabase: Update conversation]
    └─ NON → [Supabase: Create conversation]
    ↓
[HTTP Request: Claude API]
    ↓
[Function: Parser réponse]
    ↓
[Supabase: Save message user]
    ↓
[Supabase: Save message assistant]
    ↓
[Webhook Response]
```

4. **Configurer les nodes** :

**Node "Supabase: Chercher conversation"** :
- Credentials : Sélectionner "Supabase OuiGlass"
- Operation : Select
- Table : conversations
- Filter : `id = {{$json.session_id}}`

**Node "HTTP Request: Claude API"** :
- Method : POST
- URL : `https://api.anthropic.com/v1/messages`
- Authentication : Header Auth (Claude API credentials)
- Headers :
  ```json
  {
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
  }
  ```
- Body (JSON) :
  ```json
  {
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 1024,
    "system": "{{$node['Function: Load System Prompt'].json.prompt}}",
    "messages": [
      {
        "role": "user",
        "content": "{{$json.message}}"
      }
    ]
  }
  ```

5. **Sauvegarder** : Ctrl+S ou bouton "Save"
6. **Nommer** : "01 - Réception Lead Website"
7. **Activer** : Toggle en haut à droite (ON)

**IMPORTANT** : Une fois activé, le webhook est **live** (accessible publiquement).

### 4.3 Tester Workflow 1

1. **Copier l'URL du webhook** :
   - Cliquer sur node "Webhook Trigger"
   - Copier "Production Webhook URL"
   - Ex: `https://votre-instance.app.n8n.cloud/webhook/chat`

2. **Tester avec curl** :
   ```bash
   curl -X POST https://votre-instance.app.n8n.cloud/webhook/chat \
     -H "Content-Type: application/json" \
     -d '{
       "session_id": "test-123",
       "message": "Bonjour, j'\''ai mon pare-brise fissuré"
     }'
   ```

3. **Vérifier la réponse** :
   ```json
   {
     "message": "Bonjour ! Je suis désolé pour votre pare-brise...",
     "completion": 5,
     "session_id": "test-123"
   }
   ```

4. **Vérifier dans Supabase** :
   - Table `conversations` : une nouvelle ligne créée
   - Table `messages` : 2 messages (user + assistant)

**Si ça marche : BRAVO ! 🎉**

**Si erreur** :
- Voir **Executions** (menu gauche) pour logs détaillés
- Vérifier credentials Supabase et Claude
- Vérifier que les tables existent dans Supabase

### 4.4 Import des autres workflows

Répéter le processus pour :
- Workflow 2 : `02-conversation-multi-tours.json`
- Workflow 3 : `03-creation-rdv.json`
- Workflow 4 : `04-notifications-whatsapp.json`

**Configuration spécifique Workflow 3** :

Node "Google Calendar: Create Event" :
- Credentials : Google Calendar OAuth2
- Calendar : Sélectionner votre calendrier OuiGlass
- Start : `{{$json.appointment_datetime}}`
- Duration : 90 (minutes)

**Configuration spécifique Workflow 4** :

Node "HTTP Request: WhatsApp" :
- URL : `https://graph.facebook.com/v18.0/{{PHONE_NUMBER_ID}}/messages`
- Headers :
  ```json
  {
    "Authorization": "Bearer {{ACCESS_TOKEN}}",
    "Content-Type": "application/json"
  }
  ```

**Pour Phase 1 sans WhatsApp** : Remplacer par node "Send Email" (Gmail/SMTP)

---

## Étape 5 : Comprendre les Function Nodes

### 5.1 Function Node : Détection langue

**Code JavaScript** :
```javascript
// Détecte la langue du message (français par défaut en Suisse romande)
const message = $input.item.json.message || '';

// Mots-clés français
const frenchKeywords = ['bonjour', 'salut', 'merci', 'oui', 'non', 'bris', 'pare-brise'];

// Mots-clés anglais
const englishKeywords = ['hello', 'hi', 'thanks', 'yes', 'no', 'windshield', 'glass'];

const messageLower = message.toLowerCase();

let language = 'fr'; // Par défaut français

// Check si anglais
const englishCount = englishKeywords.filter(word => messageLower.includes(word)).length;
if (englishCount > 0) {
  language = 'en';
}

return {
  json: {
    ...($input.item.json),
    detected_language: language
  }
};
```

**POURQUOI ce code ?**
- La plupart des clients en Suisse romande parlent français
- Détection simple par mots-clés (suffisant pour Phase 1)
- Phase 2 : Utiliser API de détection plus sophistiquée

### 5.2 Function Node : Parser réponse LLM

```javascript
// Extrait le texte de la réponse Claude
const response = $input.item.json;

// Claude API retourne : { content: [{ type: "text", text: "..." }] }
const messageText = response.content[0].text;

// Tenter de parser si JSON
let parsedMessage = { message: messageText };
try {
  // Si le LLM retourne du JSON (selon prompt système)
  parsedMessage = JSON.parse(messageText);
} catch (e) {
  // Pas JSON, garder texte brut
}

return {
  json: {
    message: parsedMessage.message || messageText,
    infos_collectees: parsedMessage.infos_collectees || {},
    completion: parsedMessage.checklist_completion || 0,
    next_action: parsedMessage.next_action || 'continue'
  }
};
```

### 5.3 Function Node : Calculer créneaux RDV

```javascript
// Calcule 3 créneaux optimaux selon la zone du client
const canton = $input.item.json.canton;
const preferredDate = $input.item.json.preferred_date;

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

// Jours préférés par zone (pour regroupement)
const preferredDays = {
  'geneve': [1, 3, 5],      // Lun, Mer, Ven
  'lausanne': [2, 4],       // Mar, Jeu
  'valais': [3],            // Mer
  'fribourg': [2, 5],       // Mar, Ven
  'neuchatel': [1, 4],      // Lun, Jeu
  'jura': [5]               // Ven
};

// Générer 3 propositions (logique simplifiée - en vrai checker RDV existants)
const now = new Date();
const slots = [];

for (let i = 1; i <= 14; i++) {
  const date = new Date(now);
  date.setDate(date.getDate() + i);

  const dayOfWeek = date.getDay(); // 0 = Dim, 1 = Lun, etc.

  // Vérifier si jour préféré pour cette zone
  if (preferredDays[zone].includes(dayOfWeek)) {
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

**NOTE** : Ce code est **simplifié** pour Phase 1. En Phase 3 :
- Récupérer RDV existants depuis Supabase
- Vérifier disponibilité réelle
- Prendre en compte durée intervention (ADAS = 90min)
- Laisser 30min entre RDV

---

## Étape 6 : Debugging et Logs

### 6.1 Executions (Historique)

**Où voir ?** Menu **"Executions"**

**Informations visibles** :
- Date/heure exécution
- Workflow concerné
- Statut : ✅ Success, ❌ Error, ⏸ Waiting
- Durée d'exécution
- Données de chaque step

**Comment débugger** :
1. Cliquer sur une execution
2. Voir le workflow avec les données qui ont circulé
3. Cliquer sur chaque node pour voir input/output
4. Identifier où ça casse

**ASTUCE** : Activer **"Save execution data"** :
- Workflow Settings > Executions
- Save execution data: **Always**
- Permet de voir même les executions réussies

### 6.2 Erreurs courantes

**Error: "Table conversations does not exist"**
→ Supabase pas configuré correctement
→ Vérifier que schema.sql a été exécuté

**Error: "Invalid API key"**
→ Credentials mal configurées
→ Revérifier clés API

**Error: "Timeout"**
→ Claude API trop lent
→ Augmenter timeout dans node HTTP Request (Settings > Timeout: 30000ms)

**Error: "Cannot read property 'json'"**
→ Node précédent a retourné données vides
→ Vérifier flow logique

### 6.3 Mode Test vs Production

**Test Webhook** : `https://.../webhook-test/chat`
- Utiliser pendant développement
- Pas sauvegardé dans executions (sauf si activé)

**Production Webhook** : `https://.../webhook/chat`
- Utiliser quand workflow activé
- Toutes executions sauvegardées
- C'est cette URL qu'il faut mettre dans le chatbot

---

## Étape 7 : Variables d'environnement

### 7.1 Variables globales

**Où configurer ?** Settings > Variables

**Variables à créer** :
```
BUSINESS_NAME = OuiGlass Suisse
BUSINESS_PHONE = +41791234567
BUSINESS_EMAIL = contact@ouiglass.ch
NOTIFICATION_WHATSAPP = +41791234567
GOOGLE_REVIEW_LINK = https://g.page/r/...
```

**Utilisation dans workflows** :
```javascript
// Dans Function node
const businessName = $env.BUSINESS_NAME;

// Dans HTTP Request body
"footer": "{{$env.BUSINESS_NAME}} - {{$env.BUSINESS_PHONE}}"
```

### 7.2 Secrets (clés API)

**NE JAMAIS mettre les clés API en variables** → Utiliser Credentials

Variables = lisibles par tous les workflows
Credentials = chiffrées, accès contrôlé

---

## Étape 8 : Optimisation & Performance

### 8.1 Limites de rate

**Claude API** :
- Tier 1 : 50 req/min, 40,000 tokens/min
- Tier 2+ : Plus élevé

**Google Calendar API** :
- 1,000,000 req/jour (largement suffisant)

**Supabase** :
- Connections : 60 simultanées (plan Free)
- Queries : Illimitées

### 8.2 Caching

**Pour éviter d'appeler Claude trop souvent** :

1. Vérifier si question déjà posée (cache dans Supabase)
2. Réponses pré-définies pour questions FAQ
3. N'appeler Claude que si vraiment nécessaire

**Exemple** :
```javascript
// Function: Check FAQ
const message = $input.item.json.message.toLowerCase();

const faq = {
  'horaires': 'Nous sommes ouverts du lundi au vendredi, 8h-18h.',
  'tarif': 'Le tarif dépend de votre assurance. Zéro avance de frais.',
  'délai': 'Intervention possible sous 24-48h selon votre zone.'
};

for (const [keyword, answer] of Object.entries(faq)) {
  if (message.includes(keyword)) {
    return { json: { cached: true, message: answer } };
  }
}

return { json: { cached: false } };
```

### 8.3 Error handling

**Toujours ajouter Error Trigger** :
1. Créer workflow "Error Handler"
2. Trigger : **Error Trigger**
3. Action : Send notification (email/WhatsApp)
4. Body : Details de l'erreur

**Activer sur tous les workflows** :
- Workflow Settings > Error Workflow
- Sélectionner "Error Handler"

---

## ✅ Checklist finale

Avant de déployer en production :

- [ ] Compte N8N créé (plan Starter minimum)
- [ ] Credentials configurées (Supabase, Claude, Google Calendar)
- [ ] 4 workflows Phase 1 importés et actifs
- [ ] Test webhook réussi (curl ou chatbot)
- [ ] Executions sauvegardées (Settings > Always)
- [ ] Variables d'environnement configurées
- [ ] Error workflow créé et activé
- [ ] URL webhook production copiée (pour chatbot)

**Si tout est ✅ : PARFAIT !** Vous pouvez passer au chatbot ! 🚀

---

## Prochaines étapes

1. [Configuration Chatbot](SETUP-CHATBOT.md) - Intégrer sur site web
2. [Configuration Notifications](SETUP-NOTIFICATIONS.md) - WhatsApp/Email
3. [Tests](TESTING.md) - Scénarios de validation

---

## Ressources

- [Documentation N8N](https://docs.n8n.io)
- [N8N Community](https://community.n8n.io)
- [Tutoriels vidéo N8N](https://www.youtube.com/@n8n-io)

**Questions ?** Voir [API-DOCUMENTATION.md](API-DOCUMENTATION.md) pour détails webhooks.
