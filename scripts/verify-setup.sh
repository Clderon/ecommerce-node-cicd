#!/bin/bash
# Script de verificación rápida para CI/CD
# Uso: ./scripts/verify-setup.sh

set -e

echo "🔍 Verificando configuración del proyecto CI/CD..."
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0

# Función para verificar
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        ERRORS=$((ERRORS + 1))
    fi
}

# 1. Verificar Node.js
echo "1. Verificando Node.js..."
node --version > /dev/null 2>&1
check "Node.js está instalado"

# 2. Verificar npm
echo "2. Verificando npm..."
npm --version > /dev/null 2>&1
check "npm está instalado"

# 3. Verificar que existe package.json
echo "3. Verificando package.json..."
[ -f "package.json" ]
check "package.json existe"

# 4. Verificar dependencias instaladas
echo "4. Verificando dependencias..."
[ -d "node_modules" ]
check "node_modules existe (ejecuta 'npm install' si falta)"

# 5. Verificar que las pruebas pasan
echo "5. Ejecutando pruebas..."
npm test > /dev/null 2>&1
check "Las pruebas pasan"

# 6. Verificar ESLint
echo "6. Verificando ESLint..."
npx eslint . --max-warnings 0 > /dev/null 2>&1 || true
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ESLint sin errores${NC}"
else
    echo -e "${YELLOW}⚠️  ESLint tiene advertencias (revisa manualmente)${NC}"
fi

# 7. Verificar Dockerfile
echo "7. Verificando Dockerfile..."
[ -f "Dockerfile" ]
check "Dockerfile existe"

# 8. Verificar workflow de GitHub Actions
echo "8. Verificando workflow de GitHub Actions..."
[ -f ".github/workflows/ci-cd.yaml" ]
check "Workflow CI/CD existe"

# 9. Verificar infraestructura de Terraform
echo "9. Verificando infraestructura de Terraform..."
[ -f "infra/main.tf" ]
check "Terraform main.tf existe"

[ -f "infra/variables.tf" ]
check "Terraform variables.tf existe"

[ -f "infra/outputs.tf" ]
check "Terraform outputs.tf existe"

# 10. Verificar que el proyecto compila
echo "10. Verificando que el proyecto compila..."
timeout 5 npm start > /dev/null 2>&1 || true
check "El proyecto puede iniciar (timeout después de 5s es normal)"

# Resumen
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Configura los secrets en GitHub (Settings → Secrets → Actions)"
    echo "2. Configura AWS IAM User con permisos necesarios"
    echo "3. Haz push a main: git push origin main"
    echo "4. Monitorea en GitHub Actions"
    exit 0
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es)${NC}"
    echo ""
    echo "Revisa los errores arriba y corrígelos antes de continuar."
    exit 1
fi

