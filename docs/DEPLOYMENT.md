# 🚀 Guide de Déploiement - OuiGlass Agent IA

## Vue d'ensemble

Ce guide explique comment déployer votre agent IA OuiGlass en production de manière sécurisée et performante.

**Durée** : 2-3 heures
**Prérequis** : Tous les tests passés (voir [TESTING.md](TESTING.md))

---

## Phase 1 : Pré-déploiement

### Checklist pré-déploiement

- [ ] Tous les tests passés (TESTING.md)
- [ ] Backup Supabase effectué
- [ ] Credentials sauvegardées (1Password, Bitwarden, etc.)
- [ ] Documentation à jour
- [ ] Équipe formée sur l'outil
- [ ] Plan de rollback préparé

### Backup complet

#### Supabase

```sql
-- Export complet (SQL Editor > Export)
-- Sauvegarder le fichier .sql localement
```

**Alternative** : Utiliser l'API Supabase

```bash
# Export via CLI (si installé)
supabase db dump --db-url postgresql://... > backup-$(date +%Y%m%d).sql
```

#### N8N Workflows

1. Dans N8N, pour chaque workflow :
   - Workflow > Settings > Download
   - Sauvegarder les fichiers JSON

2. Créer archive :
   ```bash
   # Créer dossier backups
   mkdir -p backups/$(date +%Y%m%d)

   # Copier tous les workflows
   cp n8n-workflows/phase1/*.json backups/$(date +%Y%m%d)/
   ```

---

## Phase 2 : Configuration Production

### Supabase

#### 1. Row Level Security (RLS)

**IMPORTANT** : Activer RLS pour sécuriser les données.

```sql
-- Activer RLS sur toutes les tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Policy : Seul service_role (N8N) peut tout faire
CREATE POLICY "Service role full access conversations"
  ON conversations FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access messages"
  ON messages FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access leads"
  ON leads FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access appointments"
  ON appointments FOR ALL
  USING (auth.role() = 'service_role');
```

**Test** : Vérifier que N8N peut toujours lire/écrire.

#### 2. Index pour performance

```sql
-- Créer index si pas déjà fait
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON messages(conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_leads_status_created
  ON leads(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_appointments_scheduled
  ON appointments(scheduled_at) WHERE status IN ('scheduled', 'confirmed');
```

#### 3. Monitoring

Activer alertes Supabase :
1. Settings > Notifications
2. Activer :
   - Database > 80% storage
   - Exceeds plan limits

### N8N

#### 1. Plan payant

**Passer au plan Starter minimum ($20/mois)** :
- N8N > Settings > Billing
- Upgrade to Starter

**Pourquoi** :
- Plan gratuit : 2,500 executions/mois (insuffisant)
- Starter : 10,000 executions/mois + workflows toujours actifs

#### 2. Rate Limiting

Protéger contre abus :

Dans workflow webhook, ajouter node **"Rate Limit"** :
```
Node : Code (Function)
Code :
  const sessionId = $input.item.json.session_id;
  const now = Date.now();

  // Vérifier dernière requête
  const lastRequest = $context.get(sessionId) || 0;

  if (now - lastRequest < 1000) { // 1 req/seconde max
    throw new Error('Rate limit exceeded');
  }

  $context.set(sessionId, now);
  return $input.all();
```

#### 3. Error Workflow

Créer workflow "Error Handler" :

```
Trigger : Error Trigger
    ↓
Switch : Type d'erreur
    ├─> Timeout → Log + Retry
    ├─> API Error → Notification urgente
    └─> Other → Log
    ↓
Send Notification (WhatsApp/Email)
```

#### 4. Monitoring

Activer monitoring :
- Settings > Workflows > Save execution data : **Always**
- Configurer retention : 7 jours

---

## Phase 3 : Déploiement Chatbot

### Intégration sur site web

#### 1. Minifier les fichiers

```bash
# Installer terser et cssnano (si pas déjà fait)
npm install -g terser cssnano-cli

# Minifier JS
terser chatbot/ouiglass-chat-widget.js \
  -o chatbot/ouiglass-chat-widget.min.js \
  -c -m

# Minifier CSS
cssnano chatbot/ouiglass-chat-widget.css \
  chatbot/ouiglass-chat-widget.min.css
```

**Gain** : ~60% réduction taille

#### 2. Héberger sur CDN (Optionnel mais recommandé)

**Option A : Cloudflare CDN**

