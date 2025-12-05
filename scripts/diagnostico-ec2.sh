#!/bin/bash
# Script de diagnóstico para ejecutar dentro de la instancia EC2
# Uso: bash diagnostico-ec2.sh

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO DE LA INSTANCIA EC2"
echo "=========================================="
echo ""

# 1. Verificar Docker
echo "1️⃣ VERIFICANDO DOCKER..."
echo "----------------------------------------"
docker --version
docker ps -a
echo ""

# 2. Verificar red Docker
echo "2️⃣ VERIFICANDO RED DOCKER..."
echo "----------------------------------------"
docker network ls
docker network inspect ecommerce-network 2>/dev/null || echo "⚠️ Red ecommerce-network no existe"
echo ""

# 3. Verificar contenedor MySQL
echo "3️⃣ VERIFICANDO CONTENEDOR MYSQL..."
echo "----------------------------------------"
docker ps -a | grep ecommerce-mysql || echo "⚠️ Contenedor MySQL no encontrado"
if docker ps | grep -q ecommerce-mysql; then
    echo "✅ MySQL está corriendo"
    echo "Estado:"
    docker inspect -f '{{.State.Status}}' ecommerce-mysql
    echo ""
    echo "Últimos logs de MySQL:"
    docker logs ecommerce-mysql --tail 20
    echo ""
    echo "Verificando conexión a MySQL:"
    docker exec ecommerce-mysql mysqladmin ping -h localhost --silent && echo "✅ MySQL responde" || echo "⚠️ MySQL no responde"
else
    echo "⚠️ MySQL NO está corriendo"
fi
echo ""

# 4. Verificar contenedor de la aplicación
echo "4️⃣ VERIFICANDO CONTENEDOR DE LA APLICACIÓN..."
echo "----------------------------------------"
docker ps -a | grep ecommerce-app || echo "⚠️ Contenedor de aplicación no encontrado"
if docker ps | grep -q ecommerce-app; then
    echo "✅ Aplicación está corriendo"
    echo "Estado:"
    docker inspect -f '{{.State.Status}}' ecommerce-app
    echo ""
    echo "Puertos mapeados:"
    docker port ecommerce-app
    echo ""
    echo "Últimos logs de la aplicación:"
    docker logs ecommerce-app --tail 50
else
    echo "⚠️ Aplicación NO está corriendo"
    echo "Intentando ver logs del contenedor (si existe):"
    docker logs ecommerce-app --tail 50 2>&1 || echo "No se pueden obtener logs"
fi
echo ""

# 5. Verificar conectividad entre contenedores
echo "5️⃣ VERIFICANDO CONECTIVIDAD ENTRE CONTENEDORES..."
echo "----------------------------------------"
if docker ps | grep -q ecommerce-app && docker ps | grep -q ecommerce-mysql; then
    echo "Probando ping desde aplicación a MySQL:"
    docker exec ecommerce-app ping -c 2 ecommerce-mysql 2>&1 || echo "⚠️ No se puede hacer ping a MySQL"
    echo ""
    echo "Probando conexión MySQL desde aplicación:"
    docker exec ecommerce-app sh -c "nc -zv ecommerce-mysql 3306 2>&1" || echo "⚠️ No se puede conectar al puerto 3306"
else
    echo "⚠️ No se pueden verificar contenedores (uno o ambos no están corriendo)"
fi
echo ""

# 6. Verificar variables de entorno
echo "6️⃣ VERIFICANDO VARIABLES DE ENTORNO..."
echo "----------------------------------------"
if docker ps | grep -q ecommerce-app; then
    echo "Variables de entorno del contenedor de aplicación:"
    docker exec ecommerce-app env | grep -E "DB_|PORT|HOST" || echo "No se pueden obtener variables"
else
    echo "⚠️ Contenedor no está corriendo, verificando archivo .env:"
    cat /opt/ecommerce/.env 2>/dev/null || echo "⚠️ Archivo .env no encontrado"
fi
echo ""

