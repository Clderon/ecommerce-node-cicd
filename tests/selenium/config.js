/**
 * Configuración de Selenium para pruebas de caja negra
 */

module.exports = {
  // URL base de la aplicación
  baseUrl: process.env.BASE_URL || 'http://localhost:3000',

  // Timeouts
  timeout: {
    implicit: 10000, // 10 segundos
    pageLoad: 30000, // 30 segundos
    script: 30000, // 30 segundos
  },

  // Configuración del navegador
  browser: process.env.BROWSER || 'chrome',

  // Opciones de Chrome
  chromeOptions: {
    args: [
      // '--headless', // Comentado para ver las pruebas ejecutándose
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  },

  // URL del ChromeDriver remoto (si está corriendo en otro puerto)
  // Si tienes ChromeDriver corriendo manualmente, actualiza esta URL
  chromedriverUrl: process.env.CHROMEDRIVER_URL || null, // null = usar ChromeDriver local automático

  // Credenciales de prueba
  testUsers: {
    valid: {
      email: 'test@test.com',
      password: 'test1234',
      username: 'test',
    },
    invalid: {
      email: 'invalid@test.com',
      password: 'wrongpassword',
    },
    nonExistent: {
      email: 'nonexistent@test.com',
      password: 'password123',
    },
  },
};

