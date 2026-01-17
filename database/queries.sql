-- ============================================================================
-- REQUÊTES UTILES - OUIGLASS SUISSE
-- ============================================================================
-- Collection de requêtes SQL utiles pour gérer et analyser les données
-- À exécuter dans Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. STATISTIQUES GLOBALES
-- ============================================================================

-- Vue d'ensemble des performances (derniers 7 jours)
SELECT
  COUNT(DISTINCT c.id) as total_conversations,
  COUNT(DISTINCT l.id) as total_leads,
  COUNT(DISTINCT a.id) as total_rdv,
  ROUND(
    COUNT(DISTINCT a.id) * 100.0 / NULLIF(COUNT(DISTINCT c.id), 0),
    2
  ) as taux_conversion_pct
FROM conversations c
LEFT JOIN leads l ON c.id = l.conversation_id
LEFT JOIN appointments a ON l.id = a.lead_id
WHERE c.created_at >= NOW() - INTERVAL '7 days';

-- Statistiques par source de lead
SELECT
  lead_source,
  COUNT(*) as nombre,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv_confirmes,
  ROUND(
    COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) * 100.0 / COUNT(*),
    2
  ) as taux_conversion_pct
FROM conversations
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY lead_source
ORDER BY nombre DESC;

-- Statistiques par zone géographique
SELECT
  canton,
  COUNT(*) as nombre_leads,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv_confirmes
FROM leads
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY canton
ORDER BY nombre_leads DESC;

-- Compagnies d'assurance les plus fréquentes
SELECT
  insurance_company,
  COUNT(*) as nombre
FROM leads
WHERE insurance_company IS NOT NULL
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY insurance_company
ORDER BY nombre DESC;

-- ============================================================================
-- 2. MONITORING EN TEMPS RÉEL
-- ============================================================================

-- Conversations actives en ce moment
SELECT
  c.id,
  c.lead_source,
  c.contact_info->>'name' as nom_client,
  c.created_at,
  c.updated_at,
  (
    SELECT COUNT(*)
    FROM messages
    WHERE conversation_id = c.id
  ) as nombre_messages,
  (
    SELECT content
    FROM messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) as dernier_message
FROM conversations c
WHERE c.status = 'active'
  AND c.updated_at >= NOW() - INTERVAL '2 hours'
ORDER BY c.updated_at DESC;

