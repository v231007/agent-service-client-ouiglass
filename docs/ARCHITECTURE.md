# 🏗️ Architecture du Système OuiGlass Agent IA

## Vue d'ensemble

Ce document explique l'architecture complète du système d'agent IA pour OuiGlass Suisse. Il est conçu pour être compréhensible par les débutants tout en fournissant les détails techniques nécessaires.

## 📊 Schéma d'architecture global

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT FINAL                              │
│  [Site Web] [Email] [WhatsApp] [Téléphone]                     │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ Webhooks HTTPS
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    N8N WORKFLOWS (Cloud)                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Workflow 1: Réception Lead Multi-Canal                │    │
│  │  • Webhook Trigger (chatbot, email, WhatsApp)         │    │
│  │  • Détection langue (FR/EN)                           │    │
│  │  • Création conversation Supabase                     │    │
│  │  • Appel LLM                                          │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Workflow 2: Conversation Multi-Tours                  │    │
│  │  • Récupération historique conversation              │    │
│  │  • Construction contexte LLM                          │    │
│  │  • Détection completion infos                         │    │
│  │  • Sauvegarde messages                                │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Workflow 3: Validation & Création RDV                 │    │
│  │  • Calcul créneaux optimaux par zone                  │    │
│  │  • Création RDV Google Calendar                       │    │
│  │  • Email confirmation client                          │    │
│  │  • Notification WhatsApp propriétaire                 │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Workflow 4: Confirmation J-1                          │    │
│  │  • Schedule quotidien (9h)                            │    │
│  │  • Rappel client automatique                          │    │
│  │  • Gestion rebooking                                  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└────┬────────────┬────────────┬────────────┬────────────────────┘
     │            │            │            │
     ▼            ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  LLM    │  │Supabase │  │Cloudinary│ │WhatsApp │
│ Claude  │  │PostgreSQL│ │  S3     │  │   API   │
│  GPT-4  │  │         │  │         │  │         │
└─────────┘  └─────────┘  └─────────┘  └─────────┘
```

## 🧩 Composants détaillés

### 1. Canaux d'entrée (Frontend)

#### Chatbot Web
**Rôle** : Widget JavaScript intégré sur ouiglass.ch
**Fonctionnalités** :
- Apparaît après 5 secondes sur la page
- Upload de photos (drag & drop)
- Indicateur "Agent en train d'écrire..."
- Responsive (desktop + mobile)

**Technologies** :
- Vanilla JavaScript (pas de framework)
- CSS moderne (flexbox, grid)
- Fetch API pour communication webhook

**Flow** :
```
User tape message → JS envoie POST webhook N8N →
N8N traite → Retourne réponse → JS affiche dans chat
```

#### Email
**Rôle** : Réception et traitement emails clients
**Fonctionnalités** :
- Parsing automatique du contenu
- Détection type de demande (nouveau lead, question RDV, réclamation)
- Réponse automatique ou escalade humain

**Technologies** :
- N8N Email Trigger (IMAP)
- N8N Function pour nettoyage (retirer signatures, etc.)

#### WhatsApp Business
**Rôle** : Conversations sur WhatsApp
**Fonctionnalités** :
- Message d'accueil automatique
- Support envoi/réception photos
- Notifications propriétaire

**Technologies** :
- WhatsApp Business API (Meta)
- N8N WhatsApp Trigger

#### Téléphone (Phase 2)
**Rôle** : Conversion voicemail en texte
**Technologies** :
- Service voicemail-to-text (Twilio, Assembly AI)
- N8N webhook

---

### 2. N8N Orchestration (Cœur du système)

**POURQUOI N8N ?**
- Interface visuelle no-code/low-code
- 400+ intégrations natives
- Version Cloud hébergée (pas de serveur à gérer)
- Debugging facile avec logs visuels
- Versioning des workflows

**COMMENT ça marche ?**

N8N est un outil d'**automation** qui exécute des **workflows**.
Un workflow = suite de **nodes** (étapes) qui s'exécutent dans l'ordre.

**Exemple simple** :
```
[Webhook reçoit message]
    → [Function: extrait le texte]
    → [HTTP Request: envoie à Claude API]
    → [Function: traite la réponse]
    → [Webhook Response: retourne au client]
