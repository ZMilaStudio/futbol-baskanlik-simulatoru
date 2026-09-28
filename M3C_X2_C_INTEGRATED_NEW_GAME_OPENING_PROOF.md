# M3-C / X2-C — Integrated New-Game Opening Proof

X2-C is a read-only composition gate for one pristine M79/M80 new-game
source. It does not own career state, alter weekly runtime, produce a save,
or introduce a checkpoint/codec.

`IntegratedNewGameOpeningProof.fromNewGame` first delegates authority
validation to P1. It independently projects the supplied world and checks it
with P1, derives X1 contracts from that verified players/leagues projection,
then derives X2-A from the same projection and passes that exact X2-A object
to X2-B. The resulting gate rejects partial, answered, completed, mismatched
or drifted inputs before returning a proof.

The source digest remains a content identity only. Independent M79/M80 source
verification is performed by `verifyNewGame`; no digest becomes a revision,
CAS token, save key, or state authority.

Frozen M65/M75/M80 compatibility and existing P1/X1/X2-A/X2-B contracts are
regression-validated; no persisted field or schema changes are part of X2-C.
