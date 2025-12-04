# 📚 Documentación del Sistema - Ecommerce Quantum

## 🎯 Descripción General

Sistema de comercio electrónico desarrollado con Node.js que implementa **Tablas de Decisión** para manejar la lógica de autenticación de usuarios. El sistema permite gestionar productos, categorías y usuarios con un sistema de login robusto basado en reglas de decisión.

---

## 📂 Estructura del Proyecto y Ubicación de Archivos

### Archivos Principales

```
nodejs-ecommerce/
│
├── 📄 app.js                          # Punto de entrada principal
│   └─> Inicia el servidor Express en puerto 3000
│
├── 📁 config/
│   └── custom-express.js              # Configuración de Express, middlewares, rutas
│       └─> Configura: sesiones, CSRF, validación, Handlebars
│
├── 📁 dao/                            # Capa de Acceso a Datos
│   ├── connectionFactory.js           # Factory para crear conexiones MySQL
│   ├── userDAO.js                     # Operaciones CRUD de usuarios
│   ├── productsDAO.js                 # Operaciones CRUD de productos
│   └── categoriesDAO.js               # Operaciones CRUD de categorías
│
├── 📁 helpers/                        # Helpers y utilidades
│   ├── decisionTable.js              # ⭐ Motor genérico de tablas de decisión
│   ├── authDecisionTable.js          # ⭐ Tabla de decisión de autenticación
│   └── msg.js                         # Helper para mensajes flash (success/warning)
│
├── 📁 routes/                         # Rutas de la aplicación
│   ├── user/
│   │   ├── signIn.js                 # ⭐ Login (GET/POST) - Usa tabla de decisión
│   │   ├── signUp.js                 # Registro de usuarios
│   │   └── logOut.js                 # Cerrar sesión
│   └── search.js                     # Búsqueda de productos
│
├── 📁 tests/                          # Pruebas automatizadas
│   └── selenium/
│       ├── authDecisionTable.test.js # ⭐ Pruebas de caja negra de autenticación
│       ├── config.js                 # Configuración de Selenium
│       └── setup.js                  # Setup de WebDriver
│
├── 📁 scripts/
│   └── create-test-user.js           # Script para crear usuario de prueba
│
├── 📁 views/                          # Plantillas Handlebars
│   ├── layouts/
│   │   └── layout.hbs                # Layout principal
│   ├── sign/
│   │   ├── in.hbs                    # Formulario de login
│   │   └── up.hbs                    # Formulario de registro
│   └── home/
│       └── index.hbs                 # Página principal
│
├── 📁 public/                         # Archivos estáticos
│   ├── css/                          # Estilos CSS
│   ├── js/                           # JavaScript del frontend
│   └── img/                          # Imágenes
│
├── 📄 docker-compose.yml              # Configuración de MySQL en Docker
├── 📄 package.json                   # Dependencias y scripts npm
└── 📄 .env-exemple                   # Plantilla de variables de entorno
```

---

## 🔑 Funcionalidades Principales

### 1. Sistema de Autenticación con Tablas de Decisión

**Ubicación**: `routes/user/signIn.js` + `helpers/authDecisionTable.js`

El sistema de login utiliza una **Tabla de Decisión** que evalúa 5 reglas diferentes:

1. **Login exitoso** → Redirige a home y crea sesión
2. **Usuario ya autenticado** → Redirige a home con advertencia
3. **Errores de validación** → Muestra error y permanece en login
4. **Contraseña incorrecta** → Muestra error y permanece en login
5. **Email no registrado** → Muestra error y permanece en login

### 2. Gestión de Usuarios

**Ubicación**: `dao/userDAO.js`

- Crear usuarios con contraseñas encriptadas (bcrypt)
- Validar credenciales de login
- Obtener información de usuarios

### 3. Gestión de Productos y Categorías

**Ubicación**: `dao/productsDAO.js` + `dao/categoriesDAO.js`

- Listar productos
- Filtrar por categoría
- Ordenar productos

### 4. Pruebas Automatizadas

**Ubicación**: `tests/selenium/`

- Pruebas de caja negra usando Selenium WebDriver
- Validación de todas las reglas de la tabla de decisión
- Pruebas end-to-end del flujo de autenticación

---

## 🗺️ Mapa de Rutas

| Ruta | Método | Descripción | Archivo |
|------|--------|-------------|---------|
| `/` | GET | Página principal | `config/custom-express.js` |
| `/sign-in` | GET | Mostrar formulario de login | `routes/user/signIn.js` |
| `/sign-in` | POST | Procesar login (usa tabla de decisión) | `routes/user/signIn.js` |
| `/sign-up` | GET | Mostrar formulario de registro | `routes/user/signUp.js` |
| `/sign-up` | POST | Procesar registro | `routes/user/signUp.js` |
| `/logout` | GET | Cerrar sesión | `routes/user/logOut.js` |
| `/order/:order` | GET | Ordenar productos | `routes/search.js` |

---

## 🔧 Configuración y Variables de Entorno

**Archivo**: `.env` (crear desde `.env-exemple`)

```env
# Base de Datos
DB_HOST=localhost
DB_USER=ecommerce_user
DB_PASSWORD=ecommerce_pass
DB_NAME=equantom

# Servidor
HOST=localhost
PORT=3000

# Sesión
SESSION_SECRET=secretpasscryp

# Pruebas
BASE_URL=http://localhost:3000
```

---

## 🐳 Base de Datos

**Configuración**: `docker-compose.yml`

El sistema usa MySQL 8.0 en Docker:

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: equantom
      MYSQL_USER: ecommerce_user
      MYSQL_PASSWORD: ecommerce_pass
    ports:
      - "3306:3306"
```

**Script de inicialización**: `equantom.sql` (se ejecuta automáticamente al iniciar el contenedor)

---

## 🧪 Pruebas

### Comandos Disponibles

```bash
# Crear usuario de prueba
npm run create-test-user

# Ejecutar pruebas de autenticación
npm run test:auth

# Ejecutar todas las pruebas
npm test
```

### Usuario de Prueba

- **Email**: `test@test.com`
- **Password**: `test1234`
- **Username**: `test`

---

## 📖 Documentación Adicional

- **Tablas de Decisión**: Ver `TABLAS_DECISION.md`
- **README Original**: Ver `README.md`

---

## 🚀 Inicio Rápido

1. **Clonar/Descargar el proyecto**
2. **Instalar dependencias**:
   ```bash
   npm install
   ```

3. **Configurar variables de entorno**:
   ```bash
   cp .env-exemple .env
   # Editar .env con tus valores
   ```

4. **Iniciar base de datos**:
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

---

## 📝 Notas Importantes

- El sistema requiere **MySQL** corriendo (Docker o local)
- **ChromeDriver** debe estar corriendo para las pruebas de Selenium
- Las sesiones se almacenan en memoria (no persistente entre reinicios)
- El CSRF token es requerido para todos los formularios POST

---

**Versión**: 1.0.0  
**Última actualización**: 2024

