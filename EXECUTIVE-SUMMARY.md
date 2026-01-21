# 📊 Résumé Exécutif - OuiGlass Suisse MVP Phase 1

> Document pour décideurs, managers et non-techniques

---

## 🎯 Objectif du Projet

Créer un **agent conversationnel automatisé** pour OuiGlass Suisse qui collecte les informations essentielles des clients intéressés par un remplacement de vitrage automobile, via le site web.

---

## 📈 Périmètre Phase 1 (MVP Strict)

### Ce que fait l'agent ✅

1. **Conversation naturelle** : dialogue en français ou anglais avec les clients
2. **Collecte d'informations** : 6 données essentielles
   - Marque du véhicule (ex : Renault, Peugeot, BMW)
   - Modèle du véhicule (ex : Clio, 208, Série 3)
   - Année du véhicule (ex : 2018, 2020)
   - Type de vitre (pare-brise, vitre latérale, lunette arrière)
   - Ville en Suisse (ex : Genève, Lausanne, Zurich)
   - Nom complet du client
3. **Historique conversationnel** : l'agent se souvient des messages précédents
4. **Validation automatique** : refuse les demandes hors scope (RDV, assurance, photos)

### Ce que l'agent ne fait PAS ❌

- ❌ Prise de rendez-vous
- ❌ Gestion d'assurance
- ❌ Demande de photos
- ❌ Envoi d'emails ou SMS
- ❌ Intégration CRM (Otovia, Google Calendar, WhatsApp)

> **Pourquoi ces limitations ?** Ce MVP se concentre sur l'essentiel : **collecter les infos lead** de manière stable et fiable. Les fonctionnalités avancées seront ajoutées dans les phases suivantes, selon les besoins réels.

---

## 🏗️ Architecture Technique (Simplifié)

```
Client (site web)
    ↓
Webhook n8n (point d'entrée)
    ↓
Validation des données
    ↓
Base de données Supabase (historique)
    ↓
Intelligence Artificielle Claude (conversation)
    ↓
Réponse au client
```

### Technologies utilisées

- **n8n Cloud** : orchestration du workflow (gratuit)
- **Supabase** : stockage des conversations (gratuit)
- **Claude AI** : intelligence conversationnelle (payant, ~0.01€ par conversation)

### Coûts estimés

- **n8n Cloud** : 0€ (plan gratuit suffit)
- **Supabase** : 0€ (plan gratuit suffit pour < 10k conversations/mois)
- **Claude API** : ~1€ pour 100 conversations (~0.01€/conversation)

**Total estimé** : ~10-20€/mois pour 1000-2000 conversations

---

## 📊 Bénéfices Attendus

### 1. Disponibilité 24/7
L'agent répond **immédiatement**, même à 3h du matin ou le dimanche.

### 2. Qualification automatique des leads
Plus besoin de demander manuellement les infos basiques : l'agent les collecte pour vous.

### 3. Réduction de la charge de travail
Votre équipe reçoit des leads **pré-qualifiés** avec toutes les infos nécessaires.

### 4. Expérience client améliorée
Le client obtient une réponse instantanée au lieu d'attendre un email ou un rappel.

### 5. Data structurée
Toutes les conversations sont stockées et exploitables (statistiques, analyses).

---

## 🚀 Déploiement

### Timeline
- **Configuration Supabase** : 10 minutes
- **Configuration n8n** : 15 minutes
- **Tests** : 10 minutes
- **Total** : ~35 minutes

### Prérequis
- Compte Supabase (gratuit)
- Compte n8n Cloud (gratuit)
- Clé API Claude (~20€ de crédit pour commencer)

### Intégration sur le site web
Une fois le webhook déployé, l'intégration sur votre site nécessite :
- Ajout d'un widget de chat (ex : Chatbot UI, Typebot, ou custom)
- Configuration de l'URL webhook
- Génération automatique des `session_id` (ex : UUID)

---

## 📈 Métriques de Succès

### KPIs à suivre (Phase 1)

1. **Taux de complétion** : % de conversations où les 6 champs sont collectés
   - Objectif : > 70%
2. **Temps moyen de conversation** : durée moyenne d'une conversation complète
   - Objectif : < 3 minutes
3. **Nombre de leads qualifiés** : nombre de leads avec toutes les infos
   - Objectif : mesurable dès le premier jour
4. **Taux d'erreurs** : % de conversations avec erreurs techniques
   - Objectif : < 5%

---

## 🛣️ Roadmap

### Phase 1 : MVP (Actuel)
✅ Collecte d'infos basique
✅ Conversation multi-tours
✅ Historique stocké

### Phase 2 : Intégration CRM (Futur)
- Envoi automatique des leads dans Otovia
- Notification email aux conseillers
- Dashboard analytics

### Phase 3 : Prise de RDV (Futur)
- Intégration Google Calendar
- Propositions de créneaux
- Confirmation par email

### Phase 4 : Avancé (Futur)
- Upload et analyse de photos
- OCR plaque d'immatriculation
- Notifications WhatsApp
- Gestion d'assurance

---

## ⚠️ Risques et Limitations

### Risques identifiés

1. **Dépendance API Claude**
   - Risque : panne ou changement de prix
   - Mitigation : fallback sur OpenAI possible

2. **Quotas API**
   - Risque : dépassement du quota API
   - Mitigation : alertes configurables + fallback

3. **Qualité des réponses LLM**
   - Risque : l'IA ne suit pas toujours les instructions
   - Mitigation : fallback error dans le code

### Limitations Phase 1

- Pas de RDV (manuel pour l'instant)
- Pas d'assurance (à faire manuellement)
- Pas de photos (à demander manuellement)

---

## 💡 Recommandations

### Pour un succès optimal

1. **Testez régulièrement** : utilisez les scripts de tests fournis
2. **Surveillez les logs** : vérifiez les exécutions n8n et les données Supabase
3. **Collectez les feedbacks** : demandez l'avis des clients et de l'équipe
4. **Itérez** : améliorez le prompt système selon les retours

### Prochaines étapes après déploiement

1. **Semaine 1** : Tests intensifs + corrections
2. **Semaine 2-4** : Collecte de feedbacks clients
3. **Mois 2** : Analyse des métriques + décision Phase 2

---

## 📞 Contact et Support

### Documentation disponible

- **README.md** : documentation complète
- **INSTALLATION.md** : guide d'installation pas à pas
- **TROUBLESHOOTING.md** : résolution de problèmes
- **EXAMPLES.md** : exemples de conversations

### Support technique

Pour toute question, consulter d'abord :
1. TROUBLESHOOTING.md
2. Logs n8n (Executions)
3. Données Supabase (Table Editor)

---

## ✅ Validation du Déploiement

Le MVP est considéré comme **validé** si :

- ✅ Le webhook répond en < 3 secondes
- ✅ Les conversations sont stockées dans Supabase
- ✅ L'agent collecte les 6 champs correctement
- ✅ L'agent refuse les demandes hors scope
- ✅ Les tests 1 à 5 passent sans erreur

---

## 🎉 Conclusion

Ce MVP Phase 1 est un **point de départ solide** pour automatiser la qualification des leads OuiGlass Suisse. Il se concentre sur l'essentiel :

1. **Collecte d'infos fiable**
2. **Expérience client fluide**
3. **Coûts maîtrisés**

Les fonctionnalités avancées (RDV, assurance, photos) seront ajoutées **progressivement** dans les phases suivantes, en fonction des retours terrain et des besoins réels.

**Prêt à déployer ! 🚀**