```

**PIÈGES à éviter** :
- ❌ Ne pas activer le workflow (bouton toggle en haut)
- ❌ Oublier de configurer les credentials (clés API)
- ❌ Ne pas sauvegarder les executions (Settings > Save execution data)
- ❌ Utiliser des webhooks HTTP au lieu de HTTPS en production

**Types de Nodes utilisés** :

| Node | Usage | Exemple |
|------|-------|---------|
| **Webhook** | Recevoir requête HTTP | Chatbot envoie message |
| **Supabase** | Lire/écrire en base | Sauvegarder conversation |
| **HTTP Request** | Appeler API externe | Claude API, Google Calendar |
| **Function** | Code JavaScript custom | Calculer créneaux RDV |
| **Switch** | Branchement conditionnel | Si infos complètes → créer RDV |
| **Set** | Modifier les données | Reformater date |
| **Schedule Trigger** | Exécution planifiée | Tous les jours à 9h |

---

### 3. LLM (Intelligence conversationnelle)

**Rôle** : Comprendre client et générer réponses naturelles

**Options** :
1. **Claude (Anthropic)** - Recommandé
   - Meilleur en français
   - Moins cher que GPT-4
   - 200K tokens de contexte
   - API simple

2. **GPT-4 (OpenAI)**
   - Alternative valide
   - Très bon aussi
   - Plus connu

**Comment ça marche ?**

```javascript
// Node HTTP Request dans N8N
POST https://api.anthropic.com/v1/messages
Headers: {
  "x-api-key": "{{$credentials.anthropic_api_key}}",
  "anthropic-version": "2023-06-01",
  "content-type": "application/json"
}
Body: {
  "model": "claude-sonnet-4",
  "max_tokens": 1024,
  "system": "Tu es l'assistant OuiGlass...", // Prompt système
  "messages": [
    {"role": "user", "content": "Bonjour, j'ai mon pare-brise fissuré"}
  ]
}

// Réponse
{
  "content": [
    {"type": "text", "text": "Bonjour ! Je suis désolé pour votre pare-brise..."}
  ],
  "stop_reason": "end_turn"
}
```

**Prompt Engineering** :
Le "system prompt" est CRUCIAL. Il contient :
- Le rôle de l'agent
- Les règles de conversation
- La checklist d'infos à collecter
- Le style de réponse (ton, longueur)
- Les réponses aux objections

Voir [prompts/system-prompt-main.md](../prompts/system-prompt-main.md)

**PIÈGES** :
- ❌ Prompt trop long (> 4000 mots) = lent et cher
- ❌ Pas d'exemples concrets = réponses génériques
- ❌ Pas de format de sortie = données non structurées
- ✅ Toujours demander un JSON en sortie pour faciliter le traitement

---

### 4. Supabase (Base de données)

**POURQUOI Supabase ?**
- PostgreSQL hébergé (robuste, SQL standard)
- Gratuit jusqu'à 500 MB + 2 GB bandwidth/mois
- Interface web simple
- API REST auto-générée
- Authentification intégrée
- Chiffrement des données

**COMMENT ça marche ?**

Supabase = PostgreSQL + API REST + Dashboard web

```
Créer table "conversations" dans Supabase Dashboard
    ↓
Supabase génère automatiquement API REST
    ↓
N8N peut faire : GET, POST, PUT, DELETE via node Supabase
```

**Tables principales** :

#### `conversations`
```sql
id              UUID        -- Identifiant unique
lead_source     VARCHAR     -- 'website', 'email', 'whatsapp'
contact_info    JSONB       -- {phone, email, name}
status          VARCHAR     -- 'active', 'rdv_confirmed', 'completed'
language        VARCHAR     -- 'fr', 'en'
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

