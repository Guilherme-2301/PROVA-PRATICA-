#!/bin/sh
# Executa os testes obrigatorios e grava a saida em evidencias/*.txt
# Uso (na raiz do projeto): sh scripts/coletar-evidencias.sh
set -u
E=evidencias; mkdir -p "$E"
docker compose config > "$E/01-compose-config.txt" 2>&1 && echo "config OK" >> "$E/01-compose-config.txt"
docker compose up -d --build > "$E/02-up-build.txt" 2>&1
docker images --filter "reference=quitanda-*" > "$E/03-imagens.txt"
echo "aguardando healthchecks..."; sleep 40
docker compose ps > "$E/04-ps.txt" 2>&1
docker compose events --since 10m --until 0s --filter event=health_status > "$E/05-ordem-health.txt" 2>&1
{ curl -si http://localhost:8080 | head -5; echo; curl -si http://localhost:3000/frutas; } > "$E/06-acessos.txt" 2>&1
docker compose down > "$E/07-persistencia.txt" 2>&1
docker compose up -d >> "$E/07-persistencia.txt" 2>&1; sleep 25
curl -s http://localhost:3000/frutas >> "$E/07-persistencia.txt" 2>&1
for s in database backend frontend; do docker compose logs "$s" > "$E/08-logs-$s.txt" 2>&1; done
docker compose stop database >/dev/null 2>&1; sleep 25
docker compose logs --tail 20 backend > "$E/09-falha-banco.txt" 2>&1; docker compose ps >> "$E/09-falha-banco.txt" 2>&1
docker compose start database >/dev/null 2>&1
echo "Evidencias gravadas em $E/ (tire tambem prints de http://localhost:8080)"
