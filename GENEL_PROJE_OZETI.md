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

**M0–M74 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yoktur. M75 otomatik seçilmemiştir.**

Son kapanan milestone:
**M74 — Player President Interactive Decision Transcript Snapshot I — CLOSED / MERGED / PASS.**

M74 ile M73'ün runtime-only accepted-answer transcript'i application lifecycle boyunca geri yüklenebilir, versioned/checksummed bir replay sidecar haline getirildi. Bu sidecar game state değildir; M65 game-state checkpoint/save authority tek kaynak olmaya devam eder.

Canlı kapanış özeti:
- PR #77 — **MERGED / CLOSED**
- Branch: `feat/m74-interactive-decision-transcript-snapshot`
- Base `main`: `68b8a6437c6bc4a250ab7df8ab6597cdb5e3d42e`
- Pre-doc code HEAD: `02a2ad68368bbf4a2ffeef9a8315689d3baa5c55`
- Final exact pre-merge PR HEAD: `bc799eb4333ced2419bca752330d98ca2d6380be`
- Exact-head squash merge SHA: `6f03d14cfcba345a8f5873fccc2d603329b71e2c`
- Post-merge executable `main` push CI run: `34883829920`
- Post-merge analyzer: `No issues found!`
- Post-merge normal/non-canonical tests: **334/334 PASS**
- Post-merge canonical: **M0–M74 SUCCESS**
- Post-merge exact M74 marker: **PASS**
- Post Checkout + Complete job: **SUCCESS**
- Artifacts: **0**

