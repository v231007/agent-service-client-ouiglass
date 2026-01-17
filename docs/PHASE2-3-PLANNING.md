# 📅 Planning Phases 2 & 3 - OuiGlass Agent IA

## Vue d'ensemble

Ce document planifie les évolutions du système après la Phase 1 (MVP).

**Prérequis** : Phase 1 déployée et stable pendant au moins 1 mois.

---

## Phase 2 : Extensions (2-3 semaines)

### Objectifs

- Automatiser confirmation RDV J-1
- Gérer emails entrants automatiquement
- Gérer rebooking (report/annulation RDV)
- Déployer WhatsApp Business complet

### Workflow 5 : Emails Entrants

**Trigger** : Email reçu sur contact@ouiglass.ch

**Flow** :
```
Email Trigger (IMAP)
    ↓
Function: Nettoyer email (retirer signatures, etc.)
    ↓
HTTP Request: LLM analyser type demande
    ↓
Switch: Type
    ├─> Nouveau lead → Workflow 1 (Réception Lead)
    ├─> Question RDV existant → Chercher RDV + Répondre
    ├─> Réclamation → Escalade humain
    └─> Info générale → Réponse automatique
    ↓
Send Email: Réponse
```

**Bénéfice** : Réponse automatique emails 24/7

**Complexité** : Moyenne
**Temps dev** : 3-4 jours

### Workflow 6 : Confirmation RDV J-1

**Trigger** : Schedule quotidien (tous les jours à 9h)

**Flow** :
```
Schedule Trigger (Cron: 0 9 * * *)
    ↓
Supabase: Récupérer RDV demain
    ↓
Loop: Pour chaque RDV
    ↓
WhatsApp/Email: "Confirmer RDV demain ?"
    ↓
Set: Marquer confirmation_sent_at
    ↓
Wait for Webhook: Réponse client (4h timeout)
    ↓
Switch: Réponse
    ├─> "Oui"/"Confirmé" → Update status = 'confirmed'
    ├─> "Non"/"Annulé" → Workflow Rebooking
    └─> Pas de réponse → Relance + Notification propriétaire
```

**Bénéfice** : Taux de confirmation 95%+ (vs 70% sans rappel)

**Complexité** : Moyenne
**Temps dev** : 2-3 jours

### Workflow 7 : Rebooking

**Trigger** : Client annule/reporte RDV

**Flow** :
```
Webhook Trigger: /rebooking
    ↓
Supabase: Récupérer RDV + Lead
    ↓
HTTP Request: LLM comprendre raison annulation
    ↓
Function: Calculer nouveaux créneaux (même logique Workflow 3)
    ↓
WhatsApp/Email: Proposer 3 nouveaux créneaux
    ↓
Wait for Webhook: Choix client
    ↓
Update RDV: Nouvelle date
    ↓
Notification propriétaire: "RDV reporté"
```

**Bénéfice** : Récupérer RDV annulés (au lieu de les perdre)

**Complexité** : Faible (réutilise code Workflow 3)
**Temps dev** : 1-2 jours

### Workflow 8 : WhatsApp Business Complet

**Amélioration** : Remplacer notifications basiques par conversations complètes

**Ajout** :
- Recevoir messages WhatsApp (pas juste envoyer)
- Client peut initier conversation via WhatsApp
- Même workflow que chatbot web (réutiliser Workflow 1-2)

**Setup** :
1. Configurer WhatsApp Business API
2. Configurer webhook vers N8N
3. Créer Trigger : WhatsApp Message Received
4. Router vers Workflow 1 (même logique que web)

**Bénéfice** : Canal supplémentaire (beaucoup de clients préfèrent WhatsApp)

**Complexité** : Moyenne (setup Meta Business Suite)
**Temps dev** : 3-5 jours

### Bonus Phase 2 : Relance automatique

**Trigger** : Schedule quotidien

**Flow** :
```
Schedule Trigger (10h)
    ↓
Supabase: Leads abandonnés (status = 'collecting_info', updated > 24h)
    ↓
Loop: Pour chaque lead
    ↓
WhatsApp/Email: "Bonjour [Nom], vous aviez commencé une demande de RDV..."
    ↓
Set: Marquer relance_sent_at
```

