# 💬 Exemples de Conversations - OuiGlass Suisse MVP

Ce fichier présente des exemples de conversations attendues pour valider le comportement du chatbot.

---

## 📝 Exemple 1 : Conversation complète en français

### Message 1 : Premier contact
**User** : `Bonjour`

**Assistant** :
```json
{
  "reply": "Bonjour ! 👋 Je suis là pour t'aider avec ton vitrage auto. Pour commencer, quelle est la marque de ton véhicule ?"
}
```

**État lead** :
```json
{
  "vehicle_make": null,
  "vehicle_model": null,
  "vehicle_year": null,
  "glass_type": null,
  "city": null,
  "full_name": null
}
```

---

### Message 2 : Marque du véhicule
**User** : `Renault`

**Assistant** :
```json
{
  "reply": "Parfait ! Quel est le modèle de ta Renault ?"
}
```

**État lead** :
```json
{
  "vehicle_make": "Renault",
  "vehicle_model": null,
  "vehicle_year": null,
  "glass_type": null,
  "city": null,
  "full_name": null
}
```

---

### Message 3 : Modèle du véhicule
**User** : `Clio`

**Assistant** :
```json
{
  "reply": "Super ! De quelle année est ta Renault Clio ?"
}
```

**État lead** :
```json
{
  "vehicle_make": "Renault",
  "vehicle_model": "Clio",
  "vehicle_year": null,
  "glass_type": null,
  "city": null,
  "full_name": null
}
```

---

### Message 4 : Année du véhicule
**User** : `2018`

**Assistant** :
```json
{
  "reply": "Merci ! Quel type de vitre as-tu besoin de remplacer ? (pare-brise, vitre latérale, lunette arrière)"
}
```

**État lead** :
```json
{
  "vehicle_make": "Renault",
  "vehicle_model": "Clio",
  "vehicle_year": "2018",
  "glass_type": null,
  "city": null,
  "full_name": null
}
```

---

### Message 5 : Type de vitre
**User** : `pare-brise`

**Assistant** :
```json
{
  "reply": "D'accord ! Dans quelle ville es-tu situé ?"
}
```

**État lead** :
```json
{
  "vehicle_make": "Renault",
  "vehicle_model": "Clio",
  "vehicle_year": "2018",
  "glass_type": "pare-brise",
  "city": null,
  "full_name": null
}
```

---

### Message 6 : Ville
**User** : `Genève`

**Assistant** :
```json
{
  "reply": "Excellent ! Pour finir, peux-tu me donner ton nom complet ?"
}
```

**État lead** :
```json
{
  "vehicle_make": "Renault",
  "vehicle_model": "Clio",
  "vehicle_year": "2018",
  "glass_type": "pare-brise",
  "city": "Genève",
  "full_name": null
}
```

---

### Message 7 : Nom complet
**User** : `Jean Dupont`

**Assistant** :
```json
{
  "reply": "Merci Jean ! 🎉 J'ai toutes les informations. Un conseiller OuiGlass va te contacter très prochainement pour finaliser ton remplacement de pare-brise."
}
```

**État lead (COMPLET)** :
```json
{
  "vehicle_make": "Renault",
  "vehicle_model": "Clio",
  "vehicle_year": "2018",
  "glass_type": "pare-brise",
  "city": "Genève",
  "full_name": "Jean Dupont"
}
```

---

## 📝 Exemple 2 : Conversation en anglais

### Message 1
**User** : `Hello, I need help with my car windshield`

**Assistant** :
```json
{
  "reply": "Hello! 👋 I'm here to help you with your car glass. What's the make of your vehicle?"
}
```

---

### Message 2
**User** : `BMW`

**Assistant** :
```json
{
  "reply": "Great! What model is your BMW?"
}
```

---

### Message 3
**User** : `Series 3`

**Assistant** :
```json
{
  "reply": "Perfect! What year is your BMW Series 3?"
}
```

---

## 📝 Exemple 3 : Utilisateur donne plusieurs infos à la fois

### Message 1
**User** : `Bonjour, j'ai une Peugeot 208 de 2020 et j'ai besoin de changer mon pare-brise`

