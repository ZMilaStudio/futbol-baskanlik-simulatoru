# FBS Weekly Career Foundation — M3-B / FBS-03 Legacy Compatibility Gate

Status: **M3-B TEST/CONTRACT CANDIDATE**. The user-authorized package is test
fixtures, characterisation, and a forward contract. It does **not** implement
weekly persistence, a weekly decoder, a save/restore factory, or a migration.
See product Issue #107 and technical Issue #108.

## Live M2 baseline and authority

Base main `3bbd01f8a8ad3636e994cba52355185a2fbad6ea`;
M1 PR #109 and M2 PR #110 are merged. M2 holds one in-memory
`WeeklyWorldFixtureSnapshot` in `WeeklyWorldCommitSession`; one synchronous
`commitRound(expectedSeasonIndex, expectedRound, effectiveClubs)` advances
only the exact next round after M1 computation succeeds. It is **not**
restart-safe. It cannot be encoded as an M65 v1 checkpoint.

The established persistence authority chain remains: M65
`PlayerPresidentTicketPricingRuntimeCheckpoint` + save codec is **the sole
persisted game state**; M74 is accepted-answer replay metadata; M75 is an atomic
M65+M74+resume-config envelope; M76/M79 are application session lifecycles;
M80 is pre-checkpoint replay-only bootstrap. M77 checkpoint and M81 bootstrap
remain two physical namespaces. M83–M88 route on exact `source + slotId`,
preserving same-raw-ID siblings. No third namespace or game-state authority.

## Fixed legacy baselines (v1)

The three committed `test/fixtures/m3b_*.json.gz.b64` fixtures were captured
**once** from the M2 executable production codecs with canonical seed
`20260903`, three 16-club leagues, controlled club `t1_01`, one completed
season (M65), M75 containing the exact M65 save and empty M74 answer
transcript, and M80 pre-checkpoint bootstrap with the same immutable world
fingerprint and empty transcript. Gzip/base64 is only a lossless fixture
transport; the inflated UTF-8 bytes are the actual legacy canonical JSON.
The permanent tests read the frozen bytes; they never calculate expected
golden bytes using the current encoder. The one-time capture test is removed
from the final candidate.

M65 v1 has nested `runtimeSave` and `tenureControlSave`, each passed to its
own existing decoder. M75 v1 has nested `gameStateSave` (M65),
`transcriptSave` (M74), and `resumeConfig`, with outer **and nested**
checksums. M80 v1 holds immutable bootstrap inputs and M74 transcript only.
The tests freeze v1 open, canonical `encode(decode(bytes)) == bytes`,
envelope/version/checksum, malformed JSON, incorrect format, checksum
corruption, checksum-valid invalid payload and independently invalid nested
saves. They also load frozen M75 and M80 bytes from two same-ID physical slots.

**Version nuance:** The existing M65 v1 decoder range-checks version 0 and 1,
but v0 fails `invalidPayload` after a valid matching checksum; versions -1/2
fail `unsupportedVersion`. M75/M80 accept only v1 and reject v0/v2 as
`unsupportedVersion`. Do not retroactively rewrite production behavior just
to force identical failure labels.

## Existing tests retained, not recopied

- M74 tests: accepted-answer only; exact deterministic request-key replay.
- M75/M76 tests: nested checksums, stale transcript rejection, application
  partial restore parity; bootstrap and checkpoint origins are distinct.
- M77/M81 tests: slot overwrite, validation, corrupt bytes, interrupted
  `.bak` recovery, and isolated listing/deletion.
- M83–M88 tests: mixed catalog/loader/writer/deleter/service/transient
  binding preserve exact `source + slotId` and same-ID siblings.

The added fixture-backed physical-slot test covers the previously missing
*fixed historical bytes through current child stores* rather than duplicating
all routing tests. Existing M77 recovery chooses an existing target over a
backup, or promotes `.bak` when target is absent; an orphan `.tmp` is not
promoted on load and is removed on delete/next save. M77 does not yet provide
cross-process compare-and-swap/stale-write protection. M3-B freezes the
observed behavior and **does not change** that store.

## Weekly contract gate: existing executable invariants

`test/weekly_world_fixture_result_core_test.dart`,
`test/weekly_world_commit_session_test.dart`, and the added targeted
`test/m3b_weekly_contract_gate_test.dart` cover:

- Three tiers × 16 clubs; 30 rounds × 24 = 720 fixtures, 720 unique
  season+tier+legacy-fixture world keys; retain raw fixture ID for MatchEngine
  seed compatibility.
- W1/W2/W3 exactly 24/48/72 committed world matches; all future fixtures
  remain unplayed; 16-club partial tables derive only from committed results.
- Current cursor/phase consistency, once-only commit on a single live
  session; wrong-season, stale/duplicate and invalid world inputs fail
  without publishing a candidate.
- Published past results and earlier snapshot references remain unchanged,
  same-input deterministic replay, and static full 30-round score/xG/seed/
  standings parity with existing SeasonEngine.

`seasonComplete` with `nextRound=31` means only **30 match rounds have
committed**. It is NOT M65's completed-career checkpoint, final finance,
offseason lifecycle, or next-season state. Never synthesize an M65 v1
checkpoint from M2's week-31 snapshot.

## Future persisted weekly-state tests — NOT IMPLEMENTED/PASS IN M3-B

This gate is a required design matrix for a separately approved M65-compatible
weekly persistence milestone, **not** an assertion of current restore support.

| Future scenario | Required acceptance |
| --- | --- |
| Versioned M65 weekly discriminator | v1 historical checkpoints unchanged; unknown/missing/contradictory state kind or future version fail closed |
| Weekly round-trip | `decode(encode(weekly))` preserves all authoritative fields/fixture identity and checksum, with no new game-state authority |
| W1/W2/W3 restart | save → close → restore → continue yields exact 24/48/72 score/xG/seed/table identity vs uninterrupted run |
| Phase / cursor / fixture validation | each completed round is fully committed (24); future rounds 0; phase and nextRound coherent; 720 unique canonical keys |
| Duplicate/stale commit | restored generation/version and expected round prevent replay or stale write; no double score, event, or later finance application |
| Corrupt checksum & valid-checksum semantic corruption | reject before publishing partial session or overwriting old slot |
| Divergent source replay | reject mismatched fixture plan/fingerprint, simulationVersion, strength input/decision transcript, or result identity; never silently recompute past scores |
| Legacy path | M65 v1, M75 v1, M80 v1 open unchanged; existing two source namespaces and same-ID sibling survive |
| Completed-season boundary | week 31 is not an M65 completed checkpoint; season-finalize may occur only through separately authoritative end-of-season lifecycle |
| Interrupted disk write | preserve M77/M81 existing target/backup recovery; add separate stale-write/concurrent-writer design before promising exactly-once across processes |

FBS-01: keep current save architecture. FBS-02: not triggered. FBS-03:
**TRIGGERED — gate supplied by this test/doc packet**, persisted-field
implementation still separate. INFRA-01: repository settings out of scope.
No codec version bump, production schema/namespace, migration, M73/M76
lifecycle, UI, weekly finance, press/transfer, RC1 PR #106, or workflow change.
