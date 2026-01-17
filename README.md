# 🚗 OuiGlass Suisse - Agent IA Service Client

> Système d'agent IA pour automatiser la conversion de leads en rendez-vous confirmés pour OuiGlass Suisse

## 📋 Vue d'ensemble

Ce projet est un **agent IA conversationnel multi-canal** qui gère automatiquement :
- ✅ Conversion des leads en RDV (objectif 80%+)
- ✅ Collecte complète des informations pour l'assurance
- ✅ Optimisation du planning par zone géographique
- ✅ Confirmation/rebooking automatique des RDV
- ✅ Gestion des avis Google
- ✅ Notifications instantanées

## 🎯 Canaux supportés

- **Chatbot site web** (widget JavaScript)
- **Email** (réponses automatiques)
- **WhatsApp Business** (conversations)
- **Téléphone** (voicemail to text - Phase 2)

## 🏗️ Architecture technique

```
┌─────────────────────────────────────────────────────────────┐
│                    CANAUX D'ENTRÉE                          │
│   [Chatbot Web] [Email] [WhatsApp] [Téléphone]            │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    N8N ORCHESTRATION                         │
│  • Réception lead multi-canal                               │
│  • Conversation multi-tours                                 │
│  • Validation & création RDV                                │
│  • Confirmation J-1                                         │
│  • Rebooking                                                │
└────────────┬────────────────────────────────────────────────┘
             │
             ├──────────► [LLM: Claude/GPT]
             │            (Compréhension & génération)
             │
             ├──────────► [Supabase PostgreSQL]
             │            (Conversations, Leads, RDV)
             │
             ├──────────► [Cloudinary/S3]
             │            (Photos vitrages)
             │
             └──────────► [Notifications]
                          (WhatsApp, Slack)
```

## 📦 Stack technologique

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Orchestration** | N8N Cloud | Workflows automation |
| **LLM** | Claude Sonnet / GPT-4 | Conversation intelligente |
| **Base de données** | Supabase (PostgreSQL) | Stockage leads/conversations |
| **Stockage fichiers** | Cloudinary | Photos vitrages endommagés |
| **Notifications** | WhatsApp Business API | Alertes temps réel |
| **Planning** | Google Calendar → Otovia | Gestion RDV (migration prévue) |

## 🚀 Démarrage rapide (Phase 1 - MVP)

### Prérequis

- Compte N8N Cloud (version payante)
- Compte Supabase (gratuit pour commencer)
- Compte Cloudinary (gratuit)
- Clé API LLM (Claude API ou OpenAI)
- Numéro WhatsApp Business (optionnel Phase 1)

### Installation en 5 étapes

1. **Configurer Supabase**
   ```bash
   # Créer projet Supabase
   # Exécuter le script database/schema.sql
   ```
   📖 Voir [docs/SETUP-SUPABASE.md](docs/SETUP-SUPABASE.md)

2. **Configurer N8N**
   ```bash
   # Importer les workflows depuis n8n-workflows/phase1/
   # Configurer les credentials
   ```
   📖 Voir [docs/SETUP-N8N.md](docs/SETUP-N8N.md)

3. **Déployer le chatbot web**
   ```bash
   # Copier le code depuis chatbot/
   # Intégrer sur votre site web
   ```
   📖 Voir [docs/SETUP-CHATBOT.md](docs/SETUP-CHATBOT.md)

4. **Configurer les notifications**
   📖 Voir [docs/SETUP-NOTIFICATIONS.md](docs/SETUP-NOTIFICATIONS.md)

5. **Tester le système**
   ```bash
   # Utiliser les scénarios de tests/scenarios/
   ```
   📖 Voir [docs/TESTING.md](docs/TESTING.md)

## 📁 Structure du projet

