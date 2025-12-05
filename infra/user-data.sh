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
mkdir -p /opt/mysql-data
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

# Levantar MySQL en Docker
echo "🚀 Iniciando MySQL en Docker..."
docker pull mysql:8.0

# Detener contenedor MySQL existente si existe
docker stop ecommerce-mysql || true
docker rm ecommerce-mysql || true

# Crear red Docker para conectar contenedores
docker network create ecommerce-network || true

# Iniciar MySQL con volumen persistente
docker run -d \
  --name ecommerce-mysql \
  --restart unless-stopped \
  --network ecommerce-network \
  -e MYSQL_ROOT_PASSWORD=${db_password} \
  -e MYSQL_DATABASE=${db_name} \
  -e MYSQL_USER=${db_user} \
  -e MYSQL_PASSWORD=${db_password} \
  -v /opt/mysql-data:/var/lib/mysql \
  -p 127.0.0.1:3306:3306 \
  mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci

# Esperar a que MySQL esté disponible
echo "⏳ Esperando a que MySQL esté disponible..."
for i in {1..60}; do
  if docker exec ecommerce-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
    echo "✅ MySQL está disponible"
    break
  fi
  echo "Intento $i/60: MySQL no disponible aún, esperando 5 segundos..."
  sleep 5
done

# Verificar que MySQL esté realmente listo
echo "🔍 Verificando conexión a MySQL..."
for i in {1..10}; do
  if docker exec ecommerce-mysql mysql -u${db_user} -p${db_password} -e "SELECT 1;" ${db_name} 2>/dev/null; then
    echo "✅ MySQL está listo"
    break
  fi
  echo "Intento $i/10: Esperando que MySQL esté completamente listo..."
  sleep 3
done

# Crear tablas básicas si no existen
echo "📥 Creando schema de base de datos..."
docker exec ecommerce-mysql mysql -u${db_user} -p${db_password} ${db_name} <<'EOF' || echo "⚠️ Error creando tablas (puede que ya existan)"
CREATE TABLE IF NOT EXISTS `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `rating` decimal(2,1) NOT NULL,
  `price` decimal(6,2) NOT NULL,
  `img_url` varchar(255) NOT NULL,
  `category` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category`) REFERENCES `categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `role` varchar(50) DEFAULT 'user',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF

echo "✅ Schema de base de datos creado"

# Descargar e iniciar contenedor Docker
docker pull ${docker_image}

# Detener contenedor existente si existe
docker stop ecommerce-app || true
docker rm ecommerce-app || true

# Iniciar nuevo contenedor de la aplicación (conectado a la misma red que MySQL)
docker run -d \
  --name ecommerce-app \
  --restart unless-stopped \
  --network ecommerce-network \
  -p ${app_port}:${app_port} \
  --env-file .env \
  ${docker_image}

# Esperar a que el contenedor esté corriendo
echo "Esperando a que el contenedor inicie..."
sleep 5

# Verificar que el contenedor esté corriendo
for i in {1..12}; do
  if docker ps | grep -q ecommerce-app; then
    echo "✅ Contenedor corriendo"
    break
  fi
  echo "Intento $i/12: Contenedor aún no está corriendo..."
  sleep 5
done

# Logs para debugging
echo "=== Logs del contenedor ==="
docker logs ecommerce-app --tail 50 || true

# Esperar a que la aplicación responda (health check)
echo "Esperando a que la aplicación responda..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
HEALTH_URL="http://localhost:${app_port}/health"
APP_URL="http://$${PUBLIC_IP}:${app_port}"

for i in {1..30}; do
  if curl -f -s --max-time 3 "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ Aplicación respondiendo en intento $i/30"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠️ La aplicación no respondió después de 30 intentos"
    echo "Logs del contenedor:"
    docker logs ecommerce-app --tail 100 || true
  fi
  sleep 2
done

echo "Aplicación desplegada en $${APP_URL}"
echo "Health check disponible en $${APP_URL}/health"

