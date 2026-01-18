# 🚀 Import Complet - OuiGlass Agent IA

## 📦 Ce que contient le fichier

**OUIGLASS-COMPLETE-AGENT.json** contient **4 workflows complets** :

1. **Workflow 1** : Réception Lead Website (15 nodes)
   - Webhook chat
   - Récupération historique conversation
   - Appel Claude API avec contexte
   - Sauvegarde messages
   - Détection infos complètes
   - Déclenchement création RDV

2. **Workflow 2** : Création RDV (5 nodes)
   - Calcul créneaux optimaux par zone
   - Proposition 3 créneaux au client
   - Génération message avec Claude

3. **Workflow 3** : Confirmation RDV (7 nodes)
   - Création événement Google Calendar
   - Création appointment Supabase
   - Envoi notification propriétaire
   - Mise à jour statuts

4. **Workflow 4** : Notifications (4 nodes)
   - Formatage messages WhatsApp
   - Envoi notifications

---

## ⚡ Import en 5 minutes

### Étape 1 : Télécharger le fichier

Le fichier est : `OUIGLASS-COMPLETE-AGENT.json`

### Étape 2 : Importer dans N8N

#### Option A : Import workflows (RECOMMANDÉ)

1. Ouvrir N8N
2. Aller dans **Workflows** (menu gauche)
3. Cliquer **menu ⋮** > **Import workflows**
4. Sélectionner `OUIGLASS-COMPLETE-AGENT.json`
5. ✅ Les 4 workflows sont importés !

#### Option B : Import individuel (si Option A ne marche pas)

Certaines versions N8N n'acceptent pas le format multi-workflows.

**Solution** : Utiliser les fichiers individuels dans `phase1/` :
- `01-reception-lead-website.json`
- Etc. (à créer si besoin)

### Étape 3 : Configurer les Credentials

⚠️ **IMPORTANT** : Vous devez configurer 4 credentials.

#### A. Supabase (obligatoire)

1. N8N > **Credentials** > **Add Credential**
2. Type : **Supabase**
3. Configuration :
   ```
   Name: Supabase OuiGlass
   Host: https://xxxxx.supabase.co
   Service Role Secret: eyJhbGciOiJI... (votre clé)
   ```
4. **Save**

**Où utiliser** :
- Workflow 1 : 6 nodes (Get/Create Conversation, History, Save Messages, Update Lead)
- Workflow 2 : 1 node (Get Lead)
- Workflow 3 : 2 nodes (Create Appointment, Update Status)

#### B. Claude API (obligatoire)

1. N8N > **Credentials** > **Add Credential**
2. Type : **HTTP Header Auth**
3. Configuration :
   ```
   Name: Claude API
   Header Name: x-api-key
   Value: sk-ant-api03-... (votre clé Anthropic)
   ```
4. **Save**

**Où utiliser** :
- Workflow 1 : 1 node (Claude API)
- Workflow 2 : 1 node (Generate Slots Message)

#### C. Google Calendar (obligatoire pour RDV)

1. **Créer OAuth App dans Google Cloud** :
   - https://console.cloud.google.com
   - APIs & Services > Credentials
   - Create OAuth 2.0 Client ID
   - Authorized redirect URI : `https://votre-instance.app.n8n.cloud/rest/oauth2-credential/callback`

2. Dans N8N :
   - Credentials > Add > **Google Calendar OAuth2**
   - Client ID : [votre Client ID]
   - Client Secret : [votre Client Secret]
   - **Connect my account**
   - Autoriser accès

**Où utiliser** :
- Workflow 3 : 1 node (Create Google Calendar Event)

#### D. WhatsApp API (optionnel Phase 1)

**Si vous n'avez PAS WhatsApp Business API** :

➡️ **Remplacer le node WhatsApp par Email**

Dans Workflow 4 :
1. Supprimer node "Send WhatsApp"
2. Ajouter node **"Send Email"** (Gmail ou SMTP)
3. Configuration :
   ```
   To: {{$env.NOTIFICATION_EMAIL}}
   Subject: Nouvelle notification OuiGlass
   Body: {{$json.message}}
   ```

**Si vous AVEZ WhatsApp Business API** :

1. N8N > Credentials > **HTTP Header Auth**
2. Configuration :
   ```
   Name: WhatsApp API
   Header Name: Authorization
   Value: Bearer YOUR_ACCESS_TOKEN
   ```

### Étape 4 : Variables d'environnement

Dans N8N > **Settings** > **Variables** :

```bash
# URLs et contacts
N8N_WEBHOOK_BASE_URL = https://votre-instance.app.n8n.cloud
BUSINESS_NAME = OuiGlass Suisse
BUSINESS_PHONE = +41791234567
BUSINESS_EMAIL = contact@ouiglass.ch

# Notifications
NOTIFICATION_WHATSAPP = +41791234567  # Votre numéro perso
NOTIFICATION_EMAIL = votre-email@ouiglass.ch

# WhatsApp (si utilisé)
WHATSAPP_PHONE_NUMBER_ID = 123456789
```

**Comment obtenir N8N_WEBHOOK_BASE_URL** :
- Ouvrir n'importe quel workflow
- Cliquer sur un node Webhook
- L'URL est affichée, copier la partie avant `/webhook/...`
- Exemple : `https://abc123.app.n8n.cloud`

### Étape 5 : Remplacer les placeholders credentials

⚠️ **Action requise** : Les workflows contiennent des placeholders `{{SUPABASE_CREDENTIAL_ID}}`.

**Pour chaque workflow** :

1. Ouvrir le workflow
2. Cliquer sur chaque node qui a une credential
3. Sélectionner votre credential dans la liste
4. **Save**

