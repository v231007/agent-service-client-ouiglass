# 🧪 Guide de Test - OuiGlass Agent IA

## Vue d'ensemble

Ce guide contient tous les scénarios de test pour valider le bon fonctionnement de votre agent IA OuiGlass avant le déploiement en production.

**Durée totale des tests** : 1-2 heures
**Niveau** : Débutant à Intermédiaire

---

## Checklist pré-tests

Avant de commencer les tests, vérifier que :

- [ ] Supabase configuré et tables créées
- [ ] N8N workflows Phase 1 activés
- [ ] Chatbot intégré sur une page de test
- [ ] Credentials configurées (Supabase, Claude API, Google Calendar)
- [ ] URL webhook production copiée

---

## Test 1 : Infrastructure de base

### Objectif
Vérifier que toute l'infrastructure fonctionne.

### Étapes

1. **Test Supabase**
   ```sql
   -- Dans Supabase SQL Editor
   SELECT * FROM conversations LIMIT 1;
   SELECT * FROM messages LIMIT 1;
   SELECT * FROM leads LIMIT 1;
   SELECT * FROM appointments LIMIT 1;
   ```
   **Résultat attendu** : Requêtes s'exécutent sans erreur (même si vides)

2. **Test N8N Workflow 1**
   ```bash
   # Dans terminal
   curl -X POST https://votre-instance.app.n8n.cloud/webhook/chat \
     -H "Content-Type: application/json" \
     -d '{"session_id": "test-001", "message": "Bonjour"}'
   ```
   **Résultat attendu** :
   ```json
   {
     "message": "Bonjour ! Je suis désolé pour votre pare-brise...",
     "completion": 5,
     "session_id": "test-001"
   }
   ```

3. **Vérifier dans Supabase**
   ```sql
   SELECT * FROM conversations WHERE id = 'test-001';
   SELECT * FROM messages WHERE conversation_id = 'test-001';
   ```
   **Résultat attendu** : 1 conversation + 2 messages (user + assistant)

**✅ Test réussi si** : Tout fonctionne sans erreur

---

## Test 2 : Chatbot widget

### Objectif
Tester l'interface chatbot sur site web.

### Étapes

1. Ouvrir `chatbot/integration-example.html` dans navigateur
2. Le widget apparaît en bas à droite après 5 secondes
3. Cliquer sur le widget → fenêtre de chat s'ouvre
4. Message d'accueil visible
5. Taper "Bonjour" et envoyer
6. Attendre 2-3 secondes → réponse du bot apparaît

**✅ Test réussi si** :
- Widget s'affiche
- Chat s'ouvre/ferme correctement
- Message envoyé et réponse reçue
- Aucune erreur dans console (F12 > Console)

### Test responsive

1. DevTools > Toggle device toolbar (Ctrl+Shift+M)
2. Tester sur iPhone SE, iPad, Desktop
3. Vérifier que le widget s'adapte

**✅ Test réussi si** : Widget fonctionnel sur tous les formats

---

## Test 3 : Conversation complète (Lead qualifié)

### Objectif
Simuler une conversation complète jusqu'au RDV confirmé.

### Scénario

**Session ID** : `test-complete-001`

1. **User** : Bonjour, j'ai mon pare-brise fissuré
   **Attendu** : Bot demande marque/modèle véhicule

2. **User** : BMW Serie 3 de 2020
   **Attendu** : Bot demande VIN + photos

3. **User** : WBA3B3G59DNP12345
   **Attendu** : Bot demande photos

4. **User** : [Simuler envoi photo] Photo envoyée
   **Attendu** : Bot demande assurance

5. **User** : AXA
   **Attendu** : Bot demande numéro sinistre

6. **User** : SIN-2025-12345
   **Attendu** : Bot demande numéro police

7. **User** : POL-987654
   **Attendu** : Bot demande nom/tel/email

8. **User** : Jean Dupont, 0791234567, jean@example.com
   **Attendu** : Bot demande adresse

