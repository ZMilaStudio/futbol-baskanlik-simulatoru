# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 14 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu. Mevcut repo saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz bu repoda kurulmamıştır.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
Canonical seed: `20260903`
Dünya: 48 özgün kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 14.400 maç/20 sezon, 864 başlangıç oyuncusu.

Kalıcı kurallar:
- Live GitHub > proje dosyaları > eski sohbetler.
- Deterministic seed/replay korunur; tarih `GameDate`, para integer minor-unit `Money` kullanır.
- Eski public simulation semantiği sessizce değiştirilmez.
- Save/load/resume determinism ve parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki paralel job: `test` + `canonical`; her job `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz.
- `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır ve güncel tutulur.
- Docs→CI→docs sonsuz döngüsü üretilmez.
- Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı gerekir.
- Merge exact-head kilidiyle ve squash yöntemiyle yapılır.
- Merge sonrası `main` executable doğrulaması tamamlanmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M73 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: yok.**

**Son kapanan milestone: M73 — Player President Interactive Decision Session I.**

M73 squash merge sonrası doğrulanmış code SHA:
`a82caf70f832c20e2da2929bcaddd26aad85b618`

Post-merge gerçek `main` push CI:
- run: `34872238972`
- event: `push`
- branch: `main`
- exact head: `a82caf70f832c20e2da2929bcaddd26aad85b618`
- workflow conclusion: **SUCCESS**
- `test`: **SUCCESS**
- analyzer: `No issues found!`
- **329/329 normal/non-canonical test PASS**
- M73'e ait 5 executable acceptance testinin tamamı PASS
- `canonical`: **M0–M73 SUCCESS**
- Post Checkout + Complete job: **SUCCESS**
- artifacts: **0**

