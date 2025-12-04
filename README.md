# 🛒 Ecommerce Quantum - Sistema con Tablas de Decisión

Sistema de comercio electrónico desarrollado con Node.js que implementa **Tablas de Decisión** para manejar la lógica de autenticación de usuarios.

## 📚 Documentación

- **[SISTEMA.md](./SISTEMA.md)** - Documentación completa del sistema, estructura y ubicación de archivos
- **[TABLAS_DECISION.md](./TABLAS_DECISION.md)** - Explicación detallada de la aplicación de Tablas de Decisión

## 🚀 Inicio Rápido

### Prerrequisitos

- Node.js (v14 o superior)
- Docker y Docker Compose
- MySQL 8.0 (o usar Docker)

### Instalación

1. **Clonar el repositorio**:
   ```bash
   git clone <repository-url>
   cd nodejs-ecommerce
   ```

2. **Instalar dependencias**:
   ```bash
   npm install
   ```

3. **Configurar variables de entorno**:
   ```bash
   cp .env-exemple .env
   # Editar .env con tus valores si es necesario
   ```

4. **Iniciar base de datos MySQL**:
   ```bash
   docker-compose up -d
   ```

5. **Crear usuario de prueba**:
   ```bash
   npm run create-test-user
   ```

6. **Iniciar servidor**:
   ```bash
   npm run dev
   ```

7. **Acceder a la aplicación**:
   - URL: http://localhost:3000
   - Login: http://localhost:3000/sign-in
   - Credenciales: `test@test.com` / `test1234`

## 🧪 Pruebas

```bash
# Ejecutar pruebas de autenticación (requiere ChromeDriver corriendo)
npm run test:auth

# Ejecutar todas las pruebas
npm test
```

**Nota**: Para las pruebas de Selenium, asegúrate de tener ChromeDriver corriendo. Puedes especificar el puerto con:
```bash
$env:CHROMEDRIVER_PORT="49876"; npm run test:auth
```

## 🎯 Tablas de Decisión

Este proyecto implementa **Tablas de Decisión** en el sistema de autenticación. Ver [TABLAS_DECISION.md](./TABLAS_DECISION.md) para más detalles.

### Ubicación de Archivos Clave

- **Motor de Tablas**: `helpers/decisionTable.js`
- **Tabla de Autenticación**: `helpers/authDecisionTable.js`
- **Implementación**: `routes/user/signIn.js`
- **Pruebas**: `tests/selenium/authDecisionTable.test.js`

## 📁 Estructura del Proyecto

```
nodejs-ecommerce/
├── app.js                    # Punto de entrada
├── config/                   # Configuración de Express
├── dao/                      # Capa de acceso a datos
├── helpers/                  # Tablas de decisión y utilidades
├── routes/                   # Rutas de la aplicación
├── tests/                    # Pruebas automatizadas
├── views/                    # Plantillas Handlebars
├── public/                   # Archivos estáticos
└── scripts/                  # Scripts de utilidad
```

## 🛠️ Tecnologías

- **Backend**: Node.js + Express.js
- **Base de Datos**: MySQL 8.0
- **Autenticación**: Express-session + bcryptjs
- **Vistas**: Handlebars (HBS)
- **Pruebas**: Jest + Selenium WebDriver
- **Infraestructura**: Docker + Docker Compose

## 📝 Scripts Disponibles

```bash
npm start              # Iniciar servidor en producción
npm run dev            # Iniciar servidor en modo desarrollo (nodemon)
npm run create-test-user  # Crear usuario de prueba
npm run test:auth      # Ejecutar pruebas de autenticación
npm test               # Ejecutar todas las pruebas
```

## 📖 Más Información

Para más detalles sobre:
- **Estructura completa del sistema**: Ver [SISTEMA.md](./SISTEMA.md)
- **Aplicación de Tablas de Decisión**: Ver [TABLAS_DECISION.md](./TABLAS_DECISION.md)

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.
