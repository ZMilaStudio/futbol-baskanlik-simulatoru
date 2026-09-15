# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 15 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo hâlâ saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

Canonical dünya:
- seed `20260903`
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 864 başlangıç oyuncusu

## 2. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Deterministic seed / replay / save-resume parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job logu okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan timeout olursa aynı exact HEAD retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- Aktif milestone yoksa fresh live-main gap scan yapılmadan sonraki kapsam seçilmez.

## 3. Devir dosyaları

- Kalıcı proje özeti: `GENEL_PROJE_OZETI.md`
- Hızlı devir: `SOHBET_DEVIR_NOTU.md`

Yeni sohbet başlangıcı:
1. canlı `main` HEAD,
2. bu dosya,
3. `SOHBET_DEVIR_NOTU.md`,
4. açık PR/branch/workflow/job/artifact durumu,
5. aktif milestone varsa onu tamamla; yoksa fresh gap scan.

## 4. CANLI DURUM — buradan devam et

**M0–M80 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yoktur.**

**M81 henüz seçilmemiştir.**

Son kapanan milestone:
**M80 — Player President Interactive Decision New-Game Bootstrap Snapshot I**

PR:
**#83 — MERGED**

M80 final approved PR HEAD:
`99b94db11354be7650edbc362716896bcc66b74e`

M80 squash merge SHA:
`44dbc898de57307050f4f26525886af32c999b51`

Post-merge gerçek `main` workflow run:
`34971253889`

Bu kapanış doküman commit'i `main` HEAD'ini merge SHA'dan sonra ilerletecektir. Yeni sohbet burada yazan merge SHA'yı güncel HEAD sanmamalı; canlı `main` her zaman yeniden okunmalıdır.

## 5. Son kapanan milestone — M80

### M80 — Player President Interactive Decision New-Game Bootstrap Snapshot I

M80 öncesi açık:
- M79 application layer üzerinden sezon-0 new-game başlatabiliyordu,
- M65 checkpoint oluşmadan M75 bundle üretimi bilinçli olarak fail-closed idi,
- M73 pending karar sırasında partial game-state commit etmiyor; immutable başlangıç girdileri + accepted cevaplarla deterministik replay yapıyordu.

M80 çözümü:
- `PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot`
- versioned/checksummed replay-only bootstrap codec
- immutable `SimulationConfig`
- `controlledClubId`
- `electionInterval`
- mevcut M75 `resumeConfig`
- mevcut M74 transcript
- deterministic `worldFingerprint`
- application-session üzerinde `newGameBootstrapSnapshot`
- `encodeNewGameBootstrapSnapshot()`
- `restoreNewGameBootstrap(...)`
- `restoreEncodedNewGameBootstrap(...)`
- `canPersistBootstrap`

Restore semantiği:
- world snapshot içine serialize edilmez,
- caller aynı `clubs` + `leagues` girdilerini yeniden sağlar,
- fingerprint farklıysa transcript replay başlamadan fail-closed olur,
- aynı world + bootstrap + transcript aynı pending request'e ve tamamlanınca aynı M65 checkpoint'e deterministik ulaşır.

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik application bundle.
- M76/M79 application-session lifecycle.
- M77 exact M75 bytes file-slot store.
- M78 M75-backed read-only load-game catalog.
- M80 yalnız pre-checkpoint bootstrap/replay metadata; partial runtime/world state değildir.

M80 kapsamında özellikle yapılmayanlar:
- M77 file-slot formatını bootstrap destekleyecek şekilde büyütmek,
- M78 catalog'a bootstrap slot metadata eklemek,
- ikinci game-state codec/authority,
- partial world/runtime serialization,
- database/cloud/Flutter/provider state.

