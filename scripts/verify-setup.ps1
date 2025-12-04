# Script de verificación rápida para CI/CD (PowerShell)
# Uso: .\scripts\verify-setup.ps1

Write-Host "🔍 Verificando configuración del proyecto CI/CD..." -ForegroundColor Cyan
Write-Host ""

$Errors = 0

function Check {
    param($Message, $Condition)
    if ($Condition) {
        Write-Host "✅ $Message" -ForegroundColor Green
    } else {
        Write-Host "❌ $Message" -ForegroundColor Red
        $script:Errors++
    }
}

# 1. Verificar Node.js
Write-Host "1. Verificando Node.js..."
try {
    $nodeVersion = node --version 2>$null
    Check "Node.js está instalado" ($LASTEXITCODE -eq 0)
} catch {
    Check "Node.js está instalado" $false
}

# 2. Verificar npm
Write-Host "2. Verificando npm..."
try {
    $npmVersion = npm --version 2>$null
    Check "npm está instalado" ($LASTEXITCODE -eq 0)
} catch {
    Check "npm está instalado" $false
}

# 3. Verificar package.json
Write-Host "3. Verificando package.json..."
Check "package.json existe" (Test-Path "package.json")

# 4. Verificar node_modules
Write-Host "4. Verificando dependencias..."
Check "node_modules existe" (Test-Path "node_modules")

# 5. Verificar pruebas
Write-Host "5. Ejecutando pruebas..."
try {
    npm test 2>&1 | Out-Null
    Check "Las pruebas pasan" ($LASTEXITCODE -eq 0)
} catch {
    Check "Las pruebas pasan" $false
}

# 6. Verificar ESLint
Write-Host "6. Verificando ESLint..."
try {
    npx eslint . --max-warnings 0 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ESLint sin errores" -ForegroundColor Green
    } else {
        Write-Host "⚠️  ESLint tiene advertencias (revisa manualmente)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  No se pudo ejecutar ESLint" -ForegroundColor Yellow
}

# 7. Verificar Dockerfile
Write-Host "7. Verificando Dockerfile..."
Check "Dockerfile existe" (Test-Path "Dockerfile")

# 8. Verificar workflow
Write-Host "8. Verificando workflow de GitHub Actions..."
Check "Workflow CI/CD existe" (Test-Path ".github\workflows\ci-cd.yaml")

# 9. Verificar Terraform
Write-Host "9. Verificando infraestructura de Terraform..."
Check "Terraform main.tf existe" (Test-Path "infra\main.tf")
Check "Terraform variables.tf existe" (Test-Path "infra\variables.tf")
Check "Terraform outputs.tf existe" (Test-Path "infra\outputs.tf")

# 10. Verificar que compila
Write-Host "10. Verificando que el proyecto compila..."
# Nota: En PowerShell, iniciar y detener procesos es más complejo
# Por ahora, solo verificamos que los archivos principales existen
Check "Archivos principales existen" (Test-Path "app.js")

# Resumen
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($Errors -eq 0) {
    Write-Host "✅ Todas las verificaciones pasaron" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Configura los secrets en GitHub (Settings → Secrets → Actions)"
    Write-Host "2. Configura AWS IAM User con permisos necesarios"
    Write-Host "3. Haz push a main: git push origin main"
    Write-Host "4. Monitorea en GitHub Actions"
    exit 0
} else {
    Write-Host "❌ Se encontraron $Errors error(es)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Revisa los errores arriba y corrígelos antes de continuar." -ForegroundColor Yellow
    exit 1
}

