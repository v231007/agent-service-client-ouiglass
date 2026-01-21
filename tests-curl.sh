#!/bin/bash
# =====================================================
# OuiGlass Suisse - MVP Phase 1
# Script de tests CURL (Linux/Mac)
# =====================================================

# IMPORTANT : Remplacez cette URL par votre URL webhook n8n
WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"

echo "========================================"
echo "Tests OuiGlass Suisse - MVP Chat Agent"
echo "========================================"
echo ""

# =====================================================
# Test 1 : Nouveau session_id (premier message)
# =====================================================
echo "📝 Test 1 : Nouveau session_id (premier message)"
echo "Payload : session_id=test-session-001, message=Bonjour"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "message": "Bonjour"
  }'

echo ""
echo ""

# =====================================================
# Test 2 : Même session_id (message 2)
# =====================================================
echo "📝 Test 2 : Même session_id (message 2)"
echo "Payload : session_id=test-session-001, message=Renault"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "message": "Renault"
  }'

echo ""
echo ""

# =====================================================
# Test 3 : Continuer la conversation
# =====================================================
echo "📝 Test 3 : Continuer la conversation (modèle)"
echo "Payload : session_id=test-session-001, message=Clio"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "message": "Clio"
  }'

echo ""
echo ""

# =====================================================
# Test 4 : Message vide (doit erreur)
# =====================================================
echo "📝 Test 4 : Message vide (doit erreur)"
echo "Payload : session_id=test-session-002, message=''"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-002",
    "message": ""
  }'

echo ""
echo ""

# =====================================================
# Test 5 : session_id manquant (doit erreur)
# =====================================================
echo "📝 Test 5 : session_id manquant (doit erreur)"
echo "Payload : message=Hello (pas de session_id)"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello"
  }'

echo ""
echo ""

# =====================================================
# Test 6 : Message en anglais (doit répondre en anglais)
# =====================================================
echo "📝 Test 6 : Message en anglais (doit répondre en anglais)"
echo "Payload : session_id=test-session-003, message=Hello, I need help with my car windshield"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-003",
    "message": "Hello, I need help with my car windshield"
  }'

echo ""
echo ""

# =====================================================
# Test 7 : Conversation complète en français
# =====================================================
echo "📝 Test 7 : Conversation complète"
echo ""

echo "Message 1 : Bonjour"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "Bonjour"
  }'
echo ""
sleep 1

echo "Message 2 : Peugeot"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "Peugeot"
  }'
echo ""
sleep 1

echo "Message 3 : 208"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "208"
  }'
echo ""
sleep 1

echo "Message 4 : 2020"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "2020"
  }'
echo ""
sleep 1

echo "Message 5 : pare-brise"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "pare-brise"
  }'
echo ""
sleep 1

echo "Message 6 : Genève"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "Genève"
  }'
echo ""
sleep 1

echo "Message 7 : Jean Dupont"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-004",
    "message": "Jean Dupont"
  }'
echo ""

echo ""
echo "========================================"
echo "Tests terminés ✅"
echo "========================================"