1. Créer compte Cloudflare
2. Activer CDN pour votre domaine
3. Uploader fichiers :
   ```
   https://cdn.ouiglass.ch/chat/ouiglass-chat-widget.min.js
   https://cdn.ouiglass.ch/chat/ouiglass-chat-widget.min.css
   ```

**Option B : jsDelivr (gratuit)**

1. Créer GitHub repo public
2. Push les fichiers
3. Utiliser :
   ```html
   <script src="https://cdn.jsdelivr.net/gh/ouiglass/chatbot@main/ouiglass-chat-widget.min.js"></script>
   ```

#### 3. Intégration finale sur ouiglass.ch

```html
<!-- Dans <head> -->
<link rel="stylesheet" href="https://cdn.ouiglass.ch/chat/ouiglass-chat-widget.min.css">

<!-- Avant </body> -->
<script src="https://cdn.ouiglass.ch/chat/ouiglass-chat-widget.min.js"></script>
<script>
  new OuiGlassChat({
    webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat',
    primaryColor: '#0066CC',
    showAfterSeconds: 5
  });
</script>
```

#### 4. Vérification

1. Ouvrir site en navigation privée
2. Attendre 5 secondes
3. Widget apparaît
4. Tester conversation complète
5. Vérifier que tout fonctionne

**Si erreur** :
- F12 > Console pour voir erreurs JS
- Network tab pour vérifier chargement fichiers

---

## Phase 4 : Configuration Notifications

### WhatsApp Business (optionnel Phase 1)

Si vous avez configuré WhatsApp :

1. Vérifier que l'API fonctionne
2. Tester notification :
   ```bash
   curl -X POST https://graph.facebook.com/v18.0/PHONE_ID/messages \
     -H "Authorization: Bearer ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "messaging_product": "whatsapp",
       "to": "41791234567",
       "type": "text",
       "text": {"body": "Test notification"}
     }'
   ```

### Email (fallback)

Si pas WhatsApp, configurer email :

1. N8N > Workflow Notifications
2. Remplacer HTTP Request WhatsApp par **Gmail** ou **Send Email**
3. Configurer SMTP
4. Tester

---

## Phase 5 : Monitoring & Analytics

### Google Analytics (optionnel)

Tracker utilisation du chatbot :

```javascript
// Dans integration du chatbot
document.getElementById('ouiglass-chat-toggle').addEventListener('click', () => {
  if (typeof gtag !== 'undefined') {
    gtag('event', 'chat_opened', {
      event_category: 'Chat',
      event_label: 'Widget opened'
    });
  }
});

// Tracker message envoyé
const originalSend = chat.sendMessage;
chat.sendMessage = function() {
  originalSend.call(this);

  if (typeof gtag !== 'undefined') {
    gtag('event', 'chat_message_sent', {
      event_category: 'Chat'
    });
  }
};
```

### Dashboard Supabase

Créer queries favorites pour dashboard :

```sql
-- KPIs journaliers
SELECT
  DATE(created_at) as date,
  COUNT(*) as leads,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv,
  ROUND(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 60), 1) as avg_duration_min
FROM conversations
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## Phase 6 : Formation équipe

### Documentation à partager

1. **README.md** - Vue d'ensemble
2. **ARCHITECTURE.md** - Comprendre le système
3. **Guide utilisateur** (à créer) - Comment intervenir manuellement

### Procédures d'urgence

#### Si le chatbot ne répond plus

1. Vérifier N8N : Executions (voir erreurs)
2. Vérifier Supabase : Logs
3. Redémarrer workflow N8N (toggle OFF puis ON)
4. Si toujours HS : Désactiver widget temporairement

```html
<!-- Commenter le script du chatbot -->
<!--
<script src="ouiglass-chat-widget.js"></script>
<script>new OuiGlassChat({...});</script>
-->
```

#### Si trop de leads non convertis

1. Analyser conversations abandonnées :
   ```sql
   SELECT c.*, l.status, l.conversion_score
   FROM conversations c
   LEFT JOIN leads l ON c.id = l.conversation_id
   WHERE c.status = 'abandoned'
     AND c.created_at >= NOW() - INTERVAL '7 days'
   ORDER BY c.created_at DESC;
   ```

2. Identifier patterns (où ça bloque)
3. Améliorer prompt système
4. Tester à nouveau

---

## Phase 7 : Lancement progressif (Soft Launch)

### Stratégie recommandée

**Semaine 1 : Test interne**
- Activer chatbot sur page cachée
- Partager lien avec équipe/amis
- Collecter feedbacks

**Semaine 2 : 10% traffic**
- Activer pour 10% visiteurs (A/B test)
- Monitorer métriques
- Ajuster si nécessaire

**Semaine 3 : 50% traffic**
- Étendre à 50%
- Vérifier performance (temps réponse, taux conversion)

**Semaine 4 : 100% traffic**
- Déploiement complet
- Annoncer sur réseaux sociaux

### A/B Testing (optionnel)

```javascript
// Activer pour seulement 10% des visiteurs
const randomNumber = Math.random();
if (randomNumber < 0.1) {
  // Charger chatbot
  new OuiGlassChat({...});
}
```

---

## Phase 8 : Post-déploiement

### Monitoring quotidien (Semaine 1)

**Chaque jour** :

1. Vérifier N8N Executions (erreurs ?)
2. Vérifier Supabase :
   ```sql
   SELECT COUNT(*) FROM conversations WHERE DATE(created_at) = CURRENT_DATE;
   ```
3. Tester le chatbot manuellement (1 conversation test)
4. Répondre aux escalades (clients demandant humain)

### Métriques hebdomadaires

**Chaque lundi** :

```sql
-- Stats semaine dernière
SELECT
  COUNT(*) as total_leads,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv_confirmes,
  ROUND(
    COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) * 100.0 / COUNT(*),
    2
  ) as taux_conversion
