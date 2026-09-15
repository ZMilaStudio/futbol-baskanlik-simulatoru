# M80 — Player President Interactive Decision New-Game Bootstrap Snapshot I

Durum: **ACTIVE / PRE-MERGE**

Branch: `feat/m80-interactive-decision-new-game-bootstrap-snapshot`

PR: **#83**

## Problem

M79 ile application layer deterministic sezon-0 new-game session başlatabiliyor. Ancak bu session M65 checkpoint oluşmadan önce ilerlerken M75 bundle üretilemez; bu davranış bilinçli olarak fail-closed'dur.

M73 semantiği incelendiğinde pending decision sırasında partial game-state commit edilmediği doğrulandı. Accepted cevaplar, immutable başlangıç girdilerinden tekrar çalıştırılan deterministic session üzerinden replay edilir. Bu nedenle pre-checkpoint ilerlemeyi saklamak için partial world/runtime snapshot veya ikinci game-state authority gerekli değildir.

## Çözüm

M80 replay-only bootstrap snapshot ekler:

`PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot`

Snapshot şunları saklar:
- deterministic world fingerprint,
- `SimulationConfig`,
- controlled club id,
- election interval,
- mevcut M75 `PlayerPresidentInteractiveDecisionResumeConfig`,
- mevcut M74 accepted-answer transcript.

Snapshot **şunları saklamaz**:
- partial world state,
- partial runtime checkpoint,
- finance/player/manager/facility mutable streams,
- M65 dışında yeni authoritative game state.

Codec:
`PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec`

Özellikler:
- format id,
- save version 1,
- canonical JSON,
- existing `SaveChecksum`,
- nested existing M74 transcript codec,
- checksum/future-invalid payload fail-closed behavior.

## Application lifecycle

`PlayerPresidentInteractiveDecisionApplicationSession` M80 ile şunları kazanır:
- `canPersistBootstrap`
- `newGameBootstrapSnapshot`
- `encodeNewGameBootstrapSnapshot()`
- `restoreNewGameBootstrap(...)`
- `restoreEncodedNewGameBootstrap(...)`

New-game start sırasında application session restore için gerekli immutable bootstrap girdilerini retain eder.

Restore sırasında:
1. caller `clubs` + `leagues` sağlar,
2. supplied world deterministic fingerprint ile doğrulanır,
3. M73 raw new-game session aynı başlangıç parametreleriyle yeniden kurulur,
4. M74 transcript replay edilir,
5. exact pending request veya completed state geri elde edilir.

## Authority sınırı

Değişmedi:
- **M65 tek persisted game-state authority.**
- M74 yalnız accepted-answer replay metadata.
- M75 checkpoint-backed atomik application bundle.
- M76/M79 application lifecycle.
- M77 yalnız M75 bytes file storage.
- M78 M75-backed read-only catalog.
- M80 yalnız bootstrap/replay metadata.

M75 formatı değiştirilmedi.
M77 formatı değiştirilmedi.
M78 catalog değiştirilmedi.

## Non-scope

- bootstrap snapshot'ı M77 file slot'a kaydetmek,
- bootstrap slotları M78 catalog'da göstermek,
- ikinci save/game-state authority,
- partial runtime/world serialization,
- metadata sidecar,
- database/cloud sync,
- Flutter/provider/platform state.

## Acceptance

1. Empty bootstrap snapshot deterministic ilk pending request'i restore eder — PASS.
2. Accepted-answer transcript round-trip exact sonraki pending request'i restore eder — PASS.
3. Bootstrap codec deterministic ve checksum-protected — PASS.
4. Divergent supplied world fingerprint mismatch ile transcript replay öncesi fail-closed — PASS.
5. Bootstrap restore sonrası completion kesintisiz session ile exact M65 checkpoint/boundary/decision parity — PASS.
6. M75 authority sınırı korunur; pre-checkpoint M75 blocked kalır ve checkpoint-origin M80 bootstrap yüzeyini reddeder — PASS.

## İlk executable CI kanıtı

Exact HEAD:
`8eef05379c36003f7ba6e5b013fceddaf0260c3d`

PR run:
`34962878632`

Test job:
- analyzer `No issues found!`
- **366/366 tests PASS**
- 6 M80 acceptance testi PASS
- cleanup SUCCESS
- job SUCCESS

Canonical:
- **M0–M80 tüm executable adımlar SUCCESS**
- M80 step SUCCESS
- cleanup SUCCESS
- job SUCCESS

Artifacts:
**0**

Exact marker:
`M80_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_SNAPSHOT_PASS controlled=t1_01 decisions=9 bootstrapRoundTrip=true stableCodec=true worldGuard=true m75Blocked=true parity=true saveAuthority=M65 replayMetadata=M74 checkpointBundle=M75 worldClubs=48 seed=20260903`

## Pre-merge kapısı

Bu doküman commit'i branch HEAD'ini ilk executable SHA'dan sonra ilerletir. Merge öncesi zorunlu sıra:
1. canlı PR #83 final HEAD'i yeniden oku,
2. exact final HEAD üzerinde analyzer + 366 tests + 6 M80 acceptance doğrula,
3. canonical M0–M80 + exact marker + cleanup doğrula,
4. artifacts=0 doğrula,
5. PR'ı Ready for review yap,
6. HEAD unchanged + mergeable=true doğrula,
7. kullanıcıdan exact final SHA için açık merge onayı al.

**Onay olmadan merge yok.**
