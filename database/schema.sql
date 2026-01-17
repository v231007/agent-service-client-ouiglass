-- ============================================================================
-- OUIGLASS SUISSE - SCHEMA BASE DE DONNÉES
-- ============================================================================
-- Base de données pour agent IA service client
-- PostgreSQL via Supabase
--
-- Tables:
--   1. conversations - Historique des conversations
--   2. messages - Messages individuels (user + assistant)
--   3. leads - Informations clients collectées
--   4. appointments - Rendez-vous confirmés
--
-- Auteur: OuiGlass Suisse
-- Date: 2025-01-17
-- ============================================================================

-- Enable UUID extension (required for uuid_generate_v4())
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE 1: conversations
-- ============================================================================
-- Stocke chaque conversation avec un client (peut contenir plusieurs messages)
-- Une conversation = une session de chat du début à la fin

CREATE TABLE IF NOT EXISTS conversations (
  -- Identifiant unique
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Source du lead (d'où vient le client)
  lead_source VARCHAR(50) NOT NULL CHECK (lead_source IN ('website', 'email', 'whatsapp', 'phone')),

  -- Informations de contact (flexibles car collectées progressivement)
  contact_info JSONB DEFAULT '{}'::jsonb,
  -- Exemple: {"phone": "+41791234567", "email": "client@example.com", "name": "Jean Dupont"}

  -- Statut de la conversation
  status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'rdv_confirmed', 'completed', 'abandoned', 'escalated')),

  -- Langue détectée (français par défaut en Suisse romande)
  language VARCHAR(5) DEFAULT 'fr' CHECK (language IN ('fr', 'en', 'de', 'it')),

  -- Métadonnées
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_conversations_lead_source ON conversations(lead_source);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE 2: messages
-- ============================================================================
-- Stocke chaque message individuel dans une conversation (user ou assistant)

CREATE TABLE IF NOT EXISTS messages (
  -- Identifiant unique
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Référence vers la conversation parent
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,

  -- Rôle (qui a envoyé le message)
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),

  -- Contenu du message
  content TEXT NOT NULL,

  -- Pièces jointes (URLs de photos vitrages, etc.)
  attachments JSONB DEFAULT '[]'::jsonb,
  -- Exemple: [{"type": "image", "url": "https://cloudinary.com/...", "description": "Pare-brise fissuré"}]

  -- Métadonnées (infos collectées dans ce message si format JSON)
  metadata JSONB DEFAULT '{}'::jsonb,
  -- Exemple: {"infos_collectees": {"vehicle_make": "BMW"}, "completion": 25}

  -- Date de création
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_role ON messages(role);

-- ============================================================================
-- TABLE 3: leads
-- ============================================================================
-- Stocke TOUTES les informations collectées sur un lead/client
-- C'est la table la plus importante avec toutes les données pour l'assurance

