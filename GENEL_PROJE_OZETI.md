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
- Her PR için merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + exact-head lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- Yeni milestone seçmeden önce canlı `main` üzerinde fresh gap scan yapılır.

## 3. Devir dosyaları

Kalıcı proje özeti:
- `GENEL_PROJE_OZETI.md`

Yeni sohbet için hızlı devir notu:
- `SOHBET_DEVIR_NOTU.md`

Yeni sohbet başlangıç sırası:
1. canlı GitHub `main` HEAD'i doğrula,
2. `GENEL_PROJE_OZETI.md` oku,
3. `SOHBET_DEVIR_NOTU.md` oku,
4. branch / PR / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula,
5. aktif milestone varsa onu tamamla; yoksa fresh gap scan ile sıradaki işi seç.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır.

## 4. CANLI DURUM — buradan devam et

**M0–M77 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M78 — Player President Interactive Decision File Save Slot Catalog I.**

M78 başlanmadan önce doğrulanan canlı `main` HEAD:

`952bc9768629195d5d19ab7559170915f080ec31`

Fresh live-main gap scan M77 sonrasında şu açığı doğruladı:
- M77 file-backed save slot'larını güvenli şekilde save/load/list edebiliyor,
- ancak load-game/application katmanı yalnız ham `slotId` listesini görebiliyor,
- kulüp, sezon, cevaplanmış karar sayısı, player-control state ve pending decision gibi özetler için M75/M65 state'ini elle traverse etmesi gerekiyordu,
- deterministic read-only slot catalog surface'i yoktu.

M78 çözümü:
- `PlayerPresidentInteractiveDecisionFileSaveSlotCatalog`
- `inspect(slotId)`
- `list()`
- immutable `PlayerPresidentInteractiveDecisionSaveSlotSummary`
- summary her zaman M77 `load()` ile restore edilen exact M75 bundle'dan türetilir,
- ayrı metadata sidecar/timestamp authority yazılmaz,
- corrupt/divergent slot stale metadata üretmeden mevcut M75/M74 validation zinciriyle fail-closed olur,
- catalog save bytes'ını mutate etmez.

Aktif branch:
- `feat/m78-interactive-decision-file-save-slot-catalog`

Aktif PR:
- **#81 — DRAFT / OPEN / PRE-MERGE**
- başlık: `M78: interactive decision file save slot catalog`

İlk executable code/workflow HEAD:
- `1514f1e20d21e8d9b80b6edab26d6024a0fa3d84`

İlk executable CI:
- run `34903156421`
- test job `104173594556` SUCCESS
- analyzer `No issues found!`
- **355/355 tests PASS**
- 5 M78 acceptance testi PASS
- canonical job `104173594298` SUCCESS
- M0–M78 executable adımlarının tamamı SUCCESS
- exact M78 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

Bu ilk run executable source/test/canonical kanıtıdır. M78 milestone dokümanı + proje özeti + devir notu executable CI sonrasında eklendiği için **docs dahil final exact-head CI yeniden doğrulanmadan merge-ready/PASS sayılmaz**.

M78 milestone dokümanı:
- `M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_I.md`

## 5. Aktif milestone — M78

### M78 — Player President Interactive Decision File Save Slot Catalog I

Durum: **ACTIVE / PRE-MERGE / FINAL EXACT-HEAD CI BEKLİYOR**

Amaç:
M77 local save slot'larını gerçek load-game/application yüzeyinin doğrudan kullanabileceği deterministic read-only özetlere çevirmek.

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

Authority sınırı:
- M65 tek persisted **game-state authority** olmaya devam eder.
- M74 replay transcript metadata'dır.
- M75 versioned/checksummed atomik application persistence bundle/save formatıdır.
- M76 interactive application-session lifecycle owner'dır.
- M77 exact M75 bytes'ının file-backed storage adapter'ıdır.
- M78 yalnız M77 üzerinden authoritative save'i restore edip UI/load-game için read-only projection üretir.
- Yeni game-state codec, metadata sidecar, save formatı, Flutter/provider state, Android platform channel, database veya cloud authority eklenmez.