Ana M80 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_new_game_bootstrap_snapshot.dart`
- `lib/player_president_interactive_decision_new_game_bootstrap_snapshot.dart`
- `lib/src/player_president/player_president_interactive_decision_application_session.dart`
- `test/m80_player_president_interactive_decision_new_game_bootstrap_snapshot_test.dart`
- `tool/run_m80_player_president_interactive_decision_new_game_bootstrap_snapshot.dart`
- `.github/workflows/m0-tests.yml`
- `M80_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_SNAPSHOT_I.md`

## 6. M80 acceptance

1. Empty bootstrap snapshot deterministic ilk pending request'i restore eder — PASS.
2. Accepted-answer transcript round-trip exact sonraki pending request'i restore eder — PASS.
3. Bootstrap codec deterministic ve checksum-protected'dır — PASS.
4. Divergent supplied world fingerprint mismatch ile replay öncesi fail-closed olur — PASS.
5. Bootstrap restore sonrası completion kesintisiz new-game ile exact M65/boundary/decision parity verir — PASS.
6. M75 authority sınırı korunur; pre-checkpoint M75 blocked kalır ve checkpoint-origin M80 bootstrap yüzeyini reddeder — PASS.

## 7. M80 final CI ve merge kanıtı

### Pre-merge final exact HEAD

PR #83 final approved HEAD:
`99b94db11354be7650edbc362716896bcc66b74e`

Final PR workflow run:
`34963832381`

Kanıt:
- analyzer `No issues found!`
- **366/366 tests PASS**
- **6 M80 acceptance testi PASS**
- canonical **M0–M80 tüm executable adımları SUCCESS**
- exact M80 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

### Post-merge gerçek main

Squash merge SHA:
`44dbc898de57307050f4f26525886af32c999b51`

Push workflow run:
`34971253889`

Kanıt:
- event `push`, head `main`, exact merge SHA
- test job **SUCCESS**
- analyzer `No issues found!`
- **366/366 tests PASS**
- **6 M80 acceptance testi PASS**
- canonical job **SUCCESS**
- canonical **M0–M80 tüm executable adımları SUCCESS**
- M80 step SUCCESS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

Exact M80 marker:
`M80_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_SNAPSHOT_PASS controlled=t1_01 decisions=9 bootstrapRoundTrip=true stableCodec=true worldGuard=true m75Blocked=true parity=true saveAuthority=M65 replayMetadata=M74 checkpointBundle=M75 worldClubs=48 seed=20260903`

## 8. Yakın milestone zinciri

- M80 — New-Game Bootstrap Snapshot — PR #83 — merge `44dbc898de57307050f4f26525886af32c999b51` — 366 tests.
- M79 — Application New-Game Session — PR #82 — merge `1f75d9e7e363d17e429af77a7aa28c21a04e06ae` — 360 tests.
- M78 — File Save Slot Catalog — PR #81 — merge `cb9334341e42a8dacf629f4aa25f123b8a6f7160` — 355 tests.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0` — 350 tests.
- M76 — Interactive Decision Application Session — PR #79 — merge `3fdc084a988050b179892ebdc5818c9d032720a0` — 344 tests.
- M75 — Persistence Bundle — PR #78 — merge `c88d65f6c06769fa2298d92bc791f76a0ebf5bed` — 339 tests.
- M74 — Transcript Snapshot — PR #77 — merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c` — 334 tests.
- M73 — Interactive Decision Session — PR #76 — merge `a82caf70f832c20e2da2929bcaddd26aad85b618` — 329 tests.
- M72 — Unified Decision Gateway — PR #75 — merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c` — 324 tests.
- M71 ve öncesi — CLOSED / MERGED / PASS.

## 9. Sistem mimarisi — kısa harita

- M0–M18: temel sezon/kariyer/world/başkanlık sistemleri.
- M19–M24: başkan trait feedback.
- M25–M32: save/load ve runtime snapshots.
- M33–M48: facility/academy/stadium/sponsor/crisis runtime.
- M49–M65: player-president kontrolleri + tenure gate; M65 persisted state authority.
- M66–M71: tüm player-president domain composition.
- M72: tek application decision gateway.
- M73: pending request → response → continue interactive runtime.
- M74: accepted-answer transcript replay metadata.
- M75: M65 + M74 + resume config atomik checkpoint persistence bundle.
- M76: checkpoint-backed application-session lifecycle.
- M77: exact M75 bytes local file save-slot store.
- M78: authoritative M75-backed save-slot load-game catalog projection.
- M79: application-owned deterministic season-0 new-game session.
- M80: pre-checkpoint new-game bootstrap + M74 transcript replay snapshot; M65 authority korunur.

## 10. Sıradaki kesin iş

1. Canlı `main` HEAD'i yeniden doğrula.
2. Açık PR/branch/workflow/artifact durumunu yeniden doğrula.
3. **Fresh live-main gap scan** yap.
4. M81'i ancak bu scan sonucunda seç.
5. En küçük deterministic ve authority-safe açığı uygula.
6. Merge öncesi exact final HEAD için yeniden açık kullanıcı onayı al.

M81'i geçmiş sohbet tahmininden seçme.
