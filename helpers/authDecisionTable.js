/**
 * Tabla de Decisión para Autenticación de Usuarios
 * 
 * Esta tabla de decisión maneja todas las posibles combinaciones de condiciones
 * durante el proceso de login de un usuario.
 * 
 * CONDICIONES:
 * - emailExists: El email existe en la base de datos
 * - passwordCorrect: La contraseña es correcta
 * - userSessionExists: El usuario ya tiene una sesión activa
 * - validationErrors: Hay errores de validación en los datos
 * 
 * ACCIONES:
 * - success: Mensaje de éxito
 * - error: Mensaje de error
 * - redirect: Ruta a redirigir
 * - createSession: Crear sesión de usuario
 */

const DecisionTableFactory = require('./decisionTable');

class AuthDecisionTable {
  constructor() {
    const DecisionTable = DecisionTableFactory();
    this.table = new DecisionTable('Authentication');
    this._initializeRules();
  }

  _initializeRules() {
    // IMPORTANTE: Las reglas se evalúan en orden, las más específicas primero
    // Orden de prioridad: Validación > Sesión activa > Login exitoso > Errores
    
    // Regla 1: Errores de validación (MÁS ALTA PRIORIDAD - verificar primero)
    // Debe evaluarse ANTES que cualquier otra regla
    this.table.addRule(
      { validationErrors: true },
      {
        success: false,
        error: 'Error de validación. Por favor, verifica los datos ingresados.',
        redirect: '/sign-in',
        createSession: false,
      },
      'Errores de validación en formulario'
    );

    // Regla 2: Usuario ya tiene sesión activa (ALTA PRIORIDAD)
    // Debe evaluarse ANTES que login exitoso para evitar crear sesión duplicada
    this.table.addRule(
      { userSessionExists: true },
      {
        success: false,
        error: 'Ya tienes una sesión activa. No puedes acceder a esta área.',
        redirect: '/',
        createSession: false,
      },
      'Usuario ya autenticado'
    );

    // Regla 3: LOGIN EXITOSO - Email existe y contraseña correcta
    // Solo se evalúa si no hay errores de validación y no hay sesión activa
    this.table.addRule(
      { emailExists: true, passwordCorrect: true },
      {
        success: true,
        error: null,
        successMessage: '¡Bienvenido a Ecommerce Quantum!',
        redirect: '/',
        createSession: true,
      },
      'Login exitoso'
    );

    // Regla 4: Email existe pero contraseña incorrecta
    this.table.addRule(
      { emailExists: true, passwordCorrect: false },
      {
        success: false,
        error: '¡La contraseña no es correcta!',
        redirect: '/sign-in',
        createSession: false,
      },
      'Contraseña incorrecta'
    );

    // Regla 5: Email no existe en la base de datos (regla general al final)
    this.table.addRule(
      { emailExists: false },
      {
        success: false,
        error: '¡El correo electrónico no está registrado!',
        redirect: '/sign-in',
        createSession: false,
      },
      'Email no registrado'
    );
  }

  /**
   * Evalúa las condiciones de autenticación y retorna las acciones
   * @param {Object} context - Contexto con las condiciones actuales
   * @returns {Object} - Acciones a ejecutar
   */
  evaluateLogin(context) {
    const conditions = {
      userSessionExists: context.userSessionExists || false,
      validationErrors: context.validationErrors || false,
      emailExists: context.emailExists || false,
      passwordCorrect: context.passwordCorrect || false,
    };

    return this.table.evaluate(conditions);
  }
}

module.exports = () => AuthDecisionTable;

