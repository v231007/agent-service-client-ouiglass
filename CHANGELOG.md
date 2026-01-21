# 📜 Changelog - OuiGlass Suisse Agent Conversationnel

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

---

## [1.0.0-mvp-phase1] - 2026-01-21

### ✅ Ajouté (MVP Phase 1)

#### Infrastructure
- Workflow n8n unique avec 10 nodes (webhook → validation → LLM → réponse)
- Base de données Supabase (2 tables : conversations + messages)
- Intégration Claude API (ou OpenAI en alternative)
- Historique conversationnel (10 derniers messages)

#### Fonctionnalités
- Conversation multi-tours avec gestion de session (session_id)
- Collecte progressive de 6 champs lead :
  - `vehicle_make` : marque du véhicule
  - `vehicle_model` : modèle du véhicule
  - `vehicle_year` : année du véhicule
  - `glass_type` : type de vitre
  - `city` : ville en Suisse
  - `full_name` : nom complet du client
- Support multilingue (français/anglais automatique)
- Validation des inputs (session_id + message obligatoires)
- Gestion d'erreurs JSON avec fallback

#### Documentation
- README.md complet avec architecture et configuration
- INSTALLATION.md : guide pas à pas pour débutants
- EXAMPLES.md : exemples de conversations attendues
- supabase-schema.sql : schéma SQL avec index
- workflow-ouiglass-mvp.json : export n8n prêt à importer
- tests-curl.sh : script de tests pour Linux/Mac
- tests-powershell.ps1 : script de tests pour Windows
- prompt-system-llm.txt : prompt système standalone
- config.example.json : configuration d'exemple

#### Sécurité
- .gitignore pour éviter de committer des secrets
- Service role key Supabase (non exposée publiquement)
- API keys stockées dans credentials n8n

### ⛔ Limitations connues (SCOPE Phase 1)

- ❌ Pas de prise de RDV
- ❌ Pas de gestion d'assurance
- ❌ Pas d'upload de photos
- ❌ Pas de notifications WhatsApp/Email
- ❌ Pas d'intégration Otovia/Google Calendar
- ❌ Pas de dashboard analytics
- ❌ Pas de retry automatique sur échec
- ❌ Pas de RGPD avancé (chiffrement, consentement)

> Ces features seront ajoutées dans les phases futures si nécessaire.

---

## [Unreleased] - Roadmap Phase 2 (Futur)

### 🔮 Prévu (à discuter)

- [ ] Prise de RDV avec Google Calendar
- [ ] Gestion d'assurance (collecte infos assureur)
- [ ] Upload et analyse de photos (OCR plaque)
- [ ] Notifications WhatsApp (via n8n WhatsApp node)
- [ ] Notifications Email (confirmation lead)
- [ ] Intégration Otovia CRM
- [ ] Dashboard analytics (taux de conversion, temps moyen)
- [ ] Retry automatique sur échec LLM
- [ ] Gestion du consentement RGPD
- [ ] Support de plus de langues (allemand, italien)

---

## Format des entrées

### Types de changements
- **Ajouté** : nouvelles fonctionnalités
- **Modifié** : changements dans les fonctionnalités existantes
- **Déprécié** : fonctionnalités qui seront supprimées
- **Supprimé** : fonctionnalités supprimées
- **Corrigé** : corrections de bugs
- **Sécurité** : corrections de vulnérabilités

---

## Versioning

Ce projet suit le [Semantic Versioning](https://semver.org/lang/fr/) :
- **MAJOR** : changements incompatibles (breaking changes)
- **MINOR** : nouvelles fonctionnalités (backward compatible)
- **PATCH** : corrections de bugs (backward compatible)

Exemple : `1.2.3` = version majeure 1, version mineure 2, patch 3
