require('dotenv').config();
const mysql = require('mysql2');

/**
 * Factory para crear conexiones a la base de datos MySQL
 */
class ConnectionFactory {
  constructor() {
    this.config = {
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'ecommerce_user',
      password: process.env.DB_PASSWORD || 'ecommerce_pass',
      database: process.env.DB_NAME || 'equantom',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    };
  }

  /**
   * Crea una nueva conexión a la base de datos
   * @return {mysql.Connection} - Conexión a MySQL
   */
  createConnection() {
    const connection = mysql.createConnection({
      host: this.config.host,
      user: this.config.user,
      password: this.config.password,
      database: this.config.database,
    });

    return connection;
  }

  /**
   * Crea un pool de conexiones
   * @return {mysql.Pool} - Pool de conexiones MySQL
   */
  createPool() {
    return mysql.createPool(this.config);
  }
}

module.exports = () => {
  const factory = new ConnectionFactory();
  return factory.createConnection.bind(factory);
};