# 7. Verificar puertos en el host
echo "7️⃣ VERIFICANDO PUERTOS EN EL HOST..."
echo "----------------------------------------"
echo "Puerto 3000:"
netstat -tlnp | grep ":3000" || ss -tlnp | grep ":3000" || echo "⚠️ Puerto 3000 no está escuchando"
echo ""
echo "Puerto 3306 (MySQL):"
netstat -tlnp | grep ":3306" || ss -tlnp | grep ":3306" || echo "⚠️ Puerto 3306 no está escuchando"
echo ""

# 8. Verificar conectividad desde el host
echo "8️⃣ VERIFICANDO CONECTIVIDAD DESDE EL HOST..."
echo "----------------------------------------"
echo "Probando health check local:"
curl -f -s http://localhost:3000/health && echo "✅ Health check OK" || echo "⚠️ Health check falló"
echo ""
echo "Probando conexión a MySQL desde host:"
nc -zv localhost 3306 2>&1 || echo "⚠️ No se puede conectar a MySQL desde host"
echo ""

# 9. Verificar base de datos
echo "9️⃣ VERIFICANDO BASE DE DATOS..."
echo "----------------------------------------"
if docker ps | grep -q ecommerce-mysql; then
    echo "Listando bases de datos:"
    docker exec ecommerce-mysql mysql -uroot -p${DB_PASSWORD:-changeme} -e "SHOW DATABASES;" 2>/dev/null || \
    docker exec ecommerce-mysql mysql -uadmin -padmin -e "SHOW DATABASES;" 2>/dev/null || \
    echo "⚠️ No se puede acceder a MySQL"
    echo ""
    echo "Verificando tablas en la base de datos:"
    docker exec ecommerce-mysql mysql -uroot -p${DB_PASSWORD:-changeme} equantom -e "SHOW TABLES;" 2>/dev/null || \
    docker exec ecommerce-mysql mysql -uadmin -padmin equantom -e "SHOW TABLES;" 2>/dev/null || \
    echo "⚠️ No se pueden listar tablas"
else
    echo "⚠️ MySQL no está corriendo"
fi
echo ""

# 10. Verificar archivos y directorios
echo "🔟 VERIFICANDO ARCHIVOS Y DIRECTORIOS..."
echo "----------------------------------------"
echo "Contenido de /opt/ecommerce:"
ls -la /opt/ecommerce/ 2>/dev/null || echo "⚠️ Directorio no existe"
echo ""
echo "Archivo .env:"
cat /opt/ecommerce/.env 2>/dev/null || echo "⚠️ Archivo .env no encontrado"
echo ""
echo "Volumen de MySQL:"
ls -la /opt/mysql-data/ 2>/dev/null | head -10 || echo "⚠️ Directorio de datos MySQL no existe"
echo ""

# 11. Verificar IP pública
echo "1️⃣1️⃣ VERIFICANDO IP PÚBLICA..."
echo "----------------------------------------"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
echo "IP Pública: $PUBLIC_IP"
echo "Probando desde fuera (puede fallar si security group no permite):"
curl -f -s --max-time 5 "http://$PUBLIC_IP:3000/health" && echo "✅ Aplicación accesible desde fuera" || echo "⚠️ Aplicación no accesible desde fuera"
echo ""

# 12. Resumen
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Contenedores corriendo:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Contenedores detenidos:"
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"
echo ""

echo "✅ Diagnóstico completado"
echo ""
echo "💡 COMANDOS ÚTILES ADICIONALES:"
echo "   - Ver logs de aplicación: docker logs -f ecommerce-app"
echo "   - Ver logs de MySQL: docker logs -f ecommerce-mysql"
echo "   - Reiniciar aplicación: docker restart ecommerce-app"
echo "   - Entrar al contenedor app: docker exec -it ecommerce-app sh"
echo "   - Entrar al contenedor MySQL: docker exec -it ecommerce-mysql mysql -uadmin -padmin equantom"
echo "   - Verificar red: docker network inspect ecommerce-network"

