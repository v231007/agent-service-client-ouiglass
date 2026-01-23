# 🚀 Guide Configuration n8n Cloud v2.3.6 avec Custom API Call

## ✅ FICHIER À UTILISER

**Importe ce fichier dans n8n** :
```
workflow-ouiglass-mvp-v2.3.6.json
```

Ce workflow est adapté pour n8n Cloud v2.3.6 qui utilise **"Custom API Call"** au lieu de "Execute Query".

---

## 📋 Différences avec le Workflow Original

### Node "Get or Create Conversation"

**Version originale** (avec Execute Query) :
```sql
INSERT INTO conversations (session_id)
VALUES ('{{ $json.session_id }}')
ON CONFLICT (session_id) DO UPDATE SET updated_at = now()
RETURNING id, session_id, created_at, updated_at;
```

**Version v2.3.6** (avec Custom API Call) :

- **Operation** : `Custom API Call`
- **Method** : `POST`
- **Endpoint** : `/conversations`
- **Headers** :
  - Name : `Prefer`
  - Value : `resolution=merge-duplicates,return=representation`
- **Body** (JSON) :
```json
{
  "session_id": "={{ $json.session_id }}",
  "updated_at": "now()"
}
```

**Explication** :
- Le header `Prefer: resolution=merge-duplicates` dit à Supabase de faire un UPSERT automatiquement
- Si `session_id` existe déjà → UPDATE
- Si `session_id` n'existe pas → INSERT
- `return=representation` retourne les données créées/mises à jour

---

## 🔧 Configuration Node par Node

### Node 3 : Get or Create Conversation (⚠️ Spécifique v2.3.6)

1. **Type** : Supabase
2. **Operation** : `Custom API Call`
3. **Method** : `POST`
4. **Endpoint** : `/conversations`
5. Cliquez sur **"Add Header"**
   - **Name** : `Prefer`
   - **Value** : `resolution=merge-duplicates,return=representation`
6. **Body** → Mode `JSON` :
```json
{
  "session_id": "={{ $json.session_id }}",
  "updated_at": "now()"
}
```

**Important** : L'UPSERT automatique fonctionne grâce au **UNIQUE constraint** sur `session_id` dans ta table Supabase.

---

### Node 4 : Insert User Message (✅ Standard)

1. **Type** : Supabase
2. **Operation** : `Insert`
3. **Table** : `messages`
4. **Fields** :
   - `conversation_id` : `={{ $json[0].id }}`
   - `role` : `user`
   - `content` : `={{ $('Validate Input').item.json.message }}`

**Note** : `$json[0].id` parce que Custom API Call retourne un array avec 1 élément.

---

### Node 5 : Get Last N Messages (✅ Standard)

1. **Type** : Supabase
2. **Operation** : `Get All`
3. **Table** : `messages`
4. **Return All** : `false`
5. **Limit** : `10`
6. **Filters** :
   - Field : `conversation_id`
   - Operator : `equals`
   - Value : `={{ $('Get or Create Conversation').item.json[0].id }}`
7. **Sort** :
   - Field : `created_at`
   - Direction : `Ascending`

---

### Node 9 : Insert Assistant Message (✅ Standard)

1. **Type** : Supabase
2. **Operation** : `Insert`
3. **Table** : `messages`
4. **Fields** :
   - `conversation_id` : `={{ $('Get or Create Conversation').item.json[0].id }}`
   - `role` : `assistant`
   - `content` : `={{ $('Parse LLM JSON').item.json.reply }}`

---

## ⚠️ Points d'Attention v2.3.6

### 1. Custom API Call retourne un Array

Quand tu utilises **Custom API Call**, Supabase retourne toujours un **array** :

```json
[
  {
    "id": "uuid-123",
    "session_id": "test-001",
    "created_at": "2026-01-23T10:00:00Z",
    "updated_at": "2026-01-23T10:00:00Z"
  }
]
```

**Donc dans les autres nodes, utilise** :
- `$json[0].id` au lieu de `$json.id`
- `$json[0].session_id` au lieu de `$json.session_id`

