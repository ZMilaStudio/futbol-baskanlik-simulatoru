# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 15 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Mevcut repo saf Dart deterministic simulation core'dur. Flutter/UI katmanı henüz bu repoda kurulmamıştır.

Canonical dünya:
- seed: `20260903`
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu

## 2. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Deterministic seed / replay / save-resume parity korunur.
- Tarih `GameDate`, para integer minor-unit `Money` kullanır.
- Eski public simulation semantiği sessizce değiştirilmez.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job logu okunmadan patch atılmaz.
- Outer canonical strict timeout nedeniyle `cancelled` olsa bile tüm executable adımlar + Post Checkout + Complete job SUCCESS ise timeout-only kabul edilebilir.
- Her PR için merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- Aktif milestone yoksa canlı `main` üzerinde fresh gap scan yapılmadan sonraki kapsam seçilmez.

## 3. Devir dosyaları

Kalıcı proje özeti:
- `GENEL_PROJE_OZETI.md`

Yeni sohbet için hızlı devir notu:
- `SOHBET_DEVIR_NOTU.md`

Yeni sohbet başlangıç sırası:
1. canlı GitHub `main` HEAD'i doğrula,
2. `GENEL_PROJE_OZETI.md` oku,
3. `SOHBET_DEVIR_NOTU.md` oku,
4. açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula,
5. aktif milestone varsa onu tamamla; yoksa fresh live-main gap scan ile sıradaki işi seç.

## 4. CANLI DURUM — buradan devam et

**M0–M78 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yoktur.**

**M79 seçilmemiş ve başlatılmamıştır.**

M78 squash merge executable HEAD:
`cb9334341e42a8dacf629f4aa25f123b8a6f7160`

Bu kapanış doküman commit'i `main` HEAD'ini merge SHA'dan sonra ilerletecektir. Yeni sohbet burada yazan merge SHA'yı güncel HEAD sanmamalı; canlı `main` her zaman yeniden okunmalıdır.

## 5. Son kapanan milestone — M78

### M78 — Player President Interactive Decision File Save Slot Catalog I

Durum: **CLOSED / MERGED / PASS**

M78 öncesi açık:
- M77 exact M75 bundle bytes'ını güvenli local file slot'larına save/load/list edebiliyordu,
- fakat load-game/application katmanı yalnız ham `slotId` listesi alıyordu,
- kulüp adı, sezon, answered decision count, player-control state ve pending decision gibi özetler için authoritative M75/M65 object graph'ının elle açılması gerekiyordu,
- deterministic read-only save-slot catalog surface'i yoktu.

M78 çözümü:
- `PlayerPresidentInteractiveDecisionFileSaveSlotCatalog`
- `inspect(slotId)`
- `list()`
- immutable `PlayerPresidentInteractiveDecisionSaveSlotSummary`
- summary her zaman M77 `load()` ile restore edilen exact M75 bundle'dan türetilir,
- ayrı metadata sidecar/timestamp authority yazılmaz,
- deterministic order M77 slot sırasını korur,
- overwrite sonrası yalnız en güncel authoritative M75 bundle yansıtılır,
- missing/invalid slot M77 contract'ını korur,
- corrupt/divergent slot stale metadata göstermeden M75/M74 validation üzerinden fail-closed olur,
- inspect/list save bytes'ını mutate etmez.

Summary alanları:
- `slotId`
- `controlledClubId`
- `controlledClubName`
- `completedSeasons`
- `nextSeasonIndex`
- `answeredDecisionCount`
- `playerControlActive`
- `pendingDecisionKind`
- `sessionCompleted`
- `resumeSeasonCount`
- `hasFutureSeasonAfterReport`
- deterministic `signature`

