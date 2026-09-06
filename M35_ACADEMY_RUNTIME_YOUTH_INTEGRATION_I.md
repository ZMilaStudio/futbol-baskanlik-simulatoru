# M35 — Academy Runtime Youth Integration I

Status: CLOSED / PASS

Date: 6 September 2026

## Merge

- PR: #36
- Final PR HEAD: `ca72c880f68543321c5ce03d9bfe11166dd40c0e`
- Squash merge commit: `20fc9636ff2993eede5667365d34c722f23aadc2`
- PR CI: run `34050440949`, job `101532971925` — SUCCESS
- Post-merge main CI: run `34056184347`, job `101548394932` — SUCCESS
- Normal/non-canonical tests: 140 PASS
- M0–M35 runner chain: PASS
- Artifacts: 0

## Scope

M35 closes the deliberate M34 gap by injecting persisted academy facility levels into the real offseason player lifecycle used during facility-runtime career continuation.

Implemented:
- `FacilityRuntimeCareerEngine` resumes the real `WorldCareerEngine` through a facility-aware player lifecycle
- persisted academy level is supplied to the existing deterministic `PlayerLifecycleEngine`
- no parallel or duplicate youth-generation system was introduced
- academy level 0 preserves legacy world-resume behavior exactly
- invested academy levels materially improve the actual deterministic youth intake produced for that club
- custom underlying player-lifecycle behavior remains delegated rather than replaced
- save/load/resume reproduces the same youth history and final facility/world checkpoint as direct continuation
- M35 tests, canonical runner, and CI gate

M0–M34 public/default behavior remains preserved.

## Canonical result

Seed: `20260903`

- investment checkpoint season: 8
- investment club: `t3_05`
- academy level: 2
- baseline youth ability: 52.93
- upgraded youth ability: 54.13
- ability delta: +1.20
- baseline youth potential: 69.69
- upgraded youth potential: 73.29
- potential delta: +3.60
- completed seasons after resume: 20
- youth history match: true
- final checkpoint match: true
- academy runtime youth integration: PASS

## Result

Academy facilities are now end-to-end gameplay state: investment changes real club cash, persists through save/load, and changes the next real offseason youth intake while retaining deterministic continuation.

## Explicitly deferred

M35 does not yet automate academy investment decisions from a president management profile. A logical next step is to connect `youthOrientation` to persistent academy investment targets/decisions while retaining affordability, save/load, and deterministic career behavior.
