# Comandos de Diagnóstico para EC2

## Conectarse a la instancia EC2

```bash
# Obtener IP pública de la instancia
terraform output ec2_public_ip

# Conectarse por SSH (reemplazar con tu key)
ssh -i tu-key.pem ubuntu@<IP_PUBLICA>
```

## Comandos de Diagnóstico Rápido

### 1. Verificar estado de Docker y contenedores

```bash
# Ver todos los contenedores
docker ps -a

# Ver solo contenedores corriendo
docker ps

# Ver logs de la aplicación
docker logs ecommerce-app --tail 100

# Ver logs de MySQL
docker logs ecommerce-mysql --tail 50

# Ver logs en tiempo real
docker logs -f ecommerce-app
```

### 2. Verificar red Docker

```bash
# Listar redes
docker network ls

# Inspeccionar red
docker network inspect ecommerce-network

# Verificar conectividad entre contenedores
docker exec ecommerce-app ping -c 2 ecommerce-mysql
```

### 3. Verificar MySQL

```bash
# Verificar que MySQL esté corriendo
docker exec ecommerce-mysql mysqladmin ping -h localhost

# Conectarse a MySQL
docker exec -it ecommerce-mysql mysql -uadmin -padmin equantom

# Dentro de MySQL, ejecutar:
SHOW DATABASES;
USE equantom;
SHOW TABLES;
SELECT * FROM categories;
SELECT * FROM products;
SELECT * FROM users;
```

### 4. Verificar aplicación

```bash
# Ver variables de entorno del contenedor
docker exec ecommerce-app env | grep -E "DB_|PORT|HOST"

# Verificar que el puerto esté mapeado
docker port ecommerce-app

# Probar health check desde dentro del contenedor
docker exec ecommerce-app curl http://localhost:3000/health

# Probar health check desde el host
curl http://localhost:3000/health

# Verificar puerto en el host
netstat -tlnp | grep 3000
# o
ss -tlnp | grep 3000
```

### 5. Verificar conectividad

```bash
# Probar conexión a MySQL desde la aplicación
docker exec ecommerce-app nc -zv ecommerce-mysql 3306

# Probar conexión a MySQL desde el host
nc -zv localhost 3306

# Verificar IP pública
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Probar desde fuera (reemplazar con IP pública)
curl http://<IP_PUBLICA>:3000/health
```

### 6. Verificar archivos de configuración

```bash
# Ver archivo .env
cat /opt/ecommerce/.env

# Ver contenido del directorio
ls -la /opt/ecommerce/

# Ver datos de MySQL
ls -la /opt/mysql-data/
```

### 7. Reiniciar servicios

```bash
# Reiniciar aplicación
docker restart ecommerce-app

# Reiniciar MySQL
docker restart ecommerce-mysql

# Reiniciar ambos
docker restart ecommerce-app ecommerce-mysql

# Ver estado después de reiniciar
docker ps
```

### 8. Entrar a los contenedores

```bash
# Entrar al contenedor de la aplicación
docker exec -it ecommerce-app sh

# Dentro del contenedor de la app:
env | grep DB_
curl http://localhost:3000/health
ping ecommerce-mysql

# Entrar al contenedor MySQL
docker exec -it ecommerce-mysql bash

# Conectarse a MySQL directamente
docker exec -it ecommerce-mysql mysql -uadmin -padmin equantom
```

### 9. Verificar logs del sistema

```bash
# Ver logs de cloud-init (user-data)
sudo cat /var/log/cloud-init-output.log | tail -100

# Ver logs del sistema
sudo journalctl -u docker -n 50

# Ver logs de syslog relacionados con Docker
sudo grep docker /var/log/syslog | tail -20
```

### 10. Script de diagnóstico completo

```bash
# Copiar el script a la instancia
# (Desde tu máquina local, después de conectarte por SSH)
# O crear el script directamente en la instancia:

cat > /tmp/diagnostico.sh << 'EOF'
#!/bin/bash
echo "=== DIAGNÓSTICO ==="
echo "Docker version:"
docker --version
echo ""
echo "Contenedores:"
docker ps -a
echo ""
echo "Red Docker:"
docker network ls
echo ""
echo "Logs aplicación (últimas 20 líneas):"
docker logs ecommerce-app --tail 20 2>&1
echo ""
echo "Logs MySQL (últimas 20 líneas):"
docker logs ecommerce-mysql --tail 20 2>&1
echo ""
echo "Variables de entorno:"
docker exec ecommerce-app env | grep -E "DB_|PORT|HOST" 2>&1
echo ""
echo "Health check:"
curl -f http://localhost:3000/health 2>&1 || echo "Health check falló"
EOF

chmod +x /tmp/diagnostico.sh
/tmp/diagnostico.sh
```

## Solución de Problemas Comunes

### La aplicación no responde

```bash
# 1. Verificar que el contenedor esté corriendo
docker ps | grep ecommerce-app

# 2. Ver logs de errores
docker logs ecommerce-app --tail 100

# 3. Verificar variables de entorno
docker exec ecommerce-app env | grep DB_

# 4. Verificar conectividad a MySQL
docker exec ecommerce-app ping ecommerce-mysql
docker exec ecommerce-app nc -zv ecommerce-mysql 3306

# 5. Verificar puerto
docker port ecommerce-app
netstat -tlnp | grep 3000
```

### MySQL no está disponible

```bash
# 1. Verificar que MySQL esté corriendo
docker ps | grep ecommerce-mysql

# 2. Ver logs
docker logs ecommerce-mysql --tail 50

# 3. Probar conexión
docker exec ecommerce-mysql mysqladmin ping -h localhost

# 4. Verificar datos
ls -la /opt/mysql-data/
```

### Problemas de conectividad

```bash
# Verificar red Docker
docker network inspect ecommerce-network

# Verificar que ambos contenedores estén en la misma red
docker inspect ecommerce-app | grep NetworkMode
docker inspect ecommerce-mysql | grep NetworkMode

# Probar ping entre contenedores
docker exec ecommerce-app ping -c 2 ecommerce-mysql
```

## Comandos de Reparación

### Recrear contenedores

```bash
# Detener y eliminar contenedores
docker stop ecommerce-app ecommerce-mysql
docker rm ecommerce-app ecommerce-mysql

# Recrear red (si es necesario)
docker network rm ecommerce-network
docker network create ecommerce-network

# Volver a ejecutar user-data manualmente
# (o reiniciar la instancia)
```

### Verificar y corregir .env

```bash
# Ver archivo .env actual
cat /opt/ecommerce/.env

# Crear/actualizar .env manualmente
cat > /opt/ecommerce/.env << EOF
DB_HOST=ecommerce-mysql
DB_USER=admin
DB_PASSWORD=<tu_password>
DB_NAME=equantom
PORT=3000
HOST=0.0.0.0
SESSION_SECRET=$(openssl rand -hex 32)
EOF

# Reiniciar contenedor de aplicación
docker restart ecommerce-app
```

