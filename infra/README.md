# Infraestructura Temporal con Terraform

Este directorio contiene la configuración de Terraform para crear infraestructura temporal en AWS que se destruye automáticamente después del despliegue.

## Arquitectura

La infraestructura incluye:

- **VPC**: Red virtual aislada con subnets públicas y privadas
- **EC2**: Instancia para ejecutar la aplicación containerizada
- **RDS MySQL**: Base de datos MySQL en subnets privadas
- **Security Groups**: Reglas de firewall para seguridad
- **Internet Gateway**: Para acceso público a la aplicación

## Requisitos Previos

1. **AWS CLI** configurado con credenciales
2. **Terraform** >= 1.5.0 instalado
3. **Credenciales AWS** configuradas como secrets en GitHub Actions:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DB_PASSWORD`
   - `DB_USERNAME`
   - `DB_NAME`

## Configuración

1. Copia el archivo de ejemplo de variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edita `terraform.tfvars` con tus valores:
   ```hcl
   aws_region = "us-east-1"
   db_password = "tu-contraseña-segura"
   docker_image = "tu-ecr-repo/ecommerce-quantum:latest"
   ```

## Uso Manual

### Crear infraestructura

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### Destruir infraestructura

```bash
terraform destroy
```

O usar el script:

```bash
./scripts/destroy-infrastructure.sh
```

## Variables Principales

| Variable | Descripción | Default |
|----------|-------------|---------|
| `aws_region` | Región de AWS | `us-east-1` |
| `ec2_instance_type` | Tipo de instancia EC2 | `t3.micro` |
| `db_instance_class` | Clase de instancia RDS | `db.t3.micro` |
| `docker_image` | Imagen Docker a desplegar | Requerido |
| `db_password` | Contraseña de la base de datos | Requerido |

## Outputs

Después de `terraform apply`, obtendrás:

- `application_url`: URL pública de la aplicación
- `ec2_instance_id`: ID de la instancia EC2
- `rds_endpoint`: Endpoint de la base de datos RDS
- `ssh_command`: Comando para conectarse vía SSH

## Notas Importantes

⚠️ **Infraestructura Temporal**: Esta configuración está diseñada para infraestructura temporal que se destruye después del uso. Los datos en RDS se perderán al destruir la infraestructura.

💡 **Persistencia de Datos**: Si necesitas persistir datos, considera usar:
- S3 para backups de base de datos
- RDS Snapshots antes de destruir
- Almacenamiento externo para artefactos

## Costos

La infraestructura incluye:
- EC2 t3.micro: ~$0.0104/hora
- RDS db.t3.micro: ~$0.017/hora
- Transferencia de datos: Variable

**Total aproximado**: ~$0.65/día si está corriendo 24/7

