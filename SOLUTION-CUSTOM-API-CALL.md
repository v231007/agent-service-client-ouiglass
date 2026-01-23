# ✅ Solution : Configurer "Get or Create Conversation" avec Custom API Call

## 🎯 Configuration du Node

**Node** : Supabase "Get or Create Conversation"

### Paramètres à remplir :

#### 1. Operation
```
Custom API Call
```

#### 2. Method
```
POST
```

#### 3. Endpoint
```
/conversations
```

#### 4. Headers

Clique sur **"Add Header"** et ajoute :

| Name | Value |
|------|-------|
| `Prefer` | `resolution=merge-duplicates,return=representation` |

#### 5. Body

Sélectionne le mode **JSON** et mets :

```json
{
  "session_id": "={{ $json.session_id }}",
  "updated_at": "now()"
}
```

**Explications** :
- `session_id` : vient du node précédent (Validate Input)
- `updated_at` : sera mis à jour à chaque fois

---

## 🔍 Comment ça Marche ?

Le header `Prefer: resolution=merge-duplicates` dit à Supabase :
- Si `session_id` existe déjà → **UPDATE** (grâce au UNIQUE constraint)
- Si `session_id` n'existe pas → **INSERT**

C'est l'équivalent d'un UPSERT SQL :
```sql
INSERT INTO conversations (session_id, updated_at)
VALUES ('xxx', now())
ON CONFLICT (session_id) DO UPDATE SET updated_at = now()
RETURNING *;
```

---

## 📤 Format de Retour

Le node retournera un **array** avec 1 élément :

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

**⚠️ IMPORTANT** : Dans les nodes suivants, utilise `$json[0].id` au lieu de `$json.id`

---

## 🔗 Mise à Jour des Autres Nodes

### Node "Insert User Message"

**Champ `conversation_id`** :
```
={{ $json[0].id }}
```

### Node "Get Last N Messages"

**Filtre `conversation_id`** :
```
={{ $('Get or Create Conversation').item.json[0].id }}
```

### Node "Insert Assistant Message"

**Champ `conversation_id`** :
```
={{ $('Get or Create Conversation').item.json[0].id }}
```

---

## ✅ Checklist

- [ ] Operation = "Custom API Call"
- [ ] Method = "POST"
- [ ] Endpoint = "/conversations"
- [ ] Header "Prefer" ajouté avec la bonne valeur
- [ ] Body JSON avec session_id et updated_at
- [ ] Les autres nodes utilisent `$json[0].id`

---

## 🧪 Test

1. Execute le workflow avec `session_id = "test-001"`
2. Regarde le résultat du node → tu devrais voir un array avec 1 objet
3. Re-execute avec le même `session_id` → l'`updated_at` devrait changer mais pas l'`id`

Si ça marche, tu as réussi ! 🎉
