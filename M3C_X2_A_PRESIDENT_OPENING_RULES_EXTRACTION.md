# FBS M3-C / X2-A — President Opening Rules Extraction

Status: **X2-A IMPLEMENTATION CANDIDATE — MERGE NOT AUTHORIZED**.
Product #107; technical tracking #108. This is a narrow rules extraction, not a new W1 career-state owner.

## Authority and frozen provenance

- Implementation branch source: `main` `4d909ed2710f45946a2fa982eee3a27677ea0286` (X2-A0 merged).
- Original pre-extraction production source: `647ba661e5397115fc14532920a1922cf4bfff14`. This is historical provenance, **not** a branch reset target.
- X2-A0 fixture: `test/fixtures/x2_a0_president_opening_baseline.json`; immutable blob SHA `e532560505674da660cfae011b4234df8c1b0eae`.
- Canonical seed 20260903, simulation version 1, first season 0, controlled club `t1_01`, three leagues with 16 clubs each. The baseline retains all 48 identities, five management traits, tenure/fan/media, cursor and exact league ordering.
- X2-A0 test and frozen JSON are not modified or regenerated.

## Shared source and immutable API

`PresidentOpeningStateInitializer` in `lib/src/election/president_opening_state_initializer.dart` exposes:
- `prepareClub(clubId, config, startedSeasonIndex?)`: pure per-club opening `PresidentOpeningClubState` containing president, tenure, management profile, fan and media. It accepts the existing injected `PresidentProfileGenerator` and `PresidentManagementProfileGenerator`.
- `prepareWorld(clubs, leagues, config, controlledClubId?, electionInterval=4)`: read-only `PresidentOpeningWorldState`, immutable club list/lookup and league-tier / `league.clubIds` order, uniqueness/completeness checks, controlled president relationship, and descriptive initial election cursor (0 completed terms, 0 seasons into term, first election season = start + interval - 1). A one-club fixture remains valid; 48 is not hard-coded.

The initializer **calls legacy** `generateInitial`, `generate`, `PresidentTenureState.initial`, `FanState.initial`, `MediaState(credibility: 65)`. No alternative RNG, name source, draw order, seed tokens, challenger path or trait formula is introduced. Identity is validated before exposing a result. It has no save-layer or application-layer import, no checkpoint or serialization identity.

## Production delegation

- `PresidentTenureCareerEngine`: existing sorted league ID iteration and custom president generator preserved; only per-club initial tenure construction delegates.
- `PresidentReputationCareerEngine`: same original sorted league ID iteration, initial tenure/fan/media through the single club source, injected president generator retained; election/handover/challenger code is untouched.
- `SponsorRuntimeCareerEngine`: same incoming `clubs` order and both injected generators; initial management/fan/media maps use shared per-club state. Sponsor economics/contract behavior is untouched.
- M65 pricing `_initialContext`: same input club order, profiles, fan, stadium zero and controlled president identity; only initial values delegate. Existing completed M65 checkpoint capture/restore is untouched.
- M79 new-game prepared dashboard: only the controlled-club per-club projection delegates; still not the 48-club authority and still has no pre-completion M65 checkpoint.

## Compatibility boundary

The X2-A targeted tests compare every `prepareWorld` row and header against the **independent original 48-row frozen JSON**, verify determinism and per-club RNG independence across reordered input, immutable lists/maps, small-world support, invalid/duplicate/missing membership, injected-generator use and identity validation, and production tenure/reputation/sponsor/M65/M79 parity. Existing X2-A0 fail-closed baseline, X1/P1, M3-B M65/M75/M80 golden bytes and canonical M0–M88 remain required separate gates. Do not change expected values on failure.

This output is neither a completed-M65 checkpoint nor a new persisted domain memory/save authority. No M73 decision, M2 commit, manager lifecycle, X2-B/X2-C/P2-A1, codec/schema, weekly v2, RC1/AAB/Play Console or release change.

**X2-A IMPLEMENTATION CANDIDATE — MERGE NOT AUTHORIZED**

**X2-B / X2-C NOT AUTHORIZED**

**P2-A1 BLOCKED — EXTRACTION REQUIRED**

**M3-C BLOCKED / PRECONDITION**
