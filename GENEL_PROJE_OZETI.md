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

**Aktif milestone yoktur.**

**M78 seçilmemiş ve başlatılmamıştır.**

Yarım kalmış kod işi veya merge bekleyen milestone PR'ı devredilmiyor.

Kullanıcı “devam et” dediğinde M78 kapsamı eski sohbetten varsayılmamalıdır. Önce canlı `main`, açık PR/branch durumu ve CI yeniden doğrulanmalı; ardından fresh live-main gap scan ile oyunu gerçek ürüne yaklaştıran en küçük, test edilebilir ve deterministic açık seçilmelidir.

## 5. Son kapanan milestone — M77

### M77 — Player President Interactive Decision File Save Slot Store I

Durum: **CLOSED / MERGED / PASS**

M77 öncesi açık:
- M76 application session exact M75 bundle'ını encoded `String` olarak üretebiliyor ve restore edebiliyordu,
- ancak repoda concrete file-backed save-slot/storage adapter bulunmuyordu,
- application katmanı M75 bundle'ını gerçek local slot'a yazıp yeni process/store instance'ından yükleyemiyordu.

M77 çözümü:
- `PlayerPresidentInteractiveDecisionFileSaveSlotStore`
- `save(slotId, session)`
- `load(slotId)`
- `contains(slotId)`
- `delete(slotId)`
- `listSlotIds()`
- validated slot IDs,
- exact M75 bundle bytes için file-backed local persistence,
- temp + backup replacement,
- interrupted-write recovery,
- corrupt bundle için M75 validation üzerinden fail-closed davranış.

Authority sınırı değişmedi:
- M65 tek persisted **game-state authority** olmaya devam eder.
- M74 accepted-answer deterministic replay metadata'sıdır.
- M75 versioned/checksummed atomik application persistence bundle/save formatıdır.
- M76 interactive application-session lifecycle owner'dır.
- M77 yalnız exact M75 bytes'ını local filesystem save-slot'una materialize eden storage adapter'dır.
- Yeni game-state codec/save authority, Flutter state/provider, Android platform channel, database veya cloud authority eklenmedi.

Ana M77 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_file_save_slot_store.dart`
- `lib/player_president_interactive_decision_file_save_slot_store.dart`
- `test/m77_player_president_interactive_decision_file_save_slot_store_test.dart`
- `tool/run_m77_player_president_interactive_decision_file_save_slot_store.dart`
- `M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_I.md`
- `.github/workflows/m0-tests.yml`

Acceptance:
1. file slot yeni store instance'ından exact pending request ve exact M75 bytes ile restore edilir — PASS,
2. overwrite yalnız en yeni exact M75 bundle'ı authoritative target olarak bırakır — PASS,
3. path traversal / invalid slot ID fail-closed reddedilir — PASS,
4. interrupted replacement committed backup'tan recovery edilir — PASS,
5. corrupt target M75 validation üzerinden fail-closed reddedilir — PASS,
6. slot listesi deterministic sıralıdır ve delete slot state'ini kaldırır — PASS,
7. M65/M75/M76 authority sınırı korunur — PASS.

Exact M77 marker:
`M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true interruptedRecovery=true invalidBlocked=true stableSave=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. M77 merge ve CI kanıtı

PR:
- **#80 — MERGED / CLOSED**
- branch: `feat/m77-interactive-decision-file-save-slot-store`
- final exact pre-merge HEAD: `6115dc02774ec96f3765970ab0f84818703d1a3f`
- kullanıcı bu exact HEAD için açık merge onayı verdi
- squash merge SHA: `be1f8d382d84be01a502a4849ebd43528d97a7b0`

Final exact-head PR CI:
- run `34899088675`
- analyzer `No issues found!`
- **350/350 tests PASS**
- 6 M77 acceptance testi PASS
- canonical executable M0–M77 SUCCESS
- exact M77 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

Post-merge gerçek `main` executable CI:
- run `34900833789`
- run number `495`
- event `push`
- head SHA `be1f8d382d84be01a502a4849ebd43528d97a7b0`
- workflow conclusion **SUCCESS**
- test job `104166130043` SUCCESS
- analyzer `No issues found!`
- **350/350 tests PASS**
- 6 M77 acceptance testi PASS
- canonical job `104166130250` SUCCESS
- canonical executable M0–M77 SUCCESS
- exact M77 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

M77 **CLOSED / MERGED / PASS**.

## 7. Yakın milestone zinciri

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

## 11. Bir sonraki sohbet için kesin talimat

M78 kapsamını önceden varsayma.

Önce:
1. canlı `main` HEAD,
2. son workflow run'ları,
3. açık PR/branch durumu,
4. `GENEL_PROJE_OZETI.md`,
5. `SOHBET_DEVIR_NOTU.md`

doğrulanmalıdır.

Sonra canlı `main` üzerinde **fresh gap scan** yapılarak oyunu gerçek ürüne yaklaştıran en küçük, test edilebilir ve deterministic sonraki açık seçilmelidir.

Bu closure doküman commit'inin kendi CI sonucu gözlemlenir; sırf sonucu yeniden belgelemek için yeni bir docs→CI→docs commit döngüsü oluşturulmaz.