9. **User** : Rue de la Gare 12, 1003 Lausanne
   **Attendu** : Bot propose 3 créneaux RDV

10. **User** : Mercredi 22/01 à 14h
    **Attendu** : Bot confirme RDV + email confirmation

### Vérifications post-conversation

```sql
-- Dans Supabase
SELECT * FROM conversations WHERE id = 'test-complete-001';
SELECT * FROM messages WHERE conversation_id = 'test-complete-001';
SELECT * FROM leads WHERE conversation_id = 'test-complete-001';
SELECT * FROM appointments WHERE lead_id = (
  SELECT id FROM leads WHERE conversation_id = 'test-complete-001'
);
```

**Résultat attendu** :
- 1 conversation (status = 'rdv_confirmed')
- ~20 messages
- 1 lead avec toutes les infos
- 1 appointment (status = 'scheduled')

### Vérifier Google Calendar

1. Ouvrir Google Calendar
2. Vérifier qu'un événement est créé pour le 22/01 à 14h
3. Titre : "RDV Jean Dupont - BMW Serie 3"
4. Description contient toutes les infos

**✅ Test réussi si** : Conversation fluide, toutes infos collectées, RDV créé

---

## Test 4 : Gestion objections

### Scénario : Client doute couverture assurance

1. **User** : Combien ça coûte ?
   **Attendu** : Bot explique que assurance couvre, zéro avance de frais

2. **User** : Mais je sais pas si mon assurance couvre
   **Attendu** : Bot rassure (99% assurances couvrent) + demande compagnie

3. **User** : Mobilière
   **Attendu** : Bot confirme que Mobilière couvre

**✅ Test réussi si** : Objections gérées naturellement

### Scénario : Client pas encore déclaré sinistre

1. **User** : J'ai mon pare-brise cassé, je peux avoir un RDV demain ?
   **Attendu** : Bot demande si sinistre déclaré

2. **User** : Non, c'est obligatoire ?
   **Attendu** : Bot explique process déclaration

**✅ Test réussi si** : Bot guide client pour déclarer sinistre

---

## Test 5 : Cas limites (Edge cases)

### Test 5.1 : Messages vides

1. Envoyer message vide
   **Attendu** : Rien ne se passe (input reste vide)

### Test 5.2 : Messages très longs

1. Envoyer message de 1000 caractères
   **Attendu** : Bot répond normalement (pas de crash)

### Test 5.3 : Caractères spéciaux

1. Envoyer : "C'est à 10€, n° VIN: ABC-123 (test)"
   **Attendu** : Bot traite correctement (pas de problème encodage)

### Test 5.4 : Session expirée

1. Effacer sessionStorage
2. Envoyer message
   **Attendu** : Nouvelle session créée automatiquement

### Test 5.5 : Double envoi rapide

1. Envoyer 2 messages très rapidement (< 1 seconde)
   **Attendu** : Les 2 messages sont traités

### Test 5.6 : Connexion perdue

1. Désactiver réseau (DevTools > Network > Offline)
2. Envoyer message
   **Attendu** : Message d'erreur "Une erreur s'est produite..."

**✅ Test réussi si** : Tous les cas limites gérés correctement

---

## Test 6 : Conversations multiples simultanées

### Objectif
Vérifier que plusieurs clients peuvent converser en même temps.

### Étapes

1. Ouvrir 3 onglets du chatbot (navigation privée)
2. Dans chaque onglet, démarrer conversation différente
   - Onglet 1 : Client avec BMW
   - Onglet 2 : Client avec Audi
   - Onglet 3 : Client avec Mercedes
3. Alterner les messages entre les 3 onglets

**Vérifier dans Supabase** :
```sql
SELECT * FROM conversations ORDER BY created_at DESC LIMIT 10;
```

**Résultat attendu** : 3 conversations distinctes avec 3 session_id différents

**✅ Test réussi si** : Aucune confusion entre conversations

---

