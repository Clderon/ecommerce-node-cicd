/**
 * Pruebas Unitarias - DecisionTable
 * 
 * Pruebas rápidas que evalúan la lógica de la tabla de decisión
 * sin necesidad de navegador, webdriver o base de datos.
 */

const DecisionTable = require('../../helpers/decisionTable')();

describe('DecisionTable - Pruebas Unitarias', () => {
  let decisionTable;

  beforeEach(() => {
    decisionTable = new DecisionTable('test-table');
  });

  describe('Constructor', () => {
    test('debe crear una instancia con nombre y reglas vacías', () => {
      expect(decisionTable.name).toBe('test-table');
      expect(decisionTable.rules).toEqual([]);
    });
  });

  describe('addRule', () => {
    test('debe agregar una regla a la tabla', () => {
      const conditions = { condition1: true };
      const actions = { action1: 'do something' };
      
      decisionTable.addRule(conditions, actions, 'Test rule');
      
      expect(decisionTable.rules).toHaveLength(1);
      expect(decisionTable.rules[0].conditions).toEqual(conditions);
      expect(decisionTable.rules[0].actions).toEqual(actions);
      expect(decisionTable.rules[0].description).toBe('Test rule');
    });

    test('debe agregar múltiples reglas', () => {
      decisionTable.addRule({ a: true }, { action: 'A' });
      decisionTable.addRule({ b: true }, { action: 'B' });
      
      expect(decisionTable.rules).toHaveLength(2);
    });
  });

  describe('evaluate', () => {
    test('debe retornar la primera regla que coincida', () => {
      decisionTable.addRule(
        { condition1: true, condition2: false },
        { action: 'rule1' },
        'Regla 1'
      );
      decisionTable.addRule(
        { condition1: true, condition2: true },
        { action: 'rule2' },
        'Regla 2'
      );

      const result = decisionTable.evaluate({
        condition1: true,
        condition2: true
      });

      expect(result.matched).toBe(true);
      expect(result.rule).toBe(2); // Segunda regla (índice 1 + 1)
      expect(result.actions.action).toBe('rule2');
    });

    test('debe retornar matched: false si ninguna regla coincide', () => {
      decisionTable.addRule(
        { condition1: true },
        { action: 'rule1' }
      );

      const result = decisionTable.evaluate({
        condition1: false
      });

      expect(result.matched).toBe(false);
      expect(result.rule).toBeNull();
      expect(result.actions).toEqual({});
    });

    test('debe evaluar condiciones exactas', () => {
      decisionTable.addRule(
        { a: true, b: false },
        { action: 'match' }
      );

      const result1 = decisionTable.evaluate({ a: true, b: false });
      expect(result1.matched).toBe(true);

      const result2 = decisionTable.evaluate({ a: true, b: true });
      expect(result2.matched).toBe(false);
    });

    test('debe retornar la descripción de la regla', () => {
      decisionTable.addRule(
        { test: true },
        { action: 'test' },
        'Descripción de prueba'
      );

      const result = decisionTable.evaluate({ test: true });
      expect(result.description).toBe('Descripción de prueba');
    });
  });

  describe('_matchesConditions', () => {
    test('debe retornar true si todas las condiciones coinciden', () => {
      const conditions = { a: true, b: false, c: 'value' };
      const context = { a: true, b: false, c: 'value' };

      const result = decisionTable._matchesConditions(conditions, context);
      expect(result).toBe(true);
    });

    test('debe retornar false si alguna condición no coincide', () => {
      const conditions = { a: true, b: false };
      const context = { a: true, b: true };

      const result = decisionTable._matchesConditions(conditions, context);
      expect(result).toBe(false);
    });

    test('debe manejar valores undefined', () => {
      const conditions = { a: true };
      const context = {};

      const result = decisionTable._matchesConditions(conditions, context);
      expect(result).toBe(false);
    });
  });
});

