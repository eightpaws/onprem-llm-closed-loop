# Local LLM in a closed perimeter

[![ci](https://github.com/eightpaws/onprem-llm-closed-loop/actions/workflows/ci.yml/badge.svg)](https://github.com/eightpaws/onprem-llm-closed-loop/actions/workflows/ci.yml)

A stand for organisations where clouds are not allowed: models run on own hardware, containers have
no route to the internet, and "data does not leave the perimeter" is verified by a script rather than
by a promise.

## The problem

The requirement sounds like "AI, but data stays inside". In practice it is three separate tasks, and
each is verified differently:

| Task | How it is verified here |
|---|---|
| Data does not leave | docker network declared `internal`; `scripts/verify-isolation.sh` shows the result in a terminal |
| The model runs on own hardware | `deploy/docker-compose.yml`, two tested stacks: Ollama and llama.cpp server |
| The stand delivers the claimed speed | `scripts/bench.sh` writes a measurement into `results/`; method and limits are documented |

CI checks the contract without a GPU: network stays `internal`, ports stay on loopback, and the build
does not drift to an unsupported CUDA architecture.

## Measured, not copied

All numbers were measured on a Tesla V100-SXM2 16 GB (sm_70) and published with raw data in
[v100-field-notes](https://github.com/eightpaws/v100-field-notes). Rules that follow from them:

- 16 GB caps a 14B model at 32k context with `q8_0` KV and FlashAttention; 64k does not fit at any KV precision;
- a dense 32B is not viable on this card (3.0 tok/s), while a 30B MoE at the same depth gives 24.5 tok/s: architecture beats engine choice;
- `num_batch=2048` triples throughput over 128 and adds 31% over the Ollama default: the cheapest fix available;
- prefix cache in `llama-server` survives prompt-tail edits (95 ms vs 1697 tokens of prefill); in Ollama any tail edit resets it.

## Quick start

```bash
# on a machine with internet: pull images and model weights, copy them in
docker compose -f deploy/docker-compose.yml up -d
./scripts/verify-isolation.sh    # expect every outbound check to FAIL
./scripts/bench.sh               # writes results/<date>-<model>.md
```

## Limits

- Volta (sm_70) needs CUDA 12.9: CUDA 13 dropped the architecture entirely.
- The isolation check proves network egress is blocked; it does not prove the model will not leak data
  inside a prompt, so human review of prompts stays mandatory.
- Benchmarks are single-node, single-card; no cluster results.

## Related repositories

| Repository | What it adds |
|---|---|
| [v100-field-notes](https://github.com/eightpaws/v100-field-notes) | the measurements the model-selection rules come from |
| [it-infra-audit-kit](https://github.com/eightpaws/it-infra-audit-kit) | audit of AD, a hypervisor and backups: read-only, report with risk levels |
| [eightpaws](https://github.com/eightpaws) | profile: what else is published |

Russian documentation: [README.md](README.md). License: MIT for code (`LICENSE`), CC BY 4.0 for text and data (`LICENSE-DOCS`).
