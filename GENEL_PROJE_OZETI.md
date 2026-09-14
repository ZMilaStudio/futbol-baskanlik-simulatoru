# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 14 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

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
- Merge sonrası `main` doğrulaması tamamlanmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M72 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: yok.**

M72 sonrası otomatik yeni milestone açma. Önce canlı `main` kodunu yeniden tara; ürün/UI, simulation ve architecture/application-boundary boşluklarını gerçek koddan türet. Repo halen saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz bu repoda yoktur.

## 3. Son kapanan milestone: M72 — Player President Unified Decision Gateway Runtime I

M71 sonrası canlı `main` taramasında, sekiz ayrı player-president provider callback'inin gerçek runtime'da compose edildiği ancak uygulama/UI katmanının kullanabileceği tek bir player-president karar gateway'inin bulunmadığı doğrulandı. M72 bu architecture/application-boundary boşluğunu kapattı; yeni oyun kuralı veya UI eklemedi.

M72 çözümü:
- `PlayerPresidentDecisionGateway`, facility, sponsor, crisis, manager review/replacement, promise, media, transfer strategy ve ticket pricing kararlarını tek application-facing interface altında toplar;
- gateway adapter'ları mevcut M49–M64 provider contract'larını kullanır; domain validation ve canonical etkiler eski motorlarda kalır;
- gateway yokken M72 exact M71 checkpoint + boundary parity verir;
- gateway yalnız controlled club ve aktif persisted player-president tenure için çağrılır; successor, incumbent mismatch ve persisted-loss bloklama M58–M71 authority'sinde kalır;
- diğer 47 kulüp canonical AI yolunda kalır;
- gateway runtime-only'dir ve save içine yazılmaz;
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted authority olmaya devam eder;
- Flutter/UI eklenmemiştir; M72 UI'nin daha sonra bağlanabileceği deterministic application boundary'yi hazırlar.

M72 acceptance:
1. gateway yokken exact M71 checkpoint + boundary signature parity — PASS;
2. tek gateway sekiz player-president karar domain'ini aynı gerçek sezon runtime'ında yönlendirir — PASS;
3. gateway yalnız controlled club context'lerini alır; diğer 47 kulüp AI yolunda kalır — PASS;
4. mevcut provider validation / tenure-loss / successor bloklama semantiği bypass edilmez — PASS;
5. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run; gateway runtime-only kalır — PASS.

M72 kapanış kanıtı:
- PR #75 — **MERGED / CLOSED**
- Branch: `feat/m72-unified-player-president-decision-gateway`
- Base `main`: `bbee62a1e56d50429c71a63b784f79a72ab27d18`
- Pre-doc PR HEAD: `2fbd01d8ed9df9903fb9306c4086e02863db8cbf`
- Final pre-merge exact PR HEAD: `3868fa5c1ae3c03146cfc8c32628fde75f5e8a3b`
- İlk full başarılı PR CI `34848064210`: analyzer clean; 324/324 test; M0–M72 canonical PASS; artifacts 0.
- Final exact-head PR CI `34849038178`: `test` SUCCESS; **324/324 normal/non-canonical test PASS**; **M0–M72 canonical PASS**; artifacts 0.
- Squash merge SHA: `44aa7f9c830551a4e980b9bd233153feb92d6d2c`
- Post-merge gerçek `main` push CI: `34852091173`, exact head SHA `44aa7f9c830551a4e980b9bd233153feb92d6d2c`.
- Post-merge `test`: **SUCCESS**; analyzer `No issues found!`; **324 tests passed**.
- Post-merge canonical attempt 1: M0–M72 adımlarının tamamı, M72 marker ve cleanup SUCCESS; strict `timeout-minutes: 7` envelope sonrasında job conclusion `cancelled`.
- Aynı merge SHA'da yalnız canonical job retry edildi (run attempt 2); M0–M72 adımlarının tamamı, Post Checkout ve Complete job yine SUCCESS; job envelope yine 7 dakika sınırından sonra `cancelled` olarak kapandı.
- İki attempt'te de gerçek canonical failure yoktur; M72 executable gate iki kez PASS'tir. Sonsuz timeout-retry döngüsü üretilmedi.
- M72 canonical marker: `M72_PLAYER_PRESIDENT_UNIFIED_DECISION_GATEWAY_RUNTIME_PASS controlled=t1_01 singleGateway=true managerCalls=1 gatewayCalls=7 singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`
- Post-merge artifacts: **0**.