FROM conversations
WHERE created_at >= NOW() - INTERVAL '7 days';
```

**Objectifs** :
- Taux conversion : 80%+
- Temps moyen réponse : < 3s
- Taux d'erreur : < 1%

### Optimisations continues

#### Si taux conversion < 70%

1. Analyser conversations :
   - Où les clients abandonnent ?
   - Quelles questions posent problème ?

2. Améliorer prompt :
   - Ajouter réponses aux objections fréquentes
   - Simplifier formulations

3. A/B tester variants

#### Si temps réponse > 5s

1. Réduire taille prompt système
2. Activer cache Claude (prompt caching)
3. Pré-calculer créneaux RDV (au lieu de calcul à la volée)

---

## Checklist Finale de Déploiement

### Infrastructure
- [ ] Supabase : RLS activé
- [ ] Supabase : Index créés
- [ ] Supabase : Backup automatique configuré
- [ ] N8N : Plan payant activé
- [ ] N8N : Rate limiting configuré
- [ ] N8N : Error workflow actif

### Chatbot
- [ ] Fichiers minifiés
- [ ] Hébergé sur CDN (ou domaine principal)
- [ ] Intégré sur site production
- [ ] Testé en navigation privée
- [ ] Testé sur mobile

### Monitoring
- [ ] Notifications configurées (WhatsApp/email)
- [ ] Google Analytics (optionnel)
- [ ] Dashboard Supabase avec queries favorites
- [ ] Alertes Supabase activées

### Documentation
- [ ] Équipe formée
- [ ] Procédures d'urgence documentées
- [ ] Credentials sauvegardées en sécurité
- [ ] Backups effectués

### Tests Production
- [ ] Conversation test complète réussie
- [ ] RDV créé dans Google Calendar
- [ ] Notification reçue
- [ ] Performance < 3s

---

## Plan de Rollback

### Si problème majeur en production

1. **Désactiver le chatbot immédiatement** :
   ```html
   <!-- Commenter script -->
   <!--<script src="ouiglass-chat-widget.js"></script>-->
   ```

2. **Analyser le problème** :
   - N8N Executions : identifier erreur
   - Supabase Logs : vérifier DB
   - Console navigateur : erreurs JS

3. **Fix ou Revert** :
   - Si fix rapide (< 30 min) : corriger
   - Sinon : restaurer backup Supabase

4. **Tester en staging**

5. **Redéployer**

---

## Support Post-Déploiement

### Semaine 1-4 : Support intensif

- Monitoring quotidien
- Réponse rapide aux problèmes
- Collecte feedbacks clients
- Optimisations continues

### Mois 2+ : Maintenance

- Monitoring hebdomadaire
- Mises à jour selon feedbacks
- Préparation Phase 2

---

## Prochaines étapes

Une fois Phase 1 stable :

1. Collecter métriques pendant 1 mois
2. Analyser résultats
3. Planifier Phase 2 :
   - Workflow Email entrants
   - Confirmation RDV J-1
   - WhatsApp Business complet

Voir [PHASE2-PLANNING.md](PHASE2-PLANNING.md)

---

**FÉLICITATIONS ! 🎉**

Votre agent IA OuiGlass est déployé en production !

**Questions ?** support@ouiglass.ch