```
agent-service-client-ouiglass/
├── README.md                          # Ce fichier
├── docs/                              # Documentation complète
│   ├── ARCHITECTURE.md                # Architecture détaillée
│   ├── SETUP-N8N.md                   # Guide setup N8N
│   ├── SETUP-SUPABASE.md              # Guide setup Supabase
│   ├── SETUP-CHATBOT.md               # Guide setup chatbot
│   ├── SETUP-WHATSAPP.md              # Guide WhatsApp Business
│   ├── SETUP-NOTIFICATIONS.md         # Configuration notifications
│   ├── API-DOCUMENTATION.md           # Documentation API & webhooks
│   ├── TESTING.md                     # Guide de test
│   └── DEPLOYMENT.md                  # Déploiement production
├── database/                          # Scripts base de données
│   ├── schema.sql                     # Création tables Supabase
│   ├── seed.sql                       # Données de test
│   └── queries.sql                    # Requêtes utiles
├── n8n-workflows/                     # Workflows N8N
│   ├── phase1/                        # MVP (prioritaire)
│   │   ├── 01-reception-lead-website.json
│   │   ├── 02-conversation-multi-tours.json
│   │   ├── 03-creation-rdv.json
│   │   └── 04-notifications-whatsapp.json
│   ├── phase2/                        # Extensions
│   │   ├── 05-emails-entrants.json
│   │   ├── 06-confirmation-j1.json
│   │   └── 07-rebooking.json
│   ├── phase3/                        # Avancé
│   │   ├── 08-avis-google.json
│   │   └── 09-integration-otovia.json
│   └── diagrams/                      # Schémas visuels
├── chatbot/                           # Widget chatbot web
│   ├── ouiglass-chat-widget.js        # Code principal
│   ├── ouiglass-chat-widget.css       # Styles
│   ├── integration-example.html       # Exemple d'intégration
│   └── README.md                      # Documentation widget
├── prompts/                           # Prompts LLM
│   ├── system-prompt-main.md          # Prompt système principal
│   ├── system-prompt-email.md         # Prompt pour emails
│   ├── system-prompt-whatsapp.md      # Prompt pour WhatsApp
│   ├── examples/                      # Exemples de conversations
│   └── templates/                     # Templates de messages
├── tests/                             # Tests et scénarios
│   ├── scenarios/                     # 10 scénarios de test
│   ├── edge-cases/                    # Cas limites
│   └── webhook-tests/                 # Tests webhooks
└── integrations/                      # Intégrations futures
    ├── otovia-api/                    # Préparation Otovia
    └── google-my-business/            # API avis Google
```

## 🎯 Phases d'implémentation

### ✅ Phase 1 - MVP (1 semaine) - PRIORITAIRE
**Objectif** : Tester avec de vrais leads rapidement

- [x] Workflow Réception Lead Website (chatbot)
- [x] Workflow Conversation Multi-Tours
- [x] Workflow Création RDV (Google Calendar)
- [x] Notifications WhatsApp basiques

**Livrables** :
- Chatbot fonctionnel sur site web
- Collecte complète des informations
- Proposition de créneaux RDV
- Notifications WhatsApp personnelles

### 🔄 Phase 2 - Extensions (2-3 semaines)
- [ ] Workflow Email entrants
- [ ] Workflow Confirmation RDV J-1
- [ ] Workflow Rebooking
- [ ] WhatsApp Business complet (API)

### 🚀 Phase 3 - Avancé (1 mois)
- [ ] Intégration Otovia API
- [ ] Workflow Avis Google
- [ ] Dashboard métriques temps réel
- [ ] Optimisations & fine-tuning

## 📊 Métriques suivies

Le système track automatiquement :
- 📈 Nombre de leads par source (web/email/whatsapp)
- 🎯 Taux de conversion lead → RDV (objectif 80%+)
- ⏱️ Temps moyen de conversion
- ✅ Taux de confirmation RDV J-1 (objectif 95%+)
- 📅 Taux de rebooking
- 🗺️ Distribution géographique
- 🏢 Compagnies d'assurance les plus fréquentes
- ⭐ Note moyenne avis Google

## 🔧 Configuration minimale (Phase 1)

### Variables d'environnement N8N