**Bénéfice** : Récupérer 10-20% leads abandonnés

**Complexité** : Faible
**Temps dev** : 1 jour

### Total Phase 2

**Durée** : 2-3 semaines
**Effort** : 10-15 jours dev

**ROI attendu** :
- +10% taux de conversion (relances)
- +5% taux confirmation RDV (rappel J-1)
- -50% emails à traiter manuellement

---

## Phase 3 : Avancé (1 mois)

### Objectifs

- Intégrer Otovia (CRM/Planning)
- Automatiser demande avis Google
- Créer dashboard métriques temps réel
- Optimiser planning techniciens
- Fine-tuning & optimisations

### Intégration Otovia API

**Objectif** : Remplacer Google Calendar par Otovia

**Avantages** :
- Planning techniciens optimisé
- Commande pare-brise automatique
- Facturation intégrée
- Historique client centralisé

**Prérequis** :
- API Otovia disponible (vérifier avec fournisseur)
- Documentation API Otovia

**Migration** :

1. **Setup** :
   - Créer credentials Otovia dans N8N
   - Tester endpoints API

2. **Endpoints nécessaires** :
   ```
   GET  /api/v1/appointments?date=YYYY-MM-DD&zone=lausanne
   POST /api/v1/appointments
   PUT  /api/v1/appointments/{id}
   DELETE /api/v1/appointments/{id}

   POST /api/v1/glass-orders (commande pare-brise)
   POST /api/v1/invoices (facturation)

   GET  /api/v1/technicians (disponibilité techniciens)
   ```

3. **Modifier Workflow 3** :
   - Remplacer "Google Calendar: Create Event"
   - Par "HTTP Request: Otovia Create Appointment"
   - Exemple :
     ```json
     POST /api/v1/appointments
     {
       "client": {
         "name": "{{$json.full_name}}",
         "phone": "{{$json.phone}}",
         "email": "{{$json.email}}",
         "address": "{{$json.address}}"
       },
       "vehicle": {
         "make": "{{$json.vehicle_make}}",
         "model": "{{$json.vehicle_model}}",
         "year": {{$json.vehicle_year}},
         "vin": "{{$json.vin}}"
       },
       "glass_type": "{{$json.glass_type}}",
       "has_adas": {{$json.has_adas}},
       "scheduled_at": "{{$json.chosen_slot}}",
       "zone": "{{$json.zone}}",
       "insurance": {
         "company": "{{$json.insurance_company}}",
         "claim_number": "{{$json.claim_number}}",
         "policy_number": "{{$json.policy_number}}"
       }
     }
     ```

4. **Synchro bidirectionnelle** :
   - Workflow Otovia → N8N : Webhook quand RDV modifié manuellement
   - Mettre à jour Supabase en conséquence

5. **Migration données** :
   - Exporter RDV Google Calendar
   - Importer dans Otovia
   - Vérifier cohérence

**Complexité** : Élevée
**Temps dev** : 1-2 semaines
**Dépend de** : Qualité documentation API Otovia

### Workflow Avis Google

**Trigger** : Webhook Otovia "Intervention terminée"

**Flow** :
```
Webhook: Intervention terminée
    ↓
Wait: 2 heures (laisser temps client rentrer chez lui)
    ↓
HTTP Request: LLM générer message personnalisé
    ↓
WhatsApp/Email: "Bonjour [Nom], merci d'avoir choisi OuiGlass..."
    + Lien avis Google
    ↓
Supabase: Update appointments.google_review_requested_at
```

**Message type** :
```
Bonjour Jean,

Merci d'avoir fait confiance à OuiGlass pour votre BMW Serie 3 !

Nous espérons que l'intervention s'est bien passée.
Si vous êtes satisfait, cela nous aiderait beaucoup si vous pouviez
laisser un avis sur Google : https://g.page/r/...

Merci et à bientôt !
L'équipe OuiGlass Suisse
```

**Workflow : Surveillance avis Google**

**Trigger** : Schedule (tous les jours 10h)

