-- =====================================================
-- OuiGlass Suisse - MVP Phase 1
-- Schéma Supabase pour agent conversationnel
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Table: conversations
-- Stocke les sessions de conversation uniques
-- =====================================================
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- =====================================================
-- Table: messages
-- Stocke l'historique des messages (user + assistant)
-- =====================================================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

-- =====================================================
-- Index pour optimiser les requêtes
-- =====================================================
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_conversations_session_id ON conversations(session_id);

-- =====================================================
-- Fonction pour mettre à jour updated_at automatiquement
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour conversations
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE
    ON conversations FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Vérification de l'installation
-- =====================================================
-- Exécutez cette requête pour vérifier que tout fonctionne :
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- Vous devriez voir : conversations, messages
