# 📥 Guide d'Import N8N - OuiGlass Agent IA

## Vue d'ensemble

Ce guide explique comment importer le workflow N8N pré-configuré dans votre instance N8N.

## ⚡ Import Rapide (3 étapes)

### Étape 1 : Télécharger le fichier JSON

Le workflow est dans : `01-reception-lead-website.json`

### Étape 2 : Importer dans N8N

1. Ouvrir N8N (https://votre-instance.app.n8n.cloud)
2. Cliquer sur **"+"** (Nouveau Workflow)
3. Cliquer sur le menu **"⋮"** (3 points) en haut à droite
4. Sélectionner **"Import from File"**
5. Choisir le fichier `01-reception-lead-website.json`
6. Cliquer **"Import"**

✅ Le workflow est maintenant dans votre N8N !

### Étape 3 : Configurer les Credentials

⚠️ **IMPORTANT** : Les credentials ne sont pas incluses dans l'export (sécurité).

Vous devez les reconfigurer :

#### A. Supabase

1. Cliquer sur le node **"Get or Create Conversation"**
2. Credentials > **"Create New"**
3. Type : **Supabase**
4. Configuration :
   ```
   Name: Supabase OuiGlass
   Host: https://xxxxx.supabase.co
   Service Role Secret: eyJhbG... (votre clé)
   ```
5. **Save**

6. Répéter pour les nodes :
   - "Save User Message"
   - "Save Assistant Message"

#### B. Claude API

1. Cliquer sur le node **"Claude API"**
2. Credentials > **"Create New"**
3. Type : **HTTP Header Auth**
4. Configuration :
   ```
   Name: Claude API
   Header Name: x-api-key
   Value: sk-ant-api03-... (votre clé Anthropic)
   ```
5. **Save**

### Étape 4 : Tester

1. Cliquer sur **"Execute Workflow"** en haut
2. Le webhook devient actif
3. Copier l'URL du webhook
4. Tester avec curl :

```bash
curl -X POST https://votre-instance.app.n8n.cloud/webhook-test/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test-123", "message": "Bonjour"}'
```

**Résultat attendu** :
```json
{
  "message": "Bonjour ! Je suis désolé pour votre pare-brise...",
  "completion": 5,
  "session_id": "test-123"
}
```

### Étape 5 : Activer le Workflow

1. Toggle en haut à droite : **ON**
2. Le webhook est maintenant en mode **Production**
3. Copier l'URL de production pour le chatbot

---

## 🔧 Configuration Post-Import

### Modifier le Prompt Système

Le workflow inclut une version courte du prompt. Pour la version complète :

1. Ouvrir le fichier `prompts/system-prompt-main.md`
2. Copier tout le contenu de la section "PROMPT SYSTÈME"
3. Dans N8N, node **"Load System Prompt"**
4. Remplacer la variable `systemPrompt` avec le contenu complet
5. **Save**

### Variables d'environnement

Dans N8N > Settings > Variables, créer :

```
BUSINESS_NAME = OuiGlass Suisse
BUSINESS_PHONE = +41791234567
BUSINESS_EMAIL = contact@ouiglass.ch
NOTIFICATION_WHATSAPP = +41791234567
```

---

## 🎯 Workflows Additionnels (Phase 1)

Le fichier JSON actuel contient le **Workflow 1** (Réception Lead Website).

Pour les workflows 2-4, deux options :

### Option A : Créer manuellement (Recommandé)

Suivre le guide : `QUICK-REFERENCE.md`

**Avantages** :
- Vous comprenez chaque étape
- Personnalisation facile
- Meilleur apprentissage

### Option B : Templates JSON (À venir)

Je peux créer les 3 autres workflows en JSON si nécessaire.

---

## 📋 Checklist Post-Import

- [ ] Workflow importé avec succès
- [ ] Credentials Supabase configurées
- [ ] Credentials Claude API configurées
- [ ] Prompt système mis à jour (version complète)
- [ ] Variables d'environnement créées
- [ ] Test curl réussi
- [ ] Vérification dans Supabase (tables remplies)
- [ ] Workflow activé (toggle ON)
- [ ] URL webhook production copiée

---

## ❓ Problèmes Courants

### "Missing credentials"

→ Vous devez reconfigurer Supabase et Claude API (voir Étape 3)

### "Table does not exist"

→ Exécuter d'abord `database/schema.sql` dans Supabase

### "Invalid API key"

→ Vérifier que la clé Claude API est correcte (commence par `sk-ant-api03-`)

### Le workflow ne s'active pas

→ Vérifier qu'il n'y a pas d'erreurs (icône rouge sur un node)
→ Configurer toutes les credentials

---

## 🚀 Prochaines Étapes

1. **Tester le workflow** avec plusieurs conversations
2. **Vérifier Supabase** que les données sont bien stockées
3. **Intégrer le chatbot** sur votre site web
4. **Créer les workflows 2-4** (voir QUICK-REFERENCE.md)

---

## 📚 Documentation Complète

- **Architecture** : `docs/ARCHITECTURE.md`
- **Setup N8N** : `docs/SETUP-N8N.md`
- **Tests** : `docs/TESTING.md`
- **Déploiement** : `docs/DEPLOYMENT.md`

---

**Besoin d'aide ?** Consultez `QUICK-REFERENCE.md` pour les codes complets ! 🎉
