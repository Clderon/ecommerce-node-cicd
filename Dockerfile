# Multi-stage build para optimizar tamaño de imagen
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias de producción
RUN npm ci --only=production && npm cache clean --force

# Stage final
FROM node:18-alpine

WORKDIR /app

# Copiar node_modules desde builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código de la aplicación
COPY . .

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

# Exponer puerto de la aplicación
EXPOSE 3000

# Healthcheck usando endpoint /health (más rápido, no requiere DB)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando para iniciar la aplicación
CMD ["node", "app.js"]