Exact M74 marker:
`M74_PLAYER_PRESIDENT_INTERACTIVE_DECISION_TRANSCRIPT_SNAPSHOT_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true canonicalRoundTrip=true parityM73=true transcriptOnly=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

Bir sonraki iş ancak yeni bir canlı `main` gap scan ile seçilmelidir. Eski sohbetten M75 kapsamı varsayılmamalıdır.

## 3. M74 — Player President Interactive Decision Transcript Snapshot I — CLOSED / MERGED / PASS

### 3.1 Neden gerekliydi?

M73 gerçek UI/application katmanının deterministic `pause → pending request → response → continue` akışını kurdu; ancak kabul edilmiş cevap transcript'i yalnız RAM'de tutuluyordu. Uygulama süreci kararlar arasında kapanırsa aynı sezon içindeki daha önce verilmiş player-president cevapları kaybolabilirdi.

M74 bu boşluğu ikinci bir game-state save üretmeden kapatır: yalnız M73 replay metadata'sını persist eder.

### 3.2 Çözüm

- `PlayerPresidentInteractiveDecisionTranscriptEntry` deterministic request key + decision kind + minimal typed choice payload taşır.
- `PlayerPresidentInteractiveDecisionTranscriptSnapshot` yalnız kabul edilmiş cevap sırasını taşır; game state, pending context veya partial checkpoint taşımaz.
- `PlayerPresidentInteractiveDecisionTranscriptSaveCodec` versioned/checksummed canonical JSON sidecar üretir.
- `PlayerPresidentInteractiveDecisionTranscriptSession`, M73 session'ını sarar ve yalnız başarılı submit cevaplarını kaydeder.
- Restore sırasında uygulama aynı fresh-start input'larını veya authoritative M65 checkpoint'ini yeniden sağlar.
- Pending request/context save'den okunmaz; M73 tarafından deterministic yeniden türetilir.
- Her transcript entry restore sırasında yeniden türetilen request key + kind ile exact eşleşmek zorundadır.
- Checksum bozukluğu veya checksum-valid stale/divergent transcript fail-closed olur.
- Dokuz M73 karar türünün tamamı serialize edilir: facility, sponsor, crisis, manager review, manager replacement, promise, media, transfer strategy, ticket pricing.
- Flutter/UI, Android file-system, save-slot veya cloud-save katmanı eklenmez.

Persistence authority:
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted **game-state** authority olmaya devam eder.
- M74 sidecar game state değildir; yalnız M73 replay metadata'sıdır.
- M74 sidecar tek başına session restore etmek için yeterli değildir; aynı immutable start inputs veya aynı M65 checkpoint ayrıca gereklidir.

### 3.3 Acceptance

1. Partial fresh-start transcript encode/decode canonical round-trip verir ve restore exact pending request key'ini yeniden üretir — PASS.
2. Restored fresh-start session tamamlandığında uninterrupted M73 ile exact M65 checkpoint + boundary parity verir — PASS.
3. M65 checkpoint üstünde başlayan partial session restore aynı pending key'e döner ve uninterrupted M73 resume ile exact parity verir — PASS.
4. Checksum corruption replay başlamadan reddedilir — PASS.
5. Checksum-valid fakat stale/divergent request key restore sırasında fail-closed olur — PASS.
6. Transcript yalnız cevap metadata'sı taşır; M65 save authority/format değişmez — PASS.

M74 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_transcript_snapshot.dart`
- `lib/player_president_interactive_decision_transcript_snapshot.dart`
- `test/m74_player_president_interactive_decision_transcript_snapshot_test.dart`
- `tool/run_m74_player_president_interactive_decision_transcript_snapshot.dart`
- `M74_PLAYER_PRESIDENT_INTERACTIVE_DECISION_TRANSCRIPT_SNAPSHOT_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

### 3.4 CI ve merge kanıtı

Pre-doc CI run `34876337129`, exact code HEAD `02a2ad68368bbf4a2ffeef9a8315689d3baa5c55`:
- `test`: SUCCESS
- analyzer: clean
- 334/334 tests PASS
- 5 M74 acceptance testi PASS
- canonical attempt 1 M0–M69 SUCCESS ve M70 marker PASS sonrası strict 7 dakika envelope nedeniyle iptal oldu; gerçek assertion/runner failure yoktu
- aynı exact code HEAD'te yalnız canonical job bir kez retry edildi
- retry: M0–M74 SUCCESS, exact M74 marker SUCCESS, cleanup SUCCESS
- artifacts 0

Final exact-head PR CI run `34877936376`, exact HEAD `bc799eb4333ced2419bca752330d98ca2d6380be`:
- `test`: SUCCESS
- analyzer: `No issues found!`
- **334/334 tests PASS**
- 5 M74 acceptance testi PASS
- canonical ilk attempt substantive olarak M0–M74 + exact M74 marker + cleanup + Complete job SUCCESS tamamladı; strict 7 dakika envelope sonrasında job/run etiketi `cancelled` oldu
- aynı exact HEAD için izin verilen tek canonical retry M0–M71 marker'a kadar PASS ilerledi ve yine envelope nedeniyle M71 sonrasında iptal oldu; M72–M74 bu retry'de skip edildi
- üçüncü retry açılmadı
- runtime/assertion failure yoktu
- artifacts 0

Kullanıcı exact HEAD `bc799eb4333ced2419bca752330d98ca2d6380be` için açık merge onayı verdi.

Exact-head squash merge:
- PR #77
- merge SHA: `6f03d14cfcba345a8f5873fccc2d603329b71e2c`

Post-merge gerçek `main` CI run `34883829920`:
- `test`: **SUCCESS**
- analyzer: `No issues found!`
- **334 tests passed**
- M74'e ait 5 test PASS
- `canonical`: **SUCCESS**
- M0–M74 adımlarının tamamı SUCCESS
- exact M72 marker PASS
- exact M73 marker PASS
- exact M74 marker PASS
- Post Checkout SUCCESS
- Complete job SUCCESS
- artifacts: **0**

M74 **CLOSED / MERGED / PASS**.

## 4. Son önceki milestone: M73 — Player President Interactive Decision Session I — CLOSED / MERGED / PASS

M73 çözümü:
- session immutable başlangıç input/checkpoint'inden M72 runtime'ını deterministic olarak replay eder;
- ilk cevapsız player-president kararında partial simulation state commit etmeden durur ve tek pending request üretir;
- UI/application request kimliği + domain'e uygun cevabı gönderince transcript'e cevap eklenir ve aynı başlangıçtan deterministic replay edilir;
- stale/mismatched request ID ve domain-invalid response pending isteği tüketmeden reddedilir;
- session transcript runtime-only'dir;
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted game-state authority olmaya devam eder.

M73 kapanış kanıtı:
- PR #76 — MERGED / CLOSED
- final exact PR HEAD: `8c890582f5e597bb0d1d2155250b3586ca0c0a40`
- final exact-head PR CI run `34869241116`: workflow SUCCESS, analyzer clean, 329 tests PASS, canonical M0–M73 SUCCESS, artifacts 0
- squash merge SHA: `a82caf70f832c20e2da2929bcaddd26aad85b618`
- post-merge main CI run `34872238972`: workflow SUCCESS, analyzer clean, 329 tests PASS, canonical M0–M73 SUCCESS, exact M73 marker PASS, artifacts 0

Exact marker:
`M73_PLAYER_PRESIDENT_INTERACTIVE_DECISION_SESSION_PASS controlled=t1_01 decisions=9 uniqueKinds=9 pauseReplay=true parityM72=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

