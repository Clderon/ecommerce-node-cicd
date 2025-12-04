# 🚀 Comandos Rápidos - CI/CD

Guía de referencia rápida con los comandos más importantes.

## 📋 Verificación Pre-Push

### Windows (PowerShell)
```powershell
# Ejecutar script de verificación
.\scripts\verify-setup.ps1

# O verificar manualmente
npm test
npx eslint . --max-warnings 0
```

### Linux/Mac (Bash)
```bash
# Dar permisos de ejecución
chmod +x scripts/verify-setup.sh

# Ejecutar script de verificación
./scripts/verify-setup.sh

# O verificar manualmente
npm test
npx eslint . --max-warnings 0
```

## 🔄 Flujo Básico de Trabajo

```bash
# 1. Verificar que todo funciona localmente
npm test
npx eslint . --max-warnings 0

# 2. Agregar cambios
git add .

# 3. Hacer commit
git commit -m "feat: Descripción del cambio"

# 4. Push a main (esto activa el CI/CD)
git push origin main

# 5. Monitorear en GitHub
# Ve a: https://github.com/TU_USUARIO/TU_REPO/actions
```

## 🔍 Verificación Post-Despliegue

### Obtener URL de la Aplicación

```bash
# Opción 1: Desde GitHub Actions
# Ve a: Actions → Último workflow → Job "Deploy" → Step "Mostrar información"
# Busca: "📍 URL de la aplicación: http://XX.XX.XX.XX:3000"

# Opción 2: Desde AWS CLI
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text
```

### Probar la Aplicación

```bash
# Reemplaza XX.XX.XX.XX con la IP obtenida
APP_URL="http://XX.XX.XX.XX:3000"

# Probar con curl
curl $APP_URL

# O abrir en navegador
# Windows
start $APP_URL

# Linux
xdg-open $APP_URL

# Mac
open $APP_URL
```

## ☁️ Comandos AWS

### Ver Recursos Creados

```bash
# Ver instancias EC2
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" \
  --output table

# Ver bases de datos RDS
aws rds describe-db-instances \
  --query "DBInstances[?contains(DBInstanceIdentifier, 'ecommerce')].[DBInstanceIdentifier,Endpoint.Address,DBInstanceStatus]" \
  --output table

# Ver VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Vpcs[*].[VpcId,CidrBlock]" \
  --output table

# Ver imágenes en ECR
aws ecr describe-images \
  --repository-name ecommerce-quantum \
  --query "imageDetails[*].[imageTags[0],imagePushedAt]" \
  --output table
```

### Conectarse a EC2

```bash
# Obtener IP pública
EC2_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

# Conectarse (necesitas la clave SSH)
ssh -i /path/to/key.pem ubuntu@$EC2_IP

# Una vez conectado, ver logs
docker logs ecommerce-app -f

# Ver contenedores corriendo
docker ps

# Ver variables de entorno (sin contraseñas)
docker exec ecommerce-app env | grep -E "DB_|PORT|HOST"
```

## 🧪 Pruebas de Validación

### Probar que las Pruebas Bloquean el Despliegue

```bash
# 1. Crear un test que falle
echo "describe('Test que falla', () => {
  test('debe fallar', () => {
    expect(true).toBe(false);
  });
});" > tests/failing-test.js

# 2. Commit y push
git add tests/failing-test.js
git commit -m "test: Agregar test que falla"
git push origin main

# 3. Verificar en GitHub Actions que:
# - CI falla ❌
# - Build NO se ejecuta
# - Deploy NO se ejecuta

# 4. Eliminar el test y corregir
rm tests/failing-test.js
git add tests/failing-test.js
git commit -m "fix: Eliminar test que falla"
git push origin main

# 5. Ahora debe pasar todo ✅
```

## 🧹 Limpieza

### Destruir Infraestructura Manualmente

```bash
# Opción 1: Desde GitHub Actions
# Ve a: Actions → "CI/CD with Temporary Infrastructure" → Run workflow
# Marca: "Destroy infrastructure after deployment" → Run workflow

# Opción 2: Commit con [destroy]
git commit -m "chore: [destroy] Finalizar despliegue temporal"
git push origin main

# Opción 3: Script local (Linux/Mac)
chmod +x scripts/destroy-infrastructure.sh
./scripts/destroy-infrastructure.sh

# Opción 4: Terraform manual
cd infra
terraform destroy -auto-approve \
  -var="aws_region=us-east-1" \
  -var="docker_image=tu-imagen" \
  -var="db_password=tu-password" \
  -var="db_username=admin" \
  -var="db_name=equantom"
```

### Limpiar Recursos AWS Manualmente

```bash
# ⚠️ CUIDADO: Esto destruye recursos sin confirmación

# Eliminar instancia EC2
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Eliminar RDS
DB_IDENTIFIER=$(aws rds describe-db-instances \
  --query "DBInstances[?contains(DBInstanceIdentifier, 'ecommerce')].DBInstanceIdentifier" \
  --output text)
aws rds delete-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --skip-final-snapshot
```

## 📊 Monitoreo

### Ver Logs del Workflow en GitHub

```bash
# Si tienes GitHub CLI instalado
gh run list --workflow=ci-cd.yaml
gh run view [RUN_ID] --log
```

### Ver Estado de Recursos AWS

```bash
# Estado de EC2
aws ec2 describe-instance-status \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=ecommerce-quantum" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

# Estado de RDS
aws rds describe-db-instances \
  --query "DBInstances[?contains(DBInstanceIdentifier, 'ecommerce')].[DBInstanceIdentifier,DBInstanceStatus]" \
  --output table
```

## 🔐 Verificación de Secrets

### Verificar que los Secrets Están Configurados

```bash
# Desde GitHub CLI (si lo tienes)
gh secret list

# O manualmente:
# Ve a: GitHub → Settings → Secrets and variables → Actions
# Debes ver:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - DB_PASSWORD
# - DB_USERNAME (opcional)
# - DB_NAME (opcional)
```

## 📝 Checklist Rápido

```bash
# Antes de hacer push:
[ ] npm test pasa ✅
[ ] ESLint sin errores ✅
[ ] Secrets configurados en GitHub ✅
[ ] AWS IAM User con permisos ✅

# Después del push:
[ ] Workflow se activa en GitHub Actions ✅
[ ] Job CI pasa ✅
[ ] Job Build pasa ✅
[ ] Job Deploy pasa ✅
[ ] Aplicación accesible ✅
```

## 🆘 Comandos de Troubleshooting

### Ver Logs Detallados

```bash
# Logs de Docker en EC2
ssh ubuntu@$EC2_IP "docker logs ecommerce-app --tail 100"

# Logs del sistema en EC2
ssh ubuntu@$EC2_IP "journalctl -u docker -n 50"

# Verificar conectividad a RDS desde EC2
ssh ubuntu@$EC2_IP "nc -zv $RDS_ENDPOINT 3306"
```

### Verificar Configuración

```bash
# Verificar variables de entorno en el contenedor
ssh ubuntu@$EC2_IP "docker exec ecommerce-app env"

# Verificar que el puerto está escuchando
ssh ubuntu@$EC2_IP "netstat -tlnp | grep 3000"

# Verificar Security Groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "SecurityGroups[*].[GroupId,GroupName]" \
  --output table
```

---

## 📚 Documentación Completa

Para más detalles, consulta:
- `GUIA_PASOS.md` - Guía completa paso a paso
- `DEPLOYMENT.md` - Documentación de despliegue
- `REQUISITO_CI_CD.md` - Explicación del cumplimiento del requisito

