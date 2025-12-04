/**
 * Pruebas Unitarias - Mensajes (msg.js)
 *
 * Pruebas rápidas que evalúan la lógica de mensajes
 * sin necesidad de navegador o base de datos.
 */

const msgFactory = require('../../helpers/msg');

describe('msg - Pruebas Unitarias', () => {
  describe('Funciones de mensajes', () => {
    test('debe exportar una función factory', () => {
      // msg.js exporta una función que retorna la función msg
      expect(typeof msgFactory).toBe('function');
      expect(msgFactory).toBeDefined();
    });

    test('debe retornar una función cuando se llama el factory', () => {
      const msg = msgFactory();
      expect(typeof msg).toBe('function');
    });

    test('debe retornar objeto con success y warning cuando se ejecuta', () => {
      const msg = msgFactory();
      // Mock de request con sesión
      const mockReq = {
        session: {
          'success': 'Mensaje de éxito',
          'warning': null,
        },
      };

      const result = msg(mockReq);

      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('warning');
      expect(result.success).toBe('Mensaje de éxito');
      expect(result.warning).toBeNull();
    });

    // Si msg.js tiene funciones específicas, agrega pruebas aquí
    // Por ejemplo:
    // test('getSuccessMessage debe retornar mensaje de éxito', () => {
    //   const message = msg.getSuccessMessage('Operación exitosa');
    //   expect(message).toContain('Operación exitosa');
    // });
  });
});

