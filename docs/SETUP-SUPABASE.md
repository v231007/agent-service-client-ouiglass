# 🗄️ Guide Setup Supabase - OuiGlass

## Vue d'ensemble

Ce guide vous explique **étape par étape** comment configurer votre base de données Supabase pour l'agent IA OuiGlass.

**Durée estimée** : 15-20 minutes
**Niveau** : Débutant (tout est expliqué)

## Qu'est-ce que Supabase ?

**Supabase** = Base de données PostgreSQL hébergée + API automatique + Interface web

**POURQUOI Supabase ?**
- ✅ Gratuit jusqu'à 500 MB (largement suffisant pour commencer)
- ✅ Pas de serveur à gérer (tout est hébergé)
- ✅ Interface visuelle simple
- ✅ API REST générée automatiquement
- ✅ Compatible avec N8N (intégration native)

**ANALOGIE** : Supabase = Excel en ligne + super-pouvoirs (recherche rapide, sécurité, API, etc.)

---

## Étape 1 : Créer un compte Supabase

### 1.1 Inscription

1. Aller sur [https://supabase.com](https://supabase.com)
2. Cliquer sur **"Start your project"**
3. S'inscrire avec :
   - **GitHub** (recommandé - plus rapide)
   - ou Email + Mot de passe

![Supabase signup](https://supabase.com/docs/img/supabase-signup.png)

**PIÈGE à éviter** : Utilisez une adresse email professionnelle (pas temporaire) car vous recevrez des notifications importantes.

### 1.2 Vérification email

Si vous utilisez email/password :
1. Vérifier votre boîte mail
2. Cliquer sur le lien de confirmation
3. Revenir sur Supabase

---

## Étape 2 : Créer un projet

### 2.1 Nouveau projet

1. Dans le dashboard Supabase, cliquer **"New project"**
2. Remplir les informations :

```
Organization: Créer nouvelle organisation "OuiGlass" (ou utiliser existante)
Project name: ouiglass-agent-ia
Database password: [Générer un mot de passe fort - LE SAUVEGARDER !]
Region: Europe (Germany) - le plus proche de la Suisse
Pricing plan: Free
```

**IMPORTANT** : Le mot de passe de la base de données est **CRITIQUE**.
- Sauvegardez-le dans un gestionnaire de mots de passe (1Password, Bitwarden, etc.)
- Vous en aurez besoin pour certaines connexions avancées
- Il ne peut PAS être récupéré s'il est perdu

3. Cliquer **"Create new project"**
4. Attendre 2-3 minutes (création de la base de données)

### 2.2 Récupérer les credentials

Une fois le projet créé :

1. Aller dans **Settings** (roue crantée) > **API**
2. Vous verrez :

```
Project URL: https://xxxxxxxxxxxxx.supabase.co
Project API keys:
  - anon public: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  - service_role: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... [Secret - ne jamais exposer]
```

**SAUVEGARDER ces 3 informations** (vous en aurez besoin pour N8N) :
- Project URL
- anon public key
- service_role key

**PIÈGE** :
- ❌ Ne JAMAIS mettre `service_role` key dans du code frontend (site web)
- ✅ Utiliser `service_role` uniquement dans N8N (backend sécurisé)
- ✅ Utiliser `anon public` pour le chatbot web (limité par Row Level Security)

---

## Étape 3 : Créer les tables

### 3.1 Ouvrir SQL Editor

1. Dans le menu de gauche, cliquer **"SQL Editor"**
2. Cliquer **"New query"**

Vous verrez un éditeur de code SQL vide.

### 3.2 Copier le schéma

1. Ouvrir le fichier `database/schema.sql` de ce projet
2. **Tout sélectionner** (Ctrl+A / Cmd+A)
3. **Copier** (Ctrl+C / Cmd+C)
4. **Coller** dans le SQL Editor de Supabase

Vous devriez voir ~500 lignes de SQL.

### 3.3 Exécuter le script

1. Cliquer **"Run"** (ou Ctrl+Enter)
2. Attendre 2-3 secondes
3. Vérifier le résultat en bas :

```
Success. No rows returned
```

**Si erreur** :
- Vérifier que vous avez bien copié TOUT le contenu de schema.sql
- Vérifier qu'il n'y a pas de caractères bizarres (copier depuis le fichier brut)
- Essayer de relancer (certaines commandes sont idempotentes)

### 3.4 Vérifier les tables créées

1. Dans le menu de gauche, cliquer **"Table Editor"**
2. Vous devriez voir 4 tables :
   - `conversations`
   - `messages`
   - `leads`
   - `appointments`

![Tables created](https://via.placeholder.com/800x400.png?text=Screenshot+Tables+Supabase)

**FÉLICITATIONS !** Votre base de données est créée ! 🎉

---

## Étape 4 : Explorer la structure

### 4.1 Table `conversations`

1. Cliquer sur **`conversations`** dans Table Editor
2. Voir les colonnes :
   - `id` : Identifiant unique (UUID - généré automatiquement)
   - `lead_source` : D'où vient le lead (website, email, whatsapp)
   - `contact_info` : Infos de contact (JSON flexible)
   - `status` : Statut (active, rdv_confirmed, etc.)
   - `language` : Langue (fr, en)
   - `created_at`, `updated_at` : Dates automatiques

**TEST** : Insérer une ligne manuellement
1. Cliquer **"Insert row"**
2. Remplir :
   ```
   lead_source: website
   status: active
   language: fr
   ```
3. Cliquer **"Save"**

Vous verrez votre première conversation ! (avec un ID généré automatiquement)

### 4.2 Table `messages`

Stocke chaque message d'une conversation.

**Relation** : Chaque message a un `conversation_id` qui pointe vers une conversation.

**TEST** :
1. Noter l'ID de la conversation créée juste avant (ex: `11111111-1111-1111-1111-111111111111`)
2. Aller dans table `messages`
3. Insert row :
   ```
   conversation_id: [ID de la conversation]
   role: user
   content: Bonjour, j'ai mon pare-brise fissuré
   ```
4. Insert row :
   ```
   conversation_id: [même ID]
   role: assistant
   content: Bonjour ! Je suis désolé pour votre pare-brise. C'est pour quel véhicule ?
   ```

Vous avez créé une mini-conversation ! 💬

### 4.3 Table `leads`

Stocke les infos clients collectées.

**Colonnes importantes** :
- Client : `full_name`, `phone`, `email`, `address`, etc.
- Véhicule : `vehicle_make`, `vehicle_model`, `vin`, etc.
- Vitrage : `glass_type`, `has_adas`, `photos`
- Assurance : `insurance_company`, `claim_number`, `policy_number`

Vous n'avez pas besoin de remplir manuellement (l'agent IA le fera automatiquement).

### 4.4 Table `appointments`

Stocke les RDV confirmés.

**Colonnes importantes** :
- `scheduled_at` : Date/heure du RDV
- `zone` : Zone géographique (lausanne, geneve, etc.)
- `status` : scheduled, confirmed, completed, etc.
- `external_id` : ID Otovia (null en Phase 1)

---

## Étape 5 : Tester les requêtes utiles

### 5.1 Ouvrir le fichier queries.sql

1. Ouvrir `database/queries.sql`
2. Copier la première requête (Statistiques globales)

```sql
SELECT
  COUNT(DISTINCT c.id) as total_conversations,
  COUNT(DISTINCT l.id) as total_leads,
  COUNT(DISTINCT a.id) as total_rdv,
  ROUND(
    COUNT(DISTINCT a.id) * 100.0 / NULLIF(COUNT(DISTINCT c.id), 0),
    2
  ) as taux_conversion_pct
FROM conversations c
LEFT JOIN leads l ON c.id = l.conversation_id
LEFT JOIN appointments a ON l.id = a.lead_id
WHERE c.created_at >= NOW() - INTERVAL '7 days';
```

3. Coller dans SQL Editor
4. Run

**Résultat** (pour l'instant) :
```
total_conversations: 1
total_leads: 0
total_rdv: 0
taux_conversion_pct: 0.00
```

Normal ! Vous n'avez qu'une conversation de test.

**POURQUOI c'est utile ?**
Quand le système tournera, cette requête vous donnera les stats en temps réel.

### 5.2 Créer des "Saved queries" pour plus tard

1. Dans SQL Editor, cliquer sur **"Save"**
2. Nommer : "Stats globales 7 jours"
3. Sauvegarder

Répéter pour vos requêtes favorites depuis `queries.sql`.

---

## Étape 6 : Configuration pour N8N

### 6.1 Credentials à copier

Vous aurez besoin de ces 3 infos dans N8N :

```bash
# Supabase
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_KEY_ANON=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_KEY_SERVICE_ROLE=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Où les trouver ?**
Settings > API > Project URL + API Keys

### 6.2 Test de connexion depuis N8N

**Vous le ferez dans le guide SETUP-N8N.md**, mais voici un aperçu :

1. Dans N8N, ajouter un node **Supabase**
2. Credentials :
   - Host : `https://xxxxxxxxxxxxx.supabase.co`
   - Service Role Key : `eyJhbG...` (utiliser service_role pour N8N)
3. Tester la connexion
4. Si ✅ : parfait !

---

## Étape 7 : Sécurité (Phase 1 - Développement)

### 7.1 RLS (Row Level Security) - Désactivé pour le moment

**Qu'est-ce que le RLS ?**
System de sécurité qui limite qui peut lire/écrire quelles lignes.

**Pour Phase 1 (développement)** :
- RLS **désactivé** (pour faciliter les tests)
- Accès uniquement via `service_role` key (jamais exposée publiquement)

**Pour Production (Phase 3)** :
- Activer RLS
- Créer policies restrictives
- Utiliser `anon` key avec authentification

**Comment activer RLS plus tard** :
```sql
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "N8N can do anything" ON conversations
  FOR ALL
  USING (auth.role() = 'service_role');
```

### 7.2 Backup automatique

**GRATUIT sur Supabase** :
- Backup quotidien automatique (7 jours de rétention)
- Point-in-time recovery (PITR) disponible sur plan Pro

**Où voir les backups ?**
Settings > Database > Backups

**RECOMMANDATION** :
- Phase 1 : Backups automatiques suffisants
- Phase 3 : Export manuel hebdomadaire en CSV (via queries.sql)

---

## Étape 8 : Monitoring

### 8.1 Dashboard Supabase

**Où voir les stats ?**
1. Home (page d'accueil projet)
2. Métriques visibles :
   - Database size
   - API requests
   - Active connections

### 8.2 Logs

**Où voir les logs ?**
Logs > Postgres Logs

**Types de logs** :
- Slow queries (requêtes lentes > 100ms)
- Erreurs SQL
- Connexions

**POURQUOI c'est utile ?**
Détecter les problèmes de performance avant qu'ils deviennent critiques.

### 8.3 Alertes

**Configuration email alertes** :
Settings > Notifications
- ✅ Database > 80% storage
- ✅ API requests limite atteinte

---

## Étape 9 : Données de test (optionnel)

### 9.1 Insérer conversations de test

Pour tester les workflows N8N, vous pouvez insérer des données de test :

```sql
-- Conversation test 1
INSERT INTO conversations (id, lead_source, contact_info, status, language) VALUES
  ('11111111-1111-1111-1111-111111111111', 'website', '{"name": "Jean Dupont", "phone": "+41791234567", "email": "jean@example.com"}', 'active', 'fr');

-- Messages test
INSERT INTO messages (conversation_id, role, content) VALUES
  ('11111111-1111-1111-1111-111111111111', 'user', 'Bonjour, j''ai mon pare-brise fissuré'),
  ('11111111-1111-1111-1111-111111111111', 'assistant', 'Bonjour Jean ! C''est pour quel véhicule ?'),
  ('11111111-1111-1111-1111-111111111111', 'user', 'BMW Serie 3 de 2020');

-- Lead test
INSERT INTO leads (
  conversation_id, full_name, phone, email,
  vehicle_make, vehicle_model, vehicle_year,
  glass_type, has_adas, canton, status
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Jean Dupont', '+41791234567', 'jean@example.com',
  'BMW', 'Serie 3', 2020,
  'pare-brise', true, 'Vaud', 'collecting_info'
);
```

Exécuter dans SQL Editor.

### 9.2 Supprimer données de test

```sql
-- Tout supprimer (ATTENTION - irréversible)
DELETE FROM appointments;
DELETE FROM leads;
DELETE FROM messages;
DELETE FROM conversations;

-- Ou supprimer seulement conversations de test
DELETE FROM conversations WHERE id = '11111111-1111-1111-1111-111111111111';
-- Les messages/leads associés sont supprimés automatiquement (CASCADE)
```

---

## Étape 10 : Limites & Scaling

### 10.1 Plan gratuit (Free tier)

**Limites** :
- Storage : 500 MB
- Bandwidth : 2 GB/mois
- API requests : Illimitées
- Connections : 60 simultanées max

**Estimation** :
- 1 conversation = ~5 KB (messages + lead)
- 500 MB = ~100,000 conversations
- Largement suffisant pour Phase 1 !

### 10.2 Monitoring de l'usage

**Où voir l'usage ?**
Settings > Billing > Usage

**ALERTE** :
Si vous approchez 80% storage → Migrer vers plan Pro ($25/mois)

### 10.3 Optimisation

**Si vous manquez d'espace** :
1. Nettoyer conversations abandonnées (> 90 jours)
   ```sql
   SELECT cleanup_abandoned_conversations();
   ```
2. Archiver anciennes données (export CSV puis delete)
3. Activer compression PostgreSQL (automatique sur Supabase)

---

## ✅ Checklist finale

Avant de passer à N8N, vérifier :

- [ ] Projet Supabase créé
- [ ] Mot de passe database sauvegardé
- [ ] Tables créées (conversations, messages, leads, appointments)
- [ ] Project URL + API keys sauvegardées
- [ ] Test d'insertion manuelle réussi
- [ ] Requête SQL test exécutée avec succès

**Si tout est ✅ : Félicitations !** Vous pouvez passer à [SETUP-N8N.md](SETUP-N8N.md) 🚀

---

## Problèmes courants

### ❌ "Error: relation does not exist"

**Cause** : Table pas créée
**Solution** : Ré-exécuter schema.sql complet

### ❌ "Error: permission denied"

**Cause** : Mauvaise clé API utilisée
**Solution** : Vérifier que vous utilisez `service_role` dans N8N

### ❌ "Error: syntax error near..."

**Cause** : SQL mal copié
**Solution** : Copier depuis le fichier RAW (pas depuis un PDF ou doc)

### ❌ Données ne s'affichent pas dans Table Editor

**Cause** : Cache navigateur
**Solution** : Refresh (Ctrl+R) ou vider cache

---

## Ressources utiles

- [Documentation Supabase](https://supabase.com/docs)
- [SQL Tutorial](https://www.postgresql.org/docs/current/tutorial.html)
- [Supabase Discord](https://discord.supabase.com)

---

**Prochaine étape** : [Configuration N8N](SETUP-N8N.md) →
