# 💬 OuiGlass Chat Widget - Documentation

## Vue d'ensemble

Widget de chat intelligent pour site web OuiGlass Suisse. Interface moderne, responsive, et totalement personnalisable.

**Caractéristiques** :
- ✅ Installation en 2 minutes (copier/coller)
- ✅ Responsive (desktop + mobile)
- ✅ Upload de photos intégré
- ✅ Personnalisable (couleurs, position, messages)
- ✅ Aucune dépendance externe
- ✅ Compatible tous navigateurs modernes
- ✅ Poids léger (~15 KB minifié)

---

## Installation rapide

### Étape 1 : Télécharger les fichiers

Copier ces 2 fichiers dans votre site web :
- `ouiglass-chat-widget.js`
- `ouiglass-chat-widget.css`

### Étape 2 : Intégrer dans votre HTML

Ajouter dans le `<head>` de votre site :

```html
<link rel="stylesheet" href="chemin/vers/ouiglass-chat-widget.css">
```

Ajouter avant la fermeture `</body>` :

```html
<script src="chemin/vers/ouiglass-chat-widget.js"></script>
<script>
  const chat = new OuiGlassChat({
    webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat'
  });
</script>
```

**IMPORTANT** : Remplacer `webhookUrl` par l'URL de votre webhook N8N (voir [SETUP-N8N.md](../docs/SETUP-N8N.md)).

### Étape 3 : Tester

Ouvrir votre site, le widget apparaît en bas à droite après 5 secondes. Cliquer pour démarrer une conversation !

---

## Configuration complète

### Options disponibles

```javascript
const chat = new OuiGlassChat({
  // OBLIGATOIRE
  webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat',

  // OPTIONNEL
  primaryColor: '#0066CC',              // Couleur principale
  position: 'bottom-right',             // Position: 'bottom-right' | 'bottom-left'
  showAfterSeconds: 5,                  // Afficher après X secondes (0 = immédiat)
  greetingMessage: '👋 ...',            // Message d'accueil personnalisé
  placeholderText: 'Tapez...',          // Placeholder du champ input
  autoOpen: false,                      // Ouvrir automatiquement (true/false)
  enableFileUpload: true,               // Activer upload photos (true/false)
  maxFileSize: 5 * 1024 * 1024,         // Taille max fichiers (bytes)
  allowedFileTypes: ['image/jpeg', ...], // Types de fichiers autorisés
  sessionStorageKey: 'ouiglass_chat_session' // Clé sessionStorage
});
```

### Exemples de personnalisation

#### Changer la couleur (brand)

```javascript
const chat = new OuiGlassChat({
  webhookUrl: '...',
  primaryColor: '#FF5733' // Orange
});
```

#### Position à gauche

```javascript
const chat = new OuiGlassChat({
  webhookUrl: '...',
  position: 'bottom-left'
});
```

#### Ouvrir automatiquement

```javascript
const chat = new OuiGlassChat({
  webhookUrl: '...',
  autoOpen: true,
  showAfterSeconds: 2
});
```

#### Désactiver upload photos

```javascript
const chat = new OuiGlassChat({
  webhookUrl: '...',
  enableFileUpload: false
});
```

#### Message d'accueil personnalisé

```javascript
const chat = new OuiGlassChat({
  webhookUrl: '...',
  greetingMessage: '🚗 Pare-brise cassé ? On intervient sous 24h !'
});
```

---

## Méthodes publiques

### Contrôler le chat par JavaScript

```javascript
// Ouvrir le chat
chat.openChat();

// Fermer le chat
chat.closeChat();

// Toggle (ouvrir/fermer)
chat.toggleChat();

// Vérifier si ouvert
console.log(chat.isOpen); // true ou false

// Ajouter un message manuellement
chat.addMessage('bot', 'Message du bot');
chat.addMessage('user', 'Message utilisateur');

// Afficher le badge notification
chat.showBadge();

// Cacher le badge
chat.hideBadge();
```

### Exemples d'utilisation

#### Bouton CTA personnalisé

```html
<button onclick="openChat()">Prendre RDV maintenant</button>

<script>
  function openChat() {
    chat.openChat();
  }
</script>
```

#### Pré-remplir un message (depuis URL)

```javascript
// URL: https://ouiglass.ch?message=Je%20veux%20un%20RDV

const urlParams = new URLSearchParams(window.location.search);
const prefilledMessage = urlParams.get('message');

if (prefilledMessage) {
  chat.openChat();
  setTimeout(() => {
    document.getElementById('ouiglass-chat-input').value = decodeURIComponent(prefilledMessage);
  }, 500);
}
```

---

## Tracking & Analytics

### Google Analytics

```javascript
// Tracker ouverture du chat
document.getElementById('ouiglass-chat-toggle').addEventListener('click', () => {
  if (!chat.isOpen && typeof gtag !== 'undefined') {
    gtag('event', 'chat_opened', {
      event_category: 'Chat',
      event_label: 'User opened chat'
    });
  }
});
```

### Meta Pixel (Facebook)

