# M34 — Facility Persistence / Finance Orchestration I

Status: CLOSED / PASS

Date: 6 September 2026

## Merge

- PR: #35
- Final PR HEAD: `a7adc874dd0ded55b2e87635508449fcf4aae786`
- Squash merge commit: `89fc20e663aacb96e75881528492ed2f0edf33f8`
- PR CI: run `34048550465`, job `101527918362` — SUCCESS
- Post-merge main CI: run `34049690296`, job `101530927660` — SUCCESS
- Normal/non-canonical tests: 137 PASS
- M0–M34 runner chain: PASS
- Artifacts: 0

## Scope

M34 connects M33 academy facilities to real persistent career state and real club cash.

Implemented:
- one academy facility state for each of 48 clubs
- versioned/checksummed facility runtime save format
- synthetic v0 → v1 migration coverage
- academy upgrade cost deducted exactly from the club's real checkpoint cash
- unaffordable upgrades rejected without mutating state or creating hidden debt
- cumulative facility investment spend persisted
- facility state survives encode/decode
- save/load/resume continuation matches direct invested continuation
- M34 public API exports and CI gate

M0–M33 public behavior remains preserved.

## Canonical result

Seed: `20260903`

- investment checkpoint season: 8
- investment club: `t3_05`
- academy level after investment: 2
- investment spend: 9.00M
- immediate club cash delta: 9.00M
- save version: 1
- save bytes: 214737
- loaded academy records: 48
- completed seasons after resume: 20
- facility state preserved: true
- direct continuation == save/load/resume: true
- finance-funded facility persistence: PASS

## Explicitly deferred

M34 persists academy state and finance effects, but does not yet inject the persisted academy level into every offseason youth-intake step inside the full world career engine. M33 already proves academy level materially changes youth quality; the next integration milestone should make the persisted level affect actual resumed career youth generation end-to-end.