-- Leads avec infos incomplètes (besoin d'attention)
SELECT
  l.id,
  l.full_name,
  l.phone,
  l.status,
  calculate_lead_completion(l.id) as completion_pct,
  CASE
    WHEN l.full_name IS NULL THEN 'Nom manquant'
    WHEN l.phone IS NULL THEN 'Téléphone manquant'
    WHEN l.email IS NULL THEN 'Email manquant'
    WHEN l.vin IS NULL THEN 'VIN manquant'
    WHEN l.photos IS NULL OR jsonb_array_length(l.photos) = 0 THEN 'Photos manquantes'
    WHEN l.insurance_company IS NULL THEN 'Assurance manquante'
    ELSE 'Autre'
  END as info_manquante,
  l.updated_at
FROM leads l
WHERE l.status IN ('new', 'collecting_info')
  AND calculate_lead_completion(l.id) < 100
ORDER BY l.updated_at DESC;

-- RDV à confirmer aujourd'hui ou demain
SELECT
  a.id,
  a.scheduled_at,
  a.zone,
  l.full_name,
  l.phone,
  l.vehicle_make || ' ' || l.vehicle_model as vehicule,
  a.status,
  a.confirmation_sent_at
FROM appointments a
JOIN leads l ON a.lead_id = l.id
WHERE a.scheduled_at BETWEEN NOW() AND NOW() + INTERVAL '48 hours'
  AND a.status IN ('scheduled', 'confirmed')
ORDER BY a.scheduled_at;

-- ============================================================================
-- 3. ANALYSE DE PERFORMANCE
-- ============================================================================

-- Temps moyen de conversion (lead → RDV confirmé)
SELECT
  AVG(EXTRACT(EPOCH FROM (a.created_at - c.created_at)) / 3600) as heures_moyennes
FROM appointments a
JOIN leads l ON a.lead_id = l.id
JOIN conversations c ON l.conversation_id = c.id
WHERE a.created_at >= NOW() - INTERVAL '30 days'
  AND a.status != 'cancelled';

-- Taux de confirmation J-1 (% de clients qui confirment leur RDV)
SELECT
  COUNT(*) as total_rdv,
  COUNT(CASE WHEN confirmed_at IS NOT NULL THEN 1 END) as confirmes,
  ROUND(
    COUNT(CASE WHEN confirmed_at IS NOT NULL THEN 1 END) * 100.0 / COUNT(*),
    2
  ) as taux_confirmation_pct
FROM appointments
WHERE confirmation_sent_at IS NOT NULL
  AND scheduled_at >= NOW() - INTERVAL '30 days';

-- Évolution quotidienne des leads (7 derniers jours)
SELECT
  DATE(created_at) as jour,
  COUNT(*) as leads,
  COUNT(CASE WHEN status = 'rdv_confirmed' THEN 1 END) as rdv_confirmes,
  COUNT(CASE WHEN lead_source = 'website' THEN 1 END) as web,
  COUNT(CASE WHEN lead_source = 'email' THEN 1 END) as email,
  COUNT(CASE WHEN lead_source = 'whatsapp' THEN 1 END) as whatsapp
FROM conversations
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY jour DESC;

-- ============================================================================
-- 4. GESTION OPÉRATIONNELLE
-- ============================================================================

-- Planning des RDV de la semaine (par zone)
SELECT
  a.zone,
  DATE(a.scheduled_at) as jour,
  COUNT(*) as nombre_rdv,
  string_agg(
    TO_CHAR(a.scheduled_at, 'HH24:MI') || ' - ' || l.full_name,
    ' | '
    ORDER BY a.scheduled_at
  ) as planning
FROM appointments a
JOIN leads l ON a.lead_id = l.id
WHERE a.scheduled_at BETWEEN NOW() AND NOW() + INTERVAL '7 days'
  AND a.status IN ('scheduled', 'confirmed')
GROUP BY a.zone, DATE(a.scheduled_at)
ORDER BY jour, a.zone;

-- Créneaux disponibles pour une zone (exemple: Lausanne)
-- Cette requête liste les heures déjà prises pour identifier les créneaux libres
SELECT
  DATE(scheduled_at) as jour,
  TO_CHAR(scheduled_at, 'HH24:MI') as heure,
  duration_minutes,
  l.full_name
FROM appointments a
JOIN leads l ON a.lead_id = l.id
WHERE a.zone = 'lausanne'
  AND a.scheduled_at BETWEEN NOW() AND NOW() + INTERVAL '14 days'
  AND a.status IN ('scheduled', 'confirmed')
ORDER BY a.scheduled_at;

-- Leads à relancer (pas d'activité depuis 24h)
SELECT
  l.id,
  l.full_name,
  l.phone,
  l.email,
  calculate_lead_completion(l.id) as completion_pct,
  l.updated_at,
  EXTRACT(EPOCH FROM (NOW() - l.updated_at)) / 3600 as heures_inactivite
FROM leads l
WHERE l.status IN ('collecting_info', 'info_complete')
  AND l.updated_at < NOW() - INTERVAL '24 hours'
  AND l.updated_at > NOW() - INTERVAL '7 days'
ORDER BY l.updated_at;

-- ============================================================================
-- 5. AVIS GOOGLE
-- ============================================================================

-- RDV terminés sans demande d'avis envoyée
SELECT
  a.id,
  a.completed_at,
  l.full_name,
  l.email,
  l.phone,
  EXTRACT(EPOCH FROM (NOW() - a.completed_at)) / 3600 as heures_depuis_completion
FROM appointments a
JOIN leads l ON a.lead_id = l.id
WHERE a.status = 'completed'
  AND a.google_review_requested_at IS NULL
  AND a.completed_at >= NOW() - INTERVAL '7 days'
ORDER BY a.completed_at;

-- Statistiques avis Google
SELECT
  COUNT(*) as total_demandes,
  COUNT(CASE WHEN google_review_received THEN 1 END) as avis_recus,
  ROUND(AVG(google_review_rating), 2) as note_moyenne,
  COUNT(CASE WHEN google_review_rating >= 4 THEN 1 END) as avis_positifs,
  COUNT(CASE WHEN google_review_rating <= 3 THEN 1 END) as avis_negatifs
FROM appointments
WHERE google_review_requested_at IS NOT NULL
  AND completed_at >= NOW() - INTERVAL '90 days';

-- ============================================================================
-- 6. DÉTECTION D'ANOMALIES
-- ============================================================================

-- Conversations avec beaucoup de messages mais pas de RDV
-- (possibles problèmes dans la conversation)
SELECT
  c.id,
  c.contact_info->>'name' as nom,
  COUNT(m.id) as nombre_messages,
  c.created_at,
  l.status as lead_status
FROM conversations c
LEFT JOIN messages m ON c.conversation_id = m.id
LEFT JOIN leads l ON c.id = l.conversation_id
WHERE c.created_at >= NOW() - INTERVAL '7 days'
GROUP BY c.id, c.contact_info, c.created_at, l.status
HAVING COUNT(m.id) > 10 AND l.status NOT IN ('rdv_confirmed', 'rdv_completed')
ORDER BY COUNT(m.id) DESC;

-- Leads avec VIN en double (possible erreur ou fraude)
SELECT
  vin,
  COUNT(*) as nombre,
  string_agg(full_name, ', ') as clients
FROM leads
WHERE vin IS NOT NULL
GROUP BY vin
HAVING COUNT(*) > 1;

-- RDV annulés fréquemment (même client)
SELECT
  l.phone,
  l.email,
  COUNT(*) as rdv_annules,
  string_agg(l.full_name, ', ') as noms
FROM appointments a
JOIN leads l ON a.lead_id = l.id
WHERE a.status = 'cancelled'
  AND a.created_at >= NOW() - INTERVAL '90 days'
GROUP BY l.phone, l.email
HAVING COUNT(*) >= 2
ORDER BY COUNT(*) DESC;

-- ============================================================================
-- 7. NETTOYAGE & MAINTENANCE
-- ============================================================================

-- Nettoyer conversations abandonnées (exécuter manuellement ou via cron)
SELECT cleanup_abandoned_conversations() as conversations_supprimees;

-- Compter les conversations à nettoyer (avant de lancer le nettoyage)
SELECT
  COUNT(*) as conversations_a_supprimer
FROM conversations
WHERE status = 'abandoned'
  AND updated_at < NOW() - INTERVAL '90 days';

-- Recalculer score de completion pour tous les leads actifs
UPDATE leads
SET conversion_score = calculate_lead_completion(id)
WHERE status IN ('collecting_info', 'info_complete', 'rdv_proposed');

-- ============================================================================
-- 8. EXPORT DE DONNÉES
-- ============================================================================

-- Export complet lead pour assurance (CSV-ready)
SELECT
  l.full_name as "Nom",
  l.phone as "Téléphone",
  l.email as "Email",
  l.address as "Adresse",
  l.city as "Ville",
  l.canton as "Canton",
  l.postal_code as "Code postal",
  l.vehicle_make as "Marque",
  l.vehicle_model as "Modèle",
  l.vehicle_year as "Année",
  l.vin as "VIN",
  l.glass_type as "Type vitrage",
  CASE WHEN l.has_adas THEN 'Oui' ELSE 'Non' END as "ADAS",
  l.insurance_company as "Assurance",
  l.claim_number as "N° sinistre",
  l.policy_number as "N° police",
  a.scheduled_at as "RDV planifié",
  a.status as "Statut RDV"
FROM leads l
LEFT JOIN appointments a ON l.id = a.lead_id
WHERE l.created_at >= NOW() - INTERVAL '30 days'
ORDER BY l.created_at DESC;

-- Export historique conversations (pour analyse IA)
SELECT
  c.id as conversation_id,
  c.lead_source,
  c.language,
  m.role,
  m.content,
  m.created_at,
  l.status as lead_status
FROM conversations c
JOIN messages m ON c.id = m.conversation_id
LEFT JOIN leads l ON c.id = l.conversation_id
WHERE c.created_at >= NOW() - INTERVAL '7 days'
ORDER BY c.id, m.created_at;

-- ============================================================================
-- 9. DASHBOARD KPIs
-- ============================================================================

-- KPIs complets pour dashboard (toutes métriques importantes)
SELECT
  -- Leads
  (SELECT COUNT(*) FROM conversations WHERE created_at >= NOW() - INTERVAL '7 days') as leads_7j,
  (SELECT COUNT(*) FROM conversations WHERE created_at >= NOW() - INTERVAL '30 days') as leads_30j,

  -- Conversions
  (SELECT COUNT(*) FROM appointments WHERE created_at >= NOW() - INTERVAL '7 days') as rdv_7j,
  (SELECT COUNT(*) FROM appointments WHERE created_at >= NOW() - INTERVAL '30 days') as rdv_30j,

  -- Taux conversion
  ROUND(
    (SELECT COUNT(*) FROM appointments WHERE created_at >= NOW() - INTERVAL '7 days') * 100.0 /
    NULLIF((SELECT COUNT(*) FROM conversations WHERE created_at >= NOW() - INTERVAL '7 days'), 0),
    2
  ) as taux_conversion_7j_pct,

  -- Temps moyen conversion
  ROUND(
    (SELECT AVG(EXTRACT(EPOCH FROM (a.created_at - c.created_at)) / 3600)
     FROM appointments a
     JOIN leads l ON a.lead_id = l.id
     JOIN conversations c ON l.conversation_id = c.id
     WHERE a.created_at >= NOW() - INTERVAL '30 days'),
    1
  ) as temps_moyen_conversion_heures,

  -- RDV à venir
  (SELECT COUNT(*) FROM appointments WHERE scheduled_at > NOW() AND status IN ('scheduled', 'confirmed')) as rdv_a_venir,

  -- RDV aujourd'hui
  (SELECT COUNT(*) FROM appointments WHERE DATE(scheduled_at) = CURRENT_DATE) as rdv_aujourdhui,

  -- Note moyenne Google
  ROUND(
    (SELECT AVG(google_review_rating)
     FROM appointments
     WHERE google_review_received = true
       AND completed_at >= NOW() - INTERVAL '90 days'),
    2
  ) as note_google_moyenne,

  -- Zone la plus active
  (SELECT zone FROM appointments WHERE created_at >= NOW() - INTERVAL '30 days' GROUP BY zone ORDER BY COUNT(*) DESC LIMIT 1) as zone_plus_active;

-- ============================================================================
-- 10. DEBUGGING
-- ============================================================================

-- Voir toutes les conversations d'un client (par téléphone ou email)
SELECT
  c.id,
  c.lead_source,
  c.status,
  c.created_at,
  (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id) as nb_messages
FROM conversations c
WHERE c.contact_info->>'phone' = '+41791234567'  -- Remplacer par le numéro
   OR c.contact_info->>'email' = 'client@example.com'  -- Remplacer par l'email
ORDER BY c.created_at DESC;

-- Voir l'historique complet d'une conversation
SELECT
  m.created_at,
  m.role,
  m.content,
  m.attachments,
  m.metadata
FROM messages m
WHERE m.conversation_id = '00000000-0000-0000-0000-000000000000'  -- Remplacer par l'ID
ORDER BY m.created_at;

-- Vérifier l'intégrité des données (leads sans conversation)
SELECT
  l.id,
  l.full_name,
  l.conversation_id
FROM leads l
LEFT JOIN conversations c ON l.conversation_id = c.id
WHERE c.id IS NULL;

-- Voir les erreurs de workflow N8N (à logger dans une table custom si nécessaire)
-- Pour l'instant, vérifier directement dans N8N Executions

-- ============================================================================
-- FIN DES REQUÊTES
-- ============================================================================

-- Note: Remplacer les valeurs d'exemple (UUID, téléphones, emails) par vos données réelles
