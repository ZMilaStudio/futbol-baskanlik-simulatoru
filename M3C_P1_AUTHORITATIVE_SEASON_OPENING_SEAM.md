# FBS M3-C / P1 — Authoritative Season Opening Seam

Status: **P1 DRAFT IMPLEMENTATION CANDIDATE; M3-C remains BLOCKED / PRECONDITION**.
Scope: a read-only opening observation only. No save codec, schema, weekly
persistence, M73 lifecycle, M2 commit, M75/M76/M77 integration or release.

## Existing source authorities
- New-game: the actual M79 `PlayerPresidentInteractiveDecisionApplicationSession`,
  its M80 new-game bootstrap fingerprint/config/controlled club and independently
  supplied opening clubs/leagues, validated with existing M80 `validateWorld`.
  M79 has no M65 checkpoint before completion. P1 accepts only zero accepted
  answers; decision-influenced weekly openings belong to P2.
- Completed-season: a real validated M65
  `PlayerPresidentTicketPricingRuntimeCheckpoint` with completedSeasons > 0,
  active control, and exact world.nextSeasonIndex parity. Uses nested
  `WorldCheckpoint` baseClubs/nextSeasonLeagues/nextSeasonPlayers/
  nextSeasonFinanceStates; config is `world.config.copyWith(seasonIndex:
  checkpoint.nextSeasonIndex)`. M2 week-31 snapshot is not an M65 checkpoint.

## Proof representation and validation
`SeasonOpeningProof` stores an immutable source kind, full immutable
`SimulationConfig`, exact source season and controlled club, ordered-world,
players, finance and opening-career SHA-256 digests, M1 fixture-plan
fingerprint, immutable M1 unplayed fixture snapshot, and a private canonical
identity. New-game and M65 source digests use distinct explicit domains.
M65 source content is the canonical existing M65 v1 encoder output and is
not held as a duplicate checkpoint. The parent M65 source digest binds all
nested historical runtime/finance/decision state even if only next-season
world fields are projected into the opening.

The production dependency `crypto` provides SHA-256 for this narrow
content-fingerprint need; `SaveChecksum.canonicalJson` supplies stable field
ordering. Domain prefix `FBS-P1/season-opening/<domain>/v1\\0` prevents
untyped digest reuse. A hash is **not** proof of source authenticity. Callers
must give the actual independent M79 or M65 authority to `verifyNewGame` or
`verifyCompletedM65`; both reconstruct and compare the complete canonical
opening identity and source digest. The existing M80 32-bit worldFingerprint
continues as its legacy validation gate but is not advertised as a
cryptographic proof. There is no general-purpose identity framework.

`sourceRevisionKind=source-content-sha256-v1` is a non-monotonic snapshot
identity, **not** a CAS/generation number. No existing monotonic revision is
invented. Future write concurrency belongs to a separately approved lane.

`rulesetId` is an explicit *manual audited contract identifier* pinned to
the known M79/M65 opening, M1 fixture and M0 match seed algorithms at main
`a162c2d671cb7b39e7b661d31f7800f32bd2ec70`. It is not automatically
computed from the installed code. Relevant rule changes must update it and
tests deliberately; supplied conflicting expected ID fails closed. Full
config includes every field, not merely simulationVersion.

`league.clubIds` order, ordered source clubs/players, all player fields,
all 48 cash/debt records, and every one of the 720 M1 fixture entries
(season/tier/round/worldKey/legacy ID/home/away/production position) are
fingerprinted. Never use sorted `WorldLeague.signature` as fixture order.
The M1 projection is the **only** fixture authority, not a duplicate planner.

## Hard acceptance / non-goals
- Verify different independent source, controlled club, season, config,
  source content, order and rules mismatch fail closed before publishing proof.
- All 720 fixtures start unplayed; future matches and tables are never
  simulated or completed by P1. Match seed still uses the raw legacy fixture
  ID. No in-progress weekly state can be supplied as M65.
- Frozen M65/M75/M80 v1 golden fixtures remain exactly unchanged.
- P1 is not P2 provenance, an accepted-answer consequence, persistent
  weekly restore, restart-safe career, cross-process stale-write protection,
  M65 weekly v2 or season finalization.

**Open P2 dependency:** accepted M73 answer is not necessarily an applied
weekly career consequence. P2 needs an authoritative decision boundary,
real source revision transitions and effective-input derivation tied to the
living career. M3-C stays BLOCKED until separately authorized and validated.