```javascript
// Tracker message envoyé
const originalSendMessage = chat.sendMessage;
chat.sendMessage = function() {
  originalSendMessage.call(this);

  if (typeof fbq !== 'undefined') {
    fbq('track', 'Contact', {
      content_category: 'Chat Message'
    });
  }
};
```

---

## Personnalisation avancée

### Modifier les styles CSS

Vous pouvez surcharger les styles en ajoutant votre propre CSS après le fichier widget :

```html
<link rel="stylesheet" href="ouiglass-chat-widget.css">
<style>
  /* Changer le bouton flottant en carré */
  .ouiglass-chat-button {
    border-radius: 12px !important;
  }

  /* Changer la police */
  .ouiglass-chat-widget {
    font-family: 'Helvetica Neue', Arial, sans-serif !important;
  }

  /* Changer la taille du widget */
  .ouiglass-chat-window {
    width: 450px !important;
    height: 700px !important;
  }
</style>
```

### Variables CSS

Le widget utilise des variables CSS pour faciliter la customisation :

```css
:root {
  --ouiglass-primary-color: #0066CC;
  --ouiglass-primary-dark: #0052A3;
  --ouiglass-text-color: #333333;
  --ouiglass-bg-light: #F5F5F5;
  --ouiglass-border-color: #E0E0E0;
  --ouiglass-radius: 12px;
}
```

### Ajouter des boutons personnalisés

Exemple : Ajouter bouton "Appeler" dans le header :

```javascript
// Après initialisation du widget
const header = document.querySelector('.ouiglass-chat-header-content');
const callButton = document.createElement('a');
callButton.href = 'tel:+41791234567';
callButton.innerHTML = '📞';
callButton.style.cssText = 'background: rgba(255,255,255,0.2); padding: 8px 12px; border-radius: 20px; text-decoration: none;';
header.appendChild(callButton);
```

---

## Upload de photos

### Fonctionnement

Le widget permet d'uploader des photos (format image uniquement, max 5 MB par défaut).

**Flow actuel (Phase 1)** :
1. Client clique sur bouton 📎
2. Sélectionne photo(s) depuis son appareil
3. Preview s'affiche dans le chat
4. Message "[Photo envoyée: nom.jpg]" ajouté à la conversation

**À implémenter (selon votre setup)** :
- Upload vers Cloudinary
- Upload vers S3
- Envoi URL à N8N

### Intégration Cloudinary

Exemple d'upload vers Cloudinary :

```javascript
// Modifier la méthode handleFileUpload dans ouiglass-chat-widget.js

async handleFileUpload(event) {
  const files = Array.from(event.target.files);

  for (const file of files) {
    // Validation (déjà fait)
    if (file.size > this.config.maxFileSize) { ... }

    // Upload vers Cloudinary
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', 'votre_upload_preset'); // À créer dans Cloudinary
    formData.append('cloud_name', 'votre_cloud_name');

    try {
      const response = await fetch(
        `https://api.cloudinary.com/v1_1/votre_cloud_name/image/upload`,
        {
          method: 'POST',
          body: formData
        }
      );

      const data = await response.json();
      const imageUrl = data.secure_url;

      // Envoyer URL à N8N
      this.addMessage('user', `[Photo envoyée: ${file.name}]`);

      await fetch(this.config.webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: this.sessionId,
          message: 'Photo envoyée',
          attachment: imageUrl
        })
      });

    } catch (error) {
      console.error('Upload error:', error);
      this.addMessage('bot', 'Erreur lors de l\'envoi de la photo. Réessayez.');
    }
  }
}
```

---

## Intégration CMS

### WordPress

1. Installer plugin "Insert Headers and Footers"
2. Ajouter dans Footer Scripts :

```html
<link rel="stylesheet" href="<?php echo get_template_directory_uri(); ?>/chatbot/ouiglass-chat-widget.css">
<script src="<?php echo get_template_directory_uri(); ?>/chatbot/ouiglass-chat-widget.js"></script>
<script>
  const chat = new OuiGlassChat({
    webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat'
  });
</script>
```

### Shopify

1. Theme > Edit code > Layout > theme.liquid
2. Avant `</body>` :

```html
{{ 'ouiglass-chat-widget.css' | asset_url | stylesheet_tag }}
<script src="{{ 'ouiglass-chat-widget.js' | asset_url }}"></script>
<script>
  const chat = new OuiGlassChat({
    webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat'
  });
</script>
```

### Wix

1. Settings > Custom Code
2. Add Custom Code > Footer :

```html
<link rel="stylesheet" href="https://votre-cdn.com/ouiglass-chat-widget.css">
<script src="https://votre-cdn.com/ouiglass-chat-widget.js"></script>
<script>
  const chat = new OuiGlassChat({
    webhookUrl: 'https://votre-instance.app.n8n.cloud/webhook/chat'
  });
