# Contributing

This repository exists to prove one thing: that a container in this stand cannot reach the internet, and that the proof is a script rather than a promise. Contributions are judged by that standard.

## Reporting a hole in the isolation

The interesting report is "my container reached something". Open an issue with:

| Field | Why |
|---|---|
| `docker compose` and kernel version | network namespace behaviour differs between releases |
| The `verify-isolation.sh` output, verbatim | a summary hides which check passed |
| What you managed to reach (DNS, IP, a port) | a resolved name and a reachable port are different failures |
| The command you used | so the check can be extended to cover it |

A successful probe against a host on the same bridge network is not a leak; say which network the probe ran on.

## Adding a model-selection rule

Rules in `docs/model-selection.md` must come from a measurement, not from a README. A rule is accepted with:

- the card ID in `v100-field-notes` that established it, or your own numbers with the rig described;
- the condition under which it stops being true (context length, quantisation, VRAM headroom);
- what it replaces, if an older rule said otherwise.

## Code changes

- Keep the compose file self-contained: no images that are not pinned, no volumes outside the described layout.
- `scripts/verify-isolation.sh` must stay read-only and must not depend on tools that are absent from a minimal image.
- Anything that needs root has to say so at the top of the script.

## License

Code and scripts: MIT. Text, documentation and measurement results: CC BY 4.0. See `LICENSE` and `LICENSE-DOCS`.
