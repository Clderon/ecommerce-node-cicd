
## Aplicación en el Sistema

### ¿Dónde se Aplicó?

La técnica de **Tablas de Decisión** se aplicó en el **sistema de autenticación de usuarios** (`/sign-in`), específicamente en el proceso de login.

### Condiciones del Sistema (4 condiciones)

| # | Condición | Variable | Descripción |
|---|-----------|----------|-------------|
| C1 | `userSessionExists` | `req.session['user'] != null` | ¿Usuario ya tiene sesión activa? |
| C2 | `validationErrors` | `errorsInValidation != null` | ¿Hay errores de validación? |
| C3 | `emailExists` | `user != null` (de BD) | ¿El email existe en la base de datos? |
| C4 | `passwordCorrect` | `bcrypt.compare()` exitoso | ¿La contraseña es correcta? |

### Acciones del Sistema (4 acciones)

| # | Acción | Variable | Descripción |
|---|--------|----------|-------------|
| A1 | `success` | `true/false` | ¿Login exitoso? |
| A2 | `error` | `string/null` | Mensaje de error |
| A3 | `redirect` | `string` | Ruta a redirigir |
| A4 | `createSession` | `true/false` | ¿Crear sesión de usuario? |

**Total de combinaciones**: 2⁴ = **16 casos posibles**

---

## Tabla de Decisión Completa

### Reglas Implementadas (5 reglas prioritarias)

| # | Regla | Condiciones | Acciones | Descripción |
|---|-------|-------------|----------|-------------|
| **1** | Login Exitoso | `emailExists: true`<br>`passwordCorrect: true` | Success<br>Redirect: `/`<br>Create Session: `true` | Login exitoso → Redirigir a `/` |
| **2** | Usuario Ya Autenticado | `userSessionExists: true` | Warning<br>Redirect: `/`<br>Create Session: `false` | Usuario ya autenticado → Redirigir a `/` |
| **3** | Errores de Validación | `validationErrors: true` | Error<br>Redirect: `/sign-in`<br>Create Session: `false` | Errores de validación → Permanecer en `/sign-in` |
| **4** | Contraseña Incorrecta | `emailExists: true`<br>`passwordCorrect: false` | Error<br>Redirect: `/sign-in`<br>Create Session: `false` | Contraseña incorrecta → Permanecer en `/sign-in` |
| **5** | Email No Registrado | `emailExists: false` | Error<br>Redirect: `/sign-in`<br>Create Session: `false` | Email no registrado → Permanecer en `/sign-in` |

### Tabla con Todas las Combinaciones (16 casos)

| # | C1<br>Sesión | C2<br>Validación | C3<br>Email | C4<br>Contraseña | Regla | Acción | Redirect |
|---|--------------|------------------|-------------|------------------|-------|--------|----------|
| 1-8 | Sí | - | - | - | **Regla 2** | Warning | `/` |
| 9-12 | No | Sí | - | - | **Regla 3** | Error | `/sign-in` |
| 13 | No | No | Sí | Sí | **Regla 1** | Success | `/` |
| 14 | No | No | Sí | No | **Regla 4** | Error | `/sign-in` |
| 15-16 | No | No | No | - | **Regla 5** | Error | `/sign-in` |

**Nota**: `-` significa que la condición no se evalúa en esa regla.

### Cobertura de Casos

| Regla | Casos Cubiertos | Porcentaje |
|-------|-----------------|------------|
| Regla 1 | 1 caso (#13) | 6.25% |
| Regla 2 | 8 casos (#1-8) | 50% |
| Regla 3 | 4 casos (#9-12) | 25% |
| Regla 4 | 1 caso (#14) | 6.25% |
| Regla 5 | 2 casos (#15-16) | 12.5% |
| **TOTAL** | **16 casos** | **100%** |

---
