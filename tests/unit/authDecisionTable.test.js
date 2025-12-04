/**
 * Pruebas Unitarias - AuthDecisionTable
 * 
 * Pruebas rápidas que evalúan la lógica de autenticación
 * sin necesidad de navegador, webdriver o base de datos real.
 */

const AuthDecisionTable = require('../../helpers/authDecisionTable')();

describe('AuthDecisionTable - Pruebas Unitarias', () => {
  let authTable;

  beforeEach(() => {
    authTable = new AuthDecisionTable();
  });

  describe('Regla 1: Errores de validación', () => {
    test('debe retornar regla 1 cuando hay errores de validación', () => {
      const context = {
        emailExists: false,
        passwordCorrect: false,
        userSessionExists: false,
        validationErrors: true // Errores de validación
      };

      const result = authTable.evaluateLogin(context);

      expect(result.matched).toBe(true);
      expect(result.rule).toBe(1);
      expect(result.actions.redirect).toBe('/sign-in');
      expect(result.actions.error).toMatch(/validación|validation|error/i);
    });
  });

  describe('Regla 2: Usuario ya autenticado', () => {
    test('debe retornar regla 2 cuando ya hay sesión activa', () => {
      const context = {
        emailExists: false,
        passwordCorrect: false,
        userSessionExists: true, // Sesión ya existe
        validationErrors: false
      };

      const result = authTable.evaluateLogin(context);

      expect(result.matched).toBe(true);
      expect(result.rule).toBe(2);
      expect(result.actions.redirect).toBe('/');
      expect(result.actions.error).toMatch(/sesión|session|ya.*tienes/i);
    });
  });

  describe('Regla 3: Login Exitoso', () => {
    test('debe retornar regla 3 cuando email existe y contraseña es correcta', () => {
      const context = {
        emailExists: true,
        passwordCorrect: true,
        userSessionExists: false,
        validationErrors: false
      };

      const result = authTable.evaluateLogin(context);

      expect(result.matched).toBe(true);
      expect(result.rule).toBe(3);
      expect(result.actions.redirect).toBe('/');
      expect(result.actions.successMessage || result.actions.error).toBeDefined();
    });
  });

  describe('Regla 4: Contraseña incorrecta', () => {
    test('debe retornar regla 4 cuando email existe pero contraseña es incorrecta', () => {
      const context = {
        emailExists: true,
        passwordCorrect: false, // Contraseña incorrecta
        userSessionExists: false,
        validationErrors: false
      };

      const result = authTable.evaluateLogin(context);

      expect(result.matched).toBe(true);
      expect(result.rule).toBe(4);
      expect(result.actions.redirect).toBe('/sign-in');
      expect(result.actions.error).toMatch(/contraseña|password|incorrect/i);
    });
  });

  describe('Regla 5: Email no registrado', () => {
    test('debe retornar regla 5 cuando el email no existe', () => {
      const context = {
        emailExists: false, // Email no existe
        passwordCorrect: false,
        userSessionExists: false,
        validationErrors: false
      };

      const result = authTable.evaluateLogin(context);

      expect(result.matched).toBe(true);
      expect(result.rule).toBe(5);
      expect(result.actions.redirect).toBe('/sign-in');
      expect(result.actions.error).toMatch(/correo.*no.*registrado|email.*not.*registered/i);
    });
  });

  describe('Prioridad de reglas', () => {
    test('regla 1 (validación) debe tener prioridad sobre otras reglas', () => {
      const context = {
        emailExists: true,
        passwordCorrect: true,
        userSessionExists: false,
        validationErrors: true // Validación tiene prioridad más alta
      };

      const result = authTable.evaluateLogin(context);

      expect(result.rule).toBe(1); // Debe ser regla 1 (validación), no regla 3 (login)
    });

    test('regla 2 (sesión activa) debe tener prioridad sobre regla 3 (login exitoso)', () => {
      const context = {
        emailExists: true,
        passwordCorrect: true,
        userSessionExists: true, // Sesión activa tiene prioridad sobre login
        validationErrors: false
      };

      const result = authTable.evaluateLogin(context);

      expect(result.rule).toBe(2); // Debe ser regla 2 (sesión activa), no regla 3 (login exitoso)
    });
  });

  describe('Casos edge', () => {
    test('debe manejar contexto vacío', () => {
      const result = authTable.evaluateLogin({});
      // Debe retornar alguna regla o no coincidencia
      expect(result).toHaveProperty('matched');
    });

    test('debe manejar valores undefined', () => {
      const context = {
        emailExists: undefined,
        passwordCorrect: undefined,
        userSessionExists: undefined,
        validationErrors: undefined
      };

      const result = authTable.evaluateLogin(context);
      expect(result).toHaveProperty('matched');
    });
  });
});