CREATE TABLE IF NOT EXISTS leads (
  -- Identifiant unique
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Référence vers la conversation d'origine
  conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,

  -- ====================================
  -- INFORMATIONS CLIENT
  -- ====================================
  full_name VARCHAR(255),
  phone VARCHAR(50),
  email VARCHAR(255),

  -- Adresse d'intervention
  address TEXT,
  city VARCHAR(100),
  canton VARCHAR(50) CHECK (canton IN (
    'Genève', 'Vaud', 'Valais', 'Fribourg', 'Neuchâtel', 'Jura',
    'Berne', 'Zürich', 'Autre'
  )),
  postal_code VARCHAR(10),

  -- ====================================
  -- INFORMATIONS VÉHICULE
  -- ====================================
  vehicle_make VARCHAR(100),
  vehicle_model VARCHAR(100),
  vehicle_year INTEGER CHECK (vehicle_year >= 1980 AND vehicle_year <= 2030),
  vin VARCHAR(17) UNIQUE,  -- Vehicle Identification Number (17 caractères)

  -- ====================================
  -- INFORMATIONS VITRAGE
  -- ====================================
  glass_type VARCHAR(50) CHECK (glass_type IN (
    'pare-brise',
    'vitre-laterale-avant-gauche',
    'vitre-laterale-avant-droite',
    'vitre-laterale-arriere-gauche',
    'vitre-laterale-arriere-droite',
    'lunette-arriere',
    'custode'
  )),

  -- Présence de caméra/capteur ADAS (Advanced Driver Assistance Systems)
  has_adas BOOLEAN DEFAULT false,

  -- URLs des photos du vitrage endommagé (Cloudinary)
  photos JSONB DEFAULT '[]'::jsonb,
  -- Exemple: ["https://res.cloudinary.com/...", "https://res.cloudinary.com/..."]

  -- ====================================
  -- INFORMATIONS ASSURANCE
  -- ====================================
  insurance_company VARCHAR(100) CHECK (insurance_company IN (
    'Allianz', 'AutoMate', 'AXA', 'Baloise', 'Elvia', 'Emmental',
    'Generali', 'Helvetia', 'Mobilière', 'Postfinance', 'Simpego',
    'Smile.direct', 'TCS', 'Vaudoise', 'Wefox', 'Zurich', 'Autre'
  )),
  claim_number VARCHAR(100),      -- Numéro de sinistre
  policy_number VARCHAR(100),     -- Numéro de police d'assurance

  -- ====================================
  -- PRÉFÉRENCES RENDEZ-VOUS
  -- ====================================
  preferred_date DATE,
  preferred_time TIME,
  preferred_location VARCHAR(100) CHECK (preferred_location IN ('domicile', 'travail', 'autre')),

  -- ====================================
  -- MÉTADONNÉES & SCORING
  -- ====================================
  -- Score de qualité du lead (0-100)
  conversion_score INTEGER DEFAULT 0 CHECK (conversion_score >= 0 AND conversion_score <= 100),

  -- Statut du lead
  status VARCHAR(50) DEFAULT 'new' CHECK (status IN (
    'new',                 -- Nouveau lead
    'collecting_info',     -- En cours de collecte d'infos
    'info_complete',       -- Infos complètes
    'rdv_proposed',        -- Créneaux proposés
    'rdv_confirmed',       -- RDV confirmé
    'rdv_completed',       -- Intervention terminée
    'lost'                 -- Lead perdu
  )),

  -- Notes internes (pour escalade humain, etc.)
  internal_notes TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone);
CREATE INDEX IF NOT EXISTS idx_leads_vin ON leads(vin);
CREATE INDEX IF NOT EXISTS idx_leads_canton ON leads(canton);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_leads_updated_at
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE 4: appointments
-- ============================================================================
-- Stocke les rendez-vous confirmés avec planning

