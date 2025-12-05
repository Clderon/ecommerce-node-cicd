terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend opcional - puedes usar S3 para almacenar el estado
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "ecommerce/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ecommerce-quantum"
      Environment = "temporary"
      ManagedBy   = "terraform"
    }
  }
}

# Data source para obtener la AMI más reciente de Ubuntu
# Usa un patrón simple que funciona en todas las regiones
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Locals para determinar qué AMI usar y generar identificadores únicos
locals {
  # Usar AMI específica si se proporciona, sino usar data source
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  
  # Identificador único para este despliegue (evita conflictos entre despliegues)
  unique_id = substr(md5(timestamp()), 0, 8)
}

# Data source para VPC por defecto (si no se especifica una VPC existente)
data "aws_vpc" "default" {
  count   = var.use_existing_vpc && var.existing_vpc_id == "" ? 1 : 0
  default = true
}

# Local para determinar VPC ID a usar (sin referencia circular)
locals {
  vpc_id_for_data = var.use_existing_vpc ? (
    var.existing_vpc_id != "" ? var.existing_vpc_id : (length(data.aws_vpc.default) > 0 ? data.aws_vpc.default[0].id : "")
  ) : ""
}

# Data source para buscar subnets en VPC existente
data "aws_subnets" "all" {
  count = var.use_existing_vpc && var.existing_subnet_id == "" && local.vpc_id_for_data != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.vpc_id_for_data]
  }
}

# Data source para subnet existente específica
data "aws_subnet" "existing" {
  count = var.use_existing_vpc && var.existing_subnet_id != "" ? 1 : 0
  id    = var.existing_subnet_id
}

# Local para determinar VPC ID y Subnet ID finales
locals {
  vpc_id = var.use_existing_vpc ? (
    var.existing_vpc_id != "" ? var.existing_vpc_id : (length(data.aws_vpc.default) > 0 ? data.aws_vpc.default[0].id : "")
  ) : (length(aws_vpc.ecommerce_vpc) > 0 ? aws_vpc.ecommerce_vpc[0].id : "")
  
  subnet_id = var.use_existing_vpc ? (
    var.existing_subnet_id != "" ? var.existing_subnet_id : (
      length(data.aws_subnets.all) > 0 && length(data.aws_subnets.all[0].ids) > 0 ? data.aws_subnets.all[0].ids[0] : ""
    )
  ) : (length(aws_subnet.ecommerce_public_subnet) > 0 ? aws_subnet.ecommerce_public_subnet[0].id : "")
}

# VPC para aislar la infraestructura temporal (solo si no se usa VPC existente)
resource "aws_vpc" "ecommerce_vpc" {
  count                = var.use_existing_vpc ? 0 : 1
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecommerce-temp-vpc"
  }
}

# Internet Gateway (solo si se crea nueva VPC)
resource "aws_internet_gateway" "ecommerce_igw" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.ecommerce_vpc[0].id

  tags = {
    Name = "ecommerce-temp-igw"
  }
}

# Subnet pública (solo si se crea nueva VPC)
resource "aws_subnet" "ecommerce_public_subnet" {
  count                   = var.use_existing_vpc ? 0 : 1
  vpc_id                  = aws_vpc.ecommerce_vpc[0].id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-temp-public-subnet"
  }
}

# Nota: Subnets privadas eliminadas ya que MySQL corre en Docker dentro del mismo EC2

# Data source para availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table para subnet pública (solo si se crea nueva VPC)
resource "aws_route_table" "ecommerce_public_rt" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.ecommerce_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecommerce_igw[0].id
  }

  tags = {
    Name = "ecommerce-temp-public-rt"
  }
}

resource "aws_route_table_association" "ecommerce_public_rta" {
  count          = var.use_existing_vpc ? 0 : 1
  subnet_id      = aws_subnet.ecommerce_public_subnet[0].id
  route_table_id = aws_route_table.ecommerce_public_rt[0].id
}

# Security Group para EC2
resource "aws_security_group" "ecommerce_ec2_sg" {
  name        = "ecommerce-ec2-sg-${local.unique_id}"
  description = "Security group for Ecommerce EC2 instance"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Application Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # En producción, restringir a IPs específicas
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-ec2-sg"
  }
}

# Nota: RDS eliminado - MySQL ahora corre en Docker dentro del mismo EC2

# Key Pair para EC2 (usando clave existente o creando nueva)
resource "aws_key_pair" "ecommerce_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "ecommerce-key-${local.unique_id}"
  public_key = var.ec2_public_key

  tags = {
    Name = "ecommerce-temp-key"
  }
}

# IAM Role para EC2
resource "aws_iam_role" "ecommerce_ec2_role" {
  name = "ecommerce-ec2-role-${local.unique_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ecommerce-ec2-role"
  }
}

resource "aws_iam_instance_profile" "ecommerce_ec2_profile" {
  name = "ecommerce-ec2-profile-${local.unique_id}"
  role = aws_iam_role.ecommerce_ec2_role.name
}

# EC2 Instance
resource "aws_instance" "ecommerce_app" {
  # Usar AMI del data source (búsqueda automática)
  ami                    = local.ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.create_key_pair ? aws_key_pair.ecommerce_key[0].key_name : var.existing_key_name
  vpc_security_group_ids = [aws_security_group.ecommerce_ec2_sg.id]
  subnet_id              = local.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ecommerce_ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host     = "localhost"  # MySQL corre en Docker dentro del mismo EC2
    db_user     = var.db_username
    db_password = var.db_password
    db_name     = var.db_name
    app_port    = var.app_port
    docker_image = var.docker_image
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "ecommerce-app-instance"
  }
}

# Elastic IP para EC2 (opcional, para IP fija)
resource "aws_eip" "ecommerce_eip" {
  count  = var.allocate_eip ? 1 : 0
  domain = "vpc"
  instance = aws_instance.ecommerce_app.id

  tags = {
    Name = "ecommerce-app-eip"
  }
}