**Exemple de données** :
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "lead_source": "website",
  "contact_info": {
    "phone": "+41791234567",
    "email": "client@example.com",
    "name": "Jean Dupont"
  },
  "status": "active",
  "language": "fr",
  "created_at": "2025-01-17T10:30:00Z"
}
```

#### `messages`
```sql
id                UUID        -- Identifiant unique
conversation_id   UUID        -- Référence conversation
role              VARCHAR     -- 'user' ou 'assistant'
content           TEXT        -- Message texte
attachments       JSONB       -- URLs photos si applicable
created_at        TIMESTAMP
```

#### `leads`
Stocke TOUTES les infos collectées (client, véhicule, assurance, etc.)
Structure complète dans [database/schema.sql](../database/schema.sql)

#### `appointments`
Stocke les RDV confirmés avec statut

**Utilisation dans N8N** :

```javascript
// Node Supabase "Insert"
Table: conversations
Data: {
  "lead_source": "website",
  "status": "active",
  "language": "fr"
}

// Node Supabase "Select"
Table: messages
Filter: conversation_id = {{$json.conversation_id}}
Order: created_at ASC
```

**PIÈGES** :
- ❌ Oublier d'activer Row Level Security (RLS) en production
- ❌ Exposer la clé `service_role` (utiliser `anon` key)
- ❌ Ne pas créer d'index sur les colonnes recherchées souvent
- ✅ Toujours utiliser prepared statements (protection SQL injection)

---

### 5. Cloudinary (Stockage photos)

**Rôle** : Stocker les photos de vitrages endommagés

**POURQUOI Cloudinary ?**
- Gratuit jusqu'à 25 GB storage + 25 GB bandwidth
- Upload direct depuis navigateur
- Transformation d'images (resize, compression)
- CDN mondial (rapide partout)

**Flow** :
```
Client upload photo dans chatbot
    ↓
JavaScript upload direct vers Cloudinary
    ↓
Cloudinary retourne URL de l'image
    ↓
Chatbot envoie URL à N8N
    ↓
N8N sauvegarde URL dans Supabase (table leads)
```

**Configuration** :
```javascript
// Dans chatbot JavaScript
cloudinary.upload({
  cloudName: 'ouiglass-suisse',
  uploadPreset: 'chatbot_photos', // Créer dans dashboard
  maxFileSize: 5000000, // 5 MB max
  acceptedFiles: 'image/*'
});
```

**Alternative** : AWS S3 (plus flexible, mais setup plus complexe)

---

### 6. Google Calendar (Planning temporaire Phase 1)

**Rôle** : Stocker les RDV en attendant l'intégration Otovia

**POURQUOI temporaire ?**
- Otovia API pas encore disponible
- Google Calendar = solution rapide pour MVP
- Migration facile vers Otovia plus tard

**Utilisation dans N8N** :

```javascript
// Node Google Calendar "Create Event"
Calendar: ouiglass.rdv@gmail.com
Title: "RDV {{$json.client_name}} - {{$json.vehicle_make}}"
Start: {{$json.appointment_datetime}}
Duration: 90 minutes (pare-brise ADAS) ou 60 minutes
Description: Toutes les infos client/véhicule/assurance
Location: {{$json.client_address}}
```

**Migration vers Otovia** (Phase 3) :
1. Garder Google Calendar en lecture seule
2. Créer workflow de synchro bidirectionnelle
3. Migrer progressivement les RDV
4. Désactiver création dans Google Calendar

---

### 7. WhatsApp Business API (Notifications)

**Rôle** : Envoyer notifications au propriétaire OuiGlass

**POURQUOI WhatsApp ?**
- Taux d'ouverture 98% (vs 20% email)
- Notifications temps réel sur mobile
- Gratuit pour notifications simples

**Setup** :
1. Créer compte Meta Business Suite
2. Vérifier entreprise (2-3 jours)
3. Créer WhatsApp Business App
4. Obtenir Phone Number ID + Access Token
5. Configurer webhook vers N8N

**Utilisation dans N8N** :

```javascript
// Node HTTP Request
POST https://graph.facebook.com/v18.0/{{PHONE_NUMBER_ID}}/messages
Headers: {
  "Authorization": "Bearer {{ACCESS_TOKEN}}",
  "Content-Type": "application/json"
}
Body: {
  "messaging_product": "whatsapp",
  "to": "+41791234567", // Votre numéro
  "type": "text",
  "text": {
    "body": "🎯 Nouveau RDV : Jean Dupont - 20/01 10h - Lausanne - Pare-brise"
  }
}
```

**Types de notifications** :
- 🎯 Nouveau RDV confirmé
- ✅ Confirmation J-1
- ⚠️ Rebooking
- 🚨 Escalade urgente
- ⭐ Avis négatif Google

**Alternative Phase 1** : SMS via Twilio ou simple email

---

## 📐 Flows détaillés (Phase 1)

### Flow 1 : Réception Lead Website

```
1. [Webhook Trigger]
   - URL : https://votre-n8n.app.n8n.cloud/webhook/chat
   - Method : POST
   - Body : { message: "...", session_id: "..." }

