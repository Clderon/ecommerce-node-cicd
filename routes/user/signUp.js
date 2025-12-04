module.exports = (app) => {
  app.get('/sign-up', (req, res) => {
    // Obtener mensajes de sesión
    const messages = app.helpers.msg(req);
    const success = messages.success;
    const warning = messages.warning;

    if (req.session['user'] || req.session['user'] != null) {
      req.session['warning'] = 'Ya tienes una sesión activa. No puedes acceder a esta área.';
      return res.redirect('/');
    }

    res.render('sign/up', {
      title: 'Crear Cuenta',
      success,
      warning,
      csrfToken: req.csrfToken(),
    });
  });

  app.post('/sign-up', (req, res) => {
    const username = req.body.username;
    const email = req.body.email;
    const password = req.body.password;

    req.checkBody('username', 'El nombre de usuario está vacío').notEmpty().isLength({min: 4});
    req.checkBody('email', 'El correo electrónico no es válido').notEmpty().isEmail();
    req.checkBody('password', 'La contraseña debe tener al menos 4 caracteres').notEmpty();
    const errosInValidation = req.validationErrors();
    if (errosInValidation) {
      req.session['warning'] = errosInValidation[0].msg;
      res.redirect('/sign-up');
    };

    const connection = app.dao.connectionFactory();
    const UserDao = new app.dao.userDAO(connection);

    UserDao.saveUser(username, email, password)
        .then((result) => {
          req.session['success'] = result;
          // Create Session
          req.session['user'] = {
            username: username,
            email: email,
            admin: false,
            cart: null,
          };
          res.redirect('/');
        })
        .catch((err) => {
          req.session['warning'] = err;
          res.redirect('/sign-up');
        });
  });
};
