variable "aws_region" {
  description = "AWS region para desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "use_existing_vpc" {
  description = "Usar VPC existente en lugar de crear una nueva"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "ID de VPC existente (si use_existing_vpc es true). Si está vacío, usa la VPC por defecto"
  type        = string
  default     = ""
}

variable "existing_subnet_id" {
  description = "ID de subnet existente (si use_existing_vpc es true). Si está vacío, busca una subnet pública"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC (solo si use_existing_vpc es false)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block para la subnet pública (solo si use_existing_vpc es false)"
  type        = string
  default     = "10.0.1.0/24"
}

# Nota: Variables de subnets privadas eliminadas (ya no necesarias sin RDS)

variable "ec2_instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

# Nota: Variables de RDS eliminadas (MySQL ahora corre en Docker)

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "equantom"
  sensitive   = true
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}

variable "app_port" {
  description = "Puerto de la aplicación"
  type        = number
  default     = 3000
}

variable "docker_image" {
  description = "Imagen Docker a desplegar (formato: registry/image:tag)"
  type        = string
}

variable "create_key_pair" {
  description = "Crear un nuevo key pair para EC2"
  type        = bool
  default     = false
}

variable "existing_key_name" {
  description = "Nombre del key pair existente (si create_key_pair es false)"
  type        = string
  default     = ""
}

variable "ec2_public_key" {
  description = "Clave pública SSH para el key pair (si create_key_pair es true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allocate_eip" {
  description = "Asignar Elastic IP a la instancia EC2"
  type        = bool
  default     = false
}

variable "ami_id" {
  description = "AMI ID específica para EC2 (opcional, si no se especifica se busca automáticamente)"
  type        = string
  default     = ""
  
  # AMIs conocidas por región (usar si el data source falla):
  # us-east-1: ami-0c55b159cbfafe1f0 (Ubuntu 22.04 LTS)
  # us-west-2: ami-0c55b159cbfafe1f0
  # eu-west-1: ami-0c55b159cbfafe1f0
}

