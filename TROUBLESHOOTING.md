# 🔧 Guide de Dépannage - OuiGlass Suisse MVP

Ce guide vous aide à résoudre les problèmes courants.

---

## 📋 Checklist de vérification rapide

Avant de chercher le problème, vérifiez :

- [ ] Le workflow n8n est **actif** (toggle sur "Active")
- [ ] Vous utilisez la **Production URL** du webhook (pas Test URL)
- [ ] Les tables Supabase existent (`conversations` + `messages`)
- [ ] Les credentials Supabase sont corrects
- [ ] La clé API Claude/OpenAI est valide
- [ ] Le JSON envoyé contient bien `session_id` et `message`

---

## 🚨 Erreurs courantes et solutions

### Erreur 1 : "session_id manquant ou invalide"

**Message d'erreur** :
```
Error in node 'Validate Input'
session_id manquant ou invalide
```

**Cause** :
Le JSON envoyé ne contient pas le champ `session_id` ou il est vide/null.

**Solution** :
Vérifiez votre payload JSON :

❌ **Incorrect** :
```json
{
  "message": "Bonjour"
}
```

❌ **Incorrect** :
```json
{
  "session_id": "",
  "message": "Bonjour"
}
```

✅ **Correct** :
```json
{
  "session_id": "test-session-001",
  "message": "Bonjour"
}
```

---

### Erreur 2 : "message manquant ou invalide"

**Message d'erreur** :
```
Error in node 'Validate Input'
message manquant ou invalide
```

**Cause** :
Le JSON envoyé ne contient pas le champ `message` ou il est vide/null.

**Solution** :
Vérifiez votre payload JSON :

❌ **Incorrect** :
```json
{
  "session_id": "test-001"
}
```

❌ **Incorrect** :
```json
{
  "session_id": "test-001",
  "message": ""
}
```

✅ **Correct** :
```json
{
  "session_id": "test-001",
  "message": "Bonjour"
}
```

---

### Erreur 3 : "relation conversations does not exist"

**Message d'erreur** :
```
Error in node 'Get or Create Conversation'
relation "conversations" does not exist
```

**Cause** :
Les tables Supabase n'ont pas été créées ou le SQL n'a pas été exécuté correctement.

**Solution** :

1. Allez dans Supabase → **SQL Editor**
2. Ouvrez le fichier `supabase-schema.sql`
3. Copiez tout le contenu
4. Collez dans l'éditeur SQL de Supabase
5. Cliquez **RUN**
6. Vérifiez dans **Table Editor** que les tables `conversations` et `messages` existent

---

### Erreur 4 : "Could not connect to Supabase"

**Message d'erreur** :
```
Error in node 'Get or Create Conversation'
Could not connect to Supabase
```

**Cause** :
Les credentials Supabase sont incorrects (Host ou Service Role Key).

**Solution** :

1. Dans Supabase → **Project Settings** → **API**
2. Vérifiez votre **Project URL** (ex : `https://abcdefgh.supabase.co`)
3. Vérifiez votre **service_role key** (cliquez "Reveal")
4. Dans n8n → **Settings** → **Credentials** → trouvez `Supabase OuiGlass`
5. Cliquez **Edit** et vérifiez :
   - **Host** = Project URL (avec `https://`)
   - **Service Role Secret** = service_role key (commence par `eyJ...`)
6. **Save** et testez à nouveau

---

### Erreur 5 : "Invalid API key" (Claude)

**Message d'erreur** :
```
Error in node 'Call LLM'
401: Unauthorized
Invalid API key
```

**Cause** :
La clé API Claude est incorrecte ou expirée.

**Solution** :

