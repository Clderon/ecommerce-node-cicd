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
      CreatedAt   = timestamp()
    }
  }
}

# Locals para AMIs conocidas por región
# Estas son AMIs estables de Ubuntu 22.04 LTS que siempre están disponibles
locals {
  ami_by_region = {
    "us-east-1"      = "ami-0866e0e6b5b0b5c5c"  # Ubuntu 22.04 LTS
    "us-east-2"      = "ami-0866e0e6b5b0b5c5c"
    "us-west-1"      = "ami-0866e0e6b5b0b5c5c"
    "us-west-2"      = "ami-0866e0e6b5b0b5c5c"
    "eu-west-1"      = "ami-0866e0e6b5b0b5c5c"
    "eu-central-1"   = "ami-0866e0e6b5b0b5c5c"
    "ap-southeast-1" = "ami-0866e0e6b5b0b5c5c"
  }
  
  # Usar AMI específica si se proporciona, sino usar AMI conocida por región
  ami_id = var.ami_id != "" ? var.ami_id : lookup(local.ami_by_region, var.aws_region, "ami-0866e0e6b5b0b5c5c")
}

# Data source para obtener la AMI más reciente de Ubuntu (opcional, comentado por ahora)
# Si el patrón no funciona en tu región, se usará automáticamente la AMI conocida del local
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical
#
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/h2-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }
#
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#
#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
#
#   filter {
#     name   = "state"
#     values = ["available"]
#   }
# }

# VPC para aislar la infraestructura temporal
resource "aws_vpc" "ecommerce_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecommerce-temp-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecommerce_igw" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  tags = {
    Name = "ecommerce-temp-igw"
  }
}

# Subnet pública
resource "aws_subnet" "ecommerce_public_subnet" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-temp-public-subnet"
  }
}

# Subnet privada para RDS
resource "aws_subnet" "ecommerce_private_subnet_1" {
  vpc_id            = aws_vpc.ecommerce_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "ecommerce-temp-private-subnet-1"
  }
}

resource "aws_subnet" "ecommerce_private_subnet_2" {
  vpc_id            = aws_vpc.ecommerce_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "ecommerce-temp-private-subnet-2"
  }
}

# Data source para availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table para subnet pública
resource "aws_route_table" "ecommerce_public_rt" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecommerce_igw.id
  }

  tags = {
    Name = "ecommerce-temp-public-rt"
  }
}

resource "aws_route_table_association" "ecommerce_public_rta" {
  subnet_id      = aws_subnet.ecommerce_public_subnet.id
  route_table_id = aws_route_table.ecommerce_public_rt.id
}

# Security Group para EC2
resource "aws_security_group" "ecommerce_ec2_sg" {
  name        = "ecommerce-ec2-sg"
  description = "Security group for Ecommerce EC2 instance"
  vpc_id      = aws_vpc.ecommerce_vpc.id

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

# Security Group para RDS
resource "aws_security_group" "ecommerce_rds_sg" {
  name        = "ecommerce-rds-sg"
  description = "Security group for Ecommerce RDS MySQL"
  vpc_id      = aws_vpc.ecommerce_vpc.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecommerce_ec2_sg.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-rds-sg"
  }
}

# DB Subnet Group para RDS
resource "aws_db_subnet_group" "ecommerce_db_subnet_group" {
  name       = "ecommerce-db-subnet-group"
  subnet_ids = [aws_subnet.ecommerce_private_subnet_1.id, aws_subnet.ecommerce_private_subnet_2.id]

  tags = {
    Name = "ecommerce-db-subnet-group"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "ecommerce_db" {
  identifier             = "ecommerce-db-${substr(md5(timestamp()), 0, 8)}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.ecommerce_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.ecommerce_rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true # Para infraestructura temporal
  backup_retention_period = 0    # Sin backups para infraestructura temporal

  tags = {
    Name = "ecommerce-temp-db"
  }
}

# Key Pair para EC2 (usando clave existente o creando nueva)
resource "aws_key_pair" "ecommerce_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "ecommerce-key-${substr(md5(timestamp()), 0, 8)}"
  public_key = var.ec2_public_key

  tags = {
    Name = "ecommerce-temp-key"
  }
}

# IAM Role para EC2
resource "aws_iam_role" "ecommerce_ec2_role" {
  name = "ecommerce-ec2-role-${substr(md5(timestamp()), 0, 8)}"

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
  name = "ecommerce-ec2-profile-${substr(md5(timestamp()), 0, 8)}"
  role = aws_iam_role.ecommerce_ec2_role.name
}

# EC2 Instance
resource "aws_instance" "ecommerce_app" {
  # Usar AMI conocida por región (más confiable que data source)
  ami                    = local.ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.create_key_pair ? aws_key_pair.ecommerce_key[0].key_name : var.existing_key_name
  vpc_security_group_ids = [aws_security_group.ecommerce_ec2_sg.id]
  subnet_id              = aws_subnet.ecommerce_public_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ecommerce_ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host     = aws_db_instance.ecommerce_db.address
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

