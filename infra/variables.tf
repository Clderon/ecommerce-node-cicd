variable "aws_region" {
  description = "AWS region para desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block para la subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_1" {
  description = "CIDR block para la primera subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_2" {
  description = "CIDR block para la segunda subnet privada"
  type        = string
  default     = "10.0.3.0/24"
}

variable "ec2_instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Almacenamiento asignado para RDS (GB)"
  type        = number
  default     = 20
}

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

