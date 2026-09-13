# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 13 Eylül 2026

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
- Merge sonrası `main` CI yeşil olmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M66 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M67 — Player President Tenure-Gated Promise/Media + Transfer/Ticket Pricing Runtime Composition I.**

M67 canlı durum:
- Branch: `feat/m67-promise-media-transfer-ticket-runtime-composition`
- PR #70 — **OPEN / NOT MERGED**
- Base `main`: `5c26628d729fe1b6605255026640cb7d67a66ad6`
- İlk tam-yeşil branch HEAD: `9edb8f8b8489a002591d1e322dd014a25d1a6b49`
- İlk tam-yeşil PR CI `34781844732`: **SUCCESS**
- analyzer: `No issues found!`
- **298/298 normal/non-canonical test PASS**
- beş M67 acceptance testinin tamamı PASS
- **M0–M67 canonical PASS**
- canonical marker: `M67_PLAYER_PRESIDENT_TENURE_GATED_PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS controlled=t1_01 m66ParityWithoutPromiseMedia=true fourProviders=true singleCheckpoint=true lostBlocksAll=true saveResume=true worldClubs=48 seed=20260903`
- artifacts: **0**

Bu merge-ready özet commit'i final PR HEAD'ini değiştirecektir. Yeni exact HEAD üzerinde analyzer + 298 test + M0–M67 canonical + M67 marker + artifact=0 bir kez daha doğrulanacaktır. Sonucu sırf özete yazmak için ikinci docs commit atılmayacaktır.

M67 seçim gerekçesi: M66 kapanışı sonrası canlı `main` taramasında M59 nested facility/sponsor/crisis/manager kontrol zinciri ile M63 promise/media composition'ın M66/M65 authoritative checkpoint altında hâlâ ayrı kaldığı doğrulandı. M59 daha fazla boundary/checkpoint uyarlaması gerektirirken M47/M65 hattında zaten `PresidentDomainCareerEngine` üzerinden promise/media source seam'i bulunduğundan, en düşük riskli sıradaki birleşim M63 promise/media kararlarını M66 transfer+ticket gerçek ekonomi runtime'ına taşımaktır.

M67 çözümü:
- yeni checkpoint veya save codec oluşturulmaz;
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` authoritative kalır;
- M47 `FacilitySponsorCrisisRuntimeCareerEngine` canonical default'u koruyan opsiyonel `PromiseMediaCareerEngine` source enjeksiyon seam'i alır;
- M65 bu source engine'i M47 gerçek runtime'ına taşır;
- M67 her sezon authoritative checkpoint'ten gerçek incumbent management profile map'ini ve persisted tenure state'i okur;
- M60 transfer bridge aynı tenure state ile gerçek transfer-market seam'inde çalışır;
- M65 ticket-pricing provider aynı tenure state ile gerçek matchday economy seam'inde çalışır;
- M56 promise generator + M57 media statement engine aynı kontrollü kulüp için aynı gerçek sezon source report'una compose edilir;
- promise/media delegation yalnız tenure aktifken ve gerçek incumbent profile ID captured player-president ID ile eşleşirken açılır;
- persisted `lost` state veya incumbent identity mismatch promise + media + transfer + ticket provider'larının tamamını bloklar;
- provider callback'leri runtime-only kalır;
- M65 save codec ile save/load/resume determinism korunur.

M67 acceptance:
1. promise/media provider yokken exact M66 checkpoint + boundary parity — PASS;
2. active incumbent aynı gerçek sezonda promise + media + transfer + ticket provider delegation — PASS;
3. media event ID/topic metadata canonical kalırken stance değişebilir ve ticket pricing gerçek `ClubFinanceSeason.matchdayRevenue` etkisini korur — PASS;
4. tek persisted lost tenure state dört external provider'ı da bloklar — PASS;
5. incumbent identity mismatch dört provider'ı bloklar ve sticky loss üretir — PASS;
6. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run — PASS.

M67 dosyaları:
- `lib/src/crisis/facility_sponsor_crisis_runtime_composition.dart`
- `lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart`
- `lib/src/facility/player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `lib/player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `test/m67_player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition_test.dart`
- `tool/run_m67_player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `M67_PLAYER_PRESIDENT_TENURE_GATED_PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M67 **CODE + FIRST CI PASS / FINAL EXACT-HEAD CI BEKLENİYOR / NOT MERGED**.

## 3. Son kapanan milestone: M66 — Player President Tenure-Gated Transfer + Ticket Pricing Runtime Composition I

M66, M60 tenure-gated transfer-strategy bridge'ini M65'in gerçek ticket-pricing/economy runtime'ına yeni bir checkpoint/save adası oluşturmadan bağladı. Transfer ve ticket kararları aynı authoritative M65 checkpoint, aynı persisted `PlayerPresidentTenureControlState` ve aynı gerçek sezon akışı üzerinde çalışır; kontrol kaybı veya incumbent mismatch iki provider'ı da aynı anda bloklar. No-transfer exact M65 parity ve save/resume determinism korunur.

Kapanış kanıtı:
- PR #69 — **MERGED / CLOSED**
- Squash merge SHA: `7860ef0e03a4326a884595eeef37d0b088b6e14a`
- Post-merge `main` CI `34779120175`: **SUCCESS**
- analyzer clean; **293 tests PASS**; **M0–M66 canonical PASS**; artifacts 0.

M66 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

- M66 Player President Tenure-Gated Transfer + Ticket Pricing Runtime Composition I — PR #69 merge `7860ef0e03a4326a884595eeef37d0b088b6e14a`; 293 tests; M0–M66 PASS; artifact 0.
- M65 Player President Tenure-Gated Ticket Pricing Runtime Integration I — PR #68 merge `9e4de0ea84446293155292af39d7e887f6cdab3b`; 288 tests; M0–M65 PASS; artifact 0.
- M64 Player President Tenure-Gated Ticket Pricing Control I — PR #67 merge `4a76d1546fa02675e1c94cd57621a82d70e15a8c`; 283 tests; M0–M64 PASS; artifact 0.
- M63 Player President Tenure-Gated Promise + Media Composition I — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifact 0.
- M62 Player President Tenure-Gated Media Statement Control I — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifact 0.
- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifact 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifact 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifact 0.
- M58 Player President Tenure Control Gate Core I — PR #61 merge `fe102d25ff53f598bf5d695f95131e580a7c4523`; 253 tests; M0–M58 PASS; artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 M61+M62 single-domain promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 M64 pricing → real M47/M48 matchday economy runtime integration; M66 M60 transfer strategy + M65 ticket-pricing/economy aynı authoritative checkpoint/tenure state composition; M67 M63 promise/media + M66 transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition.

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
- M59 nested facility/sponsor/crisis/manager control stack'i M67/M65 authoritative checkpoint altında hâlâ birleşmemiştir; sıradaki üst-seviye entegrasyon boşluğu burada kalır.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
9. Docs-only merge-ready/kapanış commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