Exact M73 canonical marker:
`M73_PLAYER_PRESIDENT_INTERACTIVE_DECISION_SESSION_PASS controlled=t1_01 decisions=9 uniqueKinds=9 pauseReplay=true parityM72=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

Bu kapanıştan sonra M74 veya başka bir milestone otomatik seçilmez. Bir sonraki geliştirme ancak canlı `main` yeniden taranıp gerçek ürün/architecture boşluğu doğrulandıktan sonra seçilir.

## 3. M73 — Player President Interactive Decision Session I — CLOSED / MERGED / PASS

M72 sonrası canlı gap scan sonucu:
- M72 sekiz player-president karar domain'ini tek senkron gateway altında toplamıştı;
- fakat gerçek UI/application katmanının “kararı göster → kullanıcı seçsin → sonra devam et” akışını sürdürebileceği pending-decision / request-response / pause-continue sınırı yoktu;
- core'u async/Future tabanlı hale getirmeden bu boşluğu kapatmak M73 kapsamı olarak seçildi.

M73 çözümü:
- session immutable başlangıç input/checkpoint'inden M72 runtime'ını deterministic olarak replay eder;
- ilk cevapsız player-president kararında partial simulation state commit etmeden durur ve tek pending request üretir;
- UI/application request kimliği + domain'e uygun cevabı gönderince transcript'e cevap eklenir ve aynı başlangıçtan deterministic replay edilir;
- sıradaki cevapsız karar pending olarak sunulur; tüm kararlar cevaplandığında sonuç direct M72 checkpoint + season-boundary parity verir;
- stale/mismatched request ID ve domain-invalid response pending isteği tüketmeden reddedilir;
- session transcript runtime-only'dir; save formatına yazılmaz;
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted authority olmaya devam eder;
- M49–M72 domain validation, tenure gate ve AI parity semantiği korunur;
- Flutter/UI eklenmez; yalnız UI'nin bağlanabileceği deterministic interactive application boundary sağlanır.

M73 acceptance:
1. unanswered decision => tek stabil pending request; partial progress commit edilmez — PASS;
2. request/response session completion => direct M72 checkpoint + boundary parity — PASS;
3. request sırası/kimliği deterministic ve interaktif karar türleri için benzersizdir — PASS;
4. stale/mismatched response pending request'i tüketmeden reddedilir — PASS;
5. domain-invalid response pending request'i tüketmeden reddedilir — PASS;
6. M65 checkpoint'ten session resume => direct M72 resume parity — PASS;
7. transcript runtime-only kalır; save authority/format değişmez — PASS.

M73 ana dosyaları:
- `lib/src/player_president/player_president_interactive_decision_session.dart`
- `lib/player_president_interactive_decision_session.dart`
- `test/m73_player_president_interactive_decision_session_test.dart`
- `tool/run_m73_player_president_interactive_decision_session.dart`
- `M73_PLAYER_PRESIDENT_INTERACTIVE_DECISION_SESSION_I.md`
- `.github/workflows/m0-tests.yml`

M73 kapanış kanıtı:
- PR #76 — **MERGED / CLOSED**
- Branch: `feat/m73-interactive-player-president-decision-session`
- Base `main`: `96ca537fa0849d197bc75a2c0f8f3f8cec16bd0c`
- Pre-doc code HEAD: `b06295e27d120ac6153bdc4a59947fd8fa39dd6a`
- Merge-ready/final exact PR HEAD: `8c890582f5e597bb0d1d2155250b3586ca0c0a40`
- Pre-doc CI run `34857011263`: test SUCCESS, analyzer clean, 329 tests PASS, M73 acceptance PASS; canonical executable adımlar M0–M73 + marker + cleanup SUCCESS, fakat strict 7 dakika envelope iki attempt'te run conclusion'ı `cancelled` yaptı; gerçek assertion/runner failure yoktu ve üçüncü retry açılmadı.
- Final exact-head PR CI run `34869241116`: **workflow SUCCESS**, `test` SUCCESS, analyzer clean, **329 tests PASS**, M73 acceptance PASS, **canonical M0–M73 SUCCESS**, cleanup SUCCESS, artifacts 0.
- Kullanıcı exact HEAD `8c890582f5e597bb0d1d2155250b3586ca0c0a40` için açık merge onayı verdi.
- Exact-head squash merge SHA: `a82caf70f832c20e2da2929bcaddd26aad85b618`.
- Post-merge gerçek `main` push CI run `34872238972`: **workflow SUCCESS**, analyzer clean, **329 tests PASS**, **canonical M0–M73 SUCCESS**, exact M73 marker PASS, cleanup SUCCESS, artifacts 0.

M73 **CLOSED / MERGED / PASS**.

## 4. Önceki son milestone: M72 — Player President Unified Decision Gateway Runtime I

M72 sekiz ayrı player-president provider yüzeyini tek application-facing `PlayerPresidentDecisionGateway` altında birleştirdi.

M72 temel garantileri:
- facility, sponsor, crisis, manager review/replacement, promise, media, transfer strategy ve ticket pricing tek gateway üzerinden yönlendirilebilir;
- mevcut provider/domain validation ve tenure-loss/successor bloklama semantiği bypass edilmez;
- gateway yokken exact M71 parity korunur;
- diğer 47 kulüp canonical AI yolunda kalır;
- gateway runtime-only'dir;
- M65 save/checkpoint authority değişmez.

M72 kapanış özeti:
- PR #75 — MERGED / CLOSED
- final pre-merge exact HEAD: `3868fa5c1ae3c03146cfc8c32628fde75f5e8a3b`
- squash merge SHA: `44aa7f9c830551a4e980b9bd233153feb92d6d2c`
- 324 tests PASS
- M0–M72 executable canonical gates PASS
- artifacts 0
- exact marker: `M72_PLAYER_PRESIDENT_UNIFIED_DECISION_GATEWAY_RUNTIME_PASS controlled=t1_01 singleGateway=true managerCalls=1 gatewayCalls=7 singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

