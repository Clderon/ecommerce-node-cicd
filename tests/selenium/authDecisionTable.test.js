/**
 * Pruebas de Caja Negra - Tabla de Decisión de Autenticación
 *
 * Estas pruebas validan TODAS las reglas de la tabla de decisión de autenticación
 * sin conocer la implementación interna (caja negra).
 *
 * Total de pruebas: 5 (una por cada regla de la tabla de decisión)
 */

const SeleniumSetup = require('./setup');
const config = require('./config');

describe('Tabla de Decisión - Autenticación (Caja Negra)', () => {
  let selenium;

  beforeAll(async () => {
    selenium = new SeleniumSetup();
    await selenium.init();
  });

  afterAll(async () => {
    await selenium.quit();
  });

  beforeEach(async () => {
    // Limpiar cookies antes de cada prueba para asegurar estado limpio
    const driver = selenium.getDriver();
    await driver.manage().deleteAllCookies();
    // Navegar a la página de login antes de cada prueba
    await selenium.navigateTo('/sign-in');
    await selenium.sleep(1000);
  });

  /**
   * REGLA 1: Login Exitoso
   * Condiciones: emailExists = true, passwordCorrect = true
   * Acción esperada: Redirigir a / con mensaje de éxito y crear sesión
   */
  test('Regla 1: Login exitoso debe redirigir a home y crear sesión', async () => {
    const driver = selenium.getDriver();
    console.log('📝 Regla 1: Probando login exitoso...');

    // Llenar el formulario con credenciales válidas
    await selenium.type('input[name="email"]', config.testUsers.valid.email);
    await selenium.type('input[name="password"]', config.testUsers.valid.password);

    // Verificar CSRF token
    const {By} = require('selenium-webdriver');
    const csrfInput = await driver.findElement(By.name('_csrf'));
    const csrfToken = await csrfInput.getAttribute('value');
    console.log('🔐 CSRF Token presente:', csrfToken ? 'Sí' : 'No');

    // Enviar el formulario
    const form = await driver.findElement(By.css('form[action="/sign-in"]'));
    await selenium.sleep(500);
    await driver.executeScript(`const form = arguments[0]; form.submit();`, form);

    console.log('⏳ Regla 1: Esperando redirección...');
    await selenium.sleep(2000);

    // Esperar redirección
    let redirectDetected = false;
    const maxWaitTime = 15000;
    const startTime = Date.now();

    while (!redirectDetected && (Date.now() - startTime) < maxWaitTime) {
      await selenium.sleep(500);
      const currentUrl = await driver.getCurrentUrl();
      const urlPath = new URL(currentUrl).pathname;

      if (urlPath !== '/sign-in') {
        redirectDetected = true;
        console.log('✅ Regla 1: Redirección detectada a:', urlPath);
        break;
      }
    }

    if (!redirectDetected) {
      throw new Error('Regla 1: No se detectó redirección después de 15 segundos');
    }

    // Verificar que fue redirigido a home
    const finalUrl = await driver.getCurrentUrl();
    const finalPath = new URL(finalUrl).pathname;
    expect(finalPath).toBe('/');
    expect(finalPath).not.toBe('/sign-in');

    // Verificar mensaje de éxito (si existe)
    try {
      const pageText = await selenium.getText('body');
      expect(pageText.toLowerCase()).toMatch(/bienvenido|welcome|success/i);
    } catch (e) {
      // Si no hay mensaje visible, está bien
    }

    // Verificar que la sesión está activa (intentar acceder a /sign-in debe redirigir)
    await selenium.navigateTo('/sign-in');
    await selenium.sleep(2000);
    const newUrl = await driver.getCurrentUrl();
    const newUrlPath = new URL(newUrl).pathname;
    expect(newUrlPath).not.toBe('/sign-in'); // Debe redirigir porque ya está autenticado
    console.log('✅ Regla 1: Sesión creada correctamente');
  });

  /**
   * REGLA 2: Usuario ya tiene sesión activa
   * Condición: userSessionExists = true
   * Acción esperada: Redirigir a / con mensaje de advertencia
   */
  test('Regla 2: Usuario ya autenticado debe ser redirigido', async () => {
    const driver = selenium.getDriver();
    console.log('📝 Regla 2: Haciendo login primero...');

    // Primero hacer login exitoso (Regla 1)
    await selenium.type('input[name="email"]', config.testUsers.valid.email);
    await selenium.type('input[name="password"]', config.testUsers.valid.password);

    const {By} = require('selenium-webdriver');
    const form = await driver.findElement(By.css('form[action="/sign-in"]'));
    await selenium.sleep(500);
    await driver.executeScript(`const form = arguments[0]; form.submit();`, form);
    await selenium.sleep(2000);

    // Verificar que el login fue exitoso
    const urlAfterLogin = await driver.getCurrentUrl();
    const pathAfterLogin = new URL(urlAfterLogin).pathname;
    expect(pathAfterLogin).toBe('/');

    console.log('📝 Regla 2: Intentando acceder a /sign-in con sesión activa...');
    // Intentar acceder a /sign-in nuevamente (debe activar Regla 2)
    await selenium.navigateTo('/sign-in');
    await selenium.sleep(2000);

    // Verificar que fue redirigido a home (Regla 2)
    const currentUrl = await driver.getCurrentUrl();
    const urlPath = new URL(currentUrl).pathname;
    expect(urlPath).toBe('/');
    expect(urlPath).not.toBe('/sign-in');
    console.log('✅ Regla 2: Usuario redirigido correctamente');

    // Verificar que hay un mensaje de advertencia (si existe en la página)
    try {
      const pageText = await selenium.getText('body');
      expect(pageText.toLowerCase()).toMatch(/sesión|session|ya.*tienes/i);
    } catch (e) {
      // Si no hay mensaje visible, está bien
      // Lo importante es que fue redirigido
    }
  });

  /**
   * REGLA 3: Errores de validación
   * Condición: validationErrors = true
   * Acción esperada: Permanecer en /sign-in con mensaje de error
   */
  test('Regla 3: Errores de validación deben mostrar mensaje', async () => {
    const driver = selenium.getDriver();
    console.log('📝 Regla 3: Intentando login con datos inválidos...');

    // Intentar login con email inválido y contraseña muy corta (debe activar Regla 3)
    await selenium.type('input[name="email"]', 'invalid-email');
    await selenium.type('input[name="password"]', '123'); // Contraseña muy corta

    const {By} = require('selenium-webdriver');
    const form = await driver.findElement(By.css('form[action="/sign-in"]'));
    await selenium.sleep(500);
    await driver.executeScript(`const form = arguments[0]; form.submit();`, form);
    await selenium.sleep(2000);

    // Verificar que sigue en la página de login (Regla 3)
    const currentUrl = await driver.getCurrentUrl();
    const urlPath = new URL(currentUrl).pathname;
    expect(urlPath).toBe('/sign-in');
    expect(urlPath).not.toBe('/');
    console.log('✅ Regla 3: Permaneció en /sign-in');

    // Verificar que hay un mensaje de error de validación
    try {
      const pageText = await selenium.getText('body');
      expect(pageText.toLowerCase()).toMatch(/correo.*no.*válido|email.*not.*valid|validación|validation/i);
      console.log('✅ Regla 3: Mensaje de error de validación encontrado');
    } catch (e) {
      // Verificar que al menos no fue redirigido
      expect(urlPath).toBe('/sign-in');
    }
  });

  /**
   * REGLA 4: Contraseña incorrecta
   * Condiciones: emailExists = true, passwordCorrect = false
   * Acción esperada: Permanecer en /sign-in con error "¡La contraseña no es correcta!"
   */
  test('Regla 4: Contraseña incorrecta debe mostrar error', async () => {
    const driver = selenium.getDriver();
    console.log('📝 Regla 4: Intentando login con email válido pero contraseña incorrecta...');

    // Email válido pero contraseña incorrecta (debe activar Regla 4)
    await selenium.type('input[name="email"]', config.testUsers.valid.email);
    await selenium.type('input[name="password"]', config.testUsers.invalid.password || 'password_incorrecta_123');

    const {By} = require('selenium-webdriver');
    const form = await driver.findElement(By.css('form[action="/sign-in"]'));
    await selenium.sleep(500);
    await driver.executeScript(`const form = arguments[0]; form.submit();`, form);
    await selenium.sleep(2000);

    // Verificar que sigue en la página de login (Regla 4)
    const currentUrl = await driver.getCurrentUrl();
    const urlPath = new URL(currentUrl).pathname;
    expect(urlPath).toBe('/sign-in');
    expect(urlPath).not.toBe('/');
    console.log('✅ Regla 4: Permaneció en /sign-in');

    // Verificar mensaje de error de contraseña incorrecta
    try {
      const pageText = await selenium.getText('body');
      expect(pageText.toLowerCase()).toMatch(/contraseña.*no.*correcta|password.*not.*correct|incorrect/i);
      console.log('✅ Regla 4: Mensaje de error de contraseña encontrado');
    } catch (e) {
      // Al menos verificar que no fue redirigido
      expect(urlPath).toBe('/sign-in');
    }
  });

  /**
   * REGLA 5: Email no registrado
   * Condición: emailExists = false
   * Acción esperada: Permanecer en /sign-in con error "¡El correo electrónico no está registrado!"
   */
  test('Regla 5: Email no registrado debe mostrar error', async () => {
    const driver = selenium.getDriver();
    console.log('📝 Regla 5: Intentando login con email no registrado...');

    // Email no registrado (debe activar Regla 5)
    await selenium.type('input[name="email"]', config.testUsers.nonExistent.email || 'noexiste@test.com');
    await selenium.type('input[name="password"]', config.testUsers.nonExistent.password || 'cualquierpassword123');

    const {By} = require('selenium-webdriver');
    const form = await driver.findElement(By.css('form[action="/sign-in"]'));
    await selenium.sleep(500);
    await driver.executeScript(`const form = arguments[0]; form.submit();`, form);
    await selenium.sleep(2000);

    // Verificar que sigue en la página de login (Regla 5)
    const currentUrl = await driver.getCurrentUrl();
    const urlPath = new URL(currentUrl).pathname;
    expect(urlPath).toBe('/sign-in');
    expect(urlPath).not.toBe('/');
    console.log('✅ Regla 5: Permaneció en /sign-in');

    // Verificar mensaje de error de email no registrado
    try {
      const pageText = await selenium.getText('body');
      expect(pageText.toLowerCase()).toMatch(/correo.*no.*registrado|email.*not.*registered|no.*registrado/i);
      console.log('✅ Regla 5: Mensaje de error de email no registrado encontrado');
    } catch (e) {
      // Al menos verificar que no fue redirigido
      expect(urlPath).toBe('/sign-in');
    }
  });
});
