# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 14 Eylül 2026

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
5. ancak bundan sonra sıradaki işi seç.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır.

## 4. CANLI DURUM — buradan devam et

**M0–M76 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yoktur.**

**M77 seçilmemiş ve başlatılmamıştır.**

Yarım kalmış kod işi veya merge bekleyen milestone PR'ı devredilmiyor.

Kullanıcı “devam et” dediğinde eski sohbetten M77 kapsamı varsayılmamalıdır. Canlı `main` üzerinde fresh gap scan yapılarak oyunu gerçek ürüne yaklaştıran en küçük, test edilebilir ve deterministic sonraki açık seçilmelidir.

## 5. Son kapanan milestone — M76

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
- Filesystem, Flutter widget/state, Android save-slot backend, database veya cloud-save authority eklenmedi.

Ana M76 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_application_session.dart`
- `lib/player_president_interactive_decision_application_session.dart`
- `test/m76_player_president_interactive_decision_application_session_test.dart`
- `tool/run_m76_player_president_interactive_decision_application_session.dart`
- `M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_I.md`
- `.github/workflows/m0-tests.yml`

Acceptance:
1. aynı checkpoint/config exact aynı ilk pending request'i üretir — PASS,
2. dört cevap sonrası save/restore exact next pending request'e döner ve encoded bytes stabildir — PASS,
3. stale response fail-closed olur ve persisted transcript mutasyona uğramaz — PASS,
4. corrupt M75 bundle `restoreEncoded` sırasında reddedilir — PASS,
5. save→restore→completion uninterrupted session ile exact checkpoint/boundary/decision-count parity verir — PASS,
6. M65/M74/M75 authority sınırı korunur — PASS.

Exact M76 marker:
`M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true stableSave=true applicationLifecycle=true atomicBundle=M75 parityM75=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. M76 merge ve CI kanıtı

PR:
- **#79 — MERGED / CLOSED**
- branch: `feat/m76-interactive-decision-application-session`
- final exact pre-merge HEAD: `f84c50aac5deac7512ff7c7acd111cbc5d2fb8dd`
- kullanıcı bu exact HEAD için açık merge onayı verdi
- squash merge SHA: `3fdc084a988050b179892ebdc5818c9d032720a0`

Final exact-head PR CI:
- run `34893560191`
- analyzer `No issues found!`
- **344/344 tests PASS**
- 5 M76 acceptance testi PASS
- canonical executable M0–M76 SUCCESS
- exact M76 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts 0
- canonical dış etiketi yalnız strict 7 dakika envelope sonrasında `cancelled`; M76 dahil tüm executable adımlar önceden SUCCESS

Post-merge gerçek `main` executable CI:
- run `34894535027`
- head SHA `3fdc084a988050b179892ebdc5818c9d032720a0`
- event `push`
- run number `489`

Attempt 1:
- test job SUCCESS
- analyzer `No issues found!`
- **344/344 tests PASS**
- 5 M76 acceptance testi PASS
- canonical M0–M72 SUCCESS
- M73 kendi PASS marker'ını yazdıktan hemen sonra strict 7 dakika envelope doldu
- M74–M76 bu ilk attempt'te çalışmadı
- gerçek canonical logu incelendi; assertion/runtime failure olmadığı doğrulandı
- timeout-only olduğu için kod patch'i atılmadı

Attempt 2 — aynı exact `main` SHA üzerinde yalnız kanıt retry'sı:
- workflow conclusion **SUCCESS**
- canonical job `104147997745` **SUCCESS**
- canonical executable M0–M76 **SUCCESS**
- M73, M74, M75 ve M76 exact marker'ları PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**
- repo/kod içeriği retry için değiştirilmedi

M76 **CLOSED / MERGED / PASS**.

## 7. Yakın milestone zinciri

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

## 11. Bir sonraki sohbet için kesin talimat

Yeni sohbet başladığında doğrudan bir M77 fikrine atlama.

Önce:
1. canlı `main` HEAD,
2. son workflow run'ları,
3. açık PR/branch durumu,
4. `GENEL_PROJE_OZETI.md`,
5. `SOHBET_DEVIR_NOTU.md`

doğrulanmalıdır.

Sonra repo üzerinde **fresh live-main gap scan** yapılarak sıradaki milestone belirlenmelidir.