CREATE TABLE IF NOT EXISTS appointments (
  -- Identifiant unique
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Référence vers le lead
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,

  -- ID dans système externe (Otovia) quand intégré
  external_id VARCHAR(100),  -- Null en Phase 1 (Google Calendar seulement)

  -- ====================================
  -- PLANNING
  -- ====================================
  scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,  -- Date et heure du RDV

  -- Durée estimée en minutes
  duration_minutes INTEGER DEFAULT 90 CHECK (duration_minutes > 0),

  -- Zone géographique (pour optimisation planning)
  zone VARCHAR(50) CHECK (zone IN (
    'geneve',      -- Genève, Nyon
    'lausanne',    -- Lausanne, Morges, Yverdon
    'riviera',     -- Montreux, Vevey
    'fribourg',    -- Fribourg
    'neuchatel',   -- Neuchâtel, La Chaux-de-Fonds
    'valais',      -- Sion, Martigny, Monthey
    'jura'         -- Delémont
  )),

  -- ====================================
  -- STATUT & CONFIRMATIONS
  -- ====================================
  status VARCHAR(50) DEFAULT 'scheduled' CHECK (status IN (
    'scheduled',      -- RDV planifié
    'confirmed',      -- Client a confirmé
    'in_progress',    -- Intervention en cours
    'completed',      -- Intervention terminée
    'cancelled',      -- Annulé par client
    'no_show'         -- Client absent
  )),

  -- Dates des différentes étapes
  confirmation_sent_at TIMESTAMP WITH TIME ZONE,    -- Quand rappel J-1 envoyé
  confirmed_at TIMESTAMP WITH TIME ZONE,            -- Quand client a confirmé
  completed_at TIMESTAMP WITH TIME ZONE,            -- Quand intervention terminée

  -- ====================================
  -- SUIVI AVIS GOOGLE
  -- ====================================
  google_review_requested_at TIMESTAMP WITH TIME ZONE,  -- Quand demande d'avis envoyée
  google_review_received BOOLEAN DEFAULT false,
  google_review_rating INTEGER CHECK (google_review_rating >= 1 AND google_review_rating <= 5),

  -- ====================================
  -- MÉTADONNÉES
  -- ====================================
  -- Notes pour le technicien
  technician_notes TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_appointments_lead_id ON appointments(lead_id);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_zone ON appointments(zone);
CREATE INDEX IF NOT EXISTS idx_appointments_external_id ON appointments(external_id);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VUES UTILES
-- ============================================================================

-- Vue: Conversations actives avec dernier message
CREATE OR REPLACE VIEW active_conversations AS
SELECT
  c.id,
  c.lead_source,
  c.contact_info,
  c.status,
  c.language,
  c.created_at,
  c.updated_at,
  (
    SELECT content
    FROM messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) as last_message,
  (
    SELECT created_at
    FROM messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) as last_message_at
FROM conversations c
WHERE c.status = 'active'
ORDER BY c.updated_at DESC;

-- Vue: Leads avec infos complètes prêts pour RDV
CREATE OR REPLACE VIEW leads_ready_for_appointment AS
SELECT
  l.*,
  c.lead_source,
  c.language
FROM leads l
JOIN conversations c ON l.conversation_id = c.id
WHERE l.status = 'info_complete'
  AND l.full_name IS NOT NULL
  AND l.phone IS NOT NULL
  AND l.email IS NOT NULL
  AND l.address IS NOT NULL
  AND l.vehicle_make IS NOT NULL
  AND l.vehicle_model IS NOT NULL
  AND l.vin IS NOT NULL
  AND l.glass_type IS NOT NULL
  AND l.insurance_company IS NOT NULL
  AND l.claim_number IS NOT NULL
  AND l.policy_number IS NOT NULL
  AND l.photos IS NOT NULL
  AND jsonb_array_length(l.photos) > 0;

-- Vue: RDV à confirmer (J-1)
CREATE OR REPLACE VIEW appointments_to_confirm AS
SELECT
  a.*,
  l.full_name,
  l.phone,
  l.email,
  l.vehicle_make,
  l.vehicle_model
FROM appointments a
JOIN leads l ON a.lead_id = l.id
WHERE a.status = 'scheduled'
  AND a.scheduled_at BETWEEN NOW() + INTERVAL '20 hours' AND NOW() + INTERVAL '28 hours'
  AND a.confirmation_sent_at IS NULL;

-- Vue: Statistiques journalières
CREATE OR REPLACE VIEW daily_stats AS
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_leads,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv_confirmed,
  COUNT(CASE WHEN status = 'lost' THEN 1 END) as lost,
  ROUND(
    COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0),
    2
  ) as conversion_rate,
  COUNT(CASE WHEN lead_source = 'website' THEN 1 END) as from_website,
  COUNT(CASE WHEN lead_source = 'email' THEN 1 END) as from_email,
  COUNT(CASE WHEN lead_source = 'whatsapp' THEN 1 END) as from_whatsapp
FROM conversations
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ============================================================================
-- FONCTIONS UTILES
-- ============================================================================

-- Fonction: Nettoyer les conversations abandonnées (> 90 jours)
CREATE OR REPLACE FUNCTION cleanup_abandoned_conversations()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Marquer comme 'abandoned' si pas d'activité depuis 7 jours
  UPDATE conversations
  SET status = 'abandoned'
  WHERE status = 'active'
    AND updated_at < NOW() - INTERVAL '7 days';

  -- Supprimer si abandonné depuis > 90 jours
  WITH deleted AS (
    DELETE FROM conversations
    WHERE status = 'abandoned'
      AND updated_at < NOW() - INTERVAL '90 days'
    RETURNING *
  )
  SELECT COUNT(*) INTO deleted_count FROM deleted;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Fonction: Calculer score de completion d'un lead