## Test 7 : Performance & Latence

### Objectif
Mesurer temps de réponse du bot.

### Métrique

**Temps acceptable** :
- Réponse bot : < 3 secondes (idéal < 2s)
- Chargement widget : < 1 seconde

### Mesure

```javascript
// Dans console navigateur
const start = Date.now();

// Envoyer message via chatbot

// Quand réponse reçue
const end = Date.now();
console.log(`Temps réponse : ${end - start}ms`);
```

**Vérifier dans N8N** :
- Executions > Voir durée d'exécution workflow

**✅ Test réussi si** :
- 90% des réponses < 3 secondes
- Aucune réponse > 10 secondes

**Si trop lent** :
- Vérifier latence Claude API (peut varier)
- Vérifier timeout N8N (augmenter si nécessaire)
- Optimiser prompt système (réduire taille)

---

## Test 8 : Escalade vers humain

### Scénario : Client insiste pour parler à humain

1. **User** : Je veux parler à quelqu'un
   **Attendu** : Bot propose mise en contact conseiller

2. **User** : Oui
   **Attendu** : Bot demande coordonnées + dit "rappel sous 2h"

**Vérifier** :
- Dans N8N Executions : `next_action = "escalade"`
- Notification envoyée (WhatsApp/email)

**✅ Test réussi si** : Escalade détectée et notification envoyée

---

## Test 9 : Multi-langue (si applicable)

### Test anglais

1. **User** : Hello, I have a broken windshield
   **Attendu** : Bot détecte anglais et répond en anglais

**Note** : Pour Phase 1, focus sur français. Anglais = Phase 2.

---

## Test 10 : Sécurité

### Test injection SQL

1. **User** : `'; DROP TABLE conversations; --`
   **Attendu** : Traité comme texte normal, aucune commande SQL exécutée

**Vérifier** : Tables Supabase toujours présentes

### Test XSS

1. **User** : `<script>alert('XSS')</script>`
   **Attendu** : Affiché comme texte, pas exécuté comme script

**✅ Test réussi si** : Aucune vulnérabilité exploitable

---

## Scénarios de test complets

### Scénario A : Lead parfait (conversion 100%)

**Temps** : 5-8 minutes
**Objectif** : RDV confirmé

```
User: Bonjour
Bot: [Accueil] Quelle marque/modèle ?
User: BMW Serie 3 de 2020
Bot: VIN + photos ?
User: WBA3B3G59DNP12345
Bot: Photos ?
User: [Photo envoyée]
Bot: Assurance ?
User: AXA
Bot: N° sinistre ?
User: SIN-2025-12345
Bot: N° police ?
User: POL-987654
Bot: Nom/tel/email ?
User: Jean Dupont, 0791234567, jean@test.com
Bot: Adresse ?
User: Rue de la Gare 12, 1003 Lausanne
Bot: [3 créneaux proposés]
User: Mercredi 14h
Bot: ✅ RDV confirmé !
```

**Résultat** : Lead + Appointment créés

### Scénario B : Lead abandonné

**Temps** : 2 minutes
**Objectif** : Lead incomplet (à relancer)

```
User: Bonjour, pare-brise cassé
Bot: Marque/modèle ?
User: BMW
Bot: Année ?
[User ne répond plus]
```

**Résultat** :
- Conversation status = 'active'
- Lead status = 'collecting_info'
- Completion ~10%

**Action** : Workflow relance automatique J+1 (Phase 2)

### Scénario C : Lead avec objections

**Temps** : 10 minutes
**Objectif** : Conversion malgré doutes

```
User: C'est cher un pare-brise ?
Bot: Assurance couvre, zéro frais
User: Vraiment ?
Bot: Oui, 99% assurances. Vous êtes chez qui ?
User: Vaudoise
Bot: Parfait, Vaudoise couvre
[Conversation continue normalement]
```

**Résultat** : RDV confirmé après objections gérées

---

## Checklist finale avant production

