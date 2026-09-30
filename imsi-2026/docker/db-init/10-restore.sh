#!/bin/sh
# Importa o arquivo backend/db/bkt_quitanda.sql no PostgreSQL.
#
# ATENCAO: apesar da extensao .sql, esse arquivo e um DUMP BINARIO no formato
# "custom" do pg_dump (assinatura "PGDMP"), NAO um script SQL textual. Por isso
# o carregamento automatico de *.sql do entrypoint (que usaria o psql) nao serve:
# a restauracao precisa do pg_restore.
#
# Este script e executado pelo entrypoint oficial da imagem postgres SOMENTE na
# primeira inicializacao, quando o volume de dados esta vazio. Para reimportar
# do zero: docker compose down -v && docker compose up -d --build
#
# Este arquivo pode ser executado (subprocesso) OU lido via "source" pelo entrypoint,
# dependendo do bit de execucao. Por isso a falha do pg_restore e propagada de forma
# explicita ("|| exit 1"): a inicializacao do banco e abortada e o container falha
# de forma visivel, em vez de subir com um banco vazio/parcial.

echo "[init] Restaurando dump /dump/bkt_quitanda.sql no banco '$POSTGRES_DB'..."

# --no-owner / --no-privileges: o dump foi gerado com o dono "postgres"; aqui o
#     dono passa a ser POSTGRES_USER, seja qual for o valor configurado.
# --exit-on-error: qualquer erro interrompe a carga (nada de banco meio importado).
# O banco ja existe (criado pelo entrypoint via POSTGRES_DB), por isso nao usamos
# --create. A extensao uuid-ossp exigida pelo dump vem nativa na imagem oficial.
pg_restore \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    --no-owner \
    --no-privileges \
    --exit-on-error \
    --verbose \
    /dump/bkt_quitanda.sql \
    || { echo "[init] ERRO: falha ao importar o dump; abortando a inicializacao." >&2; exit 1; }

echo "[init] Importacao concluida."
