/**
 * Script para crear el usuario de prueba usado en las pruebas de Selenium
 * 
 * Uso: node scripts/create-test-user.js
 */

require('dotenv').config();
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');

const config = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'ecommerce_user',
  password: process.env.DB_PASSWORD || 'ecommerce_pass',
  database: process.env.DB_NAME || 'equantom',
};

const testUser = {
  email: 'test@test.com',
  password: 'test1234',
  username: 'test',
};

async function createTestUser() {
  const connection = mysql.createConnection(config);

  try {
    await new Promise((resolve, reject) => {
      connection.connect((err) => {
        if (err) {
          console.error('❌ Error conectando a MySQL:', err);
          return reject(err);
        }
        console.log('✅ Conectado a MySQL');
        resolve();
      });
    });

    // Verificar si el usuario ya existe
    const existingUser = await new Promise((resolve, reject) => {
      connection.query(
        'SELECT * FROM users WHERE email = ?',
        [testUser.email],
        (err, results) => {
          if (err) return reject(err);
          resolve(results);
        }
      );
    });

    if (existingUser.length > 0) {
      console.log('⚠️  El usuario de prueba ya existe');
      console.log('   Email:', testUser.email);
      
      // Actualizar la contraseña por si acaso
      const hashedPassword = await new Promise((resolve, reject) => {
        bcrypt.hash(testUser.password, 10, (err, hash) => {
          if (err) return reject(err);
          resolve(hash);
        });
      });

      await new Promise((resolve, reject) => {
        connection.query(
          'UPDATE users SET password = ? WHERE email = ?',
          [hashedPassword, testUser.email],
          (err) => {
            if (err) return reject(err);
            resolve();
          }
        );
      });

      console.log('✅ Contraseña del usuario de prueba actualizada');
    } else {
      // Crear el usuario
      const hashedPassword = await new Promise((resolve, reject) => {
        bcrypt.hash(testUser.password, 10, (err, hash) => {
          if (err) return reject(err);
          resolve(hash);
        });
      });

      await new Promise((resolve, reject) => {
        connection.query(
          'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
          [testUser.username, testUser.email, hashedPassword],
          (err) => {
            if (err) return reject(err);
            resolve();
          }
        );
      });

      console.log('✅ Usuario de prueba creado exitosamente');
      console.log('   Email:', testUser.email);
      console.log('   Username:', testUser.username);
      console.log('   Password:', testUser.password);
    }

    connection.end();
    console.log('✅ Proceso completado');
  } catch (error) {
    console.error('❌ Error:', error);
    connection.end();
    process.exit(1);
  }
}

createTestUser();

