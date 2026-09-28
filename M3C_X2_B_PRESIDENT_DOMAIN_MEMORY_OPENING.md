# FBS M3-C / X2-B — President Domain Memory Opening

**X2-B IMPLEMENTATION CANDIDATE — MERGE NOT AUTHORIZED**

Product vision #107; technical tracking #108. Base main:
`96816e162ff0b20d708a4d6d31e3ba9f79565e7b` (X2-A PR #118 merged, actual-main CI #36408529023 SUCCESS).

## Explicit source and ownership

`PresidentDomainMemoryOpeningInitializer.prepare(opening, rawHistorySeasons: 2)` consumes an already-created `PresidentOpeningWorldState` from X2-A. It is placed beside X2-A in `src/election`, without a save-layer import or regeneration of any incumbent. It accepts only a pristine season-zero opening with a controlled club, valid X2-A initial election cursor, exactly matching ordered club/map identities and incumbent-tenure-management-fan-media links. Invalid raw window (zero/negative), missing control and non-new-game season fail closed. It supports one-club fixtures and the actual 48 clubs; 48 is not hard-coded.

`PresidentOpeningDomainMemoryState.opening` holds the **identical X2-A source instance**; `clubs`, `byClubId` and `controlledClub` delegate directly to X2-A instances, not copied/re-generated presidents. `orderedClubIds`, season, election interval, initial election cursor and controlled-president relation delegate to X2-A. The derived diagnostic `signature` is neither a save identity nor a second election authority.

## New-game history semantics

`completedSeasons=0`; `completedElectionTerms=0`; `seasonsIntoCurrentTerm=0`. Independent read-only `PresidentOpeningHistorySummary` reports zero fan snapshots/reasons, media statements/contradictions and fulfilled/partial/broken promises. `recentFan`, `recentMedia`, and `resolvedCurrentTermPromises` are permanently empty immutable `List<Never>` in this *opening* DTO. This says there are no **resolved completed-season** promise records yet; it makes no claim about future/new/pending promises. `rawHistorySeasons` defaults to 2 but contains no fabricated history.

The new DTO is **not** `PresidentDomainMemoryCheckpoint`, `PresidentRuntimeCheckpoint`, `PresidentReputationCareerReport`, a completed season report or a `CompactAdvancedRuntimeCheckpoint`. No fake checkpoint, new persisted authority, codec, save namespace or M65 source is created. The actual completed-career `PresidentDomainMemoryCheckpoint.capture` remains the sole existing domain-memory capture path; its summary, election cursor, raw-history window and signature are not altered.

## Gates and non-scope

X2-B targeted tests cover the real frozen original X2-A0 48-row club and president identities, immutable deterministic repeat, small/custom-generator identity, invalid windows and source rejection, zero-history semantics, and separation from the actual frozen completed-M65 v1 domain checkpoint and byte-exact M65 re-encode. The existing M30 completed-career capture, X2-A/X2-A0 parity and negative tests, X1/P1/M3-B golden compatibility, M65/M75/M80 and canonical M0–M88 must remain green. Frozen original `test/fixtures/x2_a0_president_opening_baseline.json` blob `e532560505674da660cfae011b4234df8c1b0eae` and the original M65/M75/M80 v1 goldens are unchanged.

**No X2-A generator/RNG changes. No M65 completed capture/restore changes. No production save, codec, schema, workflow, RC1/release, AAB/Play or P1/X1 edits.**

**X2-B IMPLEMENTATION CANDIDATE — MERGE NOT AUTHORIZED**

**X2-C NOT AUTHORIZED**

**P2-A1 BLOCKED — INTEGRATED OPENING PROOF REQUIRED**

**M3-C BLOCKED / PRECONDITION**