M72 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

- M73 Player President Interactive Decision Session I — PR #76 merge `a82caf70f832c20e2da2929bcaddd26aad85b618`; 329 tests; M0–M73 PASS; artifacts 0.
- M72 Player President Unified Decision Gateway Runtime I — PR #75 merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c`; 324 tests; M0–M72 executable gates PASS; artifacts 0.
- M71 Player President Tenure-Gated Facility + Sponsor + Crisis + Manager + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #74 merge `fc373ee6dde881aa9bc730d0930924e7905725c9`; 321 tests; M0–M71 PASS; artifacts 0.
- M70 Player President Tenure-Gated Facility + Sponsor + Crisis + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #73 merge `b66512f08240f978286d1b6eaa128bd02ef2cfdb`; 315 tests; M0–M70 PASS; artifacts 0.
- M69 Player President Tenure-Gated Facility + Sponsor + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #72 merge `bf94f3e411f30c0d4474067650ab18c491b4f997`; 309 tests; M0–M69 PASS; artifacts 0.
- M68 Player President Tenure-Gated Facility + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #71 merge `779a0eb4d5c79b80d5afc743b9a53341bf56fcf2`; 303 tests; M0–M68 PASS; artifacts 0.
- M67 Player President Tenure-Gated Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #70 merge `9f4f3a3f314de29e770b2031de29c288a7761684`; 298 tests; M0–M67 PASS; artifacts 0.
- M66 Player President Tenure-Gated Transfer + Ticket Pricing Runtime Composition I — PR #69 merge `7860ef0e03a4326a884595eeef37d0b088b6e14a`; 293 tests; M0–M66 PASS; artifacts 0.
- M65 Player President Tenure-Gated Ticket Pricing Runtime Integration I — PR #68 merge `9e4de0ea84446293155292af39d7e887f6cdab3b`; 288 tests; M0–M65 PASS; artifacts 0.
- M64 Player President Tenure-Gated Ticket Pricing Control I — PR #67 merge `4a76d1546fa02675e1c94cd57621a82d70e15a8c`; 283 tests; M0–M64 PASS; artifacts 0.
- M63 Player President Tenure-Gated Promise + Media Composition I — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifacts 0.
- M62 Player President Tenure-Gated Media Statement Control I — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifacts 0.
- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifacts 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifacts 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifacts 0.

## 6. Sistem zinciri ve authority sınırları

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 ticket pricing → gerçek matchday economy runtime/checkpoint/save authority; M66 transfer + ticket composition; M67 promise/media + transfer/ticket composition; M68 facility + M67; M69 sponsor + M68; M70 crisis + M69; M71 manager + M70; M72 sekiz player-president karar alanını tek gateway altında birleştirir; M73 bu gateway'i deterministic replay tabanlı pending-request/response/continue session sınırına taşır.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response + M64/M65 AI ticket-pricing posture
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority

Authority zinciri:
- M58 persisted player-president tenure ownership state'ini sağlar.
- M59–M64 kontrollü başkan kararlarının tenure-gated domain authority'sini kurar.
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted authority'dir.
- M66–M71 yeni persisted authority oluşturmaz; aynı M65 checkpoint/tenure state üzerinde domain'leri compose eder.
- M72 yeni game-state/save formatı üretmez; application/UI için tek runtime decision gateway sağlar.
- M73 yeni persisted state üretmez; pending request/answer transcript'i runtime-only tutar ve immutable başlangıçtan deterministic replay yapar.

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez ve milestone kapanışlarında güncellenir.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün/architecture boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; exact-head lock kullan; merge sonrası `main` executable gates doğrulanmadan milestone'u CLOSED sayma.
9. Docs-only merge-ready/kapanış commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
10. Şu anda aktif milestone yoktur. M74 otomatik başlatılmaz; sonraki `devam et` isteğinde önce canlı `main` gap scan yapılır.