M73 **CLOSED / MERGED / PASS**.

## 5. Önceki milestone: M72 — Player President Unified Decision Gateway Runtime I — CLOSED / MERGED / PASS

M72 sekiz player-president provider yüzeyini tek application-facing `PlayerPresidentDecisionGateway` altında birleştirdi.

Temel garantiler:
- facility, sponsor, crisis, manager review/replacement, promise, media, transfer strategy ve ticket pricing tek gateway üzerinden yönlendirilebilir;
- mevcut provider/domain validation ve tenure-loss/successor bloklama semantiği bypass edilmez;
- gateway yokken exact M71 parity korunur;
- diğer 47 kulüp canonical AI yolunda kalır;
- gateway runtime-only'dir;
- M65 save/checkpoint authority değişmez.

Kapanış özeti:
- PR #75 — MERGED / CLOSED
- final pre-merge exact HEAD: `3868fa5c1ae3c03146cfc8c32628fde75f5e8a3b`
- squash merge SHA: `44aa7f9c830551a4e980b9bd233153feb92d6d2c`
- 324 tests PASS
- M0–M72 executable canonical gates PASS
- artifacts 0

Exact marker:
`M72_PLAYER_PRESIDENT_UNIFIED_DECISION_GATEWAY_RUNTIME_PASS controlled=t1_01 singleGateway=true managerCalls=1 gatewayCalls=7 singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. Yakın milestone geçmişi

- M74 Player President Interactive Decision Transcript Snapshot I — PR #77 merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c`; 334 tests; M0–M74 PASS; artifacts 0.
- M73 Player President Interactive Decision Session I — PR #76 merge `a82caf70f832c20e2da2929bcaddd26aad85b618`; 329 tests; M0–M73 PASS; artifacts 0.
- M72 Player President Unified Decision Gateway Runtime I — PR #75 merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c`; 324 tests; M0–M72 PASS; artifacts 0.
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

## 7. Sistem zinciri ve authority sınırları

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 ticket pricing → gerçek matchday economy runtime/checkpoint/save authority; M66 transfer + ticket composition; M67 promise/media + transfer/ticket composition; M68 facility + M67; M69 sponsor + M68; M70 crisis + M69; M71 manager + M70; M72 sekiz player-president karar alanını tek gateway altında birleştirir; M73 bu gateway'i deterministic replay tabanlı pending-request/response/continue session sınırına taşır; M74 M73 accepted-answer transcript'ini game state'ten ayrı versioned/checksummed replay sidecar olarak persist edip deterministic restore eder.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response + M64/M65 AI ticket-pricing posture
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority

Authority zinciri:
- M58 persisted player-president tenure ownership state'ini sağlar.
- M59–M64 kontrollü başkan kararlarının tenure-gated domain authority'sini kurar.
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted **game-state** authority'dir.
- M66–M71 yeni persisted authority oluşturmaz; aynı M65 checkpoint/tenure state üzerinde domain'leri compose eder.
- M72 yeni game-state/save formatı üretmez; application/UI için tek runtime decision gateway sağlar.
- M73 yeni persisted game state üretmez; pending request/answer transcript'i runtime-only tutar ve immutable başlangıçtan deterministic replay yapar.
- M74 yalnız M73 accepted-answer replay metadata'sını sidecar olarak persist eder; pending request/context ve game state sidecar'a yazılmaz, M65 game-state authority değişmez.

## 8. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez ve milestone kapanışlarında güncellenir.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün/architecture boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; exact-head lock kullan; merge sonrası `main` executable gates doğrulanmadan milestone'u CLOSED sayma.
9. Docs-only merge-ready/kapanış commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
10. M74 kapanmıştır. M75 veya sonraki milestone eski sohbet varsayımıyla otomatik seçilmez; kullanıcı devam etmek istediğinde önce yeni canlı `main` gap scan yapılır.