</script>
```

**Note** : Pour Wix, héberger les fichiers sur un CDN (Cloudflare, jsDelivr, etc.)

---

## Performance

### Optimisations recommandées

1. **Minifier les fichiers**
   ```bash
   # Utiliser terser pour JS
   npx terser ouiglass-chat-widget.js -o ouiglass-chat-widget.min.js -c -m

   # Utiliser cssnano pour CSS
   npx cssnano ouiglass-chat-widget.css ouiglass-chat-widget.min.css
   ```

2. **Lazy loading**
   ```javascript
   // Charger le widget seulement quand l'utilisateur scrolle
   let widgetLoaded = false;

   window.addEventListener('scroll', () => {
     if (!widgetLoaded && window.scrollY > 300) {
       const script = document.createElement('script');
       script.src = 'ouiglass-chat-widget.js';
       script.onload = () => {
         new OuiGlassChat({ webhookUrl: '...' });
       };
       document.body.appendChild(script);
       widgetLoaded = true;
     }
   });
   ```

3. **CDN**
   - Héberger sur Cloudflare CDN pour latence minimale

### Poids des fichiers

- JS (non minifié) : ~10 KB
- CSS (non minifié) : ~5 KB
- **Total minifié + gzip** : ~5 KB

---

## Compatibilité navigateurs

| Navigateur | Version minimale |
|------------|------------------|
| Chrome | 60+ |
| Firefox | 55+ |
| Safari | 12+ |
| Edge | 79+ |
| Mobile Safari | iOS 12+ |
| Chrome Android | 60+ |

**Note** : Internet Explorer n'est PAS supporté (utilise Fetch API, CSS Grid, etc.)

---

## Accessibilité (WCAG)

Le widget respecte les standards d'accessibilité :
- ✅ Navigation clavier (Tab, Enter)
- ✅ ARIA labels sur boutons
- ✅ Contraste couleurs AAA
- ✅ Focus indicators
- ✅ Screen reader friendly

### Tests effectués
- VoiceOver (macOS/iOS)
- NVDA (Windows)
- axe DevTools (audit automatique)

---

## Sécurité

### Bonnes pratiques

1. **Validation côté serveur (N8N)** :
   - Toujours valider les inputs dans N8N
   - Sanitiser les messages avant stockage

2. **CSP (Content Security Policy)** :
   ```html
   <meta http-equiv="Content-Security-Policy"
     content="default-src 'self'; script-src 'self' 'unsafe-inline'; connect-src https://votre-instance.app.n8n.cloud;">
   ```

3. **Rate limiting** :
   - Configurer rate limit dans N8N (voir SETUP-N8N.md)

4. **Pas de données sensibles côté client** :
   - Ne jamais stocker tokens/secrets dans localStorage
   - Session ID uniquement (pas de données perso)

---

## Debugging

### Mode debug

Activer logs dans la console :

```javascript
const chat = new OuiGlassChat({
  webhookUrl: '...',
  debug: true // Ajouter cette option
});
```

Modifier dans `ouiglass-chat-widget.js` :

```javascript
// Ajouter en haut de la classe
constructor(config = {}) {
  this.config = { ...DEFAULT_CONFIG, ...config };
  this.debug = config.debug || false;

  if (this.debug) {
    console.log('[OuiGlass Chat] Config:', this.config);
  }
  ...
}

// Utiliser dans les méthodes
async sendMessage() {
  if (this.debug) console.log('[OuiGlass Chat] Sending message:', message);
  ...
}
```

### Problèmes courants

**Le widget n'apparaît pas**
→ Vérifier que les fichiers CSS et JS sont bien chargés (DevTools > Network)
→ Vérifier la console pour erreurs JavaScript

**Pas de réponse du bot**
→ Vérifier l'URL du webhook (doit être HTTPS, pas HTTP)
→ Vérifier que le workflow N8N est activé
→ Voir logs N8N > Executions

**Le chat ne s'ouvre pas**
→ Vérifier qu'il n'y a pas d'erreur JavaScript
→ Tester `chat.openChat()` dans la console

**Photos ne s'envoient pas**
→ Vérifier la taille (max 5 MB)
→ Vérifier le format (JPEG, PNG, WebP uniquement)

---

## FAQ

**Q : Puis-je utiliser sur plusieurs sites ?**
R : Oui, même webhook N8N. Le `session_id` permet de différencier.

**Q : Le chatbot fonctionne hors ligne ?**
R : Non, nécessite connexion internet (appels API).

**Q : Combien de conversations simultanées ?**
R : Illimité côté widget, limité par N8N (voir plan).

**Q : Puis-je customiser le logo ?**
R : Oui, remplacer le SVG de l'avatar dans le code HTML.

**Q : Compatible mode sombre ?**
R : Oui, détection automatique via `prefers-color-scheme`.

**Q : Données stockées côté client ?**
R : Seulement `session_id` dans sessionStorage (effacé à la fermeture de l'onglet).

---

## Support

- **Documentation** : [docs/](../docs/)
- **Issues** : [GitHub Issues](https://github.com/votre-repo/issues)
- **Email** : support@ouiglass.ch

---

## Changelog

### v1.0.0 (2025-01-17)
- ✨ Version initiale
- ✅ Chat fonctionnel avec N8N
- ✅ Upload photos
- ✅ Responsive mobile
- ✅ Personnalisation couleurs/position

---

**Prochaine étape** : [Tests et scénarios](../docs/TESTING.md)
