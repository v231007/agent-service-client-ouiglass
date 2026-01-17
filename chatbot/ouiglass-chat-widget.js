/**
 * OuiGlass Chat Widget
 * Widget de chat intelligent pour site web OuiGlass Suisse
 *
 * @version 1.0.0
 * @author OuiGlass Suisse
 * @license MIT
 */

(function() {
  'use strict';

  // Configuration par défaut
  const DEFAULT_CONFIG = {
    webhookUrl: '', // URL du webhook N8N (OBLIGATOIRE)
    primaryColor: '#0066CC', // Couleur principale (bleu OuiGlass)
    position: 'bottom-right', // Position: 'bottom-right' | 'bottom-left'
    showAfterSeconds: 5, // Afficher après X secondes
    greetingMessage: '👋 Besoin d\'un remplacement de pare-brise ? Je peux vous donner un RDV en 2 minutes !',
    placeholderText: 'Tapez votre message...',
    autoOpen: false, // Ouvrir automatiquement au chargement
    enableFileUpload: true, // Activer upload photos
    maxFileSize: 5 * 1024 * 1024, // 5 MB max
    allowedFileTypes: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
    sessionStorageKey: 'ouiglass_chat_session'
  };

  class OuiGlassChat {
    constructor(config = {}) {
      this.config = { ...DEFAULT_CONFIG, ...config };
      this.sessionId = this.getOrCreateSession();
      this.messages = [];
      this.isOpen = false;
      this.isTyping = false;

      // Vérifier que webhook URL est fournie
      if (!this.config.webhookUrl) {
        console.error('[OuiGlass Chat] webhookUrl est obligatoire dans la configuration');
        return;
      }

      this.init();
    }

    /**
     * Initialisation du widget
     */
    init() {
      // Attendre que le DOM soit chargé
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => this.render());
      } else {
        this.render();
      }

      // Afficher après délai si configuré
      if (this.config.showAfterSeconds > 0 && !this.config.autoOpen) {
        setTimeout(() => {
          this.showWidget();
        }, this.config.showAfterSeconds * 1000);
      }
    }

    /**
     * Créer ou récupérer session ID
     */
    getOrCreateSession() {
      let sessionId = sessionStorage.getItem(this.config.sessionStorageKey);
      if (!sessionId) {
        sessionId = this.generateSessionId();
        sessionStorage.setItem(this.config.sessionStorageKey, sessionId);
      }
      return sessionId;
    }

    /**
     * Générer un session ID unique
     */
    generateSessionId() {
      return 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    /**
     * Render le widget dans le DOM
     */
    render() {
      // Créer container principal
      const container = document.createElement('div');
      container.id = 'ouiglass-chat-widget';
      container.className = 'ouiglass-chat-widget ouiglass-chat-closed';

      // HTML du widget
      container.innerHTML = `
        <!-- Bouton flottant -->
        <button class="ouiglass-chat-button" id="ouiglass-chat-toggle" aria-label="Ouvrir le chat">
          <svg class="ouiglass-chat-icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M21 11.5C21 16.75 16.75 21 11.5 21C6.25 21 2 16.75 2 11.5C2 6.25 6.25 2 11.5 2C16.75 2 21 6.25 21 11.5Z" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M8 10.5H8.01M12 10.5H12.01M16 10.5H16.01M8 14.5C8 14.5 9.5 16 12 16C14.5 16 16 14.5 16 14.5" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <svg class="ouiglass-close-icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M18 6L6 18M6 6L18 18" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <span class="ouiglass-chat-badge" id="ouiglass-notification-badge" style="display: none;">1</span>
        </button>

        <!-- Fenêtre de chat -->
        <div class="ouiglass-chat-window" id="ouiglass-chat-window">
          <!-- Header -->
          <div class="ouiglass-chat-header">
            <div class="ouiglass-chat-header-content">
              <div class="ouiglass-chat-avatar">
                <svg viewBox="0 0 24 24" fill="white" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/>
                </svg>
              </div>
              <div class="ouiglass-chat-header-text">
                <div class="ouiglass-chat-title">OuiGlass Suisse</div>
                <div class="ouiglass-chat-status">
                  <span class="ouiglass-status-dot"></span>
                  En ligne
                </div>
              </div>
            </div>
            <button class="ouiglass-chat-minimize" id="ouiglass-chat-minimize" aria-label="Réduire">
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M19 9L12 16L5 9" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
          </div>

          <!-- Messages -->
          <div class="ouiglass-chat-messages" id="ouiglass-chat-messages">
            <div class="ouiglass-message ouiglass-message-bot">
              <div class="ouiglass-message-content">
                ${this.config.greetingMessage}
              </div>
            </div>
          </div>

          <!-- Typing indicator -->
          <div class="ouiglass-typing-indicator" id="ouiglass-typing" style="display: none;">
            <div class="ouiglass-typing-dot"></div>
            <div class="ouiglass-typing-dot"></div>
            <div class="ouiglass-typing-dot"></div>
          </div>

          <!-- Input -->
          <div class="ouiglass-chat-input-wrapper">
            ${this.config.enableFileUpload ? `
            <button class="ouiglass-attach-button" id="ouiglass-attach-btn" aria-label="Joindre fichier">
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M21.44 11.05l-9.19 9.19a6 6 0 01-8.49-8.49l9.19-9.19a4 4 0 015.66 5.66l-9.2 9.19a2 2 0 01-2.83-2.83l8.49-8.48" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
            <input type="file" id="ouiglass-file-input" accept="image/*" style="display: none;" multiple>
            ` : ''}
            <input
              type="text"
              class="ouiglass-chat-input"
              id="ouiglass-chat-input"
              placeholder="${this.config.placeholderText}"
              autocomplete="off"
            >
            <button class="ouiglass-send-button" id="ouiglass-send-btn" aria-label="Envoyer">
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M22 2L11 13M22 2L15 22L11 13M22 2L2 9L11 13" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
          </div>

          <!-- Powered by -->
          <div class="ouiglass-chat-footer">
            Propulsé par IA Claude
          </div>
        </div>
      `;

      document.body.appendChild(container);

      // Appliquer styles personnalisés
      this.applyStyles();

      // Attacher event listeners
      this.attachEventListeners();

      // Auto-open si configuré
      if (this.config.autoOpen) {
        setTimeout(() => this.openChat(), 500);
      }
    }

    /**
     * Appliquer les styles personnalisés (couleur, position)
     */
    applyStyles() {
      const style = document.createElement('style');
      style.textContent = `
        .ouiglass-chat-widget {
          --ouiglass-primary-color: ${this.config.primaryColor};
          --ouiglass-primary-dark: ${this.darkenColor(this.config.primaryColor, 10)};
        }
        .ouiglass-chat-widget.ouiglass-position-bottom-left .ouiglass-chat-button {
          left: 20px;
          right: auto;
        }
        .ouiglass-chat-widget.ouiglass-position-bottom-left .ouiglass-chat-window {
          left: 20px;
          right: auto;
        }
      `;
      document.head.appendChild(style);

      // Ajouter classe position
      const widget = document.getElementById('ouiglass-chat-widget');
      if (this.config.position === 'bottom-left') {
        widget.classList.add('ouiglass-position-bottom-left');
      }
    }

    /**
     * Attacher tous les event listeners
     */
    attachEventListeners() {
      // Toggle chat
      const toggleBtn = document.getElementById('ouiglass-chat-toggle');
      toggleBtn.addEventListener('click', () => this.toggleChat());

      // Minimize chat
      const minimizeBtn = document.getElementById('ouiglass-chat-minimize');
      minimizeBtn.addEventListener('click', () => this.closeChat());

      // Send message
      const sendBtn = document.getElementById('ouiglass-send-btn');
      sendBtn.addEventListener('click', () => this.sendMessage());

      // Enter to send
      const input = document.getElementById('ouiglass-chat-input');
      input.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          this.sendMessage();
        }
      });

      // File upload
      if (this.config.enableFileUpload) {
        const attachBtn = document.getElementById('ouiglass-attach-btn');
        const fileInput = document.getElementById('ouiglass-file-input');

        attachBtn.addEventListener('click', () => fileInput.click());
        fileInput.addEventListener('change', (e) => this.handleFileUpload(e));
      }
    }

    /**
     * Toggle chat (ouvrir/fermer)
     */
    toggleChat() {
      if (this.isOpen) {
        this.closeChat();
      } else {
        this.openChat();
      }
    }

    /**
     * Ouvrir le chat
     */
    openChat() {
      const widget = document.getElementById('ouiglass-chat-widget');
      widget.classList.remove('ouiglass-chat-closed');
      widget.classList.add('ouiglass-chat-open');
      this.isOpen = true;

      // Focus sur input
      setTimeout(() => {
        const input = document.getElementById('ouiglass-chat-input');
        input.focus();
      }, 300);

      // Cacher badge notification
      this.hideBadge();
    }

    /**
     * Fermer le chat
     */
    closeChat() {
      const widget = document.getElementById('ouiglass-chat-widget');
      widget.classList.remove('ouiglass-chat-open');
      widget.classList.add('ouiglass-chat-closed');
      this.isOpen = false;
    }

    /**
     * Afficher le widget (animation d'entrée)
     */
    showWidget() {
      const widget = document.getElementById('ouiglass-chat-widget');
      widget.style.opacity = '0';
      widget.style.display = 'block';

      setTimeout(() => {
        widget.style.transition = 'opacity 0.3s ease';
        widget.style.opacity = '1';

        // Afficher badge notification
        this.showBadge();
      }, 100);
    }

    /**
     * Afficher badge notification
     */
    showBadge() {
      if (!this.isOpen) {
        const badge = document.getElementById('ouiglass-notification-badge');
        badge.style.display = 'block';
      }
    }

    /**
     * Cacher badge notification
     */
    hideBadge() {
      const badge = document.getElementById('ouiglass-notification-badge');
      badge.style.display = 'none';
    }

    /**
     * Envoyer un message
     */
    async sendMessage() {
      const input = document.getElementById('ouiglass-chat-input');
      const message = input.value.trim();

      if (!message) return;

      // Ajouter message utilisateur
      this.addMessage('user', message);

      // Clear input
      input.value = '';

      // Montrer typing indicator
      this.showTyping();

      try {
        // Appeler webhook N8N
        const response = await fetch(this.config.webhookUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            session_id: this.sessionId,
            message: message
          })
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Cacher typing indicator
        this.hideTyping();

        // Ajouter réponse bot
        this.addMessage('bot', data.message || 'Désolé, je n\'ai pas compris. Pouvez-vous reformuler ?');

        // Gérer actions spéciales si nécessaire
        if (data.action === 'choose_slot') {
          // Afficher sélecteur de créneaux
          this.displaySlotPicker(data.slots);
        }

      } catch (error) {
        console.error('[OuiGlass Chat] Erreur lors de l\'envoi:', error);
        this.hideTyping();
        this.addMessage('bot', 'Désolé, une erreur s\'est produite. Veuillez réessayer dans quelques instants.');
      }
    }

    /**
     * Ajouter un message au chat
     */
    addMessage(type, content) {
      const messagesContainer = document.getElementById('ouiglass-chat-messages');

      const messageDiv = document.createElement('div');
      messageDiv.className = `ouiglass-message ouiglass-message-${type}`;

      const contentDiv = document.createElement('div');
      contentDiv.className = 'ouiglass-message-content';
      contentDiv.textContent = content;

      messageDiv.appendChild(contentDiv);
      messagesContainer.appendChild(messageDiv);

      // Scroll vers le bas
      this.scrollToBottom();

      // Stocker dans historique
      this.messages.push({ type, content, timestamp: Date.now() });
    }

    /**
     * Afficher typing indicator
     */
    showTyping() {
      const typing = document.getElementById('ouiglass-typing');
      typing.style.display = 'flex';
      this.isTyping = true;
      this.scrollToBottom();
    }

    /**
     * Cacher typing indicator
     */
    hideTyping() {
      const typing = document.getElementById('ouiglass-typing');
      typing.style.display = 'none';
      this.isTyping = false;
    }

    /**
     * Scroll vers le bas des messages
     */
    scrollToBottom() {
      const messagesContainer = document.getElementById('ouiglass-chat-messages');
      setTimeout(() => {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
      }, 100);
    }

    /**
     * Gérer upload de fichiers
     */
    async handleFileUpload(event) {
      const files = Array.from(event.target.files);

      for (const file of files) {
        // Valider taille
        if (file.size > this.config.maxFileSize) {
          this.addMessage('bot', `Le fichier ${file.name} est trop volumineux (max 5 MB).`);
          continue;
        }

        // Valider type
        if (!this.config.allowedFileTypes.includes(file.type)) {
          this.addMessage('bot', `Le fichier ${file.name} n'est pas un format image valide.`);
          continue;
        }

        // Afficher preview
        this.showImagePreview(file);

        // Upload vers Cloudinary ou autre (à implémenter selon votre setup)
        // Pour l'instant, on affiche juste un message
        this.addMessage('user', `[Photo envoyée: ${file.name}]`);
        this.addMessage('bot', 'Merci pour la photo ! Je continue la collecte des informations...');
      }

      // Reset input
      event.target.value = '';
    }

    /**
     * Afficher preview d'image
     */
    showImagePreview(file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        const messagesContainer = document.getElementById('ouiglass-chat-messages');
        const imageDiv = document.createElement('div');
        imageDiv.className = 'ouiglass-message ouiglass-message-user';
        imageDiv.innerHTML = `
          <div class="ouiglass-message-content">
            <img src="${e.target.result}" alt="Photo envoyée" style="max-width: 200px; border-radius: 8px;">
          </div>
        `;
        messagesContainer.appendChild(imageDiv);
        this.scrollToBottom();
      };
      reader.readAsDataURL(file);
    }

    /**
     * Afficher sélecteur de créneaux
     */
    displaySlotPicker(slots) {
      const messagesContainer = document.getElementById('ouiglass-chat-messages');
      const slotsDiv = document.createElement('div');
      slotsDiv.className = 'ouiglass-message ouiglass-message-bot';

      let slotsHTML = '<div class="ouiglass-message-content"><div class="ouiglass-slots">';
      slots.forEach((slot, index) => {
        slotsHTML += `
          <button class="ouiglass-slot-button" data-slot="${slot.datetime}">
            ${slot.display}
          </button>
        `;
      });
      slotsHTML += '</div></div>';

      slotsDiv.innerHTML = slotsHTML;
      messagesContainer.appendChild(slotsDiv);

      // Attacher event listeners aux boutons
      slotsDiv.querySelectorAll('.ouiglass-slot-button').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const chosenSlot = e.target.dataset.slot;
          this.selectSlot(chosenSlot);
        });
      });

      this.scrollToBottom();
    }

    /**
     * Sélectionner un créneau
     */
    async selectSlot(slot) {
      // Envoyer choix au serveur
      const input = document.getElementById('ouiglass-chat-input');
      input.value = slot;
      await this.sendMessage();
    }

    /**
     * Utilitaire : Assombrir une couleur
     */
    darkenColor(color, percent) {
      const num = parseInt(color.replace('#', ''), 16);
      const amt = Math.round(2.55 * percent);
      const R = (num >> 16) - amt;
      const G = (num >> 8 & 0x00FF) - amt;
      const B = (num & 0x0000FF) - amt;
      return '#' + (
        0x1000000 +
        (R < 255 ? (R < 1 ? 0 : R) : 255) * 0x10000 +
        (G < 255 ? (G < 1 ? 0 : G) : 255) * 0x100 +
        (B < 255 ? (B < 1 ? 0 : B) : 255)
      ).toString(16).slice(1);
    }
  }

  // Exposer globalement
  window.OuiGlassChat = OuiGlassChat;

})();
