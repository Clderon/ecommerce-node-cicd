# Verificación del CI/CD - Flujo Paso a Paso con Tiempos

Esta guía te muestra exactamente qué hacer y cuánto tiempo esperar para verificar que tu CI/CD está funcionando correctamente.

## ⏱️ Resumen de Tiempos

| Fase | Tiempo Estimado | Qué Verificar |
|------|-----------------|---------------|
| **Configuración inicial** | 15-30 min | Secrets y AWS configurados |
| **Primer push** | 20-30 min | Workflow completo ejecutándose |
| **Job CI** | 2-5 min | Pruebas unitarias pasando |
| **Job Build** | 5-10 min | Imagen Docker construida |
| **Job Deploy** | 10-15 min | Infraestructura creada |
| **Verificación final** | 5 min | Aplicación accesible |

**Total estimado:** 20-30 minutos desde el push hasta aplicación funcionando

---

## 📋 Paso 1: Configuración Inicial (15-30 minutos)

### 1.1 Configurar Secrets en GitHub (5 minutos)

**Tiempo:** 5 minutos

**Pasos:**
1. Ve a: `https://github.com/TU_USUARIO/TU_REPO/settings/secrets/actions`
2. Agrega cada secret uno por uno:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DB_PASSWORD`
   - `DB_USERNAME` (opcional)
   - `DB_NAME` (opcional)

**✅ Verificación:**
- Debes ver todos los secrets listados en la página
- Cada secret debe tener un nombre correcto (case-sensitive)

**⏱️ Tiempo:** 5 minutos

---

### 1.2 Configurar AWS IAM User (10-20 minutos)

**Tiempo:** 10-20 minutos

**Pasos:**
1. Ve a AWS Console → IAM → Users
2. Crea usuario: `github-actions-ci-cd`
3. Asigna permisos (AdministratorAccess o política personalizada)
4. Crea Access Keys
5. Copia Access Key ID y Secret Access Key

**✅ Verificación:**
- Usuario creado en AWS
- Access Keys creadas y guardadas
- Keys copiadas a GitHub Secrets

**⏱️ Tiempo:** 10-20 minutos

---

## 🚀 Paso 2: Primer Push y Activación del Workflow (1 minuto)

### 2.1 Hacer Push a Main

**Tiempo:** 1 minuto

**Comandos:**
```bash
git add .
git commit -m "feat: Configurar CI/CD con infraestructura temporal"
git push origin main
```

**✅ Verificación inmediata:**
- El push se completa sin errores
- En GitHub, ve a la pestaña **Actions**

**⏱️ Tiempo:** 1 minuto

---

### 2.2 Verificar que el Workflow se Activó

**Tiempo:** 30 segundos

**Pasos:**
1. Ve a: `https://github.com/TU_USUARIO/TU_REPO/actions`
2. Debes ver un workflow ejecutándose: **"CI/CD with Temporary Infrastructure"**
3. Click en el workflow para ver detalles

**✅ Verificación:**
- Workflow aparece en la lista
- Estado: "🟡 In progress" o "🟢 Running"
- Puedes ver los jobs: CI, Build, Deploy

**⏱️ Tiempo:** 30 segundos

---

## ✅ Paso 3: Job CI - Pruebas Unitarias (2-5 minutos)

### 3.1 Monitorear Job CI

**Tiempo de ejecución:** 2-5 minutos

**Qué observar:**
1. Click en el job **"Continuous Integration - Pruebas Automáticas"**
2. Verás estos steps ejecutándose:

```
✅ Checkout código (10-20 segundos)
✅ Configurar Node.js (10-20 segundos)
✅ Instalar dependencias (30-60 segundos)
⏳ Ejecutar pruebas unitarias (10-30 segundos) ← Aquí se ejecutan las pruebas
⏳ Verificar estilo con ESLint (10-20 segundos)
✅ Construir artefacto (5 segundos)
```

**✅ Verificación exitosa:**
- Todos los steps tienen ✅ (check verde)
- En "Ejecutar pruebas unitarias" ves:
  ```
  ✅ PASS tests/unit/decisionTable.test.js
  ✅ PASS tests/unit/authDecisionTable.test.js
  ✅ PASS tests/unit/msg.test.js
  ```
- El job muestra: **"✅ This job has completed successfully"**