**Flow** :
```
Schedule Trigger
    ↓
Google My Business API: Récupérer nouveaux avis
    ↓
Loop: Pour chaque avis
    ↓
Switch: Note
    ├─> 4-5★ → LLM génère remerciement
    └─> 1-3★ → LLM génère réponse empathique + Notification propriétaire
    ↓
Google My Business API: Poster réponse automatique
```

**Complexité** : Moyenne
**Temps dev** : 2-3 jours

### Dashboard Métriques

**Option A : Supabase Dashboard (Simple)**

Créer vues SQL dans Supabase :

```sql
CREATE VIEW dashboard_kpis AS
SELECT
  (SELECT COUNT(*) FROM conversations WHERE created_at >= NOW() - INTERVAL '7 days') as leads_7j,
  (SELECT COUNT(*) FROM appointments WHERE created_at >= NOW() - INTERVAL '7 days') as rdv_7j,
  -- ... autres KPIs
```

Accès : Supabase > Table Editor > Views

**Option B : Dashboard Custom (Avancé)**

Stack : Next.js + Recharts + Supabase

**Pages** :
1. Vue d'ensemble (KPIs)
2. Conversations actives
3. RDV à venir
4. Performance (graphiques)
5. Avis Google

**Complexité** : Élevée
**Temps dev** : 1 semaine
**ROI** : Faible (sauf si équipe >5 personnes)

**Recommandation** : Utiliser Supabase Dashboard (gratuit, suffit pour Phase 3)

### Optimisation Planning Techniciens

**Objectif** : Minimiser km parcourus, maximiser RDV/jour

**Algorithme** :

```javascript
// Function Node N8N
function optimizeSchedule(appointments, newRequest) {
  const { zone, preferredDate } = newRequest;

  // 1. Trouver jours où il y a déjà des RDV dans cette zone
  const existingInZone = appointments.filter(a =>
    a.zone === zone &&
    a.scheduled_at.startsWith(preferredDate)
  );

  if (existingInZone.length > 0) {
    // Proposer créneaux le même jour (regroupement)
    return calculateSlotsSameDay(existingInZone);
  }

  // 2. Sinon, proposer jours fixes par zone
  const preferredDays = {
    'geneve': [1, 3, 5],    // Lun, Mer, Ven
    'lausanne': [2, 4],     // Mar, Jeu
    // ...
  };

  return calculateSlotsPreferredDays(zone, preferredDays[zone]);
}
```

**Bénéfice** :
- -30% km parcourus
- +2-3 RDV/jour/technicien

**Complexité** : Moyenne
**Temps dev** : 3-5 jours

### Fine-tuning Prompt LLM

**Méthode** :

1. **Collecter conversations réelles** (export Supabase)
2. **Analyser** :
   - Quelles questions posent problème ?
   - Où les clients abandonnent ?
   - Quelles objections reviennent ?
3. **Améliorer prompt** :
   - Ajouter exemples spécifiques
   - Clarifier instructions
   - Ajouter réponses aux objections fréquentes
4. **A/B tester** :
   - 50% ancien prompt
   - 50% nouveau prompt
   - Comparer taux conversion
5. **Déployer** le meilleur

**Outils** :
- Anthropic Console (Workbench) pour tester prompts
- Supabase Analytics pour metrics

**Complexité** : Moyenne
**Temps** : Itératif (1-2h/semaine pendant 1 mois)

**ROI** : Élevé (+5-10% taux conversion possible)

### Total Phase 3

**Durée** : 1 mois
**Effort** : 15-20 jours dev

**ROI attendu** :
- +10% efficacité techniciens (optimisation planning)
- +20 avis Google/mois (automatisation)
- +5-10% taux conversion (fine-tuning prompt)

---

## Roadmap Globale

