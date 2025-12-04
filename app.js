require('dotenv').config();
const app = require('./config/custom-express');
const port = process.env.PORT || 3000;
const host = process.env.HOST || 'localhost';

// Iniciar el servidor
app.listen(port, host, () => {
  console.log(`🚀 Servidor corriendo en http://${host}:${port}`);
  console.log(`📊 Base de datos: ${process.env.DB_NAME || 'equantom'}`);
  console.log(`🔐 Host DB: ${process.env.DB_HOST || 'localhost'}`);
});

module.exports = app;

