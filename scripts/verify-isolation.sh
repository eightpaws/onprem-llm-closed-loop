#!/usr/bin/env bash
# Проверяет, что стенд действительно изолирован.
# Ожидаемый результат: все проверки выхода наружу провалены, порты слушают только loopback.
set -u
fail=0
COMPOSE="deploy/docker-compose.yml"

echo "== 1. DNS наружу (ожидается провал)"
if getent hosts api.openai.com >/dev/null 2>&1; then
  echo "   ПРОВАЛ: имя разрешилось, из контура есть DNS-выход"; fail=1
else
  echo "   ок: имя не разрешается"
fi

echo "== 2. Прямой выход по HTTPS (ожидается провал)"
if curl -s -m 6 -o /dev/null https://1.1.1.1; then
  echo "   ПРОВАЛ: есть маршрут наружу"; fail=1
else
  echo "   ок: соединения нет"
fi

echo "== 3. Изнутри контейнера (ожидается провал)"
if docker compose -f "$COMPOSE" exec -T ollama \
     sh -c 'curl -s -m 6 -o /dev/null https://api.openai.com' 2>/dev/null; then
  echo "   ПРОВАЛ: контейнер достаёт интернет"; fail=1
else
  echo "   ок: контейнер изолирован"
fi

echo "== 4. Порты слушают только loopback (ожидается 127.0.0.1)"
ss -tlnp 2>/dev/null | grep -E ':(11434|8080)\b' || echo "   портов не найдено: стенд не поднят"

echo "== 5. Отладочный вывод выключен"
if docker compose -f "$COMPOSE" exec -T ollama env 2>/dev/null | grep -q 'OLLAMA_DEBUG=0'; then
  echo "   ок"
else
  echo "   внимание: проверьте переменные окружения ollama"
fi

echo
if [ "$fail" -eq 0 ]; then echo "ИТОГ: контур закрыт"; else echo "ИТОГ: есть выход наружу, смотреть пункты с ПРОВАЛ"; fi
exit "$fail"
