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
- oluşturma commit'i: `95233a3e524b031e665f298774c9576676bd81ba`

Yeni sohbet başlangıç sırası:
1. canlı GitHub `main` HEAD'i doğrula,
2. `GENEL_PROJE_OZETI.md` oku,
3. `SOHBET_DEVIR_NOTU.md` oku,
4. branch / PR / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula,
5. aktif milestone varsa onu tamamla; yoksa fresh gap scan ile sıradaki işi seç.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır.

## 4. CANLI DURUM — buradan devam et

**M0–M76 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M77 — Player President Interactive Decision File Save Slot Store I.**

M77 başlanmadan önce canlı `main` HEAD:
`3e38c7eb918f11bb42eb473be66cc12376758d5a`

Fresh live-main gap scan M76 sonrasında şu açığı doğruladı:
- M76 application session exact M75 bundle'ını encoded `String` olarak üretip restore edebiliyor,
- ancak repoda concrete save-slot/storage adapter yoktu,
- `dart:io` tabanlı local persistence backend yoktu,
- application katmanı M75 bundle'ını gerçek bir local slot'a yazıp daha sonra yeni process/store instance'ından yükleyemiyordu.

M77 bu açığı yeni authority oluşturmadan kapatır:
- `PlayerPresidentInteractiveDecisionFileSaveSlotStore`
- `save(slotId, session)`
- `load(slotId)`
- `contains(slotId)`
- `delete(slotId)`
- `listSlotIds()`
- validated slot IDs,
- temp + backup replacement,
- interrupted-write recovery,
- corrupt bundle için M75 validation üzerinden fail-closed davranış.

Aktif branch:
- `feat/m77-interactive-decision-file-save-slot-store`

Aktif PR:
- **#80 — DRAFT / OPEN / PRE-MERGE**
- başlık: `M77: interactive decision file save slot store`

İlk exact code/workflow HEAD:
- `e217f7bcb937e8bd83bad3cda8d6c80c4460d4fb`

İlk executable CI:
- run `34898142811`
- test job `104157272601` SUCCESS
- analyzer `No issues found!`
- **350/350 tests PASS**
- 6 M77 acceptance testi PASS
- canonical job `104157272375`: M0–M77 executable adımlarının tamamı SUCCESS
- exact M77 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

Bu ilk run executable source/test/canonical kanıtıdır. M77 milestone dokümanı ve devir docs commit'leri branch HEAD'ini ilerlettiği için **final exact-head PR CI yeniden doğrulanmadan merge-ready/PASS sayılmaz**.

M77 milestone dokümanı:
- `M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_I.md`

## 5. Aktif milestone — M77

### M77 — Player President Interactive Decision File Save Slot Store I

Durum: **ACTIVE / PRE-MERGE / FINAL EXACT-HEAD CI BEKLİYOR**

Amaç:
M76'nın application-session lifecycle'ını gerçek local save slot ile bağlamak; exact M75 bundle bytes'ını güvenli ve deterministic şekilde local filesystem üzerinde saklamak/yüklemek.

Authority sınırı:
- M65 tek persisted **game-state authority** olmaya devam eder.
- M74 replay transcript metadata'dır.
- M75 versioned/checksummed atomik application persistence bundle'dır.
- M76 interactive application-session lifecycle owner'dır.
- M77 yalnız M75 bundle bytes'ını filesystem slot'una materialize eden application storage adapter'dır.
- Yeni game-state codec, yeni save formatı, Flutter state/provider, Android platform channel, database veya cloud authority eklenmez.

Ana M77 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_file_save_slot_store.dart`
- `lib/player_president_interactive_decision_file_save_slot_store.dart`
- `test/m77_player_president_interactive_decision_file_save_slot_store_test.dart`
- `tool/run_m77_player_president_interactive_decision_file_save_slot_store.dart`
- `M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_I.md`
- `.github/workflows/m0-tests.yml`

Acceptance:
1. save edilen slot yeni store instance'ından exact pending request + exact M75 bytes ile restore edilir — ilk CI PASS,
2. overwrite yalnız en yeni exact M75 bundle'ı authoritative target yapar — ilk CI PASS,
3. path traversal / invalid slot id fail-closed reddedilir — ilk CI PASS,
4. interrupted replacement committed backup'tan recovery edilir — ilk CI PASS,
5. corrupt target M75 validation üzerinden fail-closed reddedilir — ilk CI PASS,
6. slot listesi deterministic sıralıdır ve delete slot state'ini kaldırır — ilk CI PASS,
7. M65/M75/M76 authority sınırı korunur — ilk CI PASS.

Exact M77 marker:
`M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true interruptedRecovery=true invalidBlocked=true stableSave=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. Son kapanan milestone — M76

### M76 — Player President Interactive Decision Application Session I

Durum: **CLOSED / MERGED / PASS**

