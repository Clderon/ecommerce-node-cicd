const mysql = require('mysql2');
const bcrypt = require('bcryptjs');

class userDAO {
  constructor(connection) {
    this.connection = connection;
  }

  /**
   * Guarda un nuevo usuario en la base de datos
   * @param {String} username - Nombre de usuario
   * @param {String} email - Email del usuario
   * @param {String} password - Contraseña sin encriptar
   * @return {Promise} - Promise que resuelve con mensaje de éxito
   */
  saveUser(username, email, password) {
    return new Promise((resolve, reject) => {
      // Verificar si el email ya existe
      this.connection.query(
          'SELECT * FROM users WHERE email = ?',
          [email],
          (err, results) => {
            if (err) {
              console.error('Error verificando email:', err);
              return reject('Error de base de datos');
            }

            if (results.length > 0) {
              return reject('¡El correo electrónico ya está registrado!');
            }

            // Encriptar la contraseña
            bcrypt.hash(password, 10, (hashErr, hashedPassword) => {
              if (hashErr) {
                console.error('Error hashing password:', hashErr);
                return reject('Error procesando la contraseña');
              }

              // Insertar el nuevo usuario
              this.connection.query(
                  'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
                  [username, email, hashedPassword],
                  (insertErr, insertResults) => {
                    if (insertErr) {
                      console.error('Error insertando usuario:', insertErr);
                      return reject('Error al crear el usuario');
                    }

                    resolve('¡Usuario creado exitosamente!');
                  },
              );
            });
          },
      );
    });
  }

  /**
   * Valida las credenciales de login de un usuario
   * @param {String} email - Email del usuario
   * @param {String} password - Contraseña sin encriptar
   * @return {Promise} - Promise que resuelve con el usuario si las credenciales son correctas
   */
  login(email, password) {
    return new Promise((resolve, reject) => {
      // Buscar el usuario por email
      this.connection.query(
          'SELECT * FROM users WHERE email = ?',
          [email],
          (err, results) => {
            if (err) {
              console.error('Error en query de login:', err);
              return reject('Database error');
            }

            if (results.length === 0) {
              return reject('Email is not registered!');
            }

            const user = results[0];

            // Verificar la contraseña
            bcrypt.compare(password, user.password, (compareErr, isMatch) => {
              if (compareErr) {
                console.error('Error comparando contraseña:', compareErr);
                return reject('Error verifying password');
              }

              if (!isMatch) {
                return reject('Password is not correct!');
              }

              // Si todo está bien, retornar el usuario (sin la contraseña)
              const {password: _, ...userWithoutPassword} = user;
              resolve(userWithoutPassword);
            });
          },
      );
    });
  }

  /**
   * Obtiene un usuario por email
   * @param {String} email - Email del usuario
   * @return {Promise} - Promise que resuelve con el usuario
   */
  getUserByEmail(email) {
    return new Promise((resolve, reject) => {
      this.connection.query(
          'SELECT * FROM users WHERE email = ?',
          [email],
          (err, results) => {
            if (err) {
              return reject(err);
            }

            if (results.length === 0) {
              return resolve(null);
            }

            const user = results[0];
            const {password: _, ...userWithoutPassword} = user;
            resolve(userWithoutPassword);
          },
      );
    });
  }
}

module.exports = () => userDAO;