**Assistant** :
```json
{
  "reply": "Bonjour ! J'ai bien noté : Peugeot 208 de 2020, pare-brise à remplacer. Dans quelle ville es-tu situé ?"
}
```

**État lead** :
```json
{
  "vehicle_make": "Peugeot",
  "vehicle_model": "208",
  "vehicle_year": "2020",
  "glass_type": "pare-brise",
  "city": null,
  "full_name": null
}
```

> ✅ Le chatbot doit être capable d'extraire plusieurs informations d'un seul message et sauter les questions déjà répondues.

---

## 📝 Exemple 4 : Utilisateur dévie du sujet

### Message 1
**User** : `Bonjour`

**Assistant** : (demande la marque du véhicule)

---

### Message 2
**User** : `Est-ce que vous faites aussi les assurances ?`

**Assistant** :
```json
{
  "reply": "Je ne gère pas les assurances, je suis là uniquement pour collecter tes infos de vitrage. 😊 Pour commencer, quelle est la marque de ton véhicule ?"
}
```

> ✅ Le chatbot doit refuser poliment les sujets hors scope et recentrer sur la collecte d'infos.

---

## 📝 Exemple 5 : Utilisateur demande un RDV

### Message quelconque
**User** : `Pouvez-vous me donner un rendez-vous demain à 14h ?`

**Assistant** :
```json
{
  "reply": "Je ne peux pas prendre de RDV pour l'instant. Mon rôle est de collecter tes infos, puis un conseiller te contactera. 😊 Continuons : quelle est la marque de ton véhicule ?"
}
```

> ✅ Le chatbot doit refuser les RDV et recentrer sur la collecte.

---

## 📝 Exemple 6 : Utilisateur envoie un message vide ou invalide

### Test avec message vide
**Request** :
```json
{
  "session_id": "test-001",
  "message": ""
}
```

**Response** : Erreur HTTP 400 ou 500
```
"message manquant ou invalide"
```

---

### Test avec session_id manquant
**Request** :
```json
{
  "message": "Bonjour"
}
```

**Response** : Erreur HTTP 400 ou 500
```
"session_id manquant ou invalide"
```

---

## 🧪 Comment utiliser ces exemples

1. **Test manuel** : Envoyez ces messages un par un avec curl/PowerShell
2. **Validation** : Vérifiez que les réponses correspondent aux exemples ci-dessus
3. **Base de données** : Vérifiez dans Supabase que les messages sont bien stockés
4. **État du lead** : Le LLM doit remplir progressivement les champs `lead.*`

---

## ✅ Critères de validation

Le chatbot est validé si :

- ✅ Il répond en JSON valide
- ✅ Il pose 1 question à la fois
- ✅ Il collecte les 6 champs dans l'ordre
- ✅ Il ne redemande jamais un champ déjà collecté
- ✅ Il refuse poliment les sujets hors scope (RDV, assurance, photos)
- ✅ Il s'adapte à la langue du client (français/anglais)
- ✅ Il valide les inputs (session_id + message obligatoires)
- ✅ Il gère les erreurs JSON avec un fallback

---

## 🎯 OBJECTIF FINAL

À la fin d'une conversation complète, vous devriez avoir dans Supabase :

**Table `conversations`** :
| id | session_id | created_at | updated_at |
|----|------------|------------|------------|
| uuid-1 | test-session-001 | 2026-01-21 10:00:00 | 2026-01-21 10:05:00 |

**Table `messages`** :
| id | conversation_id | role | content | created_at |
|----|-----------------|------|---------|------------|
| uuid-1 | uuid-1 | user | Bonjour | 2026-01-21 10:00:00 |
| uuid-2 | uuid-1 | assistant | Bonjour ! 👋 Je suis là... | 2026-01-21 10:00:01 |
| uuid-3 | uuid-1 | user | Renault | 2026-01-21 10:00:30 |
| uuid-4 | uuid-1 | assistant | Parfait ! Quel est le modèle... | 2026-01-21 10:00:31 |
| ... | ... | ... | ... | ... |

Et le dernier message assistant devrait contenir les 6 champs lead complets.