M76'nın amacı, M75 sonrasında application/UI katmanının M65 checkpoint + M74 transcript + M75 resume config'i ayrı ayrı eşleyip interactive save/load lifecycle'ını elle yönetmesi gereğini kaldırmaktı.

M76 çözümü:
- `PlayerPresidentInteractiveDecisionApplicationSession`
- `resume(...)`
- `restore(...)` / `restoreEncoded(...)`
- `advance()` / `submit(...)`
- `persistenceBundle`
- `encodePersistenceBundle()`
- `pendingDecision`
- `answeredDecisionCount`
- `completed`

Authority sınırı değişmedi:
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + save codec tek persisted **game-state authority** olmaya devam eder.
- M74 accepted-answer transcript yalnız deterministic replay metadata'sıdır.
- M75 atomik application persistence bundle'dır.
- M76 yalnız runtime/application lifecycle composition sağlar; yeni game-state/save authority oluşturmaz.

PR / merge:
- **#79 — MERGED / CLOSED**
- final exact pre-merge HEAD: `f84c50aac5deac7512ff7c7acd111cbc5d2fb8dd`
- squash merge SHA: `3fdc084a988050b179892ebdc5818c9d032720a0`

Final exact-head PR CI:
- run `34893560191`
- analyzer clean
- 344/344 tests PASS
- canonical M0–M76 SUCCESS
- exact M76 marker PASS
- artifacts 0

Post-merge gerçek `main` executable CI:
- run `34894535027`
- merge SHA `3fdc084a988050b179892ebdc5818c9d032720a0`
- attempt 1 timeout-only: test SUCCESS, M0–M72 SUCCESS, M73 marker çıktıktan sonra envelope doldu
- attempt 2 aynı SHA üzerinde canonical retry: workflow/canonical SUCCESS, M0–M76 SUCCESS, cleanup SUCCESS, artifacts 0

M76 closure docs commit:
- `3e38c7eb918f11bb42eb473be66cc12376758d5a`

Closure docs CI:
- run `34896080070`
- test SUCCESS
- analyzer SUCCESS
- canonical executable M0–M76 + Post Checkout + Complete job SUCCESS
- dış canonical etiketi strict 7 dakika envelope nedeniyle `cancelled`
- artifacts 0
- docs→CI→docs döngüsü üretilmedi

M76 **CLOSED / MERGED / PASS**.

## 7. Yakın milestone zinciri

- M77 — File Save Slot Store — PR #80 — **ACTIVE / PRE-MERGE** — 350 tests on initial executable HEAD.
- M76 — Interactive Decision Application Session — PR #79 — merge `3fdc084a988050b179892ebdc5818c9d032720a0` — 344 tests.
- M75 — Interactive Decision Persistence Bundle — PR #78 — merge `c88d65f6c06769fa2298d92bc791f76a0ebf5bed` — 339 tests.
- M74 — Interactive Decision Transcript Snapshot — PR #77 — merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c` — 334 tests.
- M73 — Interactive Decision Session — PR #76 — merge `a82caf70f832c20e2da2929bcaddd26aad85b618` — 329 tests.
- M72 — Unified Decision Gateway Runtime — PR #75 — merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c` — 324 tests.
- M71 — eight-domain player-president runtime composition — CLOSED.
- M70 — seven-domain composition — CLOSED.
- M69 — sponsor composition — CLOSED.
- M68 — facility composition — CLOSED.
- M67 — promise/media/transfer/ticket composition — CLOSED.
- M66 — transfer/ticket composition — CLOSED.
- M65 — persisted player-president ticket-pricing runtime authority — CLOSED.
- M0–M64 — CLOSED / MERGED / PASS.

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
- M76 bu mevcut katmanları tek application-session lifecycle owner içinde compose eder; yeni game-state/save authority üretmez.
- M77 M75'in exact encoded bundle'ını local slot dosyasına materialize eder; save-format/game-state authority üretmez.

## 11. Bir sonraki sohbet için kesin talimat

M77 aktifken M78 seçme.

Önce:
1. canlı `main` HEAD,
2. PR #80 canlı head SHA / draft / mergeable durumu,
3. exact-head workflow run / `test` / `canonical` / artifacts durumu,
4. `GENEL_PROJE_OZETI.md`,
5. `SOHBET_DEVIR_NOTU.md`

doğrulanmalıdır.

Docs dahil **final exact PR HEAD** için analyzer + 350 test + M0–M77 executable canonical + exact M77 marker + cleanup + artifacts=0 doğrulanmalıdır. Tüm gates başarılıysa PR ready hale getirilmeli, exact final HEAD tekrar kilitlenmeli ve kullanıcıdan **o SHA için açık merge onayı** istenmelidir. Onay gelmeden merge edilmez. Merge sonrası gerçek `main` executable CI doğrulanmadan M77 CLOSED yazılmaz.