```bash
# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# LLM (choisir un)
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENAI_API_KEY=sk-...

# Cloudinary
CLOUDINARY_CLOUD_NAME=ouiglass-suisse
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

# WhatsApp (optionnel Phase 1)
WHATSAPP_PHONE_NUMBER_ID=...
WHATSAPP_ACCESS_TOKEN=...

# Configuration OuiGlass
BUSINESS_PHONE=+41...
BUSINESS_EMAIL=contact@ouiglass.ch
NOTIFICATION_WHATSAPP=+41... # Votre numéro perso
```

## 🧪 Tester le système

### Test rapide du chatbot

1. Ouvrir `chatbot/integration-example.html` dans un navigateur
2. Cliquer sur le widget en bas à droite
3. Simuler une conversation :
   ```
   Vous: Bonjour, j'ai mon pare-brise fissuré
   IA: [Collecte infos véhicule]
   Vous: BMW Serie 3 de 2020
   IA: [Demande photos + VIN]
   ...
   ```

4. Vérifier dans Supabase que :
   - Une conversation est créée dans `conversations`
   - Les messages sont enregistrés dans `messages`
   - Un lead est créé dans `leads` quand infos complètes

### Tests des workflows N8N

Voir [docs/TESTING.md](docs/TESTING.md) pour 10 scénarios complets

## 📚 Documentation détaillée

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Architecture complète du système |
| [SETUP-N8N.md](docs/SETUP-N8N.md) | Configuration N8N pas à pas |
| [SETUP-SUPABASE.md](docs/SETUP-SUPABASE.md) | Configuration Supabase |
| [SETUP-CHATBOT.md](docs/SETUP-CHATBOT.md) | Intégration chatbot sur site web |
| [API-DOCUMENTATION.md](docs/API-DOCUMENTATION.md) | Webhooks et API |
| [TESTING.md](docs/TESTING.md) | Scénarios de test |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | Mise en production |

## 🆘 Support et aide

### Problèmes courants

**Le chatbot ne répond pas**
→ Vérifier que le webhook N8N est actif
→ Voir logs N8N pour erreurs

**L'agent ne collecte pas toutes les infos**
→ Vérifier le prompt système
→ Augmenter le seuil de completion dans le workflow

**Les notifications WhatsApp ne partent pas**
→ Vérifier les credentials WhatsApp Business API
→ Voir [docs/SETUP-NOTIFICATIONS.md](docs/SETUP-NOTIFICATIONS.md)

### Logs et debugging

```bash
# Voir logs Supabase
# Dashboard Supabase > Logs > postgres-logs

# Voir logs N8N
# N8N > Executions (historique complet de chaque workflow)

# Activer mode debug N8N
# Workflow > Settings > Save execution data: Always
```

## 🔒 Sécurité & RGPD

- ✅ Données personnelles chiffrées dans Supabase (encryption at rest)
- ✅ HTTPS obligatoire pour tous les webhooks
- ✅ Tokens API stockés en credentials N8N (vault sécurisé)
- ✅ Consentement client collecté (mentionné dans prompt IA)
- ✅ Conformité RGPD Suisse

## 📞 Contact

**Créé pour** : OuiGlass Suisse
**Zone de service** : Suisse romande (Genève, Lausanne, Montreux, Vevey, etc.)
**Support** : [Voir documentation technique]

---

## 🚀 Commencer maintenant

**Pour débutants** (recommandé) :
1. Lire [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) pour comprendre le système
2. Suivre [docs/SETUP-SUPABASE.md](docs/SETUP-SUPABASE.md) pour créer la base de données
3. Suivre [docs/SETUP-N8N.md](docs/SETUP-N8N.md) pour importer les workflows
4. Tester avec [docs/TESTING.md](docs/TESTING.md)

**Pour développeurs expérimentés** :
```bash
# 1. Créer projet Supabase et exécuter database/schema.sql
# 2. Importer workflows depuis n8n-workflows/phase1/
# 3. Configurer credentials N8N (Supabase, LLM, Cloudinary)
# 4. Activer les workflows et tester webhook chatbot
# 5. Intégrer chatbot sur site web avec chatbot/ouiglass-chat-widget.js
```

---

**⚡ Prêt à automatiser votre business ?** Commencez par la Phase 1 ! 🚀