**❌ Si falla:**
- Verás ❌ en algún step
- Revisa los logs para ver qué falló
- Corrige el error y haz push nuevamente

**⏱️ Tiempo de ejecución:** 2-5 minutos

---

### 3.2 Esperar a que CI Complete

**Qué hacer:**
- ⏳ Espera a que el job CI termine
- ✅ Verifica que todos los steps pasaron
- ✅ Verifica que las pruebas unitarias pasaron

**⏱️ Tiempo de espera:** 2-5 minutos

---

## 🏗️ Paso 4: Job Build - Construcción Docker (5-10 minutos)

### 4.1 Monitorear Job Build

**Tiempo de ejecución:** 5-10 minutos

**Qué observar:**
1. El job **"Build Docker Image"** se activa automáticamente (solo si CI pasó)
2. Verás estos steps:

```
✅ Checkout código (10-20 segundos)
✅ Configurar AWS credentials (5-10 segundos)
✅ Login a Amazon ECR (10-20 segundos)
✅ Crear repositorio ECR si no existe (5-10 segundos)
⏳ Construir imagen Docker (3-7 minutos) ← Toma más tiempo
✅ Subir imagen a ECR (1-2 minutos)
✅ Guardar imagen ECR para CD (5 segundos)
```

**✅ Verificación exitosa:**
- Todos los steps tienen ✅
- En "Construir imagen Docker" ves:
  ```
  Step 1/10 : FROM node:18-alpine AS builder
  Step 2/10 : WORKDIR /app
  ...
  Successfully built abc123def456
  ```
- En "Subir imagen a ECR" ves:
  ```
  The push refers to repository [123456789.dkr.ecr.us-east-1.amazonaws.com/ecommerce-quantum]
  ...
  latest: digest: sha256:... size: ...
  ```

**⏱️ Tiempo de ejecución:** 5-10 minutos

---

### 4.2 Verificar Imagen en ECR

**Tiempo:** 2 minutos

**Pasos:**
1. Ve a AWS Console → ECR → Repositories
2. Busca: `ecommerce-quantum`
3. Debes ver imágenes con tags:
   - `latest`
   - `abc123def456` (el SHA del commit)

**✅ Verificación:**
- Repositorio existe
- Imágenes están disponibles
- Tags correctos

**⏱️ Tiempo:** 2 minutos

---

## 🌍 Paso 5: Job Deploy - Despliegue con Terraform (10-15 minutos)

### 5.1 Monitorear Job Deploy

**Tiempo de ejecución:** 10-15 minutos

**Qué observar:**
1. El job **"Deploy Infrastructure"** se activa automáticamente (solo si Build pasó)
2. Verás estos steps:

```
✅ Checkout código (10-20 segundos)
✅ Configurar AWS credentials (5-10 segundos)
✅ Configurar Terraform (10-20 segundos)
⏳ Terraform Init (30-60 segundos)
⏳ Terraform Plan (1-2 minutos) ← Muestra qué se va a crear
⏳ Terraform Apply (5-10 minutos) ← Crea la infraestructura
✅ Obtener outputs de Terraform (10 segundos)
⏳ Esperar a que la aplicación esté lista (1-3 minutos)
✅ Mostrar información de despliegue (5 segundos)
```

**✅ Verificación exitosa:**

**En "Terraform Plan":**
```
Plan: 15 to add, 0 to change, 0 to destroy.
+ aws_vpc.ecommerce_vpc
+ aws_subnet.ecommerce_public_subnet
+ aws_instance.ecommerce_app
+ aws_db_instance.ecommerce_db
...
```

**En "Terraform Apply":**
```
aws_vpc.ecommerce_vpc: Creating...
aws_vpc.ecommerce_vpc: Creation complete after 5s
aws_subnet.ecommerce_public_subnet: Creating...
...
aws_instance.ecommerce_app: Creating...
aws_instance.ecommerce_app: Still creating... [10s elapsed]
aws_instance.ecommerce_app: Creation complete after 45s
...
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
```

**En "Mostrar información de despliegue":**
```
🚀 Despliegue completado
📍 URL de la aplicación: http://XX.XX.XX.XX:3000
🖥️  Instancia EC2: i-xxxxxxxxxxxxx
🗄️  RDS Endpoint: ecommerce-db-xxxxx.xxxxx.us-east-1.rds.amazonaws.com
```

