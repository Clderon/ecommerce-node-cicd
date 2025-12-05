#!/bin/bash
# Script para diagnosticar y solucionar problemas en EC2

echo "=========================================="
echo "🔧 DIAGNÓSTICO Y SOLUCIÓN DE PROBLEMAS"
echo "=========================================="
echo ""

# 1. Ver logs del user-data (cloud-init)
echo "1️⃣ VERIFICANDO LOGS DEL USER-DATA..."
echo "----------------------------------------"
echo "Últimas 100 líneas del log de cloud-init:"
sudo tail -100 /var/log/cloud-init-output.log | grep -A 5 -B 5 "ecommerce-app\|docker run\|Error\|error\|ERROR" || echo "No se encontraron errores relevantes"
echo ""

# 2. Verificar si la imagen Docker existe
echo "2️⃣ VERIFICANDO IMÁGENES DOCKER..."
echo "----------------------------------------"
docker images | grep ecommerce || echo "⚠️ No se encontró imagen de ecommerce"
echo ""

# 3. Verificar archivo .env
echo "3️⃣ VERIFICANDO ARCHIVO .env..."
echo "----------------------------------------"
if [ -f /opt/ecommerce/.env ]; then
    echo "✅ Archivo .env existe:"
    cat /opt/ecommerce/.env
    echo ""
    
    # Extraer credenciales
    DB_USER=$(grep DB_USER /opt/ecommerce/.env | cut -d'=' -f2)
    DB_PASSWORD=$(grep DB_PASSWORD /opt/ecommerce/.env | cut -d'=' -f2)
    DB_NAME=$(grep DB_NAME /opt/ecommerce/.env | cut -d'=' -f2)
    DB_HOST=$(grep DB_HOST /opt/ecommerce/.env | cut -d'=' -f2)
    APP_PORT=$(grep PORT /opt/ecommerce/.env | cut -d'=' -f2)
    
    echo "Credenciales extraídas:"
    echo "  DB_HOST=$DB_HOST"
    echo "  DB_USER=$DB_USER"
    echo "  DB_NAME=$DB_NAME"
    echo "  PORT=$APP_PORT"
    echo ""
else
    echo "⚠️ Archivo .env NO existe en /opt/ecommerce/.env"
    echo ""
fi

# 4. Probar conexión a MySQL con las credenciales del .env
echo "4️⃣ PROBANDO CONEXIÓN A MYSQL..."
echo "----------------------------------------"
if [ -f /opt/ecommerce/.env ]; then
    echo "Intentando conectar con credenciales del .env..."
    docker exec ecommerce-mysql mysql -u${DB_USER} -p${DB_PASSWORD} -e "SELECT 1;" ${DB_NAME} 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Conexión a MySQL exitosa"
    else
        echo "⚠️ Conexión a MySQL falló"
        echo ""
        echo "Intentando con root..."
        docker exec ecommerce-mysql mysql -uroot -p${DB_PASSWORD} -e "SELECT 1;" 2>&1 || echo "⚠️ También falló con root"
    fi
else
    echo "⚠️ No se puede probar conexión (archivo .env no existe)"
fi
echo ""

# 5. Intentar crear el contenedor manualmente para ver el error
echo "5️⃣ INTENTANDO CREAR CONTENEDOR MANUALMENTE..."
echo "----------------------------------------"
if [ -f /opt/ecommerce/.env ]; then
    # Obtener la imagen Docker
    DOCKER_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep ecommerce | head -1)
    
    if [ -z "$DOCKER_IMAGE" ]; then
        echo "⚠️ No se encontró imagen Docker de ecommerce"
        echo "Imágenes disponibles:"
        docker images
    else
        echo "Imagen encontrada: $DOCKER_IMAGE"
        echo ""
        echo "Intentando crear contenedor (modo dry-run para ver errores)..."
        
        # Intentar crear el contenedor
        docker run -d \
          --name ecommerce-app-test \
          --network ecommerce-network \
          -p 0.0.0.0:${APP_PORT:-3000}:${APP_PORT:-3000} \
          --env-file /opt/ecommerce/.env \
          ${DOCKER_IMAGE} 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ Contenedor creado exitosamente"
            sleep 2
            echo "Estado del contenedor:"
            docker ps -a | grep ecommerce-app-test
            echo ""
            echo "Logs del contenedor:"
            docker logs ecommerce-app-test --tail 50
            echo ""
            echo "Si funciona, puedes eliminar el test y recrear el original:"
            echo "  docker stop ecommerce-app-test"
            echo "  docker rm ecommerce-app-test"
        else
            echo "⚠️ Error al crear contenedor (ver arriba)"
        fi
    fi
else
    echo "⚠️ No se puede crear contenedor (archivo .env no existe)"
fi
echo ""

# 6. Verificar red Docker
echo "6️⃣ VERIFICANDO RED DOCKER..."
echo "----------------------------------------"
docker network inspect ecommerce-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null
echo ""

# 7. Verificar puertos
echo "7️⃣ VERIFICANDO PUERTOS..."
echo "----------------------------------------"
echo "Puerto 3000:"
netstat -tlnp | grep 3000 || ss -tlnp | grep 3000 || echo "⚠️ Puerto 3000 no está en uso"
echo ""

# 8. Resumen y comandos de solución
echo "=========================================="
echo "📋 RESUMEN Y SOLUCIÓN"
echo "=========================================="
echo ""
echo "Si el contenedor no existe, intenta recrearlo manualmente:"
echo ""
echo "1. Verificar que la imagen existe:"
echo "   docker images | grep ecommerce"
echo ""
echo "2. Verificar archivo .env:"
echo "   cat /opt/ecommerce/.env"
echo ""
echo "3. Crear contenedor manualmente:"
echo "   docker run -d \\"
echo "     --name ecommerce-app \\"
echo "     --restart unless-stopped \\"
echo "     --network ecommerce-network \\"
echo "     -p 0.0.0.0:3000:3000 \\"
echo "     --env-file /opt/ecommerce/.env \\"
echo "     <TU_IMAGEN_DOCKER>"
echo ""
echo "4. Ver logs después de crear:"
echo "   docker logs -f ecommerce-app"
echo ""

