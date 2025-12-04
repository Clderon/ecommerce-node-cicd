# Guía de Despliegue - CI/CD con Infraestructura Temporal

Este documento describe el flujo completo de CI/CD con infraestructura temporal usando Terraform y AWS.

## 📋 Flujo de Trabajo

```
1. Desarrollador hace cambios → git push a GitHub
            │
            ▼
2. GitHub Actions inicia CI:
   - Instala dependencias
   - Ejecuta pruebas
   - Verifica estilo con ESLint
            │  (si todo pasa)
            ▼
3. Build construye imagen Docker:
   - Construye imagen desde Dockerfile
   - Sube imagen a Amazon ECR
            │
            ▼
4. CD ejecuta Terraform:
   - Crea infraestructura temporal (VPC, EC2, RDS)
   - Configura red, seguridad, roles
   - Despliega contenedor en EC2
            │
            ▼
5. App queda funcionando en la nube
   - Se usa mientras haya tráfico o mientras se necesite
            │
            ▼
6. Al finalizar uso o nuevo release:
   - Terraform destruye infraestructura
   - Solo quedan artefactos en ECR
```

## 🔧 Configuración Inicial

### 1. Secrets en GitHub

Configura los siguientes secrets en tu repositorio de GitHub (Settings → Secrets and variables → Actions):

#### AWS Credentials
- `AWS_ACCESS_KEY_ID`: Tu Access Key ID de AWS
- `AWS_SECRET_ACCESS_KEY`: Tu Secret Access Key de AWS

#### Database Credentials
- `DB_PASSWORD`: Contraseña para la base de datos MySQL
- `DB_USERNAME`: Usuario de la base de datos (default: `admin`)
- `DB_NAME`: Nombre de la base de datos (default: `equantom`)

### 2. Configurar AWS

#### Crear IAM User para CI/CD

1. Ve a AWS Console → IAM → Users → Create User
2. Nombre: `github-actions-ci-cd`
3. Permisos necesarios:
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
           "iam:PassRole"
         ],
         "Resource": "*"
       }
     ]
   }
   ```
4. Crea Access Keys y guárdalas como secrets en GitHub

#### Crear ECR Repository

El workflow creará automáticamente el repositorio ECR si no existe, pero puedes crearlo manualmente:

```bash
aws ecr create-repository --repository-name ecommerce-quantum --region us-east-1
```

### 3. Configurar Terraform (Opcional para uso local)

Si deseas probar Terraform localmente:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars con tus valores
terraform init
terraform plan
```

## 🚀 Uso del Flujo CI/CD

### Despliegue Automático

Cada push a la rama `main` activará automáticamente:

1. **CI**: Pruebas y validaciones
2. **Build**: Construcción de imagen Docker
3. **Deploy**: Creación de infraestructura y despliegue

### Destruir Infraestructura

#### Opción 1: Workflow Manual

1. Ve a Actions → CI/CD with Temporary Infrastructure
2. Click en "Run workflow"
3. Marca la casilla "Destroy infrastructure after deployment"
4. Click en "Run workflow"

#### Opción 2: Commit con mensaje especial

Haz un commit con el mensaje que contenga `[destroy]`:

```bash
git commit -m "Update: [destroy] Finalizar despliegue temporal"
git push origin main
```

#### Opción 3: Script Local

```bash
chmod +x scripts/destroy-infrastructure.sh
./scripts/destroy-infrastructure.sh
```

## 📊 Monitoreo

### Ver Estado del Despliegue

1. Ve a GitHub Actions en tu repositorio
2. Selecciona el workflow "CI/CD with Temporary Infrastructure"
3. Revisa los logs de cada job

### Acceder a la Aplicación

Después del despliegue exitoso, la URL estará disponible en:
- GitHub Actions → Deploy job → Outputs → `application_url`
- O en el environment "temporary-infrastructure"

### Ver Logs de la Aplicación

Conecta vía SSH a la instancia EC2:

```bash
# Obtén el comando SSH del output de Terraform
terraform output -raw ssh_command

# O conecta manualmente
ssh -i <tu-key.pem> ubuntu@<ec2-public-ip>

# Ver logs del contenedor
docker logs ecommerce-app -f
```

## 🔍 Troubleshooting

### La aplicación no responde

1. Verifica que el Security Group permita tráfico en el puerto 3000
2. Revisa los logs del contenedor: `docker logs ecommerce-app`
3. Verifica que RDS esté disponible: `nc -z <rds-endpoint> 3306`

### Error de conexión a RDS

1. Verifica que el Security Group de RDS permita conexiones desde el Security Group de EC2
2. Verifica que las credenciales sean correctas
3. Revisa los logs del user-data script en EC2

### Terraform falla al crear recursos

1. Verifica que las credenciales AWS sean correctas
2. Verifica que tengas permisos suficientes en AWS
3. Revisa los límites de tu cuenta AWS (número de instancias, VPCs, etc.)

### La imagen Docker no se construye

1. Verifica que el Dockerfile esté correcto
2. Revisa los logs del job "Build Docker Image"
3. Verifica que ECR esté configurado correctamente

## 💰 Gestión de Costos

### Monitorear Costos

1. Ve a AWS Console → Cost Explorer
2. Filtra por tags: `Project = ecommerce-quantum`
3. Configura alertas de costo si es necesario

### Reducir Costos

- Usa instancias más pequeñas (`t3.micro`, `db.t3.micro`)
- Destruye la infraestructura cuando no la uses
- Considera usar Spot Instances para EC2 (requiere cambios en Terraform)

## 🔐 Seguridad

### Mejores Prácticas

1. **Nunca commitees** archivos con credenciales
2. Usa **secrets de GitHub** para información sensible
3. **Rota las credenciales** regularmente
4. **Restringe Security Groups** a IPs específicas en producción
5. Usa **HTTPS** en producción (requiere Load Balancer y certificado SSL)

### Hardening Adicional

- Usa AWS Secrets Manager en lugar de variables de entorno
- Habilita VPC Flow Logs para auditoría
- Usa AWS WAF para protección adicional
- Implementa backup automático de RDS antes de destruir

## 📚 Recursos Adicionales

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Amazon ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