```
Mois 1 : Phase 1 (MVP)
  ├─ Semaine 1-2 : Setup infrastructure
  ├─ Semaine 3 : Tests
  └─ Semaine 4 : Déploiement + monitoring

Mois 2 : Stabilisation Phase 1
  ├─ Semaine 1-2 : Monitoring intensif
  ├─ Semaine 3-4 : Collecte feedbacks + optimisations mineures
  └─ Analyse métriques

Mois 3-4 : Phase 2
  ├─ Semaine 1-2 : Workflows 5-7 (Emails, Confirmation J-1, Rebooking)
  ├─ Semaine 3-4 : WhatsApp Business + Relances
  └─ Tests + Déploiement

Mois 5-6 : Phase 3
  ├─ Semaine 1-3 : Intégration Otovia
  ├─ Semaine 4-5 : Avis Google + Optimisation planning
  ├─ Semaine 6-7 : Dashboard + Fine-tuning
  └─ Semaine 8 : Tests finaux + Documentation

Mois 7+ : Maintenance & Évolutions
  ├─ Monitoring continu
  ├─ Fine-tuning itératif
  └─ Nouvelles features selon feedbacks
```

---

## Budget Estimatif

### Coûts mensuels (après Phase 3 complète)

| Service | Plan | Coût |
|---------|------|------|
| **N8N** | Pro | $50/mois |
| **Supabase** | Pro | $25/mois |
| **Claude API** | Pay-as-you-go | $30-50/mois* |
| **Cloudinary** | Free → Plus | $0-10/mois |
| **WhatsApp Business** | Free (< 1000 msg/mois) | $0 |
| **Google Calendar** | Free | $0 |
| **Total** | | **$105-135/mois** |

*Estimation pour 500 conversations/mois

### ROI

**Coût agent IA** : ~$120/mois
**vs**
**Coût employé mi-temps** : ~$3,000/mois

**Économie** : ~$2,880/mois = **$34,560/an**

**Break-even** : Immédiat

---

## Métriques de Succès

### Phase 1 (Mois 1-2)

- [ ] Taux de conversion lead → RDV : 80%+
- [ ] Temps moyen réponse bot : < 3s
- [ ] Taux d'erreur : < 1%
- [ ] Satisfaction client : 4.5+/5

### Phase 2 (Mois 3-4)

- [ ] Taux confirmation J-1 : 95%+
- [ ] % emails traités automatiquement : 80%+
- [ ] Taux récupération RDV annulés : 30%+

### Phase 3 (Mois 5-6)

- [ ] Avis Google : +30/mois
- [ ] Note moyenne Google : 4.5+/5
- [ ] Optimisation planning : -20% km parcourus
- [ ] Taux conversion final : 85%+

---

## Risques & Mitigation

### Risques Phase 2

**Risque** : WhatsApp Business API refusée (vérification entreprise échouée)
**Mitigation** : Utiliser Twilio WhatsApp (alternatif payant)

**Risque** : Trop de relances → clients agacés
**Mitigation** : Limiter à 1 relance par lead, opt-out facile

### Risques Phase 3

**Risque** : API Otovia indisponible ou mal documentée
**Mitigation** : Garder Google Calendar en backup, migration progressive

**Risque** : Google My Business API complexe
**Mitigation** : Commencer par version manuelle (copier-coller réponses)

---

## Prochaines Étapes

Après Phase 3 stable, explorer :

### Phase 4 : Intelligence Avancée (6+ mois)

- **Prédiction annulations** : ML model pour prédire clients à risque
- **Recommandations proactives** : "Votre pare-brise a 5 ans, prévoir remplacement ?"
- **Multi-langue** : Support allemand, italien (Suisse)
- **Voice AI** : Répondre appels téléphoniques (Twilio + Speech-to-Text)
- **Mobile App** : App client iOS/Android

### Intégrations Futures

- **CRM Marketing** : Mailchimp, Sendinblue pour campagnes
- **Comptabilité** : Intégration directe factures (Bexio, etc.)
- **Fournisseurs** : API automatique commande pièces
- **Assurances** : API directe déclaration sinistre

---

## Conclusion

Le système OuiGlass Agent IA est conçu de manière **modulaire et évolutive**.

**Phase 1** : Valider concept (MVP)
**Phase 2** : Automatiser process complet
**Phase 3** : Optimiser et scaler

Chaque phase apporte ROI immédiat tout en préparant la suivante.

**Questions ?** Voir documentation complète dans `docs/`

---

**Bonne chance pour le déploiement ! 🚀**