### 2. Header "Prefer" est OBLIGATOIRE

Sans le header `Prefer: resolution=merge-duplicates`, tu auras une erreur **409 Conflict** si le `session_id` existe déjà.

### 3. UNIQUE constraint requis

Pour que l'UPSERT fonctionne, la table `conversations` DOIT avoir un **UNIQUE constraint** sur `session_id`.

Vérifie dans Supabase → SQL Editor :
```sql
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'conversations' AND constraint_type = 'UNIQUE';
```

Tu devrais voir une contrainte UNIQUE sur `session_id`.

---

## 🧪 Tester le Node "Get or Create Conversation"

### Test 1 : Premier appel (INSERT)

1. Execute le workflow avec `session_id = "test-001"`
2. Regarde le résultat du node "Get or Create Conversation"
3. Tu devrais voir :
```json
[
  {
    "id": "uuid-xxx",
    "session_id": "test-001",
    "created_at": "2026-01-23...",
    "updated_at": "2026-01-23..."
  }
]
```

### Test 2 : Deuxième appel (UPDATE)

1. Re-execute le workflow avec le même `session_id = "test-001"`
2. Regarde le résultat
3. Tu devrais voir le **même `id`** mais avec `updated_at` mis à jour
4. Ça confirme que l'UPSERT fonctionne ✅

---

## 🐛 Troubleshooting v2.3.6

### Erreur : "409 Conflict - duplicate key value violates unique constraint"

**Cause** : Le header `Prefer: resolution=merge-duplicates` est manquant ou mal configuré.

**Solution** :
1. Ouvre le node "Get or Create Conversation"
2. Vérifie que le header `Prefer` existe
3. Vérifie la valeur : `resolution=merge-duplicates,return=representation`

---

### Erreur : "Cannot read property 'id' of undefined"

**Cause** : Tu utilises `$json.id` au lieu de `$json[0].id`

**Solution** :
Dans tous les nodes qui référencent "Get or Create Conversation", utilise :
- `$json[0].id`
- `$json[0].session_id`
- etc.

---

### Erreur : "Field 'updated_at' expected a value but received null"

**Cause** : Le champ `updated_at` dans le body est mal formaté.

**Solution** :
Utilise `"updated_at": "now()"` (avec guillemets) dans le body JSON :
```json
{
  "session_id": "={{ $json.session_id }}",
  "updated_at": "now()"
}
```

---

### Le node retourne un array vide []

**Cause** : Le `session_id` n'a pas pu être inséré.

**Solution** :
1. Vérifie que la table `conversations` existe dans Supabase
2. Vérifie que les credentials Supabase sont corrects
3. Teste directement dans Supabase SQL Editor :
```sql
INSERT INTO conversations (session_id)
VALUES ('test-manual')
ON CONFLICT (session_id) DO UPDATE SET updated_at = now()
RETURNING *;
```

---

## ✅ Checklist de Validation

Avant de tester le workflow complet :

- [ ] Le fichier `workflow-ouiglass-mvp-v2.3.6.json` est importé dans n8n
- [ ] Les credentials Supabase sont configurés
- [ ] Les credentials Claude API sont configurés
- [ ] Le node "Get or Create Conversation" utilise **Custom API Call**
- [ ] Le header `Prefer: resolution=merge-duplicates,return=representation` est présent
- [ ] Les autres nodes utilisent `$json[0].id` pour référencer l'ID de conversation
- [ ] Le workflow est **Active**
- [ ] L'URL du webhook est copiée

---

## 🎯 Résumé

**Version n8n** : 2.3.6 ✅
**Operation utilisée** : Custom API Call ✅
**Fichier à importer** : `workflow-ouiglass-mvp-v2.3.6.json` ✅

**Différences clés** :
1. "Get or Create Conversation" utilise Custom API Call avec header `Prefer`
2. Les références à la conversation utilisent `$json[0].id` au lieu de `$json.id`
3. Tout le reste est identique au workflow original

**Prochaine étape** : Importe le fichier et teste ! 🚀
