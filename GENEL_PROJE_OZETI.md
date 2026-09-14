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
- CI kırmızıysa gerçek job logu okunmadan patch atılmaz.
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
5. ancak bundan sonra sıradaki işi seç veya aktif milestone'u kaldığı yerden sürdür.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır.

## 4. CANLI DURUM — buradan devam et

**M0–M75 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M76 — Player President Interactive Decision Application Session I.**

Fresh live-main gap scan M75 sonrasında şu açığı buldu: M75 persistence bundle formatını çözmesine rağmen application/UI katmanı çalışan oturum sırasında M65 checkpoint + M74 transcript + M75 resume config'i ayrı ayrı eşleyip save/load lifecycle'ını elle yönetmek zorundaydı.

M76 bu açığı yeni authority üretmeden tek application-facing lifecycle owner ile kapatır:
- `PlayerPresidentInteractiveDecisionApplicationSession`
- `advance()` / `submit(...)`
- `encodePersistenceBundle()`
- `restore(...)` / `restoreEncoded(...)`
- pending/completed/answered state read surface.

Aktif branch:
- `feat/m76-interactive-decision-application-session`

Aktif PR:
- **#79 — DRAFT / OPEN**
- başlık: `M76: interactive decision application session`

İlk exact code HEAD:
- `7711aa26287212e10e329ffa8b750653ecc7db95`

İlk executable CI:
- run `34892927092`
- analyzer `No issues found!`
- **344/344 tests PASS**
- 5 M76 acceptance testi PASS
- test job SUCCESS

Bu ilk run M76 canonical workflow step'i eklenmeden önce source/test compile kanıtı almak için kullanıldı. Ardından M76 canonical marker step'i ve pre-merge docs eklendi. **Final exact-head PR CI henüz tamamlanmadan M76 merge-ready/PASS sayılmaz.**

M76 milestone dokümanı:
- `M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_I.md`

## 5. Son kapanan milestone — M75

### M75 — Player President Interactive Decision Persistence Bundle I

Durum: **CLOSED / MERGED / PASS**

M75'in amacı, checkpoint-backed interaktif başkanlık oturumunun uygulama seviyesinde güvenli biçimde saklanabilmesi için şu üç parçayı tek atomik envelope altında eşlemekti:

- authoritative M65 game-state save,
- M74 accepted-answer transcript save,
- M73 resume için gereken minimal deterministic runtime config.

M75 yeni bir game-state authority oluşturmaz.

Authority sınırı:
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted **game-state authority** olmaya devam eder.
- M74 transcript yalnız deterministic replay metadata'sıdır.
- M75 M65 + M74 + minimal M73 resume config'i versioned/checksummed outer persistence bundle içinde atomik olarak compose eder.
- Partial runtime state, UI state, filesystem save-slot backend veya cloud-save authority oluşturulmaz.

Ana M75 tipleri:
- `PlayerPresidentInteractiveDecisionResumeConfig`
- `PlayerPresidentInteractiveDecisionPersistenceBundle`
- `PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec`

Ana M75 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_persistence_bundle.dart`
- `lib/player_president_interactive_decision_persistence_bundle.dart`
- `test/m75_player_president_interactive_decision_persistence_bundle_test.dart`
- `tool/run_m75_player_president_interactive_decision_persistence_bundle.dart`
- `M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_I.md`

Acceptance:
1. canonical bundle round-trip exact nested M65 + M74 save'lerini korur — PASS,
2. restore exact pending request'e döner ve uninterrupted M74 parity verir — PASS,
3. başka M65 save ile eşleştirilmiş checksum-valid stale transcript fail-closed olur — PASS,
4. outer checksum corruption nested restore öncesinde reddedilir — PASS,
5. valid outer checksum içindeki bozuk nested M65 save nested validation ile reddedilir — PASS,
6. M65 tek persisted game-state authority olarak kalır — PASS.

Exact M75 marker:
`M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true canonicalRoundTrip=true atomicBundle=true nestedChecksums=true parityM74=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. M75 merge ve CI kanıtı

PR:
- **#78 — MERGED / CLOSED**
- branch: `feat/m75-interactive-decision-persistence-bundle`
- final exact pre-merge HEAD: `6c71902ba8c8cd3398aac3e40828fb4093cdd436`
- kullanıcı exact HEAD için açık merge onayı verdi
- squash merge SHA: `c88d65f6c06769fa2298d92bc791f76a0ebf5bed`

Final exact-head PR CI:
- run `34888876382`
- analyzer clean
- 339/339 tests PASS
- 5 M75 acceptance testi PASS
- canonical executable M0–M75 SUCCESS
- exact M75 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts 0
- canonical dış etiketi strict 7 dakika envelope sonunda `cancelled`; assertion/runtime failure yok

Post-merge gerçek `main` executable CI:
- run `34890260125`
- test job SUCCESS
- analyzer `No issues found!`
- 339 tests PASS
- 5 M75 acceptance testi PASS
- canonical executable M0–M75 SUCCESS
- M72, M73, M74 ve M75 exact marker'ları PASS
- Post Checkout + Complete job SUCCESS
- artifacts 0
- canonical dış etiketi yalnız strict 7 dakika envelope sonrasında `cancelled`; tüm executable adımlar önceden SUCCESS

M75 closure docs commit:
- `f7ae064e63d1ef05bff841f54ed25253dd9b024c`

Closure docs CI:
- run `34891239476`
- head SHA `f7ae064e63d1ef05bff841f54ed25253dd9b024c`
- event `push`
- test job SUCCESS
- analyzer SUCCESS
- canonical M0–M75 SUCCESS
- Post Checkout + Complete job SUCCESS
- strict 7 dakika outer envelope sonunda run/canonical conclusion `cancelled`
- runtime/assertion failure yok
- artifacts 0
- retry açılmadı ve docs→CI→docs döngüsü üretilmedi

M75 **CLOSED / MERGED / PASS**.

## 7. Yakın milestone zinciri

- M76 — Interactive Decision Application Session — PR #79 — **ACTIVE / PRE-MERGE** — 344 tests on initial code HEAD.
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

M76 aktifken yeni milestone seçme.

Önce:
1. canlı `main` HEAD,
2. PR #79'un canlı head SHA / draft / mergeable durumu,
3. exact-head workflow run / `test` / `canonical` / artifact durumu,
4. `GENEL_PROJE_OZETI.md`,
5. `SOHBET_DEVIR_NOTU.md`

doğrulanmalıdır.

Final exact-head CI henüz tamamlanmamışsa onu doğrula. Tüm executable gates başarılıysa PR'ı merge-ready hale getir, exact final HEAD'i tekrar kilitle ve kullanıcıdan **o SHA için açık merge onayı** iste. Onay gelmeden merge etme. Merge sonrası gerçek `main` executable CI doğrulanmadan M76 CLOSED yazma.
