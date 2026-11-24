#!/usr/bin/env bash
# Замер скорости на поднятом стенде. Пишет JSON в results/ с датой и хостом,
# чтобы цифру можно было перепроверить, а не пересказывать.
set -euo pipefail
MODEL="${1:?укажите модель, например qwen2.5-coder:14b}"
PROMPT="${2:-Опиши, как организовать резервное копирование в закрытом контуре.}"
HOST_SHORT="$(hostname -s 2>/dev/null || echo host)"
OUT="results/$(date +%Y%m%d-%H%M)-${HOST_SHORT}.json"

echo "замер: $MODEL"
curl -s http://127.0.0.1:11434/api/generate \
  -d "{\"model\":\"${MODEL}\",\"prompt\":\"${PROMPT}\",\"stream\":false}" \
| python3 -c '
import json, sys, datetime
d = json.load(sys.stdin)
ev, ed = d.get("eval_count"), d.get("eval_duration")
pv, pd = d.get("prompt_eval_count"), d.get("prompt_eval_duration")
row = {
  "model": sys.argv[1],
  "measured_at": datetime.datetime.now().isoformat(timespec="seconds"),
  "decode_tok_s": round(ev / (ed / 1e9), 2) if ev and ed else None,
  "prefill_tok_s": round(pv / (pd / 1e9), 2) if pv and pd else None,
  "eval_count": ev,
}
open(sys.argv[2], "w", encoding="utf-8").write(json.dumps(row, ensure_ascii=False, indent=1))
print(json.dumps(row, ensure_ascii=False, indent=1))
' "$MODEL" "$OUT"
echo "записано в $OUT"
