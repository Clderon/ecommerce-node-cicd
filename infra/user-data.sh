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
# IMPORTANTE: DB_HOST debe ser el nombre del contenedor MySQL en la red Docker
cat > .env <<EOF
DB_HOST=ecommerce-mysql
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
PORT=${app_port}
HOST=0.0.0.0
SESSION_SECRET=$(openssl rand -hex 32)
EOF

echo "📝 Variables de entorno configuradas:"
echo "   DB_HOST=ecommerce-mysql (nombre del contenedor MySQL)"
echo "   DB_USER=${db_user}"
echo "   DB_NAME=${db_name}"
echo "   PORT=${app_port}"

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
echo "🚀 Iniciando contenedor de la aplicación..."
docker run -d \
  --name ecommerce-app \
  --restart unless-stopped \
  --network ecommerce-network \
  -p 0.0.0.0:${app_port}:${app_port} \
  --env-file .env \
  ${docker_image}

echo "✅ Contenedor iniciado, verificando mapeo de puertos..."
docker port ecommerce-app || echo "⚠️ No se puede verificar mapeo de puertos"

# Esperar a que el contenedor esté corriendo
echo "⏳ Esperando a que el contenedor inicie (puede tardar hasta 30 segundos)..."
sleep 10

# Verificar que el contenedor esté iniciando
for i in {1..6}; do
  if docker ps -a | grep -q ecommerce-app; then
    CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' ecommerce-app 2>/dev/null || echo "unknown")
    echo "   Estado del contenedor: $CONTAINER_STATUS"
    if [ "$CONTAINER_STATUS" = "running" ]; then
      echo "✅ Contenedor está corriendo"
      break
    fi
  fi
  echo "   Esperando... ($i/6)"
  sleep 5
done

# Verificar que el contenedor esté corriendo
echo "🔍 Verificando estado del contenedor..."
for i in {1..12}; do
  if docker ps | grep -q ecommerce-app; then
    echo "✅ Contenedor corriendo"
    # Verificar que el contenedor no esté en estado de error
    CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' ecommerce-app 2>/dev/null || echo "unknown")
    if [ "$CONTAINER_STATUS" != "running" ]; then
      echo "⚠️ Contenedor en estado: $CONTAINER_STATUS"
    fi
    break
  fi
  echo "Intento $i/12: Contenedor aún no está corriendo..."
  sleep 5
done

# Verificar conectividad entre contenedores
echo "🔍 Verificando conectividad entre contenedores..."
docker exec ecommerce-app ping -c 2 ecommerce-mysql > /dev/null 2>&1 && echo "✅ Aplicación puede alcanzar MySQL" || echo "⚠️ Problema de conectividad con MySQL"

# Logs para debugging
echo "=== Logs del contenedor de la aplicación ==="
docker logs ecommerce-app --tail 100 || true

# Verificar que el puerto esté expuesto correctamente
echo "🔍 Verificando puerto ${app_port}..."
netstat -tlnp | grep ":${app_port}" || ss -tlnp | grep ":${app_port}" || echo "⚠️ Puerto ${app_port} no está escuchando"

# Esperar a que la aplicación responda (health check)
echo "Esperando a que la aplicación responda..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
HEALTH_URL="http://localhost:${app_port}/health"
APP_URL="http://$${PUBLIC_IP}:${app_port}"

for i in {1..30}; do
  if curl -f -s --max-time 3 "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ Aplicación respondiendo en intento $i/30"
    # Verificar respuesta del health check
    curl -s "$HEALTH_URL" | head -5
    break
  fi
  
  # Mostrar diagnóstico cada 5 intentos
  if [ $((i % 5)) -eq 0 ]; then
    echo ""
    echo "🔍 Diagnóstico (intento $i/30):"
    echo "   - Estado del contenedor:"
    docker ps -a | grep ecommerce-app || echo "     Contenedor no encontrado"
    echo "   - Últimos logs del contenedor:"
    docker logs ecommerce-app --tail 20 2>&1 | tail -5 || echo "     No se pueden obtener logs"
    echo "   - Verificando puerto:"
    docker port ecommerce-app 2>&1 || echo "     No se puede verificar puerto"
    echo ""
  fi
  
  if [ $i -eq 30 ]; then
    echo "⚠️ La aplicación no respondió después de 30 intentos"
    echo ""
    echo "=== Diagnóstico completo ==="
    echo "Estado del contenedor:"
    docker ps -a | grep ecommerce-app || echo "Contenedor no encontrado"
    echo ""
    echo "Logs completos del contenedor:"
    docker logs ecommerce-app --tail 200 2>&1 || echo "No se pueden obtener logs"
    echo ""
    echo "Verificando conectividad a MySQL desde el contenedor:"
    docker exec ecommerce-app ping -c 2 ecommerce-mysql 2>&1 || echo "No se puede hacer ping a MySQL"
    echo ""
    echo "Verificando variables de entorno:"
    docker exec ecommerce-app env | grep -E "DB_|PORT|HOST" || echo "No se pueden obtener variables de entorno"
  fi
  sleep 2
done

echo "Aplicación desplegada en $${APP_URL}"
echo "Health check disponible en $${APP_URL}/health"