CREATE OR REPLACE FUNCTION calculate_lead_completion(lead_id UUID)
RETURNS INTEGER AS $$
DECLARE
  completion_score INTEGER := 0;
  lead_record RECORD;
BEGIN
  SELECT * INTO lead_record FROM leads WHERE id = lead_id;

  IF lead_record.full_name IS NOT NULL THEN completion_score := completion_score + 8; END IF;
  IF lead_record.phone IS NOT NULL THEN completion_score := completion_score + 8; END IF;
  IF lead_record.email IS NOT NULL THEN completion_score := completion_score + 8; END IF;
  IF lead_record.address IS NOT NULL THEN completion_score := completion_score + 8; END IF;
  IF lead_record.city IS NOT NULL THEN completion_score := completion_score + 4; END IF;
  IF lead_record.canton IS NOT NULL THEN completion_score := completion_score + 4; END IF;
  IF lead_record.postal_code IS NOT NULL THEN completion_score := completion_score + 4; END IF;

  IF lead_record.vehicle_make IS NOT NULL THEN completion_score := completion_score + 6; END IF;
  IF lead_record.vehicle_model IS NOT NULL THEN completion_score := completion_score + 6; END IF;
  IF lead_record.vehicle_year IS NOT NULL THEN completion_score := completion_score + 6; END IF;
  IF lead_record.vin IS NOT NULL THEN completion_score := completion_score + 8; END IF;

  IF lead_record.glass_type IS NOT NULL THEN completion_score := completion_score + 6; END IF;
  IF lead_record.has_adas IS NOT NULL THEN completion_score := completion_score + 4; END IF;
  IF lead_record.photos IS NOT NULL AND jsonb_array_length(lead_record.photos) > 0 THEN
    completion_score := completion_score + 8;
  END IF;

  IF lead_record.insurance_company IS NOT NULL THEN completion_score := completion_score + 6; END IF;
  IF lead_record.claim_number IS NOT NULL THEN completion_score := completion_score + 6; END IF;
  IF lead_record.policy_number IS NOT NULL THEN completion_score := completion_score + 6; END IF;

  RETURN completion_score;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - À activer en production
-- ============================================================================
-- Pour l'instant désactivé pour faciliter le développement
-- À activer quand vous passez en production

-- ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY "Service role full access" ON conversations
--   FOR ALL
--   USING (auth.role() = 'service_role');

-- ============================================================================
-- DONNÉES DE TEST (optionnel - pour développement)
-- ============================================================================
-- Décommenter pour insérer des données de test

/*
-- Conversation test 1
INSERT INTO conversations (id, lead_source, contact_info, status, language) VALUES
  ('11111111-1111-1111-1111-111111111111', 'website', '{"name": "Jean Dupont", "phone": "+41791234567"}', 'active', 'fr');

-- Messages test conversation 1
INSERT INTO messages (conversation_id, role, content) VALUES
  ('11111111-1111-1111-1111-111111111111', 'user', 'Bonjour, j''ai mon pare-brise fissuré'),
  ('11111111-1111-1111-1111-111111111111', 'assistant', 'Bonjour Jean ! Je suis désolé pour votre pare-brise. C''est pour quel véhicule ? (marque et modèle)'),
  ('11111111-1111-1111-1111-111111111111', 'user', 'Une BMW Serie 3 de 2020');

-- Lead test 1
INSERT INTO leads (conversation_id, full_name, phone, email, vehicle_make, vehicle_model, vehicle_year, status) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Jean Dupont', '+41791234567', 'jean.dupont@example.com', 'BMW', 'Serie 3', 2020, 'collecting_info');
*/

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================

-- Vérification: Afficher toutes les tables créées
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Vérification: Afficher toutes les vues créées
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;
