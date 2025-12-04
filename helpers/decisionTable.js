/**
 * Tabla de Decisión Genérica
 *
 * Implementa un sistema de tabla de decisión que evalúa condiciones
 * y retorna acciones correspondientes según las reglas definidas.
 */

class DecisionTable {
  constructor(name) {
    this.name = name;
    this.rules = [];
  }

  /**
   * Agrega una regla a la tabla de decisión
   * @param {Object} conditions - Objeto con las condiciones que deben cumplirse
   * @param {Object} actions - Objeto con las acciones a ejecutar si se cumple la regla
   * @param {String} description - Descripción de la regla (opcional)
   */
  addRule(conditions, actions, description = '') {
    this.rules.push({
      conditions,
      actions,
      description,
    });
  }

  /**
   * Evalúa las condiciones y retorna la primera regla que coincida
   * @param {Object} context - Contexto con los valores actuales de las condiciones
   * @return {Object} - Objeto con matched (boolean), rule (número de regla), y actions (acciones)
   */
  evaluate(context) {
    for (let i = 0; i < this.rules.length; i++) {
      const rule = this.rules[i];
      if (this._matchesConditions(rule.conditions, context)) {
        return {
          matched: true,
          rule: i + 1,
          description: rule.description,
          actions: rule.actions,
        };
      }
    }

    // Si ninguna regla coincide, retornar que no hubo coincidencia
    return {
      matched: false,
      rule: null,
      description: 'No rule matched',
      actions: {},
    };
  }

  /**
   * Verifica si las condiciones de una regla se cumplen con el contexto dado
   * @param {Object} ruleConditions - Condiciones de la regla
   * @param {Object} context - Contexto actual
   * @return {Boolean} - true si todas las condiciones se cumplen
   */
  _matchesConditions(ruleConditions, context) {
    for (const key in ruleConditions) {
      const ruleValue = ruleConditions[key];
      const contextValue = context[key];

      // Si la regla requiere true y el contexto es false (o viceversa), no coincide
      if (ruleValue !== contextValue) {
        return false;
      }
    }

    // Si todas las condiciones coinciden, la regla se cumple
    return true;
  }
}

module.exports = () => DecisionTable;

