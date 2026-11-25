# Локальный LLM в закрытом контуре

[![ci](https://github.com/eightpaws/onprem-llm-closed-loop/actions/workflows/ci.yml/badge.svg)](https://github.com/eightpaws/onprem-llm-closed-loop/actions/workflows/ci.yml)

Стенд для организаций, где облака запрещены: модели работают на своём железе, контейнеры физически не имеют выхода в интернет, а невыход данных за периметр проверяется скриптом, а не обещанием.

## Задача, которую это решает

Требование звучит как «ИИ, но чтобы данные не уходили». На практике это три отдельные задачи, и проверяются они по-разному:

| Задача | Чем проверяется здесь |
|---|---|
| Данные не уходят наружу | сеть docker объявлена как `internal`, `scripts/verify-isolation.sh` показывает результат в терминале |
| Модель работает на своём железе | `deploy/docker-compose.yml`, две проверенные связки: Ollama и llama.cpp server |
| Стенд даёт заявленную скорость | `scripts/bench.sh` пишет замер в `results/`, методика и ограничения описаны |

## Что проверено на реальном железе

Все цифры измерены на Tesla V100-SXM2 16 ГБ и опубликованы с сырыми данными в [v100-field-notes](https://github.com/eightpaws/v100-field-notes). Здесь они собраны как правила выбора, чтобы не повторять чужие ошибки:

- на 16 ГБ практический потолок для модели 14B - контекст 32k с `q8_0` KV и включённым FlashAttention; контекст 64k не влезает ни при какой точности KV;
- плотная модель 32B на этой карте нежизнеспособна (3,0 tok/s), а MoE 30B с тем же числом слоёв даёт 24,5 tok/s: выбор архитектуры важнее выбора движка;
- `num_batch=2048` даёт трёхкратный рост против 128 и +31% против дефолта Ollama, это самая дешёвая правка;
- префиксный кэш в `llama-server` переживает правку хвоста промпта (95 мс против повторного prefill 1697 токенов), в Ollama любая правка хвоста сбрасывает кэш;
- патчи volta-fa обещают +34-45%, по факту дают +7,4% на decode, и 4 из 8 патчей не применяются без ручной работы;
- DRY sampler не воспроизвёлся на qwen2.5-coder-14b и стоит около 3% скорости decode, держать выключенным.

## Быстрый старт

```bash
cp deploy/env.example deploy/env
vi deploy/env                                # модель, пути, контекст
set -a; . deploy/env; set +a
docker compose -f deploy/docker-compose.yml up -d
./scripts/verify-isolation.sh                # должно показать, что наружу хода нет
./scripts/bench.sh qwen2.5-coder:14b         # замер попадёт в results/
```

## Состав

```
deploy/   docker-compose.yml, Dockerfile для сборки llama.cpp под sm_70, env.example
docs/     чек-лист закрытого контура, правила выбора модели
scripts/  проверка изоляции, замер скорости
results/  замеры с этого стенда и ссылки на подробные карточки
```

## Что здесь не проверено

Честный список, чтобы не создавать ложного впечатления:

- много-GPU конфигурации: всё измерено на одной карте 16 ГБ;
- промышленные объёмы: стенд рассчитан на пилот и на доказательство работоспособности, а не на 500 одновременных пользователей;
- vLLM-форк для Volta существует и работает, но в базовую поставку не включён: требует своей сборки;
- качество ответов под конкретную задачу здесь не решается, только скорость и влезаемость в память.

## Смежные репозитории

| Репозиторий | Что добавляет |
|---|---|
| [v100-field-notes](https://github.com/eightpaws/v100-field-notes) | замеры на Tesla V100, из которых взяты правила выбора модели |
| [it-infra-audit-kit](https://github.com/eightpaws/it-infra-audit-kit) | аудит домена, гипервизора и бэкапов: только чтение, отчёт с уровнями риска |
| [eightpaws](https://github.com/eightpaws) | профиль: что ещё опубликовано |

## Лицензии

Код и скрипты: MIT (`LICENSE`). Тексты, документация и результаты замеров: CC BY 4.0 (`LICENSE-DOCS`).

---

**In English.** A closed-loop LLM deployment for environments where cloud services are banned: containers have no route to the internet by construction, and the absence of egress is verified by a script rather than promised. The measured rules of thumb for a 16 GB card (14B dense at 32k context, 30B MoE instead of dense 32B, `num_batch=2048`, prefix cache on, DRY off) come from raw measurements published in [v100-field-notes](https://github.com/eightpaws/v100-field-notes). Author: Anton Korovin, [korovin.info](https://korovin.info).

English: [README.en.md](README.en.md).