M72 dosyaları:
- `lib/src/player_president/player_president_unified_decision_gateway_runtime.dart`
- `lib/player_president_unified_decision_gateway_runtime.dart`
- `test/m72_player_president_unified_decision_gateway_runtime_test.dart`
- `tool/run_m72_player_president_unified_decision_gateway_runtime.dart`
- `M72_PLAYER_PRESIDENT_UNIFIED_DECISION_GATEWAY_RUNTIME_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M72 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

- M72 Player President Unified Decision Gateway Runtime I — PR #75 merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c`; 324 tests; M0–M72 executable canonical gates PASS; artifact 0; canonical job envelope iki attempt'te 7 dakika sınırından sonra cancelled.
- M71 Player President Tenure-Gated Facility + Sponsor + Crisis + Manager + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #74 merge `fc373ee6dde881aa9bc730d0930924e7905725c9`; 321 tests; M0–M71 PASS; artifact 0.
- M70 Player President Tenure-Gated Facility + Sponsor + Crisis + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #73 merge `b66512f08240f978286d1b6eaa128bd02ef2cfdb`; 315 tests; M0–M70 PASS; artifact 0.
- M69 Player President Tenure-Gated Facility + Sponsor + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #72 merge `bf94f3e411f30c0d4474067650ab18c491b4f997`; 309 tests; M0–M69 PASS; artifact 0.
- M68 Player President Tenure-Gated Facility + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #71 merge `779a0eb4d5c79b80d5afc743b9a53341bf56fcf2`; 303 tests; M0–M68 PASS; artifact 0.
- M67 Player President Tenure-Gated Promise/Media + Transfer/Ticket Pricing Runtime Composition I — PR #70 merge `9f4f3a3f314de29e770b2031de29c288a7761684`; 298 tests; M0–M67 PASS; artifact 0.
- M66 Player President Tenure-Gated Transfer + Ticket Pricing Runtime Composition I — PR #69 merge `7860ef0e03a4326a884595eeef37d0b088b6e14a`; 293 tests; M0–M66 PASS; artifact 0.
- M65 Player President Tenure-Gated Ticket Pricing Runtime Integration I — PR #68 merge `9e4de0ea84446293155292af39d7e887f6cdab3b`; 288 tests; M0–M65 PASS; artifact 0.
- M64 Player President Tenure-Gated Ticket Pricing Control I — PR #67 merge `4a76d1546fa02675e1c94cd57621a82d70e15a8c`; 283 tests; M0–M64 PASS; artifact 0.
- M63 Player President Tenure-Gated Promise + Media Composition I — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifact 0.
- M62 Player President Tenure-Gated Media Statement Control I — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifact 0.
- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifact 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifact 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 M61+M62 single-domain promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 M64 pricing → real M47/M48 matchday economy runtime integration; M66 M60 transfer strategy + M65 ticket-pricing/economy aynı authoritative checkpoint/tenure state composition; M67 M63 promise/media + M66 transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M68 M49 facility control + M67 promise/media/transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M69 M50 sponsor control + M68 facility/promise/media/transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M70 M51 crisis control + M69 facility/sponsor/promise/media/transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M71 M52 manager control + M70 facility/sponsor/crisis/promise/media/transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M72 M71'in sekiz ayrı runtime provider yüzeyini tek application-facing `PlayerPresidentDecisionGateway` altında adapter ile birleştirir.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response + M64/M65 AI ticket-pricing posture
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M58 persisted tenure ownership state'i sağlar.
- M59 M49–M52 nested decision stack'ini gerçek incumbent ownership ile yetkilendirir.
- M60 M55 transfer-strategy kontrolünü gerçek incumbent ownership ile yetkilendirir.
- M61 M56 promise kontrolünü gerçek incumbent ownership ile yetkilendirir.
- M62 M57 media statement stance kontrolünü gerçek incumbent ownership ile yetkilendirir.
- M63 promise + media kararlarını aynı president-domain checkpoint/save akışında compose eder.
- M64 tenure-gated ticket-pricing kararını üretir.
- M65 bu kararı gerçek matchday revenue multiplier ve `ClubFinanceSeason.matchdayRevenue` akışına compose eder.
- M66 M60 transfer-strategy bridge'ini M65'in gerçek runtime/checkpoint/save akışına aynı tenure ownership state ile compose eder.
- M67 M63 promise/media player kararlarını M66 transfer/ticket gerçek runtime'ına aynı authoritative M65 checkpoint ve persisted tenure state üzerinde compose eder.
- M68 M49 facility investment player kararını M67'nin authoritative M65 checkpoint akışına aynı persisted tenure state üzerinde compose eder.
- M69 M50 sponsor player kararını M68'in authoritative M65 checkpoint akışına aynı persisted tenure state üzerinde compose eder.
- M70 M51 crisis player kararını M69'un authoritative M65 checkpoint akışına aynı persisted tenure state üzerinde compose eder ve gerçek crisis continuation state'ine yazar.
- M71 M52 manager player kararını M70'ın authoritative M65 checkpoint akışına ekler; böylece M49–M52 + M60–M64 player-president karar alanlarının bilinen runtime birleşimi tamamlanır.
- M72 bu sekiz domain için yeni game-state üretmez; application/UI entegrasyonu için tek runtime gateway sağlar ve M65 save authority'sini korur.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` executable gates doğrulanmadan milestone'u CLOSED sayma.
9. Docs-only merge-ready/kapanış commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
10. M72 kapanışından sonra otomatik M73 açma; önce canlı `main` üzerinde ürün/UI/simulation/architecture gap scan yap.