2. [Function: Détection langue]
   - Détecter si message en français ou anglais
   - Sauvegarder langue pour la suite

3. [Supabase: Chercher conversation existante]
   - SELECT * FROM conversations WHERE id = {{$json.session_id}}
   - Si existe : récupérer, sinon : créer nouvelle

4. [Supabase: Créer conversation si nouvelle]
   - INSERT INTO conversations (lead_source, language, status)
   - VALUES ('website', 'fr', 'active')

5. [HTTP Request: Appel LLM]
   - POST vers Claude API
   - System prompt + message user
   - Retour : réponse IA

6. [Function: Parser réponse LLM]
   - Extraire le message texte
   - Extraire les infos collectées (si JSON)
   - Calculer % completion checklist

7. [Supabase: Sauvegarder message user]
   - INSERT INTO messages (conversation_id, role, content)

8. [Supabase: Sauvegarder message assistant]
   - INSERT INTO messages (conversation_id, role, content)

9. [Switch: Checker si infos complètes]
   - Si completion >= 100% → Déclencher Workflow 3 (Création RDV)
   - Sinon → Continuer conversation

10. [Webhook Response]
    - Return { message: "...", completion: 65 }
```

**Diagramme** :
Voir [n8n-workflows/diagrams/01-reception-lead.png](../n8n-workflows/diagrams/)

---

### Flow 2 : Conversation Multi-Tours

**Objectif** : Maintenir le contexte de la conversation

```
1. [Webhook Trigger]
   - Nouveau message du client

2. [Supabase: Récupérer historique]
   - SELECT * FROM messages
     WHERE conversation_id = {{$json.session_id}}
     ORDER BY created_at ASC

3. [Function: Construire contexte LLM]
   - Transformer messages en format Claude :
     [
       {role: "user", content: "..."},
       {role: "assistant", content: "..."},
       {role: "user", content: "..."} // Nouveau message
     ]

4. [HTTP Request: LLM avec historique]
   - Envoyer tout le contexte
   - LLM a la mémoire de la conversation complète

5. [Function: Checker completion]
   - Analyser réponse LLM
   - Calculer % infos collectées
   - Décider next action

6. [Supabase: Update lead si nouvelles infos]
   - UPDATE leads SET vehicle_make = '...', ...
     WHERE conversation_id = {{$json.session_id}}

7. [Switch: Next action]
   - demander_photos → Indiquer au client comment envoyer
   - proposer_creneaux → Déclencher Workflow 3
   - confirmer_rdv → Finaliser
   - escalade → Notifier propriétaire

8. [Webhook Response]
```

---

### Flow 3 : Validation & Création RDV

```
1. [Trigger: Webhook ou appelé depuis Workflow 2]

2. [Supabase: Récupérer lead complet]
   - SELECT * FROM leads WHERE conversation_id = ...

3. [Function: Valider données]
   - Vérifier que TOUTES les infos obligatoires sont présentes
   - Valider format (email, téléphone, VIN)

4. [Supabase: Récupérer RDV existants]
   - SELECT * FROM appointments
     WHERE scheduled_at BETWEEN '2025-01-20' AND '2025-01-27'

5. [Function: Calculer créneaux optimaux]
   - Identifier zone géographique du client
   - Trouver créneaux libres dans cette zone
   - Proposer 3 options