### Infrastructure

- [ ] Supabase : 4 tables créées et testées
- [ ] N8N : 4 workflows Phase 1 actifs
- [ ] Credentials : Toutes configurées et testées
- [ ] Backups : Backup manuel Supabase effectué

### Chatbot

- [ ] Widget intégré sur site production
- [ ] URL webhook production configurée
- [ ] Couleur/branding OuiGlass appliqué
- [ ] Testé sur desktop + mobile

### Monitoring

- [ ] N8N Error Workflow créé
- [ ] Notifications configurées (WhatsApp/email)
- [ ] Logs Supabase activés
- [ ] Google Calendar synchronisé

### Tests

- [ ] Test 1 : Infrastructure ✅
- [ ] Test 2 : Chatbot widget ✅
- [ ] Test 3 : Conversation complète ✅
- [ ] Test 4 : Objections ✅
- [ ] Test 5 : Edge cases ✅
- [ ] Test 6 : Multi-sessions ✅
- [ ] Test 7 : Performance ✅
- [ ] Test 8 : Escalade ✅
- [ ] Test 10 : Sécurité ✅

### Documentation

- [ ] README.md à jour
- [ ] Guides setup partagés avec équipe
- [ ] Credentials sauvegardées en lieu sûr

---

## Métriques à suivre (post-déploiement)

### Semaine 1

- Nombre de conversations : ___
- Taux de conversion : ___% (objectif 80%+)
- Temps moyen conversation : ___ min
- Taux d'abandon : ___%
- Erreurs N8N : ___

### Actions selon résultats

**Si taux conversion < 60%** :
→ Analyser conversations abandonnées
→ Optimiser prompt système
→ Ajouter réponses FAQ

**Si temps réponse > 5s** :
→ Optimiser prompt (réduire taille)
→ Vérifier latence Claude API
→ Envisager cache réponses fréquentes

**Si beaucoup d'escalades** :
→ Identifier raisons (cas complexes, bugs, etc.)
→ Améliorer gestion objections dans prompt

---

## Outils de test

### Postman Collection

Créer collection Postman avec requêtes tests :

```json
{
  "info": { "name": "OuiGlass Agent IA Tests" },
  "item": [
    {
      "name": "Test Webhook Chat",
      "request": {
        "method": "POST",
        "url": "https://votre-instance.app.n8n.cloud/webhook/chat",
        "body": {
          "mode": "raw",
          "raw": "{\"session_id\": \"test-001\", \"message\": \"Bonjour\"}"
        }
      }
    }
  ]
}
```

### Script de test automatisé

```bash
#!/bin/bash
# test-agent.sh - Script de test automatique

WEBHOOK_URL="https://votre-instance.app.n8n.cloud/webhook/chat"
SESSION_ID="test-auto-$(date +%s)"

echo "🧪 Test Agent IA OuiGlass"
echo "Session: $SESSION_ID"

# Test 1: Accueil
echo "Test 1: Message accueil..."
curl -s -X POST $WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION_ID\", \"message\": \"Bonjour\"}" \
  | jq '.message'

sleep 2

# Test 2: Infos véhicule
echo "Test 2: Infos véhicule..."
curl -s -X POST $WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION_ID\", \"message\": \"BMW Serie 3 de 2020\"}" \
  | jq '.message'

echo "✅ Tests terminés"
```

---

## Support & Debugging

### Si un test échoue

1. **Vérifier logs N8N** : Executions > Voir erreur exacte
2. **Vérifier Supabase** : Logs > postgres-logs
3. **Console navigateur** : F12 > Console (erreurs JS)
4. **Network tab** : Vérifier requêtes HTTP

### Contacts

- Documentation : `docs/`
- Issues GitHub : [lien]
- Support : support@ouiglass.ch

---

**Félicitations !** Si tous les tests passent, vous êtes prêt pour la production ! 🚀

**Prochaine étape** : [Déploiement Production](DEPLOYMENT.md)