**Liste des nodes à vérifier** :

**Workflow 1** :
- Get or Create Conversation → Supabase
- Get Message History → Supabase
- Claude API → Claude API (HTTP Header Auth)
- Save User Message → Supabase
- Save Assistant Message → Supabase
- Update or Create Lead → Supabase

**Workflow 2** :
- Get Lead Info → Supabase
- Generate Slots Message → Claude API

**Workflow 3** :
- Get Lead → Supabase
- Create Google Calendar Event → Google Calendar OAuth2
- Create Appointment → Supabase
- Update Status → Supabase

**Workflow 4** :
- Send WhatsApp → WhatsApp API (ou Send Email)

### Étape 6 : Tester

#### Test Workflow 1 (Principal)

1. Ouvrir "OuiGlass - 01 Reception Lead Website"
2. Cliquer **"Execute Workflow"**
3. Copier l'URL webhook test
4. Tester avec curl :

```bash
curl -X POST https://votre-instance.app.n8n.cloud/webhook-test/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test-001", "message": "Bonjour, j'\''ai mon pare-brise fissuré"}'
```

**Résultat attendu** :
```json
{
  "message": "Bonjour ! Je suis désolé...",
  "completion": 5,
  "session_id": "test-001",
  "next_action": "demander_vehicule"
}
```

#### Vérifier Supabase

```sql
-- Dans Supabase SQL Editor
SELECT * FROM conversations WHERE id = 'test-001';
SELECT * FROM messages WHERE conversation_id = 'test-001';
```

Vous devriez voir 1 conversation + 2 messages.

#### Test complet (conversation → RDV)

Suivre le guide : `docs/TESTING.md` > Scénario "Conversation complète"

### Étape 7 : Activer les workflows

Une fois tous les tests passés :

1. **Workflow 1** : Toggle **ON**
2. **Workflow 2** : Toggle **ON**
3. **Workflow 3** : Toggle **ON**
4. **Workflow 4** : Toggle **ON**

✅ **L'agent IA est maintenant ACTIF !**

---

## 🎯 URLs des webhooks

### Workflow 1 - Chat Principal

**Production** : `https://votre-instance.app.n8n.cloud/webhook/chat`

➡️ À copier dans le chatbot (`ouiglass-chat-widget.js`) :

```javascript
new OuiGlassChat({
  webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat'
});
```

### Workflow 2 - Création RDV

**Production** : `https://votre-instance.app.n8n.cloud/webhook/create-appointment`

(Appelé automatiquement par Workflow 1)

### Workflow 3 - Confirmation RDV

**Production** : `https://votre-instance.app.n8n.cloud/webhook/confirm-appointment`

(Appelé par le chatbot quand client choisit un créneau)

### Workflow 4 - Notifications

**Production** : `https://votre-instance.app.n8n.cloud/webhook/notification`

(Appelé automatiquement par Workflow 3)

---

## 📊 Architecture des workflows

```
CHATBOT WEB
    ↓
[Workflow 1: Reception Lead]
    ├─ Récupère historique
    ├─ Appelle Claude API
    ├─ Sauvegarde messages
    └─ Si infos complètes → [Workflow 2]
            ↓
[Workflow 2: Création RDV]
    ├─ Calcule créneaux optimaux
    ├─ Propose 3 créneaux
    └─ Client choisit → [Workflow 3]
            ↓
[Workflow 3: Confirmation RDV]
    ├─ Crée Google Calendar Event
    ├─ Crée Appointment Supabase
    └─ Déclenche → [Workflow 4]
            ↓
[Workflow 4: Notifications]
    └─ Envoie WhatsApp/Email propriétaire
```

---

## ❓ Problèmes courants

### "Missing credentials"

➡️ Étape 5 non faite : configurer les credentials manuellement

### "Table does not exist"

➡️ Exécuter `database/schema.sql` dans Supabase d'abord

### "Invalid API key"

➡️ Vérifier que la clé Claude commence par `sk-ant-api03-`

### "Cannot find workflow"

➡️ Les workflows s'appellent les uns les autres via webhooks internes
➡️ Vérifier que `N8N_WEBHOOK_BASE_URL` est correct dans variables

### Workflow 4 ne fonctionne pas

➡️ Si pas WhatsApp : remplacer node par "Send Email"
➡️ Voir section "WhatsApp optionnel"

### Les créneaux proposés sont bizarres

➡️ Vérifier la timezone dans N8N Settings
➡️ Devrait être : Europe/Zurich

---

## ✅ Checklist Post-Import

- [ ] 4 workflows importés
- [ ] Credentials Supabase configurées (6 nodes)
- [ ] Credentials Claude API configurées (2 nodes)
- [ ] Credentials Google Calendar configurées (1 node)
- [ ] Variables d'environnement créées
- [ ] WhatsApp configuré OU remplacé par Email
- [ ] Test curl Workflow 1 réussi
- [ ] Vérification Supabase OK
- [ ] Les 4 workflows activés (toggle ON)
- [ ] URL webhook copiée pour chatbot

---

## 🚀 Prochaines étapes

1. **Intégrer le chatbot** sur votre site : `docs/SETUP-CHATBOT.md`
2. **Tester en conditions réelles** : `docs/TESTING.md`
3. **Déployer en production** : `docs/DEPLOYMENT.md`

---

## 📚 Documentation complète

- Architecture : `docs/ARCHITECTURE.md`
- Tests : `docs/TESTING.md`
- Codes à copier-coller : `n8n-workflows/QUICK-REFERENCE.md`

---

**Temps total d'import et configuration : 30-45 minutes**

**Besoin d'aide ?** Consulter les guides dans `docs/` ! 🎉