Authority sınırı değişmedi:
- M65 tek persisted **game-state authority**.
- M74 accepted-answer deterministic replay metadata.
- M75 versioned/checksummed atomik application persistence bundle/save formatı.
- M76 interactive application-session lifecycle owner.
- M77 exact M75 bytes'ının file-backed local storage adapter'ı.
- M78 yalnız M77 üzerinden authoritative save'i restore edip load-game için read-only projection üretir.
- Yeni game-state codec, metadata sidecar, save formatı, database, Flutter/provider state, Android platform channel veya cloud authority eklenmedi.

Fresh scan sırasında ayrıca M73'ün sezon 0'dan `start`, M76/M75'in checkpoint-backed olduğu doğrulandı. Pre-checkpoint/new-game persistence gerçek ama daha büyük bir açık olduğundan M78'e dahil edilmedi; sonraki milestone için ancak fresh gap scan sonucunda değerlendirilmelidir.

Ana M78 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_file_save_slot_catalog.dart`
- `lib/player_president_interactive_decision_file_save_slot_catalog.dart`
- `test/m78_player_president_interactive_decision_file_save_slot_catalog_test.dart`
- `tool/run_m78_player_president_interactive_decision_file_save_slot_catalog.dart`
- `M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_I.md`
- `.github/workflows/m0-tests.yml`

M78 acceptance:
1. slot authoritative M75/M65 state'ten deterministic load-game metadata'ya inspect edilir — PASS,
2. summary listesi deterministic slot-id sırasını korur — PASS,
3. overwrite sonrası catalog yalnız en güncel M75 bundle'ı yansıtır ve metadata sidecar oluşturmaz — PASS,
4. missing/invalid slot M77 contract'ını korur — PASS,
5. corrupt slot stale metadata üretmeden fail-closed olur — PASS,
6. inspect/list save bytes'ını mutate etmez — PASS,
7. M65/M75/M76/M77 authority sınırı korunur — PASS.

Exact M78 marker:
`M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 slots=2 ordered=true metadata=true latestBundle=true nonMutating=true missingNull=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. M78 PR / merge / CI kanıtı

PR:
- **#81 — MERGED / CLOSED**
- branch: `feat/m78-interactive-decision-file-save-slot-catalog`
- final exact pre-merge HEAD: `14552b44fea0b67d19e65b7cf57083ce2f34169c`
- kullanıcı bu exact HEAD için açık merge onayı verdi
- squash merge SHA: `cb9334341e42a8dacf629f4aa25f123b8a6f7160`

İlk executable CI:
- run `34903156421`
- analyzer `No issues found!`
- **355/355 tests PASS**
- 5 M78 acceptance testi PASS
- canonical M0–M78 SUCCESS
- exact M78 marker PASS
- artifacts **0**

Final exact-head PR CI:
- run `34903897958`
- final exact HEAD `14552b44fea0b67d19e65b7cf57083ce2f34169c`
- test job SUCCESS
- analyzer `No issues found!`
- **355/355 tests PASS**
- 5 M78 acceptance testi PASS
- canonical ilk iki denemede strict 7 dakika nedeniyle M78'ye ulaşmadan M77 civarında kesildi ve merge kanıtı sayılmadı
- aynı exact HEAD'deki üçüncü canonical attempt'te **M0–M78 executable adımlarının tamamı SUCCESS**
- exact M78 marker PASS
- Post Checkout + Complete job SUCCESS
- outer canonical yalnız strict envelope nedeniyle tamamlanan adımlardan sonra `cancelled` göründü; timeout-only kabul edildi
- artifacts **0**

Post-merge gerçek `main` executable CI:
- run `34907025955`
- run number `499`
- event `push`
- head SHA `cb9334341e42a8dacf629f4aa25f123b8a6f7160`
- test job `104185977876` **SUCCESS**
- analyzer clean
- **355/355 tests PASS**
- canonical job `104185977667` **SUCCESS**
- canonical **M0–M78 tüm executable adımları SUCCESS**
- exact M78 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

M78 **CLOSED / MERGED / PASS**.

## 7. Yakın milestone zinciri

