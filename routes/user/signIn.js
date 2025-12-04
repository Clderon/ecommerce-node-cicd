const AuthDecisionTableFactory = require('../../helpers/authDecisionTable');

module.exports = (app) => {
  const AuthDecisionTable = AuthDecisionTableFactory();
  const authDecisionTable = new AuthDecisionTable();

  app.get('/sign-in', (req, res) => {
    // Obtener mensajes de sesión
    const messages = app.helpers.msg(req);
    const success = messages.success;
    const warning = messages.warning;

    // Aplicar Tabla de Decisión: Verificar si usuario ya tiene sesión
    const decision = authDecisionTable.evaluateLogin({
      userSessionExists: req.session['user'] != null,
    });

    if (decision.actions.redirect === '/') {
      req.session['warning'] = decision.actions.error;
      return res.redirect(decision.actions.redirect);
    }

    res.render('sign/in', {
      title: 'Iniciar Sesión',
      success, 
      warning,
      csrfToken: req.csrfToken(),
    });
  });

  app.post('/sign-in', async (req, res) => {
    console.log('📥 POST /sign-in recibido');
    console.log('   Body:', { email: req.body.email, password: req.body.password ? '***' : 'undefined' });
    console.log('   CSRF Token:', req.body._csrf ? 'presente' : 'ausente');
    
    const email = req.body.email;
    const password = req.body.password;

    // Validación de datos
    req.checkBody('email', 'El correo electrónico no es válido').notEmpty().isEmail();
    req.checkBody('password', 'La contraseña debe tener al menos 4 caracteres')
        .notEmpty().isLength({min: 4});
    const errorsInValidation = req.validationErrors();
    
    if (errorsInValidation) {
      console.log('⚠️  Errores de validación:', errorsInValidation);
    }

    // Aplicar Tabla de Decisión: Verificar errores de validación
    let decision = authDecisionTable.evaluateLogin({
      validationErrors: errorsInValidation != null,
    });

    if (decision.matched && decision.actions.error && errorsInValidation && errorsInValidation.length > 0) {
      req.session['warning'] = errorsInValidation[0].msg;
      req.session.save((err) => {
        if (err) console.error('Error guardando sesión:', err);
        res.redirect(decision.actions.redirect);
      });
      return;
    }

    // Usar UserDAO para verificar credenciales
    const connection = app.dao.connectionFactory();
    const UserDao = new app.dao.userDAO(connection);

    try {
      // Conectar a la base de datos
      await new Promise((resolve, reject) => {
        connection.connect((err) => {
          if (err) {
            // Si el error es que ya está conectado, continuar
            if (err.code === 'PROTOCOL_ENQUEUE_AFTER_QUIT' || err.code === 'PROTOCOL_CONNECTION_LOST') {
              console.log('⚠️ Conexión ya establecida o perdida, reconectando...');
              // Intentar reconectar
              connection.connect((reconnectErr) => {
                if (reconnectErr) {
                  console.error('Error reconectando a MySQL:', reconnectErr);
                  return reject(reconnectErr);
                }
                return resolve();
              });
            } else {
              console.error('Error conectando a MySQL:', err);
              return reject(err);
            }
          } else {
            console.log('✅ Conectado a MySQL en', process.env.DB_HOST || 'localhost');
            resolve();
          }
        });
      });

      // Usar el método login del UserDAO para validar credenciales
      let user = null;
      let emailExists = false;
      let passwordCorrect = false;
      
      try {
        // Intentar hacer login - esto valida email y contraseña
        user = await UserDao.login(email, password);
        // Si llegamos aquí, el login fue exitoso
        emailExists = true;
        passwordCorrect = true;
      } catch (loginErr) {
        // El UserDAO.login lanza error si el email no existe o la contraseña es incorrecta
        const errorMessage = loginErr.toString();
        
        if (errorMessage.includes('Email is not registered')) {
          emailExists = false;
          passwordCorrect = false;
        } else if (errorMessage.includes('Password is not correct')) {
          emailExists = true;
          passwordCorrect = false;
        } else {
          // Otro tipo de error de base de datos, relanzar
          throw loginErr;
        }
      }
      
      // Si el login fue exitoso, obtener el usuario completo para la sesión
      if (emailExists && passwordCorrect && !user) {
        try {
          user = await UserDao.getUserByEmail(email);
        } catch (getUserErr) {
          console.error('Error obteniendo usuario:', getUserErr);
          // Continuar con el proceso aunque no podamos obtener todos los datos
        }
      }

      // Aplicar Tabla de Decisión: Evaluar resultado del login
      decision = authDecisionTable.evaluateLogin({
        userSessionExists: false,
        validationErrors: false,
        emailExists,
        passwordCorrect,
      });

      console.log('=== LOGIN DEBUG ===');
      console.log('Email:', email);
      console.log('Email exists:', emailExists);
      console.log('Password correct:', passwordCorrect);
      console.log('Decision matched:', decision.matched);
      console.log('Decision rule:', decision.rule);
      console.log('Decision redirect:', decision.actions.redirect);
      console.log('==================');

      // Verificar que la decisión coincidió y tiene acciones válidas
      if (!decision.matched || !decision.actions.redirect) {
        console.error('ERROR: No se encontró regla válida o falta redirect');
        console.error('Decision:', JSON.stringify(decision, null, 2));
        req.session['warning'] = 'An error occurred during login';
        connection.end();
        req.session.save((err) => {
          if (err) console.error('Error guardando sesión:', err);
          res.redirect('/sign-in');
        });
        return;
      }

      // Ejecutar acciones según la tabla de decisión
      if (decision.actions.success) {
        req.session['success'] = decision.actions.successMessage;
        
        if (decision.actions.createSession && user) {
          req.session['user'] = {
            id: user.id || null,
            username: user.username,
            email: email,
            admin: user.admin || false,
            cart: null,
          };
          console.log('✅ Session created for user:', user.username);
        }
      } else {
        req.session['warning'] = decision.actions.error;
      }
      
      // Cerrar la conexión a la base de datos antes de redirigir
      if (connection) {
        connection.end();
      }
      
      // Guardar la sesión y redirigir
      console.log('💾 Preparando redirección...');
      console.log('   Session ID:', req.sessionID);
      console.log('   User en sesión:', req.session['user'] ? req.session['user'].username : 'null');
      console.log('   Redirect a:', decision.actions.redirect);
      console.log('   Response headers antes de redirect:', {
        'content-type': res.getHeader('content-type'),
        'location': res.getHeader('location')
      });
      
      // Verificar que la respuesta no se haya enviado ya
      if (res.headersSent) {
        console.error('❌ ERROR: La respuesta ya fue enviada!');
        return;
      }
      
      // Marcar la sesión como modificada para forzar el guardado
      req.session.touch();
      
      // express-session guarda automáticamente la sesión antes de enviar la respuesta
      // Redirigir directamente - express-session se encargará de guardar la sesión
      console.log('✅ Login exitoso - Redirecting to:', decision.actions.redirect);
      console.log('   Enviando respuesta 302...');
      
      // Redirigir - express-session guardará la sesión automáticamente
      res.redirect(302, decision.actions.redirect);
      
      console.log('✅ Redirect enviado');
      console.log('   Response headers después de redirect:', {
        'statusCode': res.statusCode,
        'location': res.getHeader('location')
      });

    } catch (dbError) {
        // Manejar errores de base de datos
        console.error('Error en proceso de login:', dbError);
        
        // Si es un error conocido del UserDAO, usar esos mensajes
        const errorMessage = dbError.toString();
        if (errorMessage.includes('Email is not registered')) {
          emailExists = false;
          passwordCorrect = false;
        } else if (errorMessage.includes('Password is not correct')) {
          emailExists = true;
          passwordCorrect = false;
        } else {
          // Error de conexión o base de datos
          connection.end();
          req.session['warning'] = 'Database connection error. Please try again later.';
          req.session.save((err) => {
            if (err) console.error('Error guardando sesión:', err);
            res.redirect('/sign-in');
          });
          return;
        }

        // Aplicar tabla de decisión con el error conocido
        decision = authDecisionTable.evaluateLogin({
          userSessionExists: false,
          validationErrors: false,
          emailExists,
          passwordCorrect,
        });

        if (decision.matched && decision.actions.error) {
          req.session['warning'] = decision.actions.error;
        } else {
          req.session['warning'] = 'An error occurred during login';
        }

        connection.end();
        
        // Guardar la sesión antes de redirigir
        req.session.save((err) => {
          if (err) {
            console.error('❌ Error guardando sesión:', err);
          }
          console.log('❌ Login fallido - Redirecting to:', decision.actions.redirect || '/sign-in');
          res.redirect(decision.actions.redirect || '/sign-in');
        });
    }
  });
};