6. [HTTP Request: LLM générer message proposition]
   - "Parfait ! J'ai 3 créneaux disponibles pour vous :
     1. Lundi 20/01 à 10h
     2. Mercredi 22/01 à 14h
     3. Vendredi 24/01 à 9h
     Lequel vous convient le mieux ?"

7. [Webhook Response: Proposer créneaux]

8. [Attendre choix client] (nouveau message via Workflow 2)

9. [Google Calendar: Créer événement]
   - Titre : "RDV {{client_name}} - {{vehicle}}"
   - Date/heure choisie
   - Description : Toutes les infos

10. [Supabase: Créer appointment]
    - INSERT INTO appointments (lead_id, scheduled_at, zone, status)

11. [Function: Générer email récap]
    - Template avec toutes les infos

12. [Send Email: Confirmation client]
    - Sujet : "Votre RDV OuiGlass confirmé - 20/01 10h"
    - Corps : Récap complet

13. [HTTP Request: WhatsApp notification propriétaire]
    - "🎯 Nouveau RDV : Jean Dupont - 20/01 10h - Lausanne - Pare-brise BMW"

14. [Supabase: Update lead status]
    - UPDATE leads SET status = 'rdv_confirmed'

15. [Supabase: Update conversation]
    - UPDATE conversations SET status = 'rdv_confirmed'
```

---

## 🔄 Gestion d'état

**Problème** : Comment maintenir l'état de la conversation entre les messages ?

**Solution** : Utiliser Supabase comme "mémoire" du système

```
Conversation 1:
  ├─ Message 1 (user): "Bonjour, pare-brise fissuré"
  ├─ Message 2 (assistant): "Quelle est la marque de votre véhicule ?"
  ├─ Message 3 (user): "BMW Serie 3"
  ├─ Message 4 (assistant): "Année du véhicule ?"
  └─ ...

Lead 1 (infos collectées progressivement):
  {
    vehicle_make: "BMW",
    vehicle_model: "Serie 3",
    vehicle_year: null, // Pas encore collecté
    ...
  }
```

**À chaque nouveau message** :
1. Récupérer l'historique complet depuis Supabase
2. Envoyer à LLM
3. LLM comprend le contexte et continue
4. Sauvegarder nouveau message

---

## 🎯 Optimisation du planning

**Objectif** : Regrouper interventions par zone pour minimiser déplacements

**Algorithme simple** :

```javascript
function calculerCreneaux(clientZone, dateDebut, dateFin) {
  // 1. Récupérer RDV existants dans la période
  const rdvExistants = await supabase
    .from('appointments')
    .select('*')
    .gte('scheduled_at', dateDebut)
    .lte('scheduled_at', dateFin);

  // 2. Grouper par zone et date
  const rdvParZoneEtDate = groupBy(rdvExistants, ['zone', 'date']);

  // 3. Priorité 1 : Jours où il y a déjà des RDV dans la même zone
  const creneauxMemeZone = rdvParZoneEtDate
    .filter(r => r.zone === clientZone)
    .map(r => trouverCreneauLibre(r.date));

  // 4. Priorité 2 : Jours fixes par zone (ex: Lausanne = Mardi/Jeudi)
  const creneauxJoursFixes = joursFixesParZone[clientZone];

  // 5. Priorité 3 : N'importe quel créneau libre
  const autresCreneaux = trouverTousCreneauxLibres();

  // 6. Retourner top 3
  return [...creneauxMemeZone, ...creneauxJoursFixes, ...autresCreneaux]
    .slice(0, 3);
}
```

**Jours fixes par zone** (recommandés) :
```javascript
const joursFixesParZone = {
  'geneve': [1, 3, 5],      // Lun, Mer, Ven
  'lausanne': [2, 4],       // Mar, Jeu
  'montreux': [3],          // Mer
  'fribourg': [2, 5],       // Mar, Ven
  'neuchatel': [1, 4],      // Lun, Jeu
  'valais': [3],            // Mer (journée complète)
  'jura': [5]               // Ven
};
```

**Durées d'intervention** :
```javascript
const dureeParType = {
  'pare-brise-adas': 90,         // 1h30
  'pare-brise-sans-adas': 60,    // 1h
  'vitre-laterale': 45,          // 45min
  'lunette-arriere': 45,         // 45min
  'custode': 30                  // 30min
};