- M78 — File Save Slot Catalog — PR #81 — merge `cb9334341e42a8dacf629f4aa25f123b8a6f7160` — 355 tests.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0` — 350 tests.
- M76 — Interactive Decision Application Session — PR #79 — merge `3fdc084a988050b179892ebdc5818c9d032720a0` — 344 tests.
- M75 — Interactive Decision Persistence Bundle — PR #78 — merge `c88d65f6c06769fa2298d92bc791f76a0ebf5bed` — 339 tests.
- M74 — Interactive Decision Transcript Snapshot — PR #77 — merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c` — 334 tests.
- M73 — Interactive Decision Session — PR #76 — merge `a82caf70f832c20e2da2929bcaddd26aad85b618` — 329 tests.
- M72 — Unified Decision Gateway Runtime — PR #75 — merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c` — 324 tests.
- M71 ve öncesi — CLOSED / MERGED / PASS.

## 8. Sistem mimarisi — kısa harita

- M0–M18: sezon / kariyer / oyuncu / ekonomi / transfer / world / manager / contract / fan / media / vaat / seçim / başkanlık temelleri.
- M19–M24: başkan trait feedback zinciri.
- M25–M32: save/load, runtime snapshot, history compaction ve resume stress.
- M33–M39: facility / academy / portfolio yatırımları ve başkan karar döngüsü.
- M40–M48: stadium attendance, fan trust, sponsor, crisis ve facility/sponsor/crisis runtime composition.
- M49–M57: player-president facility / sponsor / crisis / manager / transfer / promise / media kontrolleri.
- M58–M65: tenure ownership gate ve tenure-gated player controls; M65 persisted runtime game-state authority.
- M66–M71: tüm player-president domain'lerinin aynı M65 checkpoint authority üzerinde composition'ı.
- M72: application-facing tek `PlayerPresidentDecisionGateway`.
- M73: deterministic `pending request → response → continue` interactive session.
- M74: accepted-answer transcript için checksummed replay sidecar.
- M75: M65 game-state + M74 transcript + minimal M73 resume config için atomik application bundle.
- M76: checkpoint-backed interaktif oturum application lifecycle owner'ı.
- M77: exact M75 bytes'ını local validated file slot'larına materialize eden storage adapter.
- M78: M77 slotlarını authoritative state üzerinden load-game için deterministic read-only catalog summary'ye projekte eder.

## 9. Authority zinciri

- M58 player-president tenure ownership state'ini sağlar.
- M59–M64 tenure-gated domain control katmanlarını kurar.
- M65 tek persisted **game-state authority**'dir.
- M66–M71 yeni authority üretmeden M65 üzerinde domain composition yapar.
- M72 tek application decision gateway sağlar.
- M73 runtime-only interactive session sağlar.
- M74 yalnız replay transcript metadata'sını persist eder.
- M75 M65 + M74 + minimal M73 resume config'i tek outer persistence envelope içinde eşler; authority değiştirmez.
- M76 mevcut katmanları tek application-session lifecycle owner içinde compose eder.
- M77 M75'in exact encoded bundle'ını local slot dosyasına materialize eder.
- M78 mevcut authoritative state'ten read-only load-game summary üretir; persistence/authority üretmez.

## 10. Bir sonraki sohbet için kesin talimat

M79 kapsamını önceden varsayma.

Önce:
1. canlı `main` HEAD,
2. son workflow run'ları,
3. açık PR/branch durumu,
4. `GENEL_PROJE_OZETI.md`,
5. `SOHBET_DEVIR_NOTU.md`

doğrulanmalıdır.

Ardından canlı `main` üzerinde **fresh gap scan** yapılarak oyunu gerçek ürüne yaklaştıran en küçük, test edilebilir ve deterministic sonraki açık seçilmelidir.

Bu closure doküman commit'inin kendi CI sonucu yalnız gözlemlenir; sırf sonucu yeniden belgelemek için yeni docs→CI→docs commit döngüsü oluşturulmaz.
