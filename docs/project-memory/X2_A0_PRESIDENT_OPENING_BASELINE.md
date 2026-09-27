# X2-A0 — President opening pre-extraction characterization

**Scope:** baseline evidence only. No production extraction, DTO, checkpoint, new save authority, workflow or release change. Draft PR stays unmerged.

## Authority and provenance

- Real production source: `main` at `647ba661e5397115fc14532920a1922cf4bfff14`.
- Seed: `20260903`; simulation version: `1`; opening season index: `0`.
- Controlled club: `t1_01`; initial player president ID: `president_t1_01_initial`.
- Collection candidate HEAD: `c7d56d47504202ef626aad3a83e1d9b99607b08b`.
- **Actual Dart execution**: [collection run #36356894071](https://github.com/ZMilaStudio/futbol-baskanlik-simulatoru/actions/runs/36356894071), Core Simulation Tests, PR event, both jobs SUCCESS; the normal test job logged all `X2A0_ROW` records.
- Frozen evidence: [48-club JSON fixture](../../test/fixtures/x2_a0_president_opening_baseline.json), transcribed programmatically from **those CI log rows**, not calculated from a replacement algorithm.
- Collector and verification: [X2-A0 test](../../test/x2_a0_president_opening_baseline_test.dart).

## Rules captured

`FictionalWorldFactory.build()` provides 48 unique club IDs in original league order: `t1_01..t1_16`, `t2_01..t2_16`, `t3_01..t3_16`. The JSON retains that exact ordered list, individual initial president IDs/names and signatures, management archetype and **all five** traits, tenure and fan/media signatures. It also retains the initial election counters (0 completed terms, 0 seasons in current term), four-season interval and first election season index 3. These counters describe the opening boundary; no completed-season report or checkpoint is synthesized.

Frozen representative rows from the first execution:

| Club | President | Archetype | Financial / Risk / Transfer / Youth / Patience |
| --- | --- | --- | --- |
| `t1_01` | `president_t1_01_initial` — Emir Kaya | `prudentBuilder` | 85 / 20 / 30 / 69 / 79 |
| `t2_01` | `president_t2_01_initial` — Mert Aydin | `youthArchitect` | 59 / 38 / 38 / 90 / 86 |
| `t3_01` | `president_t3_01_initial` — Selim Ozer | `prudentBuilder` | 79 / 34 / 35 / 62 / 64 |

Every initial tenure has number 1, started season 0 and reelections 0. Every initial fan has sporting/financial/transfer/identity/overall 60; media credibility is 65.

## Production coverage and verification protocol

The X2-A0 tests call the existing `PresidentProfileGenerator.generateInitial`, `PresidentManagementProfileGenerator.generate`, `PresidentTenureState.initial`, `FanState.initial` and `MediaState` directly. They also exercise real `PresidentTenureCareerEngine`, `PresidentReputationCareerEngine`, `SponsorRuntimeCareerEngine`, M65 pricing runtime and M79 prepared new-game dashboard. Sponsor and M65 compare initial president identity; M79 remains a **single controlled-club read-only projection**, not the 48-club career-state authority.

The first run deliberately reported `X2A0_FROZEN_BASELINE_VERIFICATION=NOT_YET_FROZEN`. On subsequent runs the JSON file exists; the test decodes that **stored immutable evidence** and deep-compares it against newly generated production output. A drift fails the test, and `X2A0_FROZEN_BASELINE_VERIFICATION=PASS` is printed only after equality. Do not substitute output-to-itself comparisons or newly generated expected values.

Existing workflow `.github/workflows/m0-tests.yml` runs Dart stable setup, `dart analyze`, normal tests, and canonical M0–M88 as independent jobs on a PR to main. No workflow change or new secret is used. Verify the final candidate commit via the PR head and its own completed successful CI run; the collection run does **not** substitute for frozen-baseline verification.

## Lifecycle boundary

This fixture is an extraction-before reference only. It does not create an opening DTO, completed M65 checkpoint, PresidentDomainMemoryCheckpoint, future election outcome, resolved promise, weekly consequence or any persisted save namespace. X2-A production implementation still requires a separate explicit owner approval. X2-B/X2-C/P2-A1 and merge remain unauthorized.
