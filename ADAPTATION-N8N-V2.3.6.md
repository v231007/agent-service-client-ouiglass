# 🔧 Adaptation pour n8n Cloud v2.3.6

## Problème Identifié

Dans n8n Cloud v2.3.6, certaines opérations du node Supabase peuvent ne pas être disponibles, notamment :
- `Execute Query` / `Execute SQL` / `Run SQL Query`

## Solutions Selon Ton Cas

### CAS 1 : Tu as "Execute Query" ✅

Si dans le menu "Operation" tu vois **"Execute Query"** ou **"Execute SQL"** :

**→ Utilise le workflow original** (`workflow-ouiglass-mvp.json`)

Tout fonctionnera directement.

---

### CAS 2 : Tu n'as PAS "Execute Query" ❌

Si cette opération n'existe pas, voici 2 méthodes alternatives :

---

## MÉTHODE A : Créer une Fonction PostgreSQL (Recommandé)

### Étape 1 : Créer la fonction dans Supabase

1. Va dans Supabase → **SQL Editor**
2. Exécute ce SQL :

```sql
-- Fonction pour get_or_create_conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(p_session_id TEXT)
RETURNS TABLE(id UUID, session_id TEXT, created_at TIMESTAMP, updated_at TIMESTAMP) AS $$
BEGIN
  INSERT INTO conversations (session_id)
  VALUES (p_session_id)
  ON CONFLICT (session_id) DO UPDATE SET updated_at = now()
  RETURNING conversations.id, conversations.session_id, conversations.created_at, conversations.updated_at
  INTO id, session_id, created_at, updated_at;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
```

### Étape 2 : Remplacer le node dans n8n

**Remplace le node "Get or Create Conversation" (Supabase) par un node "HTTP Request"** :

- **Name** : `Get or Create Conversation`
- **Method** : POST
- **URL** : `https://VOTRE-PROJET.supabase.co/rest/v1/rpc/get_or_create_conversation`
- **Authentication** : Generic Credential Type → Header Auth
  - Name : `apikey`
  - Value : `YOUR_SERVICE_ROLE_KEY`

**Headers** :
```
Authorization: Bearer YOUR_SERVICE_ROLE_KEY
Content-Type: application/json
Prefer: return=representation
```

**Body** (JSON) :
```json
{
  "p_session_id": "={{ $json.session_id }}"
}
```

**Options** :
- Response Format : JSON

### Avantages :
- ✅ Plus rapide (1 seule requête)
- ✅ Atomique (pas de race condition)
- ✅ Fonctionne sur toutes les versions n8n

---

## MÉTHODE B : Double Node (Get + Insert)

Si tu ne veux pas créer de fonction PostgreSQL, utilise 2 nodes :

### Node 1 : IF (Condition)

Remplace "Get or Create Conversation" par un node **IF** qui check si la conversation existe.

**MAIS** c'est plus complexe et nécessite :
1. Node Supabase "Get" (cherche la conversation)
2. Node IF (vérifie si trouvée)
3. Node Supabase "Insert" (si pas trouvée)
4. Node Supabase "Update" (si trouvée)
5. Node Merge (réunit les 2 branches)

**→ Je ne recommande PAS cette méthode**, c'est trop compliqué.

---

## MÉTHODE C : Utiliser PostgREST directement

Tous les nodes Supabase peuvent être remplacés par des HTTP Request vers l'API PostgREST de Supabase.

### Pour "Get or Create Conversation"

**Node : HTTP Request**

- **URL** : `https://VOTRE-PROJET.supabase.co/rest/v1/conversations`
- **Method** : POST
- **Headers** :
```
apikey: YOUR_SERVICE_ROLE_KEY
Authorization: Bearer YOUR_SERVICE_ROLE_KEY
Content-Type: application/json
Prefer: resolution=merge-duplicates,return=representation
```
- **Body** :
```json
{
  "session_id": "={{ $json.session_id }}",
  "updated_at": "now()"
}
```

**Note** : Le header `Prefer: resolution=merge-duplicates` fait l'upsert automatiquement.

### Pour "Insert User Message"

**Node : HTTP Request**

- **URL** : `https://VOTRE-PROJET.supabase.co/rest/v1/messages`
- **Method** : POST
- **Headers** : (mêmes que ci-dessus)
- **Body** :
```json
{
  "conversation_id": "={{ $('Get or Create Conversation').item.json.id }}",
  "role": "user",
  "content": "={{ $('Validate Input').item.json.message }}"
}
```

### Pour "Get Last N Messages"

**Node : HTTP Request**

- **URL** : `https://VOTRE-PROJET.supabase.co/rest/v1/messages?conversation_id=eq.{{ $('Get or Create Conversation').item.json.id }}&order=created_at.asc&limit=10`
- **Method** : GET
- **Headers** : (mêmes que ci-dessus)

---

## 🎯 MA RECOMMANDATION

**MÉTHODE A** (Fonction PostgreSQL + HTTP Request) est la meilleure solution :

1. ✅ Simple à implémenter
2. ✅ Performant (1 seule requête)
3. ✅ Fonctionne sur toutes les versions n8n
4. ✅ Évite les race conditions

**Prochaines étapes** :

1. Dis-moi si tu as "Execute Query" dans ton node Supabase
2. Si non, je te crée un workflow adapté avec la Méthode A
3. Je te guide étape par étape

---

## 📞 Besoin d'Aide ?

Envoie-moi :
- La liste des opérations disponibles dans ton node Supabase
- OU un screenshot du menu "Operation"

Et je t'adapte le workflow immédiatement ! 🚀