1. Allez sur [console.anthropic.com](https://console.anthropic.com)
2. Connectez-vous et allez dans **API Keys**
3. Vérifiez que votre clé est active (ou créez-en une nouvelle)
4. Copiez la clé (commence par `sk-ant-...`)
5. Dans n8n → **Settings** → **Credentials** → trouvez `Claude API Key`
6. Cliquez **Edit** et vérifiez :
   - **Name** = `x-api-key`
   - **Value** = votre clé API Claude
7. **Save** et testez à nouveau

---

### Erreur 6 : "Incorrect API key provided" (OpenAI)

**Message d'erreur** :
```
Error in node 'Call LLM'
401: Unauthorized
Incorrect API key provided
```

**Cause** :
La clé API OpenAI est incorrecte ou expirée.

**Solution** :

1. Allez sur [platform.openai.com](https://platform.openai.com)
2. Connectez-vous et allez dans **API Keys**
3. Vérifiez que votre clé est active (ou créez-en une nouvelle)
4. Copiez la clé (commence par `sk-...`)
5. Dans n8n → **Settings** → **Credentials** → trouvez votre credential
6. Cliquez **Edit** et vérifiez :
   - **Name** = `Authorization`
   - **Value** = `Bearer sk-...` (avec le mot "Bearer" devant)
7. **Save** et testez à nouveau

---

### Erreur 7 : Le LLM répond en texte brut au lieu de JSON

**Symptôme** :
Le workflow plante au node "Parse LLM JSON" avec une erreur de parsing.

**Exemple** :
```
Error in node 'Parse LLM JSON'
Unexpected token B in JSON at position 0
```

**Cause** :
Le LLM n'a pas respecté la consigne JSON strict. Possible causes :
- Le prompt système n'est pas bien passé
- Le modèle Claude/OpenAI ne suit pas les instructions

**Solution** :

1. Ouvrez le node **Build LLM Context**
2. Vérifiez que le `systemPrompt` contient bien :
   ```
   Réponds UNIQUEMENT en JSON valide, sans texte avant ou après
   ```
3. Ouvrez le node **Call LLM**
4. Vérifiez que le body contient :
   ```json
   {
     "model": "claude-3-5-sonnet-20241022",
     "max_tokens": 1024,
     "system": "={{ $json.systemPrompt }}",
     "messages": {{ $json.messages }}
   }
   ```
5. Si le problème persiste, le fallback du node "Parse LLM JSON" devrait gérer l'erreur :
   ```javascript
   return {
     reply: "Désolé, j'ai eu un souci technique. Peux-tu répéter ton message ?",
     lead: {},
     missing_fields: [],
     next_action: 'error'
   };
   ```

---

### Erreur 8 : Le workflow ne répond pas

**Symptôme** :
Le webhook ne répond rien, timeout ou erreur de connexion.

**Cause** :
Le workflow n'est pas actif ou l'URL est incorrecte.

**Solution** :

1. Ouvrez votre workflow dans n8n
2. En haut à droite, vérifiez que le toggle est sur **Active** (vert)
3. Si non, cliquez dessus pour l'activer
4. Ouvrez le node **Webhook Chat**
5. Vérifiez que vous utilisez la **Production URL** (pas Test URL)
6. Copiez l'URL et testez avec curl :
   ```bash
   curl -X POST "https://your-url/webhook/chat" \
     -H "Content-Type: application/json" \
     -d '{"session_id":"test","message":"hello"}'
   ```

---

### Erreur 9 : "Cannot read property 'json' of undefined"

**Message d'erreur** :
```
Error in node 'X'
Cannot read property 'json' of undefined
```

**Cause** :
Un node essaie d'accéder aux données d'un node précédent qui a échoué ou qui n'existe pas.

**Solution** :

1. Vérifiez l'ordre des nodes (ils doivent être connectés dans l'ordre)
2. Vérifiez les références aux nodes précédents :
   - `$json` = données du node précédent direct
   - `$('Node Name').item.json` = données d'un node spécifique
3. Ouvrez **Executions** et regardez quel node a échoué
4. Vérifiez que tous les nodes précédents ont bien des données de sortie

---

### Erreur 10 : Le LLM redemande des infos déjà collectées

**Symptôme** :
L'assistant redemande la marque du véhicule alors qu'elle a déjà été donnée.

**Cause** :
L'historique des messages n'est pas récupéré correctement.

**Solution** :

1. Ouvrez le node **Get Last N Messages**
2. Vérifiez la requête SQL :
   ```sql
   SELECT role, content, created_at
   FROM messages
   WHERE conversation_id = '{{ $('Get or Create Conversation').item.json.id }}'
   ORDER BY created_at ASC
   LIMIT 10;
   ```
3. Testez dans Supabase SQL Editor :
   ```sql
   SELECT * FROM messages WHERE conversation_id = 'VOTRE_UUID';
   ```
4. Vérifiez dans **Executions** que le node retourne bien les messages

---

### Erreur 11 : "Rate limit exceeded" (429)

**Message d'erreur** :
```
Error in node 'Call LLM'
429: Too Many Requests
Rate limit exceeded
```

**Cause** :
Vous avez dépassé le quota de requêtes API (Claude ou OpenAI).

**Solution** :

1. **Claude** : Vérifiez votre usage sur [console.anthropic.com](https://console.anthropic.com)
2. **OpenAI** : Vérifiez votre usage sur [platform.openai.com](https://platform.openai.com)
3. Attendez quelques minutes avant de réessayer
4. Si nécessaire, augmentez votre plan API

---

### Erreur 12 : Les messages ne s'enregistrent pas dans Supabase

**Symptôme** :
Le workflow fonctionne mais les tables `conversations` et `messages` restent vides.

**Cause** :
Le node Supabase n'exécute pas la requête ou les credentials sont incorrects.

**Solution** :

1. Allez dans Supabase → **Table Editor** → table `conversations`
2. Si vide, vérifiez dans **Executions** (n8n) le node **Insert User Message**
3. Regardez les erreurs éventuelles
4. Testez manuellement dans Supabase SQL Editor :
   ```sql
   INSERT INTO conversations (session_id) VALUES ('test-manual');
   SELECT * FROM conversations;
   ```
5. Si erreur, vérifiez les permissions Supabase (Row Level Security)

---

### Erreur 13 : "Cannot destructure property 'session_id' of 'body' as it is undefined"

**Message d'erreur** :
```
Error in node 'Validate Input'
Cannot destructure property 'session_id' of 'body' as it is undefined
```

**Cause** :
Le webhook reçoit un body vide ou mal formaté.

**Solution** :

Vérifiez votre requête :

❌ **Incorrect (pas de body)** :
```bash
curl -X POST https://webhook-url
```

❌ **Incorrect (body non-JSON)** :
```bash
curl -X POST https://webhook-url -d "session_id=test&message=hello"
```

✅ **Correct** :
```bash
curl -X POST https://webhook-url \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test","message":"hello"}'
```

---

## 🔍 Comment débugger

### Méthode 1 : Utiliser les Executions n8n

1. Dans n8n, ouvrez votre workflow
2. Cliquez **Executions** (en haut à droite)
3. Cliquez sur une exécution récente
4. Vous verrez chaque node avec :
   - ✅ Vert = succès
   - ❌ Rouge = erreur
5. Cliquez sur un node rouge pour voir l'erreur détaillée

### Méthode 2 : Tester les nodes individuellement

1. Dans n8n, ouvrez votre workflow
2. Cliquez sur **Execute Workflow** (en haut à droite)
3. Les nodes vont s'exécuter un par un
4. Vous pouvez voir les données en sortie de chaque node

### Méthode 3 : Vérifier les données dans Supabase

1. Allez dans Supabase → **Table Editor**
2. Ouvrez la table `conversations` :
   ```sql
   SELECT * FROM conversations ORDER BY created_at DESC;
   ```
3. Ouvrez la table `messages` :
   ```sql
   SELECT * FROM messages ORDER BY created_at DESC;
   ```
4. Vérifiez que les données correspondent à vos tests

### Méthode 4 : Tester avec curl en verbose

```bash
curl -v -X POST "https://webhook-url" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test","message":"hello"}'
```

L'option `-v` affiche tous les détails (headers, status code, etc.)

---

## 📞 Support

Si le problème persiste après avoir suivi ce guide :

1. Vérifiez les logs d'exécution dans n8n (**Executions**)
2. Vérifiez les données dans Supabase (**Table Editor**)
3. Testez avec les exemples fournis dans `EXAMPLES.md`
4. Réexécutez les scripts de tests (`tests-curl.sh` ou `tests-powershell.ps1`)

---

## ✅ Checklist de validation complète

Cochez chaque élément pour valider que tout fonctionne :

### Supabase
- [ ] Les tables `conversations` et `messages` existent
- [ ] Les index sont créés
- [ ] Les credentials Supabase sont corrects dans n8n
- [ ] Vous pouvez insérer manuellement une ligne dans `conversations`

### n8n
- [ ] Le workflow est **actif**
- [ ] Tous les nodes sont connectés
- [ ] Les credentials sont configurés (Supabase + Claude/OpenAI)
- [ ] Vous pouvez voir l'URL du webhook (Production URL)
- [ ] Une exécution de test fonctionne (Execute Workflow)

### API Claude/OpenAI
- [ ] Votre clé API est valide
- [ ] Vous avez du crédit API disponible
- [ ] Le header `x-api-key` (Claude) ou `Authorization` (OpenAI) est correct
- [ ] Le modèle spécifié existe (`claude-3-5-sonnet-20241022` ou `gpt-4`)

### Tests
- [ ] Test 1 (premier message) fonctionne
- [ ] Test 2 (même session) fonctionne et conserve le contexte
- [ ] Test 3 (message vide) retourne une erreur
- [ ] Test 4 (session_id manquant) retourne une erreur
- [ ] Test 5 (message anglais) répond en anglais

---

**Si tous les éléments sont cochés, votre MVP est opérationnel ! 🎉**