**⏱️ Tiempo de ejecución:** 10-15 minutos

---

### 5.2 Esperar a que la Aplicación Esté Lista

**Tiempo:** 1-3 minutos adicionales

**Qué observar:**
- El step "Esperar a que la aplicación esté lista" intenta conectarse a la URL
- Verás mensajes como:
  ```
  Intento 1/30: Aplicación no disponible aún, esperando 10 segundos...
  Intento 2/30: Aplicación no disponible aún, esperando 10 segundos...
  ✅ Aplicación disponible en http://XX.XX.XX.XX:3000
  ```

**⏱️ Tiempo de espera:** 1-3 minutos

---

## ✅ Paso 6: Verificación Final (5 minutos)

### 6.1 Obtener URL de la Aplicación

**Tiempo:** 1 minuto

**Pasos:**
1. En GitHub Actions, ve al job "Deploy Infrastructure"
2. Busca el step "Mostrar información de despliegue"
3. Copia la URL: `http://XX.XX.XX.XX:3000`

**✅ Verificación:**
- Tienes la URL de la aplicación
- Tienes el ID de la instancia EC2
- Tienes el endpoint de RDS

**⏱️ Tiempo:** 1 minuto

---

### 6.2 Probar la Aplicación

**Tiempo:** 2 minutos

**Opción 1: Navegador**
1. Abre la URL en tu navegador: `http://XX.XX.XX.XX:3000`
2. Debe cargar la página principal del ecommerce

**Opción 2: curl**
```bash
curl http://XX.XX.XX.XX:3000
```

**✅ Verificación exitosa:**
- La página carga correctamente
- No hay errores 404 o 500
- Puedes ver la interfaz del ecommerce

**❌ Si falla:**
- Verifica que la instancia EC2 está corriendo en AWS
- Verifica que el Security Group permite tráfico en puerto 3000
- Revisa los logs del contenedor Docker

**⏱️ Tiempo:** 2 minutos

---

### 6.3 Verificar Recursos en AWS

**Tiempo:** 2 minutos

**Pasos:**
1. Ve a AWS Console → EC2 → Instances
2. Busca instancia con tag: `Project = ecommerce-quantum`
3. Verifica que está en estado: **"running"**
4. Ve a AWS Console → RDS → Databases
5. Busca base de datos con nombre que contenga: `ecommerce`
6. Verifica que está en estado: **"available"**

**✅ Verificación:**
- Instancia EC2 corriendo
- Base de datos RDS disponible
- VPC creada correctamente

**⏱️ Tiempo:** 2 minutos

---

## 📊 Timeline Completo

```
Tiempo 0:00 → Configuración inicial (15-30 min)
  ├─ Configurar Secrets (5 min)
  └─ Configurar AWS (10-20 min)

Tiempo 0:30 → Push a main (1 min)
  └─ git push origin main

Tiempo 0:31 → Workflow se activa (30 seg)
  └─ Ver en GitHub Actions

Tiempo 0:32 → Job CI ejecutándose (2-5 min)
  ├─ Checkout código (20 seg)
  ├─ Instalar dependencias (60 seg)
  ├─ Ejecutar pruebas unitarias (30 seg) ← ⚠️ IMPORTANTE
  └─ ESLint (20 seg)

Tiempo 0:37 → Job Build ejecutándose (5-10 min)
  ├─ Login ECR (20 seg)
  ├─ Construir Docker (5 min) ← ⚠️ TOMA TIEMPO
  └─ Subir a ECR (2 min)

Tiempo 0:47 → Job Deploy ejecutándose (10-15 min)
  ├─ Terraform Init (60 seg)
  ├─ Terraform Plan (2 min)
  ├─ Terraform Apply (10 min) ← ⚠️ TOMA MÁS TIEMPO
  └─ Esperar aplicación (2 min)

Tiempo 1:02 → Aplicación lista ✅
  └─ Verificar en navegador (2 min)

TOTAL: ~30-35 minutos desde configuración hasta aplicación funcionando
```

---

## 🎯 Checklist de Verificación

Usa este checklist para asegurarte de que todo funciona:

### Configuración
- [ ] Secrets configurados en GitHub
- [ ] AWS IAM User creado
- [ ] Access Keys configuradas

