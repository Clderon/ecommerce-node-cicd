#!/bin/bash
# Script para destruir infraestructura temporal
# Uso: ./scripts/destroy-infrastructure.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_DIR="$PROJECT_ROOT/infra"

echo "🧹 Iniciando destrucción de infraestructura temporal..."

cd "$INFRA_DIR"

# Verificar que Terraform esté instalado
if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform no está instalado"
    exit 1
fi

# Verificar que existe el estado de Terraform
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "⚠️  No se encontró estado de Terraform. La infraestructura puede no existir."
    read -p "¿Deseas continuar de todas formas? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Inicializar Terraform si es necesario
if [ ! -d ".terraform" ]; then
    echo "📦 Inicializando Terraform..."
    terraform init
fi

# Mostrar recursos que serán destruidos
echo "📋 Recursos que serán destruidos:"
terraform plan -destroy

# Confirmar destrucción
read -p "¿Estás seguro de que deseas destruir toda la infraestructura? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "❌ Destrucción cancelada"
    exit 1
fi

# Destruir infraestructura
echo "🔥 Destruyendo infraestructura..."
terraform destroy -auto-approve

echo "✅ Infraestructura destruida exitosamente"
echo "📝 Nota: Los artefactos en ECR y datos en almacenamiento externo permanecen intactos"

