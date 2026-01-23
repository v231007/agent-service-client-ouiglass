# Instructions pour Configurer le Node "Get or Create Conversation" dans n8n v2.3.6

**Contexte** : Je configure un workflow n8n pour OuiGlass Suisse. Mon n8n Cloud v2.3.6 n'a pas l'opération "Execute Query" dans le node Supabase, mais j'ai "Custom API Call".

---

## ✅ CE QUE JE VEUX FAIRE

Je veux faire un **UPSERT** sur la table `conversations` :
- Si le `session_id` existe déjà → UPDATE le `updated_at`
- Si le `session_id` n'existe pas → INSERT une nouvelle ligne

**Structure de ma table Supabase `conversations`** :
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);
```

---

## ❓ MA QUESTION

Comment configurer le node Supabase "Get or Create Conversation" avec l'opération **"Custom API Call"** pour faire cet UPSERT ?

**Informations disponibles** :
- Mon node précédent me passe `$json.session_id` (validé)
- Je dois retourner `id`, `session_id`, `created_at`, `updated_at` pour les nodes suivants
- J'ai accès à ces opérations dans mon node Supabase v2.3.6 :
  - Insert
  - Update
  - Delete
  - Get
  - Get All
  - **Custom API Call** ← je dois utiliser celle-ci

---

## 🎯 CE QUE JE DOIS CONFIGURER

Guide-moi pour remplir les champs du node Supabase "Custom API Call" :

1. **Operation** : Custom API Call (déjà sélectionné)
2. **Method** : ?
3. **Endpoint** : ?
4. **Headers** : ?
5. **Body** : ?
6. **Autres paramètres** : ?

---

## ⚠️ CONTRAINTES

- Le `session_id` a un **UNIQUE constraint** dans ma table
- Je veux que ça retourne les données créées/mises à jour (RETURNING)
- Les nodes suivants attendent `$json.id` ou `$json[0].id` (selon le format de retour)

---

## 📚 INFO SUPPLÉMENTAIRE

J'ai lu que PostgREST (l'API de Supabase) supporte un header spécial pour faire des UPSERT :
```
Prefer: resolution=merge-duplicates
```

Est-ce que c'est la bonne approche ? Comment je configure ça dans n8n ?

---

## ✅ EXEMPLE DE RÉPONSE ATTENDUE

Guide-moi avec des instructions claires, étape par étape, avec les valeurs exactes à mettre dans chaque champ du node n8n.
