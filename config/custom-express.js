const path = require('path');
const express = require('express');
const bodyParser = require('body-parser');
const consign = require('consign');
const { engine } = require('express-handlebars');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const csrf = require('csurf');
const cors = require('cors');
require('dotenv').config();

class AppController {
  constructor() {
    this.app = express();

    this.middlewares();
    this.routes();
    this.errors();
  }

  middlewares() {
    this.app.use(bodyParser.urlencoded({ extended: true }));
    this.app.use(bodyParser.json());
    this.app.use(cookieParser());
    this.app.use(session({
      secret: process.env.SESSION_SECRET || 'secretpasscryp',
      resave: false,
      saveUninitialized: false, // Cambiar a false para no guardar sesiones vacías
      cookie: {
        secure: false, // Cambiar a true en producción con HTTPS
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000 // 24 horas
      },
      // Forzar el guardado de la sesión antes de enviar la respuesta
      rolling: true
    }));
    this.app.use(cors());
    this.app.use(csrf({ cookie: true }));
    
    // express-validator v5 - se debe usar como middleware para agregar métodos a req
    const validator = require('express-validator');
    this.app.use(validator());

    // Middleware para hacer disponible req.csrfToken() en las vistas
    this.app.use((req, res, next) => {
      res.locals.csrfToken = req.csrfToken();
      next();
    });

    this.app.engine('hbs', engine({
      extname: 'hbs',
      defaultLayout: 'layout',
      layoutsDir: 'views/layouts/',
    }));
    this.app.set('view engine', 'hbs');
  }

  routes() {
    this.app.set('views', path.join(__dirname, '../views'));
    this.app.use(express.static(path.join(__dirname, '../public')));

    // Ruta principal
    this.app.get('/', (req, res) => {
      const success = req.session['success'];
      const warning = req.session['warning'];
      
      // Limpiar mensajes de sesión después de mostrarlos
      delete req.session['success'];
      delete req.session['warning'];

      // Cargar categorías y productos desde la base de datos
      const connection = this.app.dao.connectionFactory();
      const CategoriesDao = new this.app.dao.categoriesDAO(connection);
      const ProductsDao = new this.app.dao.productsDAO(connection);

      Promise.all([
        CategoriesDao.list(),
        ProductsDao.list()
      ])
        .then(([categories, products]) => {
          connection.end();
          res.render('home/index', {
            title: 'Inicio',
            success,
            warning,
            user: req.session['user'] || null,
            categories: categories || [],
            products: products || [],
          });
        })
        .catch((err) => {
          console.error('Error cargando datos:', err);
          connection.end();
          res.render('home/index', {
            title: 'Inicio',
            success,
            warning,
            user: req.session['user'] || null,
            categories: [],
            products: [],
          });
        });
    });

    // Cargar rutas y DAOs usando consign
    consign()
      .include('routes')
      .then('dao')
      .then('helpers')
      .into(this.app);

    // Middleware para cargar categorías en todas las vistas (después de cargar DAOs)
    // Se ejecuta después de que consign haya cargado los DAOs
    this.app.use((req, res, next) => {
      // Verificar si los DAOs están disponibles
      if (!this.app.dao || !this.app.dao.connectionFactory || !this.app.dao.categoriesDAO) {
        res.locals.categories = [];
        return next();
      }

      try {
        const connection = this.app.dao.connectionFactory();
        const CategoriesDao = new this.app.dao.categoriesDAO(connection);
        
        CategoriesDao.list()
          .then((categories) => {
            res.locals.categories = categories || [];
            connection.end();
            next();
          })
          .catch((err) => {
            console.error('Error cargando categorías:', err);
            res.locals.categories = [];
            if (connection && connection.end) connection.end();
            next();
          });
      } catch (err) {
        console.error('Error en middleware de categorías:', err);
        res.locals.categories = [];
        next();
      }
    });
  }

  errors() {
    // Manejo específico de errores CSRF
    this.app.use((err, req, res, next) => {
      if (err.code === 'EBADCSRFTOKEN') {
        console.error('❌ Error CSRF:', err.message);
        console.error('   URL:', req.url);
        console.error('   Method:', req.method);
        req.session['warning'] = 'Invalid security token. Please try again.';
        if (req.url.includes('/sign-in')) {
          return res.redirect('/sign-in');
        } else if (req.url.includes('/sign-up')) {
          return res.redirect('/sign-up');
        }
        return res.status(403).send('Invalid CSRF token');
      }
      next(err);
    });
    
    // Manejo de errores 404
    this.app.use((req, res, next) => {
      return res.status(404)
        .render('errors/404', { title: 'Page not Found - 404' });
    });
    
    // Manejo de errores 500 (habilitado para evitar crashes)
    this.app.use((err, req, res, next) => {
      console.error('❌ Error no manejado:', err);
      console.error('Stack:', err.stack);
      return res.status(500)
        .render('errors/500', { title: 'Error - 500' });
    });
  }
}

module.exports = new AppController().app;

