#!/bin/bash
set -e

# Actualizar sistema
apt-get update -y
apt-get upgrade -y

# Instalar Docker
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Agregar usuario ubuntu al grupo docker
usermod -aG docker ubuntu

# Iniciar Docker
systemctl start docker
systemctl enable docker

# Esperar a que Docker esté listo
sleep 10

# Crear directorio para la aplicación
mkdir -p /opt/ecommerce
cd /opt/ecommerce

# Crear archivo .env con variables de entorno
cat > .env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
PORT=${app_port}
HOST=0.0.0.0
SESSION_SECRET=$(openssl rand -hex 32)
EOF

# Esperar a que RDS esté disponible (máximo 5 minutos)
echo "Esperando a que RDS esté disponible..."
for i in {1..60}; do
  if nc -z ${db_host} 3306; then
    echo "RDS está disponible"
    break
  fi
  echo "Intento $i/60: RDS no disponible aún, esperando 5 segundos..."
  sleep 5
done

# Descargar e iniciar contenedor Docker
docker pull ${docker_image}

# Detener contenedor existente si existe
docker stop ecommerce-app || true
docker rm ecommerce-app || true

# Iniciar nuevo contenedor
docker run -d \
  --name ecommerce-app \
  --restart unless-stopped \
  -p ${app_port}:${app_port} \
  --env-file .env \
  ${docker_image}

# Logs para debugging
docker logs ecommerce-app

echo "Aplicación desplegada exitosamente en http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):${app_port}"

