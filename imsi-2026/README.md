# Quitanda – Docker + Compose

Ambiente completo (PostgreSQL + API Node + frontend React/Vite) com um único comando.

## Arquivos
| Arquivo | Função |
|---|---|
| `Dockerfile` | Multi-stage único, alvos `frontend` (porta 8080) e `backend` (porta 3000) |
| `compose.yaml` | Serviços `database`, `backend`, `frontend`, rede `quitanda-net`, volume `pgdata` |
| `docker/db-init/10-restore.sh` | Importa o dump com `pg_restore` na 1ª inicialização |
| `.env.example` | Modelo de variáveis (o `.env` real é ignorado pelo git) |

## Iniciar
```bash
cp .env.example .env            # 1ª vez: ajuste DB_PASS
docker compose config -q        # valida o compose
docker compose up -d --build    # constrói e sobe tudo (database -> backend -> frontend)
docker compose ps               # os 3 devem ficar "healthy"
```
Acessos: http://localhost:8080 (frontend) e http://localhost:3000/frutas (API).

## Logs e encerramento
```bash
docker compose logs -f              # todos os serviços
docker compose logs backend         # só o backend
docker compose down                 # encerra, MANTÉM os dados (volume)
docker compose down -v              # encerra e APAGA os dados (volume pgdata)
```

## Sobre o arquivo `backend/db/bkt_quitanda.sql`
Apesar da extensão, é um **dump binário** (`pg_dump -Fc`, assinatura `PGDMP`, gerado no PostgreSQL 18.1),
não SQL textual. Por isso **não** é colocado em `docker-entrypoint-initdb.d` (seria executado como SQL e falharia):
ele é montado em `/dump` e restaurado por `10-restore.sh` com `pg_restore`. A carga ocorre só quando o volume
está vazio. Para reimportar: `docker compose down -v && docker compose up -d --build`.
O dump exige PostgreSQL ≥ 17, por isso a imagem é `postgres:18-alpine`.

## Ajustes feitos no código
- `backend/src/config/db.js`: `DB_PORT | 5432` (OU bit-a-bit) → `Number(DB_PORT) || 5432`.
- `backend/src/main.js`: nova rota `GET /health` (`SELECT 1`) usada no HEALTHCHECK.
- `frontend/src/App.jsx`: URL da API via `VITE_API_URL` (build arg) e `key` na lista.

## Testes obrigatórios (comandos)
```bash
docker compose config                                   # 1. validação
docker compose build                                    # 2. imagens (sem Node/Postgres local)
docker compose up -d                                    # 3. um comando
docker compose ps ; docker inspect --format '{{.Name}} {{.State.Health.Status}}' $(docker compose ps -q)
docker compose events --since 5m --filter event=health_status   # 4. ordem: database -> backend -> frontend
curl -i http://localhost:8080 ; curl -i http://localhost:3000/frutas   # 5. acessos
docker compose down && docker compose up -d && curl http://localhost:3000/frutas   # 6. persistência
```

### Diagnosticar falha de conexão com o banco (item 7)
```bash
# a) banco parado: backend vira unhealthy e o log mostra o erro
docker compose stop database
docker compose logs --tail 20 backend       # "Healthcheck falhou..." / "ECONNREFUSED" / "Unexpected error on idle client"
docker compose ps                           # backend unhealthy
docker compose start database

# b) host errado (simulação)
docker compose run --rm --no-deps -e DB_HOST=banco-errado backend
#    -> "getaddrinfo ENOTFOUND banco-errado"   (nome do serviço não resolve na rede)

# c) senha errada
docker compose run --rm -e DB_PASS=errada backend
#    -> "password authentication failed for user ..." ; no lado do banco: docker compose logs database
```
Como ler: `ENOTFOUND` = nome/host errado; `ECONNREFUSED` = banco fora do ar/porta errada;
`password authentication failed` = credenciais divergentes entre `backend` e `database`.
