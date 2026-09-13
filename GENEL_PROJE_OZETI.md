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

**M0–M64 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M65 — Player President Tenure-Gated Ticket Pricing Runtime Integration I.**

M65 canlı durum:
- Branch: `feat/m65-ticket-pricing-economy-runtime-integration`
- PR #68 — **OPEN / NOT MERGED / MERGEABLE**
- Base `main`: `b0f38ec4d0c02243991fc250aa235381f605d6e2`
- Son non-summary branch HEAD: `1d74d504130d4fa6f82dce4cb0065448514cb3a3`
- Verified pre-merge-ready summary HEAD: `60713b1f94ba93ceb99a9557bedc9a5eb98d5522`
- PR CI `34770188103`: **SUCCESS**
- analyzer: `No issues found!`
- **288/288 normal/non-canonical test PASS**
- beş M65 acceptance testinin tamamı PASS
- **M0–M65 canonical PASS**
- canonical marker: `M65_PLAYER_PRESIDENT_TENURE_GATED_TICKET_PRICING_RUNTIME_INTEGRATION_PASS controlled=t1_01 aiParity=47 balancedM48Parity=true realEconomy=true activeDelegation=true bounded=true saveResume=true deterministic=true worldClubs=48 seed=20260903`
- artifacts: **0**

Bu merge-ready özet commit'i final PR HEAD'ini değiştirecektir. Yeni exact HEAD üzerinde analyzer + 288 test + M0–M65 canonical + M65 marker + artifact=0 bir kez daha doğrulanacaktır. Sonucu sırf özete yazmak için ikinci docs commit atılmayacaktır.

M65 seçim gerekçesi: M64 kapanışı sonrası canlı `main` taramasında M64 pricing outcome'unun hesaplandığı ancak M47/M48 gerçek `ClubFinanceSeason.matchdayRevenue` satırına compose edilmediği doğrulandı. M47'nin authoritative stadium + fan-trust multiplier'ı `BasicEconomyEngine.matchdayRevenueMultiplierBpsByClub` seam'inden geçtiği için M65 bu mevcut seam'i kullandı; kapalı M47/M48 kaynak kodu değiştirilmedi.

M65 çözümü:
- M47/M48 runtime zincirine custom `baseWorldEngine.economyEngine` enjekte edilir;
- M47'nin gönderdiği M40/M41 stadium+fan multiplier aynı authoritative attendance modeliyle doğrulanır;
- yalnız matchday revenue multiplier M64 pricing outcome ile değiştirilir;
- gerçek `ClubFinanceSeason.matchdayRevenue`, closing cash ve mevcut economy etkileri doğal olarak bu sonuçtan beslenir;
- sponsor, crisis, facility investment, election, fan/media ve world akışları mevcut runtime zincirinde kalır;
- M48 facility yatırımları sonraki sezon stadium level pricing context'ine doğal olarak girer;
- M58 tenure ownership state M65 checkpoint'inde persist edilir ve her tamamlanan sezondan sonra gerçek incumbent identity ile refresh edilir;
- player provider runtime-only kalır;
- successor mismatch ve persisted `lost` state provider'ı bloklar;
- diğer 47 kulüp exact AI ticket-pricing/finance path'inde kalır;
- forced `balanced` policy exact M48 runtime parity üretir.

M65 acceptance:
1. forced-balanced pricing exact M48 runtime parity — PASS;
2. premium player pricing gerçek matchday finance row etkisi + bounded multiplier — PASS;
3. active incumbent controlled club override + diğer 47 exact AI finance parity — PASS;
4. successor mismatch + persisted lost tenure provider bloklama — PASS;
5. save round-trip + 2+2 resume == uninterrupted 4-season deterministic run — PASS.

M65 dosyaları:
- `lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart`
- `lib/player_president_tenure_gated_ticket_pricing_runtime_integration.dart`
- `test/m65_player_president_tenure_gated_ticket_pricing_runtime_integration_test.dart`
- `tool/run_m65_player_president_tenure_gated_ticket_pricing_runtime_integration.dart`
- `M65_PLAYER_PRESIDENT_TENURE_GATED_TICKET_PRICING_RUNTIME_INTEGRATION_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M65 **CODE + CI PASS / FINAL EXACT-HEAD CI BEKLENİYOR / NOT MERGED**.

## 3. Son kapanan milestone: M64 — Player President Tenure-Gated Ticket Pricing Control I

M64, M40/M41 stadyum + fan-trust attendance modelinin sabit ticket-yield davranışına, kulüp başkanı rolüne uygun tenure-gated maç günü bilet fiyatlandırma karar yüzeyi ekledi.

Kapanış kanıtı:
- PR #67 — **MERGED / CLOSED**
- Squash merge SHA: `4a76d1546fa02675e1c94cd57621a82d70e15a8c`
- Post-merge `main` CI `34768517130`: **SUCCESS**
- Docs close commit: `b0f38ec4d0c02243991fc250aa235381f605d6e2`
- docs-only close CI `34768940183`: **SUCCESS**
- analyzer clean; **283 tests PASS**; **M0–M64 canonical PASS**; artifacts 0.

M64 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

- M64 Player President Tenure-Gated Ticket Pricing Control I — PR #67 merge `4a76d1546fa02675e1c94cd57621a82d70e15a8c`; 283 tests; M0–M64 PASS; artifact 0.
- M63 Player President Tenure-Gated Promise + Media Composition I — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifact 0.
- M62 Player President Tenure-Gated Media Statement Control I — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifact 0.
- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifact 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifact 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifact 0.
- M58 Player President Tenure Control Gate Core I — PR #61 merge `fe102d25ff53f598bf5d695f95131e580a7c4523`; 253 tests; M0–M58 PASS; artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 M61+M62 single-domain promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 M64 pricing → real M47/M48 matchday economy runtime integration.

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
- M59, M60, M63 ve M65 henüz tek üst-level player-president kariyer checkpoint altında birleşmemiştir.

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
