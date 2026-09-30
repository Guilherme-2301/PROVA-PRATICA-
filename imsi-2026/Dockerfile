# syntax=docker/dockerfile:1
#
# Dockerfile multi-stage UNICO do projeto da quitanda.
# Alvos nomeados (use com --target ou com "build.target" no compose.yaml):
#
#   frontend  -> React + Vite compilado, servido na porta 8080
#   backend   -> API Node/Express (somente dependencias de producao), porta 3000
#
# Nenhuma credencial ou endereco de banco esta neste arquivo: DB_HOST, DB_USER,
# DB_PASS, DB_NAME e DB_PORT chegam ao backend como variaveis de ambiente em
# tempo de execucao (definidas no compose.yaml / .env).

ARG NODE_VERSION=22

# =============================================================================
# FRONTEND - estagio 1: compila o React com Vite
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS frontend-build
WORKDIR /build

# Cache de dependencias: so os manifestos entram primeiro. Esta camada (e o
# npm ci) so e refeita quando package.json / package-lock.json mudam.
COPY frontend/package.json frontend/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund

# Codigo-fonte depois das dependencias (muda com mais frequencia)
COPY frontend/ ./

# URL da API acessada pelo NAVEGADOR (o Vite embute o valor no bundle em build).
# Nao e segredo: e um endereco publico do backend publicado no host.
ARG VITE_API_URL=http://localhost:3000
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

# =============================================================================
# FRONTEND - estagio final (alvo "frontend"): serve o /dist na porta 8080
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS frontend
ENV NODE_ENV=production \
    NPM_CONFIG_UPDATE_NOTIFIER=false
WORKDIR /app

# Servidor estatico minimo (somente ele, sem o toolchain do Vite). Vem antes do
# COPY do dist para que esta camada fique em cache entre rebuilds do frontend.
RUN npm install --omit=dev --no-audit --no-fund --no-package-lock serve@14.2.6 \
    && npm cache clean --force

# Somente o resultado da compilacao vai para a imagem final
COPY --from=frontend-build --chown=node:node /build/dist ./dist

# Usuario nao privilegiado (uid 1000, ja existe na imagem oficial do Node).
# Porta 8080 (> 1024) dispensa privilegios de root.
USER node
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:8080/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# --single: fallback para index.html (SPA) | --no-clipboard: sem efeitos no container
CMD ["node_modules/.bin/serve", "--single", "--no-clipboard", "--listen", "8080", "dist"]

# =============================================================================
# BACKEND - estagio 1: instala SOMENTE dependencias de producao
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS backend-deps
WORKDIR /app

COPY backend/package.json backend/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --no-audit --no-fund

# =============================================================================
# BACKEND - estagio final (alvo "backend"): API na porta 3000
# =============================================================================
FROM node:${NODE_VERSION}-alpine AS backend
ENV NODE_ENV=production \
    DOTENV_CONFIG_QUIET=true
WORKDIR /app

# Ordem pensada para o cache: node_modules (raramente muda) -> manifesto -> src.
# backend/.env e backend/db/ NAO sao copiados (ver .dockerignore): credenciais
# e dump do banco ficam fora da imagem.
COPY --from=backend-deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node backend/package.json ./
COPY --chown=node:node backend/src ./src

USER node
EXPOSE 3000

# /health executa "SELECT 1": so fica saudavel se o banco estiver acessivel
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Forma "exec": o node recebe os sinais (SIGTERM) diretamente
CMD ["node", "src/main.js"]