### Primer Push
- [ ] Push completado sin errores
- [ ] Workflow aparece en GitHub Actions
- [ ] Workflow muestra "🟡 In progress"

### Job CI (2-5 min)
- [ ] Job CI se ejecuta
- [ ] Pruebas unitarias pasan (✅ PASS)
- [ ] ESLint pasa sin errores
- [ ] Job CI muestra "✅ completed successfully"

### Job Build (5-10 min)
- [ ] Job Build se ejecuta (solo si CI pasó)
- [ ] Docker build completa exitosamente
- [ ] Imagen se sube a ECR
- [ ] Imagen visible en AWS ECR Console

### Job Deploy (10-15 min)
- [ ] Job Deploy se ejecuta (solo si Build pasó)
- [ ] Terraform Plan muestra recursos a crear
- [ ] Terraform Apply completa exitosamente
- [ ] Output muestra URL de la aplicación

### Verificación Final
- [ ] URL de aplicación obtenida
- [ ] Aplicación carga en navegador
- [ ] Instancia EC2 corriendo en AWS
- [ ] Base de datos RDS disponible en AWS

---

## ⚠️ Problemas Comunes y Soluciones

### Problema 1: Job CI falla

**Síntomas:**
- ❌ Pruebas unitarias fallan
- ❌ ESLint encuentra errores

**Solución:**
```bash
# Ejecutar pruebas localmente primero
npm test
npx eslint . --max-warnings 0

# Corregir errores
# Hacer push nuevamente
```

**Tiempo adicional:** 5-10 minutos

---

### Problema 2: Job Build falla

**Síntomas:**
- ❌ Error de credenciales AWS
- ❌ Error al construir Docker

**Solución:**
- Verificar que `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` están correctos
- Verificar que el Dockerfile está correcto
- Revisar logs del job Build

**Tiempo adicional:** 10-15 minutos

---

### Problema 3: Job Deploy falla

**Síntomas:**
- ❌ Terraform Plan falla
- ❌ Terraform Apply falla
- ❌ Error de permisos AWS

**Solución:**
- Verificar permisos del IAM User
- Verificar que las variables de Terraform son correctas
- Revisar logs de Terraform

**Tiempo adicional:** 15-20 minutos

---

### Problema 4: Aplicación no responde

**Síntomas:**
- ✅ Deploy completa exitosamente
- ❌ URL no carga en navegador

**Solución:**
```bash
# Verificar que EC2 está corriendo
aws ec2 describe-instances --filters "Name=tag:Project,Values=ecommerce-quantum"

# Verificar Security Group permite puerto 3000
# Conectarse a EC2 y ver logs
ssh ubuntu@XX.XX.XX.XX
docker logs ecommerce-app
```

**Tiempo adicional:** 10-15 minutos

---

## 📈 Tiempos Esperados por Escenario

### Escenario 1: Todo funciona perfectamente
- **Configuración:** 20 minutos
- **Primer push:** 1 minuto
- **CI/CD completo:** 20 minutos
- **Verificación:** 5 minutos
- **Total:** ~45 minutos

### Escenario 2: Necesitas corregir errores
- **Configuración:** 20 minutos
- **Primer push:** 1 minuto
- **CI falla, corriges:** +10 minutos
- **Push nuevamente:** 1 minuto
- **CI/CD completo:** 20 minutos
- **Verificación:** 5 minutos
- **Total:** ~60 minutos

### Escenario 3: Problemas con AWS
- **Configuración:** 30 minutos (con troubleshooting)
- **Primer push:** 1 minuto
- **Build/Deploy falla:** +20 minutos troubleshooting
- **Push nuevamente:** 1 minuto
- **CI/CD completo:** 20 minutos
- **Verificación:** 5 minutos
- **Total:** ~75 minutos

---

## ✅ Conclusión

**Tiempo mínimo esperado:** 30-35 minutos desde configuración hasta aplicación funcionando

**Tiempo realista:** 45-60 minutos (incluyendo verificación y posibles correcciones)

**Qué verificar en cada paso:**
1. ✅ Workflow se activa
2. ✅ CI pasa (pruebas unitarias)
3. ✅ Build completa (imagen Docker)
4. ✅ Deploy completa (infraestructura creada)
5. ✅ Aplicación accesible

---

**💡 Tip:** Monitorea el workflow en tiempo real en GitHub Actions para ver el progreso de cada job y step.