const tempsDeplacement = 30;  // 30min entre chaque RDV
```

---

## 🔐 Sécurité

### Authentification API

**N8N Credentials** :
- Stockage sécurisé des clés API (vault chiffré)
- Jamais en clair dans les workflows
- Rotation possible sans modifier workflows

**Supabase** :
```javascript
// Utiliser la clé "anon" (publique mais sécurisée par RLS)
const supabaseUrl = 'https://xxxxx.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

// JAMAIS utiliser service_role en frontend
// service_role = accès complet, réservé au backend (N8N)
```

**Row Level Security (RLS)** :
```sql
-- Exemple : Seul N8N peut écrire, personne ne peut lire directement
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "N8N can insert" ON conversations
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "No public read" ON conversations
  FOR SELECT
  USING (false);
```

### Protection données personnelles

**RGPD Suisse** :
- ✅ Consentement collecté (mentionné dans chatbot)
- ✅ Droit à l'oubli (DELETE cascade dans DB)
- ✅ Chiffrement at rest (Supabase)
- ✅ Chiffrement in transit (HTTPS partout)
- ✅ Logs anonymisés (pas de données perso dans logs N8N)

**Rétention données** :
```sql
-- Auto-delete conversations abandonnées après 90 jours
CREATE OR REPLACE FUNCTION delete_old_conversations()
RETURNS void AS $$
BEGIN
  DELETE FROM conversations
  WHERE status = 'abandoned'
    AND updated_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Exécuter via N8N Schedule Trigger (1x/semaine)
```

---

## 📊 Monitoring & Observabilité

### Logs N8N
- Dashboard : N8N > Executions
- Filtres : Success, Error, Waiting
- Durée d'exécution visible
- Données de chaque step visible

### Logs Supabase
- Dashboard : Supabase > Logs
- Types : API, Postgres, Realtime
- Filtrer par table, type de query

### Métriques business
```sql
-- KPIs à tracker
SELECT
  COUNT(*) as total_leads,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv_confirmes,
  ROUND(
    COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) * 100.0 / COUNT(*),
    2
  ) as taux_conversion
FROM leads
WHERE created_at >= NOW() - INTERVAL '7 days';
```

### Alertes
- N8N : Error Trigger Workflow → Notification
- Supabase : Database Webhooks → N8N
- WhatsApp : Notifications instantanées propriétaire

---

## 🚀 Évolutivité

### Limites actuelles (Phase 1)
- ~100 conversations simultanées max
- Supabase gratuit : 500 MB storage
- N8N Cloud : 5000 executions/mois (plan Starter)
- Cloudinary : 25 GB storage

### Scaling (Phase 3)
- Supabase Pro : 8 GB storage, connection pooling
- N8N Pro : executions illimitées
- Cloudinary Advanced : 100+ GB
- CDN pour chatbot (Cloudflare)
- Cache Redis pour RDV (Upstash)

---

## 📝 Résumé pour débutants

**En une phrase** : Le système reçoit des messages de clients (web, email, WhatsApp), utilise une IA (Claude) pour converser et collecter des infos, sauvegarde tout dans une base de données (Supabase), crée des RDV dans Google Calendar, et vous notifie sur WhatsApp.

**Analogie** :
- **Chatbot** = Réceptionniste qui accueille clients
- **N8N** = Chef d'orchestre qui coordonne tout
- **LLM (Claude)** = Expert qui comprend et répond aux clients
- **Supabase** = Classeur qui stocke toutes les fiches clients
- **Google Calendar** = Agenda des RDV
- **WhatsApp** = Téléphone pour vous notifier

**Pour aller plus loin** :
1. [SETUP-SUPABASE.md](SETUP-SUPABASE.md) - Créer la base de données
2. [SETUP-N8N.md](SETUP-N8N.md) - Configurer les workflows
3. [SETUP-CHATBOT.md](SETUP-CHATBOT.md) - Intégrer le chatbot

---

**Questions ?** Voir [API-DOCUMENTATION.md](API-DOCUMENTATION.md) pour détails techniques complets.
