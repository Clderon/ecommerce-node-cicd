# Guía Paso a Paso: Configuración y Verificación del CI/CD

Esta guía te llevará paso a paso para configurar y verificar que el flujo CI/CD funciona correctamente.

## 📋 Tabla de Contenidos

1. [Prerrequisitos](#prerrequisitos)
2. [Configuración Inicial](#configuración-inicial)
3. [Configurar Secrets en GitHub](#configurar-secrets-en-github)
4. [Configurar AWS](#configurar-aws)
5. [Primera Ejecución](#primera-ejecución)
6. [Verificación del Flujo](#verificación-del-flujo)
7. [Pruebas de Validación](#pruebas-de-validación)
8. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerrequisitos

### 1. Verificar que tienes instalado:

```bash
# Node.js y npm
node --version  # Debe ser v18 o superior
npm --version

# Git
git --version

# AWS CLI (opcional, para verificación local)
aws --version
```

### 2. Verificar estructura del proyecto:

```bash
cd C:\nube\Tarea-03\nodejs-ecommerce

# Verificar que existe el workflow
ls .github/workflows/ci-cd.yaml

# Verificar que existe la infraestructura de Terraform
ls infra/main.tf

# Verificar que existe el Dockerfile
ls Dockerfile
```

---

## ⚙️ Configuración Inicial

### Paso 1: Verificar que las pruebas funcionan localmente

```bash
# Instalar dependencias
npm install

# Ejecutar pruebas
npm test

# Verificar ESLint
npx eslint . --max-warnings 0
```

**✅ Resultado esperado:**
- Las pruebas deben pasar sin errores
- ESLint no debe mostrar errores críticos

### Paso 2: Verificar que el proyecto compila

```bash
# Verificar que la aplicación inicia correctamente
npm start
# Presiona Ctrl+C para detener
```

---

## 🔐 Configurar Secrets en GitHub

### Paso 1: Acceder a la configuración de Secrets

1. Ve a tu repositorio en GitHub
2. Click en **Settings** (Configuración)
3. En el menú lateral, click en **Secrets and variables** → **Actions**

### Paso 2: Agregar cada Secret

Click en **New repository secret** y agrega uno por uno:

#### Secret 1: AWS_ACCESS_KEY_ID
```
Name: AWS_ACCESS_KEY_ID
Value: [Tu Access Key ID de AWS]
```

#### Secret 2: AWS_SECRET_ACCESS_KEY
```
Name: AWS_SECRET_ACCESS_KEY
Value: [Tu Secret Access Key de AWS]
```

#### Secret 3: DB_PASSWORD
```
Name: DB_PASSWORD
Value: [Contraseña segura para MySQL, mínimo 8 caracteres]
Ejemplo: MySecurePass123!
```

#### Secret 4: DB_USERNAME (Opcional)
```
Name: DB_USERNAME
Value: admin
```

#### Secret 5: DB_NAME (Opcional)
```
Name: DB_NAME
Value: equantom
```

### Paso 3: Verificar que los Secrets están configurados

En la página de Secrets, debes ver:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY
- ✅ DB_PASSWORD
- ✅ DB_USERNAME (opcional)
- ✅ DB_NAME (opcional)

---

## ☁️ Configurar AWS

### Paso 1: Crear IAM User para CI/CD

#### Opción A: Desde AWS Console (Recomendado)

1. Ve a **AWS Console** → **IAM** → **Users**
2. Click en **Create user**
3. Nombre: `github-actions-ci-cd`
4. Click en **Next**

#### Paso 2: Asignar Permisos

**Opción 1: Política Administradora (Solo para pruebas)**
- Selecciona **AdministratorAccess**
- ⚠️ **No recomendado para producción**

**Opción 2: Permisos Específicos (Recomendado)**

Crea una política personalizada con este JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "vpc:*",
        "ecr:*",
        "iam:CreateRole",
        "iam:CreateInstanceProfile",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:GetInstanceProfile"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Paso 3: Crear Access Keys

1. Selecciona el usuario creado
2. Click en la pestaña **Security credentials**
3. Click en **Create access key**
4. Selecciona **Command Line Interface (CLI)**
5. Click en **Next** → **Create access key**
6. **⚠️ IMPORTANTE**: Copia y guarda:
   - **Access key ID**
   - **Secret access key** (solo se muestra una vez)

### Paso 2: Verificar Credenciales AWS (Opcional)

```bash
# Configurar credenciales localmente (solo para verificación)
aws configure

# Probar acceso
aws sts get-caller-identity

# Verificar que puedes crear recursos
aws ec2 describe-regions
```

---

## 🚀 Primera Ejecución

### Paso 1: Hacer Commit y Push

```bash
# Asegúrate de estar en la rama main
git checkout main

# Verificar estado
git status

# Agregar todos los cambios
git add .

# Hacer commit
git commit -m "feat: Configurar CI/CD con infraestructura temporal"

# Push a GitHub
git push origin main
```

### Paso 2: Monitorear el Workflow

1. Ve a tu repositorio en GitHub
2. Click en la pestaña **Actions**
3. Deberías ver un workflow ejecutándose: **"CI/CD with Temporary Infrastructure"**
4. Click en el workflow para ver los detalles

### Paso 3: Verificar cada Job

#### Job 1: CI (Continuous Integration)
```
✅ Debe mostrar:
- Checkout código
- Configurar Node.js
- Instalar dependencias
- Ejecutar pruebas unitarias ✅
- Verificar estilo con ESLint ✅
- Construir artefacto ✅
```

**⏱️ Tiempo estimado:** 2-3 minutos

#### Job 2: Build (Construir Docker Image)
```
✅ Debe mostrar:
- Checkout código
- Configurar AWS credentials ✅
- Login a Amazon ECR ✅
- Crear repositorio ECR si no existe ✅
- Construir imagen Docker ✅
- Subir imagen a ECR ✅
```

**⏱️ Tiempo estimado:** 5-7 minutos

#### Job 3: Deploy (Desplegar Infraestructura)
```
✅ Debe mostrar:
- Checkout código
- Configurar AWS credentials ✅
- Configurar Terraform ✅
- Terraform Init ✅
- Terraform Plan ✅
- Terraform Apply ✅
- Obtener outputs de Terraform ✅
- Esperar a que la aplicación esté lista ✅
- Mostrar información de despliegue ✅
```

**⏱️ Tiempo estimado:** 10-15 minutos

---

## ✅ Verificación del Flujo

### Verificación 1: Workflow Completo

```bash
# En GitHub Actions, verifica que:
✅ Todos los jobs pasaron (marcas verdes)
✅ No hay errores en rojo
✅ El workflow muestra "completed" en verde
```

### Verificación 2: Obtener URL de la Aplicación

En el job **Deploy**, busca el step **"Mostrar información de despliegue"**:

```
🚀 Despliegue completado
📍 URL de la aplicación: http://XX.XX.XX.XX:3000
🖥️  Instancia EC2: i-xxxxxxxxxxxxx
🗄️  RDS Endpoint: ecommerce-db-xxxxx.xxxxx.us-east-1.rds.amazonaws.com
```

### Verificación 3: Probar la Aplicación

```bash
# Reemplaza XX.XX.XX.XX con la IP que obtuviste
curl http://XX.XX.XX.XX:3000

# O abre en el navegador
# http://XX.XX.XX.XX:3000
```

**✅ Resultado esperado:**
- La aplicación debe responder (código HTTP 200)
- Debe mostrar la página principal del ecommerce

### Verificación 4: Verificar Recursos en AWS

```bash
# Verificar instancia EC2
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" \
  --output table

# Verificar RDS
aws rds describe-db-instances \
  --query "DBInstances[?contains(DBInstanceIdentifier, 'ecommerce')].[DBInstanceIdentifier,Endpoint.Address,DBInstanceStatus]" \
  --output table

# Verificar VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=ecommerce-quantum" \
  --query "Vpcs[*].[VpcId,CidrBlock]" \
  --output table
```

---

## 🧪 Pruebas de Validación

### Prueba 1: Verificar que las Pruebas Bloquean el Despliegue

#### Paso 1: Crear un test que falle

```bash
# Crear un archivo de prueba que falle
cat > tests/failing-test.js << 'EOF'
describe('Test que falla', () => {
  test('debe fallar', () => {
    expect(true).toBe(false);
  });
});
EOF
```

#### Paso 2: Hacer commit y push

```bash
git add tests/failing-test.js
git commit -m "test: Agregar test que falla para verificar CI"
git push origin main
```

#### Paso 3: Verificar en GitHub Actions

```
✅ Resultado esperado:
- Job CI debe FALLAR ❌
- Job Build NO debe ejecutarse (se omite)
- Job Deploy NO debe ejecutarse (se omite)
- Workflow debe mostrar "failed" o "cancelled"
```

#### Paso 4: Corregir y verificar que funciona

```bash
# Eliminar el test que falla
rm tests/failing-test.js

git add tests/failing-test.js
git commit -m "fix: Eliminar test que falla"
git push origin main

# Ahora el workflow debe pasar completamente ✅
```

### Prueba 2: Verificar Logs de la Aplicación

```bash
# Obtener la IP de la instancia EC2 desde GitHub Actions o AWS Console
EC2_IP="XX.XX.XX.XX"  # Reemplaza con tu IP

# Conectarte vía SSH (necesitas la clave SSH)
# Primero, obtén la clave desde AWS o GitHub Secrets
ssh -i /path/to/key.pem ubuntu@$EC2_IP

# Una vez conectado, ver logs del contenedor
docker logs ecommerce-app -f

# Verificar que el contenedor está corriendo
docker ps

# Ver variables de entorno (sin mostrar contraseñas)
docker exec ecommerce-app env | grep -E "DB_|PORT|HOST"
```

### Prueba 3: Verificar Base de Datos

```bash
# Conectarte a la instancia EC2
ssh -i /path/to/key.pem ubuntu@$EC2_IP

# Instalar cliente MySQL
sudo apt update
sudo apt install mysql-client -y

# Conectarte a RDS (reemplaza con el endpoint de RDS)
mysql -h ecommerce-db-xxxxx.xxxxx.us-east-1.rds.amazonaws.com \
      -u admin \
      -p equantom

# Una vez conectado, verificar tablas
SHOW TABLES;

# Verificar datos
SELECT COUNT(*) FROM productos;
SELECT COUNT(*) FROM categorias;
```

---

## 🔍 Comandos de Verificación Rápida

### Verificar Estado del Workflow

```bash
# Usando GitHub CLI (si lo tienes instalado)
gh workflow list
gh run list --workflow=ci-cd.yaml
gh run view [RUN_ID] --log
```

### Verificar desde AWS Console

1. **EC2 Console**: Verifica que hay una instancia corriendo
2. **RDS Console**: Verifica que hay una base de datos MySQL activa
3. **VPC Console**: Verifica que hay una VPC creada
4. **ECR Console**: Verifica que hay imágenes Docker almacenadas

### Verificar Logs del Workflow

En GitHub Actions:
1. Click en el workflow ejecutado
2. Click en cada job para ver logs detallados
3. Busca errores en rojo o advertencias en amarillo

---

## 🐛 Troubleshooting

### Problema 1: Workflow no se activa

**Síntomas:**
- Haces push pero no aparece en Actions

**Solución:**
```bash
# Verificar que estás en la rama main
git branch

# Verificar que el archivo workflow existe
ls .github/workflows/ci-cd.yaml

# Verificar sintaxis YAML
# Puedes usar un validador online: https://www.yamllint.com/
```

### Problema 2: Error "AWS credentials not found"

**Síntomas:**
- Job Build o Deploy falla con error de credenciales

**Solución:**
1. Verifica que los secrets están configurados en GitHub
2. Verifica que los nombres son exactos (case-sensitive):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Verifica que las credenciales son válidas en AWS

### Problema 3: Error "Terraform plan failed"

**Síntomas:**
- Job Deploy falla en Terraform Plan

**Solución:**
```bash
# Verificar logs detallados en GitHub Actions
# Busca el error específico en el step "Terraform Plan"

# Errores comunes:
# - Variables faltantes → Verificar secrets en GitHub
# - Permisos insuficientes → Verificar IAM User
# - Región incorrecta → Verificar AWS_REGION en workflow
```

### Problema 4: Aplicación no responde

**Síntomas:**
- Deploy pasa pero la aplicación no carga

**Solución:**
```bash
# 1. Verificar que la instancia EC2 está corriendo
aws ec2 describe-instances --instance-ids i-xxxxx

# 2. Verificar Security Group permite tráfico en puerto 3000
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=ecommerce-ec2-sg"

# 3. Conectarte a EC2 y ver logs
ssh ubuntu@$EC2_IP
docker logs ecommerce-app
docker ps  # Verificar que el contenedor está corriendo
```

### Problema 5: RDS no está disponible

**Síntomas:**
- Aplicación no puede conectar a la base de datos

**Solución:**
```bash
# Verificar estado de RDS
aws rds describe-db-instances \
  --db-instance-identifier ecommerce-db-*

# Verificar Security Group de RDS permite conexiones desde EC2
# El Security Group de RDS debe permitir puerto 3306 desde el SG de EC2
```

---

## 📊 Checklist Final de Verificación

Usa este checklist para asegurarte de que todo funciona:

### Configuración
- [ ] Secrets configurados en GitHub
- [ ] IAM User creado en AWS con permisos correctos
- [ ] Access Keys creadas y guardadas

### Primera Ejecución
- [ ] Push a main activa el workflow
- [ ] Job CI pasa (pruebas y ESLint)
- [ ] Job Build pasa (Docker construido y subido)
- [ ] Job Deploy pasa (infraestructura creada)

### Verificación de Despliegue
- [ ] URL de aplicación accesible
- [ ] Aplicación carga correctamente
- [ ] Base de datos conectada
- [ ] Recursos visibles en AWS Console

### Validación de Requisito
- [ ] Pruebas que fallan bloquean el despliegue ✅
- [ ] Pruebas que pasan permiten el despliegue ✅
- [ ] Despliegue es automático ✅

---

## 🎯 Comandos de Resumen

```bash
# 1. Verificar localmente
npm test
npx eslint . --max-warnings 0

# 2. Hacer push
git add .
git commit -m "test: Verificar CI/CD"
git push origin main

# 3. Monitorear en GitHub
# Ve a: https://github.com/TU_USUARIO/TU_REPO/actions

# 4. Verificar aplicación (después del despliegue)
curl http://XX.XX.XX.XX:3000

# 5. Verificar recursos AWS
aws ec2 describe-instances --filters "Name=tag:Project,Values=ecommerce-quantum"
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, 'ecommerce')]"
```

---

## 📞 Siguiente Paso

Una vez que todo esté funcionando:

1. ✅ Documenta la URL de tu aplicación
2. ✅ Guarda las credenciales de forma segura
3. ✅ Configura alertas de costo en AWS
4. ✅ Prueba el flujo de destrucción de infraestructura

¡Listo! Tu CI/CD está funcionando correctamente. 🎉