Fresh scan'de ayrıca M73'ün sezon 0'dan interaktif `start` desteklediği, M76/M75'in checkpoint-backed olduğu görüldü. Pre-checkpoint/new-game persistence gerçek bir açık olsa da M65 checkpoint dışı persistence representation gerektirdiği için M78 kapsamına alınmadı; daha büyük ayrı bir milestone olarak değerlendirilmelidir.

Ana M78 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_file_save_slot_catalog.dart`
- `lib/player_president_interactive_decision_file_save_slot_catalog.dart`
- `test/m78_player_president_interactive_decision_file_save_slot_catalog_test.dart`
- `tool/run_m78_player_president_interactive_decision_file_save_slot_catalog.dart`
- `M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_I.md`
- `.github/workflows/m0-tests.yml`

Acceptance:
1. slot authoritative M75/M65 state'ten deterministic load-game metadata'ya inspect edilir — ilk CI PASS,
2. summary listesi deterministic slot-id sırasını korur — ilk CI PASS,
3. overwrite sonrası catalog yalnız en güncel M75 bundle'ı yansıtır ve metadata sidecar oluşturmaz — ilk CI PASS,
4. missing/invalid slot M77 contract'ını korur — ilk CI PASS,
5. corrupt slot stale metadata üretmeden fail-closed olur — ilk CI PASS,
6. inspect/list save bytes'ını mutate etmez — ilk CI PASS,
7. M65/M75/M76/M77 authority sınırı korunur — ilk CI PASS.

Exact M78 marker:

`M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 slots=2 ordered=true metadata=true latestBundle=true nonMutating=true missingNull=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. Son kapanan milestone — M77

### M77 — Player President Interactive Decision File Save Slot Store I

Durum: **CLOSED / MERGED / PASS**

PR / merge:
- #80 — MERGED / CLOSED
- final exact pre-merge HEAD: `6115dc02774ec96f3765970ab0f84818703d1a3f`
- squash merge SHA: `be1f8d382d84be01a502a4849ebd43528d97a7b0`

Final exact-head PR CI:
- run `34899088675`
- analyzer clean
- 350/350 tests PASS
- canonical M0–M77 SUCCESS
- exact M77 marker PASS
- artifacts 0

Post-merge gerçek `main` CI:
- run `34900833789`
- head SHA `be1f8d382d84be01a502a4849ebd43528d97a7b0`
- workflow SUCCESS
- analyzer clean
- 350/350 tests PASS
- canonical M0–M77 SUCCESS
- exact M77 marker PASS
- artifacts 0

M77 closure docs commit:
- `952bc9768629195d5d19ab7559170915f080ec31`

Closure docs CI:
- run `34901563339`
- test SUCCESS
- canonical outer conclusion `cancelled` yalnız strict 7 dakika envelope nedeniyle
- gerçek canonical M0–M77, M77, Post Checkout ve Complete job SUCCESS
- artifacts 0
- docs→CI→docs döngüsü oluşturulmadı.

M77 **CLOSED / MERGED / PASS**.

## 7. Yakın milestone zinciri

- M78 — File Save Slot Catalog — PR #81 — **ACTIVE / PRE-MERGE** — 355 tests on initial executable HEAD.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0` — 350 tests.
- M76 — Interactive Decision Application Session — PR #79 — merge `3fdc084a988050b179892ebdc5818c9d032720a0` — 344 tests.
- M75 — Interactive Decision Persistence Bundle — PR #78 — merge `c88d65f6c06769fa2298d92bc791f76a0ebf5bed` — 339 tests.
- M74 — Interactive Decision Transcript Snapshot — PR #77 — merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c` — 334 tests.
- M73 — Interactive Decision Session — PR #76 — merge `a82caf70f832c20e2da2929bcaddd26aad85b618` — 329 tests.
- M72 — Unified Decision Gateway Runtime — PR #75 — merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c` — 324 tests.
- M71 ve öncesi — CLOSED / MERGED / PASS.

