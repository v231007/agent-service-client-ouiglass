-- =====================================================
-- OuiGlass Suisse - MVP Phase 1
-- VERSION ADAPTÉE POUR n8n Cloud v2.3.6
-- Fonction PostgreSQL pour get_or_create_conversation
-- =====================================================

-- Cette fonction remplace l'opération UPSERT manquante dans n8n 2.3.6

CREATE OR REPLACE FUNCTION get_or_create_conversation(p_session_id TEXT)
RETURNS TABLE(id UUID, session_id TEXT, created_at TIMESTAMP, updated_at TIMESTAMP) AS $$
BEGIN
  -- Essaie d'insérer la conversation
  INSERT INTO conversations (session_id)
  VALUES (p_session_id)
  ON CONFLICT (session_id) DO UPDATE SET updated_at = now()
  RETURNING conversations.id, conversations.session_id, conversations.created_at, conversations.updated_at
  INTO id, session_id, created_at, updated_at;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Test de la fonction
-- =====================================================
-- SELECT * FROM get_or_create_conversation('test-session-001');
