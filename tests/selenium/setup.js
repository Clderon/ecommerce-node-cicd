/**
 * Setup de Selenium WebDriver
 */

const {Builder, By, until} = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const config = require('./config');

class SeleniumSetup {
  constructor() {
    this.driver = null;
  }

  async init() {
    const chromeOptions = new chrome.Options();

    // Agregar opciones de Chrome
    if (config.chromeOptions.args) {
      chromeOptions.addArguments(config.chromeOptions.args);
    }

    // Intentar usar ChromeDriver remoto primero (si está corriendo)
    // El usuario tiene ChromeDriver corriendo manualmente en un puerto específico
    const remoteUrl = process.env.CHROMEDRIVER_URL || config.chromedriverUrl;

    // Intentar puertos comunes donde ChromeDriver puede estar corriendo
    // El puerto puede cambiar cada vez que se inicia ChromeDriver
    const possiblePorts = remoteUrl ? [remoteUrl] : [
      // Intentar primero con variable de entorno si está configurada
      process.env.CHROMEDRIVER_PORT ? `http://localhost:${process.env.CHROMEDRIVER_PORT}` : null,
      'http://localhost:49876', // Puerto actual de ChromeDriver (puede cambiar)
      'http://localhost:55228', // Puerto que mencionó el usuario anteriormente
      'http://localhost:9515', // Puerto por defecto
      'http://127.0.0.1:49876',
      'http://127.0.0.1:55228',
      'http://127.0.0.1:9515',
    ].filter(Boolean); // Eliminar valores null

    let driverCreated = false;

    for (const url of possiblePorts) {
      try {
        console.log(`Intentando conectar a ChromeDriver en: ${url}`);
        this.driver = await new Builder()
            .forBrowser(config.browser)
            .setChromeOptions(chromeOptions)
            .usingServer(url)
            .build();

        // Verificar que funciona haciendo una operación simple
        await this.driver.get('about:blank');
        console.log(`✅ Conectado exitosamente a ChromeDriver en: ${url}`);
        driverCreated = true;
        break;
      } catch (error) {
        // Continuar con el siguiente puerto
        continue;
      }
    }

    // Si no se pudo conectar a ningún ChromeDriver remoto, usar local
    if (!driverCreated) {
      console.log('⚠️  No se encontró ChromeDriver remoto, usando local (puede fallar si las versiones no coinciden)...');
      try {
        this.driver = await new Builder()
            .forBrowser(config.browser)
            .setChromeOptions(chromeOptions)
            .build();
      } catch (error) {
        throw new Error(
            `No se pudo crear el driver. ` +
          `Asegúrate de tener ChromeDriver corriendo o que las versiones de Chrome y ChromeDriver coincidan. ` +
          `Error: ${error.message}`,
        );
      }
    }

    // Configurar timeouts
    await this.driver.manage().setTimeouts({
      implicit: config.timeout.implicit,
      pageLoad: config.timeout.pageLoad,
      script: config.timeout.script,
    });

    // Maximizar ventana
    await this.driver.manage().window().maximize();

    // Asegurar que las cookies se manejen correctamente
    // No eliminar cookies entre requests para mantener la sesión

    return this.driver;
  }

  async navigateTo(url) {
    const fullUrl = url.startsWith('http') ? url : `${config.baseUrl}${url}`;
    await this.driver.get(fullUrl);
  }

  async quit() {
    if (this.driver) {
      await this.driver.quit();
    }
  }

  async waitForElement(selector, timeout = config.timeout.implicit) {
    return await this.driver.wait(
        until.elementLocated(By.css(selector)),
        timeout,
    );
  }

  async findElement(selector) {
    return await this.driver.findElement(By.css(selector));
  }

  async findElements(selector) {
    return await this.driver.findElements(By.css(selector));
  }

  async getText(selector) {
    const element = await this.findElement(selector);
    return await element.getText();
  }

  async click(selector) {
    const element = await this.waitForElement(selector);
    await element.click();
  }

  async type(selector, text) {
    const element = await this.waitForElement(selector);
    await element.clear();
    await element.sendKeys(text);
  }

  async getCurrentUrl() {
    return await this.driver.getCurrentUrl();
  }

  async waitForUrl(url, timeout = config.timeout.implicit) {
    const fullUrl = url.startsWith('http') ? url : `${config.baseUrl}${url}`;
    try {
      await this.driver.wait(
          until.urlIs(fullUrl),
          timeout,
      );
    } catch (e) {
      // También intentar con URL que contiene el path
      await this.driver.wait(
          until.urlContains(url),
          timeout,
      );
    }
  }

  async waitForUrlContains(url, timeout = config.timeout.implicit) {
    await this.driver.wait(
        until.urlContains(url),
        timeout,
    );
  }

  async sleep(ms) {
    await this.driver.sleep(ms);
  }

  // Exponer el driver para acceso directo
  getDriver() {
    return this.driver;
  }
}

module.exports = SeleniumSetup;

