# Script de test pour l'API MotorGuard (PowerShell)
# Usage: .\test_api.ps1

$BASE_URL = "http://localhost:8000"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Test-Health {
    Write-Section "1. Health Check"
    try {
        $response = Invoke-RestMethod -Uri "$BASE_URL/health" -Method Get -TimeoutSec 5
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor White
        return $true
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $false
    }
}

function Test-Login {
    Write-Section "2. Login"
    try {
        $body = @{
            email = "admin@motorguard.local"
            password = "admin123"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$BASE_URL/auth/login-json" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5
        $script:TOKEN = $response.access_token
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "Token obtenu: $($TOKEN.Substring(0, [Math]::Min(20, $TOKEN.Length)))..." -ForegroundColor White
        return $TOKEN
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $null
    }
}

function Test-CreateMotor {
    param([string]$Token)
    Write-Section "3. Créer un moteur"
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        $body = @{
            name = "Broyeur Principal"
            code = "M001"
            location = "Atelier 3"
            description = "Broyeur principal de production"
            esp32_uid = "ESP32_001"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$BASE_URL/motors/" -Method Post -Headers $headers -Body $body -TimeoutSec 5
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "Moteur créé: ID=$($response.id), Name=$($response.name)" -ForegroundColor White
        return $response.id
    } catch {
        Write-Host "Avertissement: $_" -ForegroundColor Yellow
        return 1
    }
}

function Test-ListMotors {
    param([string]$Token)
    Write-Section "4. Lister les moteurs"
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }
        $response = Invoke-RestMethod -Uri "$BASE_URL/motors/" -Method Get -Headers $headers -TimeoutSec 5
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "$($response.Count) moteur(s) trouvé(s):" -ForegroundColor White
        foreach ($motor in $response) {
            Write-Host "  - $($motor.name) (ID: $($motor.id), Code: $($motor.code))" -ForegroundColor Gray
        }
        return $response[0].id
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $null
    }
}

function Test-CreateESP32Device {
    param([string]$Token, [int]$MotorId)
    Write-Section "5. Créer un ESP32 device"
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        $body = @{
            esp32_uid = "ESP32_001"
            motor_id = $MotorId
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$BASE_URL/esp32-devices/" -Method Post -Headers $headers -Body $body -TimeoutSec 5
        $script:API_KEY = $response.api_key
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "ESP32 device créé:" -ForegroundColor White
        Write-Host "  - ID: $($response.id)" -ForegroundColor Gray
        Write-Host "  - UID: $($response.esp32_uid)" -ForegroundColor Gray
        Write-Host "  - API Key: $($API_KEY.Substring(0, [Math]::Min(30, $API_KEY.Length)))..." -ForegroundColor Gray
        return $API_KEY
    } catch {
        Write-Host "Avertissement: $_" -ForegroundColor Yellow
        return "EXISTING_DEVICE"
    }
}

function Test-SendTelemetry {
    param([string]$ApiKey, [int]$MotorId)
    Write-Section "6. Envoyer de la télémétrie (simuler ESP32)"
    if ($ApiKey -eq "EXISTING_DEVICE") {
        Write-Host "Impossible de tester sans API Key valide" -ForegroundColor Yellow
        return $false
    }
    try {
        $headers = @{
            "X-API-Key" = $ApiKey
            "Content-Type" = "application/json"
        }
        $body = @{
            motor_id = $MotorId
            temperature = 55.5
            vibration = 2.4
            current = 12.5
            speed_rpm = 1450
            is_running = $true
            battery_percent = 87.0
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$BASE_URL/iot/telemetry/from-esp32" -Method Post -Headers $headers -Body $body -TimeoutSec 5
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "Télémétrie envoyée: ID=$($response.telemetry_id)" -ForegroundColor White
        return $true
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $false
    }
}

function Test-GetTelemetry {
    param([string]$Token, [int]$MotorId)
    Write-Section "7. Récupérer la télémétrie"
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }
        $response = Invoke-RestMethod -Uri "$BASE_URL/telemetry/motor/$MotorId?limit=5" -Method Get -Headers $headers -TimeoutSec 5
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "$($response.Count) point(s) de télémétrie trouvé(s):" -ForegroundColor White
        $count = [Math]::Min(3, $response.Count)
        for ($i = 0; $i -lt $count; $i++) {
            $tel = $response[$i]
            Write-Host "  - Temp: $($tel.temperature)°C, RPM: $($tel.speed_rpm), Running: $($tel.is_running)" -ForegroundColor Gray
        }
        return $true
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $false
    }
}

function Test-SendCommand {
    param([string]$Token, [int]$MotorId)
    Write-Section "8. Envoyer une commande START"
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        $body = @{
            action = "START"
            target_speed_rpm = 1500
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$BASE_URL/iot/motor/command?motor_id=$MotorId" -Method Post -Headers $headers -Body $body -TimeoutSec 5
        Write-Host "Status: OK" -ForegroundColor Green
        Write-Host "Commande envoyée: $($response.message)" -ForegroundColor White
        return $true
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Main
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "  TEST DE L'API MOTORGUARD" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""
Write-Host "Base URL: $BASE_URL" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# Test 1: Health Check
if (-not (Test-Health)) {
    Write-Host ""
    Write-Host "Le serveur n'est pas accessible. Assurez-vous qu'il est lancé." -ForegroundColor Red
    Write-Host "Commande: cd backend; uvicorn app.main:app --reload" -ForegroundColor Yellow
    exit 1
}

# Test 2: Login
$token = Test-Login
if (-not $token) {
    Write-Host ""
    Write-Host "Impossible de se connecter. Vérifiez les identifiants." -ForegroundColor Red
    exit 1
}

# Test 3: Créer un moteur
$motorId = Test-CreateMotor -Token $token
if (-not $motorId) {
    $motorId = 1
}

# Test 4: Lister les moteurs
$motorId = Test-ListMotors -Token $token
if (-not $motorId) {
    $motorId = 1
}

# Test 5: Créer un ESP32 device
$apiKey = Test-CreateESP32Device -Token $token -MotorId $motorId

# Test 6: Envoyer de la télémétrie
if ($apiKey -and $apiKey -ne "EXISTING_DEVICE") {
    Test-SendTelemetry -ApiKey $apiKey -MotorId $motorId
}

# Test 7: Récupérer la télémétrie
Test-GetTelemetry -Token $token -MotorId $motorId

# Test 8: Envoyer une commande
Test-SendCommand -Token $token -MotorId $motorId

# Résumé
Write-Section "RÉSUMÉ"
Write-Host "Tests terminés !" -ForegroundColor Green
Write-Host ""
Write-Host "Pour plus d'informations, consultez:" -ForegroundColor White
Write-Host "  - Swagger UI: $BASE_URL/docs" -ForegroundColor Gray
Write-Host "  - ReDoc: $BASE_URL/redoc" -ForegroundColor Gray
Write-Host ""