## 8. Sistem mimarisi — kısa harita

M0–M18:
- sezon / kariyer / oyuncu / ekonomi / transfer / world / manager / contract / fan / media / vaat / seçim / başkanlık temelleri.

M19–M24:
- başkan trait feedback zinciri.

M25–M32:
- save/load, runtime snapshot, history compaction ve resume stress.

M33–M39:
- facility / academy / portfolio yatırımları ve başkan karar döngüsü.

M40–M48:
- stadium attendance, fan trust, sponsor, crisis ve facility/sponsor/crisis runtime composition.

M49–M57:
- player-president facility / sponsor / crisis / manager / transfer / promise / media kontrolleri.

M58–M65:
- tenure ownership gate ve tenure-gated player controls; M65 persisted runtime game-state authority.

M66–M71:
- tüm player-president domain'lerinin aynı M65 checkpoint authority üzerinde composition'ı.

M72:
- application-facing tek `PlayerPresidentDecisionGateway`.

M73:
- deterministic `pending request → response → continue` interactive session.

M74:
- accepted-answer transcript için checksummed replay sidecar.

M75:
- M65 game-state save + M74 transcript + M73 resume config için atomik application persistence bundle.

M76:
- checkpoint-backed interaktif oturum için tek application lifecycle owner; M65/M74/M75'i eşli halde tutarak `advance / submit / save / restore` surface sağlar.

M77:
- exact M75 bundle bytes'ını validated local save-slot dosyalarına yazan/yükleyen file-backed application storage adapter; interrupted replacement recovery sağlar.

M78:
- M77 slotlarını tekrar authoritative M75/M65 state üzerinden restore ederek load-game için deterministic read-only slot summary/catalog projection üretir; ayrı metadata persistence oluşturmaz.

## 9. Başkan trait etkileri

- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response + AI ticket pricing
- `transferAmbition`: transfer activity + stadium priority + supporter crisis
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority

## 10. Authority zinciri

- M58 player-president tenure ownership state'ini sağlar.
- M59–M64 tenure-gated domain control katmanlarını kurar.
- M65 tek persisted **game-state authority**'dir.
- M66–M71 yeni authority üretmeden M65 üzerinde domain composition yapar.
- M72 tek application decision gateway sağlar.
- M73 runtime-only interactive session sağlar.
- M74 yalnız replay transcript metadata'sını persist eder.
- M75 M65 + M74 + minimal M73 resume config'i tek outer persistence envelope içinde eşler; authority değiştirmez.
- M76 mevcut katmanları tek application-session lifecycle owner içinde compose eder; yeni game-state/save authority üretmez.
- M77 M75'in exact encoded bundle'ını local slot dosyasına materialize eder; save-format/game-state authority üretmez.
- M78 M77 üzerinden restore edilen mevcut authoritative state'ten read-only load-game summary üretir; yeni persistence/authority üretmez.

## 11. Bir sonraki sohbet için kesin talimat

M78 aktifken M79 seçme.

Önce:
1. canlı `main` HEAD,
2. PR #81 canlı head SHA / draft / mergeable durumu,
3. exact-head workflow run / `test` / `canonical` / artifacts durumu,
4. `GENEL_PROJE_OZETI.md`,
5. `SOHBET_DEVIR_NOTU.md`

doğrulanmalıdır.

Docs dahil **final exact PR HEAD** için analyzer + 355 test + 5 M78 acceptance testi + M0–M78 executable canonical + exact M78 marker + cleanup + artifacts=0 doğrulanmalıdır.

Tüm gates başarılıysa PR ready hale getirilmeli, ready sonrası exact final HEAD tekrar kilitlenmeli ve kullanıcıdan **o SHA için açık merge onayı** istenmelidir. Onay gelmeden merge edilmez.

Onay sonrası yalnız onaylanan exact HEAD squash + `expected_head_sha` ile merge edilir. Post-merge gerçek `main` executable CI doğrulanmadan M78 CLOSED / MERGED / PASS yazılmaz.
