# =====================================================
# OuiGlass Suisse - MVP Phase 1
# Script de tests PowerShell (Windows)
# =====================================================

# IMPORTANT : Remplacez cette URL par votre URL webhook n8n
$WEBHOOK_URL = "YOUR_WEBHOOK_URL_HERE"

Write-Host "========================================"
Write-Host "Tests OuiGlass Suisse - MVP Chat Agent"
Write-Host "========================================"
Write-Host ""

# =====================================================
# Test 1 : Nouveau session_id (premier message)
# =====================================================
Write-Host "📝 Test 1 : Nouveau session_id (premier message)" -ForegroundColor Cyan
Write-Host "Payload : session_id=test-session-001, message=Bonjour"
Write-Host ""

$body = @{
    session_id = "test-session-001"
    message = "Bonjour"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
    Write-Host "Réponse :" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur :" -ForegroundColor Red
    $_.Exception.Message
}

Write-Host ""
Write-Host ""

# =====================================================
# Test 2 : Même session_id (message 2)
# =====================================================
Write-Host "📝 Test 2 : Même session_id (message 2)" -ForegroundColor Cyan
Write-Host "Payload : session_id=test-session-001, message=Renault"
Write-Host ""

$body = @{
    session_id = "test-session-001"
    message = "Renault"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
    Write-Host "Réponse :" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur :" -ForegroundColor Red
    $_.Exception.Message
}

Write-Host ""
Write-Host ""

# =====================================================
# Test 3 : Continuer la conversation
# =====================================================
Write-Host "📝 Test 3 : Continuer la conversation (modèle)" -ForegroundColor Cyan
Write-Host "Payload : session_id=test-session-001, message=Clio"
Write-Host ""

$body = @{
    session_id = "test-session-001"
    message = "Clio"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
    Write-Host "Réponse :" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur :" -ForegroundColor Red
    $_.Exception.Message
}

Write-Host ""
Write-Host ""

# =====================================================
# Test 4 : Message vide (doit erreur)
# =====================================================
Write-Host "📝 Test 4 : Message vide (doit erreur)" -ForegroundColor Cyan
Write-Host "Payload : session_id=test-session-002, message=''"
Write-Host ""

$body = @{
    session_id = "test-session-002"
    message = ""
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
    Write-Host "Réponse :" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur attendue :" -ForegroundColor Yellow
    $_.Exception.Message
}

Write-Host ""
Write-Host ""

# =====================================================
# Test 5 : session_id manquant (doit erreur)
# =====================================================
Write-Host "📝 Test 5 : session_id manquant (doit erreur)" -ForegroundColor Cyan
Write-Host "Payload : message=Hello (pas de session_id)"
Write-Host ""

$body = @{
    message = "Hello"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
    Write-Host "Réponse :" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur attendue :" -ForegroundColor Yellow
    $_.Exception.Message
}

Write-Host ""
Write-Host ""

# =====================================================
# Test 6 : Message en anglais (doit répondre en anglais)
# =====================================================
Write-Host "📝 Test 6 : Message en anglais (doit répondre en anglais)" -ForegroundColor Cyan
Write-Host "Payload : session_id=test-session-003, message=Hello, I need help with my car windshield"
Write-Host ""

$body = @{
    session_id = "test-session-003"
    message = "Hello, I need help with my car windshield"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
    Write-Host "Réponse :" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur :" -ForegroundColor Red
    $_.Exception.Message
}

Write-Host ""
Write-Host ""

# =====================================================
# Test 7 : Conversation complète en français
# =====================================================
Write-Host "📝 Test 7 : Conversation complète" -ForegroundColor Cyan
Write-Host ""

$messages = @(
    @{ session_id = "test-session-004"; message = "Bonjour" },
    @{ session_id = "test-session-004"; message = "Peugeot" },
    @{ session_id = "test-session-004"; message = "208" },
    @{ session_id = "test-session-004"; message = "2020" },
    @{ session_id = "test-session-004"; message = "pare-brise" },
    @{ session_id = "test-session-004"; message = "Genève" },
    @{ session_id = "test-session-004"; message = "Jean Dupont" }
)

foreach ($msg in $messages) {
    Write-Host "Message : $($msg.message)" -ForegroundColor Magenta

    $body = $msg | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType "application/json"
        Write-Host "Réponse : $($response.reply)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur :" -ForegroundColor Red
        $_.Exception.Message
    }

    Write-Host ""
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "========================================"
Write-Host "Tests terminés ✅"
Write-Host "========================================"
