# M3-C / X2-C — Integrated New-Game Opening Proof

**X2-C REVISED IMPLEMENTATION CANDIDATE — MERGE NOT AUTHORIZED.**

X2-C is a read-only composition gate for a pristine independent M79/M80
new-game source. It does not own career state, alter weekly runtime, produce a
save, or introduce a checkpoint/codec. It keeps P1, X1, X2-A and X2-B source
rules unchanged.

`IntegratedNewGameOpeningProof.fromNewGame` first delegates authority
validation to P1. It independently projects supplied world data and checks it
with P1, derives X1 contracts from verified players/leagues, then X2-A from
the same opening and gives the **identical X2-A object** to X2-B. It rejects
partial, answered, completed, mismatched or drifted inputs before returning.

## Independent verification after audit

`verifyNewGame` invokes the **existing**
`seasonOpening.verifyNewGame(application, sourceClubs, sourceLeagues,
expectedRulesetId)` directly with the independently supplied actual M79/M80
source. P1 re-creates and compares its private **complete canonical identity**,
including ordered M1 fixture-plan content, rather than accepting only selected
public P1 digests. The separate X2-C rebuild additionally checks its opening
and X2-B memory identity.

X1 is independently regenerated from this same source and compared against
the original X1 result: seed/version/season, source digest and source player
and league counts, exact **ordered** active contract signatures and player IDs,
and exact **ordered** initial event signatures and player IDs. Construction
also validates unique contract/event player coverage of the supplied P1 roster.
The positive test compares those ordered outputs with a separately built X1
state **and** the existing legacy lazy `PlayerContractController` after its
first annual-wages initialization. Neither event ordering nor generated wages
are replaced by an aggregate or newly invented hash framework.

Negative tests reject different simulation version/election interval, changed
world/club input, actual application source vs independently supplied
clubs/leagues mismatch, missing/duplicate club IDs, wrong controlled club and
season, answered transcripts and zero/negative raw-history windows. The
existing P1 public `assertOpeningProjectionMatches` checks independently
modified player and finance observations; the X2-C public verification API
does not accept arbitrary injected player/finance objects. Likewise X2-C's
private-constructor X1 and X2-B results cannot be swapped via its public API:
**no production mutation or injection API is added merely for testing**.
Existing P1/X1/X2-A/X2-B standalone tests continue as regression gates.

Source digests and diagnostic signatures are **content identities only**, not
authentication, monotonic revisions, CAS keys, save IDs or state authorities.
No persisted field/schema/codec, frozen X2-A0 evidence, M65/M75/M80 goldens,
P1/X1/X2-A/X2-B production rule, workflow or release file changes.

The previous exact source CI #36435436372 printed **552/552 PASS** (not
548/548). That is historical pre-repair evidence, not CI for this revision.
The exact new source HEAD and its test/canonical/checkout tree checks must be
recorded separately on the revised PR.

**X2-C REVISED IMPLEMENTATION CANDIDATE — MERGE NOT AUTHORIZED**

**P2-A1 BLOCKED — INTEGRATED OPENING PROOF REQUIRED**

**M3-C BLOCKED / PRECONDITION**
