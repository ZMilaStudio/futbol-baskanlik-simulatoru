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

**M0–M65 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M66 — Player President Tenure-Gated Transfer + Ticket Pricing Runtime Composition I.**

M66 canlı durum:
- Branch: `feat/m66-transfer-ticket-pricing-runtime-composition`
- PR #69 — **OPEN / NOT MERGED**
- Base `main`: `9bd9553839cf9295e3049f120e41b5eb15387151`
- İlk tam-yeşil branch HEAD: `cd49e779f1e67ae3cde2a5df00a6e1e5e2b2b1d6`
- PR CI `34778364485`: **SUCCESS**
- analyzer: `No issues found!`
- **293/293 normal/non-canonical test PASS**
- beş M66 acceptance testinin tamamı PASS
- **M0–M66 canonical PASS**
- canonical marker: `M66_PLAYER_PRESIDENT_TENURE_GATED_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS controlled=t1_01 m65ParityWithoutTransfer=true bothProviders=true singleCheckpoint=true lostBlocksBoth=true saveResume=true worldClubs=48 seed=20260903`
- artifacts: **0**
- geçici `M66_IMPLEMENTATION_STATUS.md` dosyası merge öncesi kaldırıldı.

Bu merge-ready özet commit'i final PR HEAD'ini değiştirecektir. Yeni exact HEAD üzerinde analyzer + 293 test + M0–M66 canonical + M66 marker + artifact=0 bir kez daha doğrulanacaktır. Sonucu sırf özete yazmak için ikinci docs commit atılmayacaktır.

M66 seçim gerekçesi: M65 kapanışı sonrası canlı `main` taramasında M59, M63 ve M65'in ayrı checkpoint/save/tenure-state adaları taşıdığı; M60'ın ise checkpoint oluşturmadan `WorldCareerEngine.transferMarketEngine` seam'ine bağlanan bir bridge olduğu doğrulandı. Tüm player-president yüzeylerini tek milestone'da yeniden yazmak yerine M66, M60 transfer stratejisini M65'in authoritative gerçek ekonomi runtime'ına aynı sezon ve aynı persisted tenure state üzerinde compose eden düşük-riskli ilk üst-seviye birleşim adımıdır.

M66 çözümü:
- yeni checkpoint veya save codec oluşturulmaz;
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` authoritative kalır;
- M66 M65 runtime'ını birer sezonluk authoritative segmentler halinde ilerletir;
- her sezon başında gerçek incumbent management profile map'i mevcut M65 checkpoint'inden alınır;
- M60 `PlayerPresidentTenureGatedTransferStrategyWorldBridge`, M65 checkpoint'indeki aynı `PlayerPresidentTenureControlState` ile gerçek transfer-market seam'ine kurulur;
- ticket-pricing provider M65'in gerçek economy seam'inde çalışmaya devam eder;
- transfer provider yoksa M66 exact M65 checkpoint + boundary parity üretir;
- persisted `lost` tenure state veya incumbent identity mismatch hem transfer hem ticket provider'ını bloklar;
- provider callback'leri runtime-only kalır;
- M65 save codec ile save/load/resume determinism korunur.

M66 acceptance:
1. transfer provider yokken exact M65 checkpoint + boundary parity — PASS;
2. active incumbent aynı gerçek sezonda transfer + ticket provider delegation — PASS;
3. ticket pricing gerçek `ClubFinanceSeason.matchdayRevenue` etkisini korur — PASS;
4. tek persisted lost tenure state iki external provider'ı da bloklar — PASS;
5. successor mismatch iki provider'ı bloklar ve sticky loss üretir — PASS;
6. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run — PASS.

M66 dosyaları:
- `lib/src/facility/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart`
- `lib/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart`
- `test/m66_player_president_tenure_gated_transfer_ticket_pricing_runtime_composition_test.dart`
- `tool/run_m66_player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart`
- `M66_PLAYER_PRESIDENT_TENURE_GATED_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M66 **CODE + FIRST CI PASS / FINAL EXACT-HEAD CI BEKLENİYOR / NOT MERGED**.

## 3. Son kapanan milestone: M65 — Player President Tenure-Gated Ticket Pricing Runtime Integration I

M65, M64 ticket-pricing kararını gerçek M47/M48 season economy path'ine bağladı. Balanced politika exact M48 parity üretirken aktif oyuncu başkanın fiyat seçimi gerçek `ClubFinanceSeason.matchdayRevenue` ve kapanış nakdını etkiler; tenure ownership, 47 AI kulüp parity'si ve save/resume determinism korunur.

Kapanış kanıtı:
- PR #68 — **MERGED / CLOSED**
- Squash merge SHA: `9e4de0ea84446293155292af39d7e887f6cdab3b`
- Post-merge `main` CI `34777266793`: **SUCCESS**
- Docs close commit: `9bd9553839cf9295e3049f120e41b5eb15387151`
- docs-only close CI `34777657555`: **SUCCESS**
- analyzer clean; **288 tests PASS**; **M0–M65 canonical PASS**; artifacts 0.

M65 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

- M65 Player President Tenure-Gated Ticket Pricing Runtime Integration I — PR #68 merge `9e4de0ea84446293155292af39d7e887f6cdab3b`; 288 tests; M0–M65 PASS; artifact 0.
- M64 Player President Tenure-Gated Ticket Pricing Control I — PR #67 merge `4a76d1546fa02675e1c94cd57621a82d70e15a8c`; 283 tests; M0–M64 PASS; artifact 0.
- M63 Player President Tenure-Gated Promise + Media Composition I — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifact 0.
- M62 Player President Tenure-Gated Media Statement Control I — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifact 0.
- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifact 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifact 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifact 0.
- M58 Player President Tenure Control Gate Core I — PR #61 merge `fe102d25ff53f598bf5d695f95131e580a7c4523`; 253 tests; M0–M58 PASS; artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 M61+M62 single-domain promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 M64 pricing → real M47/M48 matchday economy runtime integration; M66 M60 transfer strategy + M65 ticket-pricing/economy aynı authoritative checkpoint/tenure state composition.

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
- M59 nested facility/sponsor/crisis/manager control stack'i ve M63 promise/media composition hâlâ M66/M65 authoritative checkpoint altında birleşmemiştir; sıradaki üst-seviye entegrasyon boşluğu buradadır.

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
