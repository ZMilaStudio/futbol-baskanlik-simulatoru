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

**M0–M63 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M64 — Player President Tenure-Gated Ticket Pricing Control I.**

M64 canlı durum:
- Branch: `feat/m64-player-president-tenure-gated-ticket-pricing-control`
- Base `main`: `e1c849eaeae02a988c7858ffbf3c64b751b4ffd0`
- Code-bearing HEAD before this summary refresh: `db09b3d58ca912e161d7746a02d517d12658bb7b`
- PR: henüz açılmadı
- CI: henüz canlı PR üzerinde doğrulanmadı

M64 seçim gerekçesi: M63 kapanışı sonrası canlı `main` taramasında M40/M41 stadyum + fan-trust attendance modelinin gerçek maç günü talep/gelir etkisi ürettiği, ancak `StadiumInvestmentPolicy.ticketYieldBpsForLevel` değerinin yalnız stadyum seviyesine sabit olduğu ve oyuncu-başkan için ticari bilet fiyatlandırma karar yüzeyi bulunmadığı doğrulandı. Bu doğrudan kulüp başkanı yetkisidir; teknik direktör/taktik alanına girmez.

M64 çözümü:
- üç canonical fiyat seviyesi: `supporterFriendly`, `balanced`, `premium`;
- `balanced` seçimi mevcut M40/M41 demand + attendance + occupancy + ticket yield + revenue multiplier semantiğini birebir korur;
- supporter-friendly daha düşük yield / daha yüksek talep, premium daha yüksek yield / daha düşük talep üretir;
- etkiler bounded kalır;
- AI fiyat politikası mevcut `PresidentManagementProfile.financialDiscipline`, fan trust ve baz doluluk bağlamını kullanır;
- player provider yalnız controlled club + M58 tenure state aktif + gerçek president id captured player-president id ile eşleşiyorsa çalışır;
- successor mismatch ve persisted `lost` state provider'ı bloklar;
- diğer 47 kulüp exact AI pricing path'te kalır;
- core katman world/finance/fan/stadium/president state mutate etmez; provider runtime-only kalır.

M64 acceptance hedefleri:
1. balanced pricing exact M40/M41 parity;
2. supporter-friendly/premium bounded demand-yield elasticity;
3. AI pricing fan trust + occupancy + financial discipline bağlamına deterministik tepki;
4. active incumbent controlled club override + diğer 47 AI parity;
5. successor mismatch + persisted lost tenure provider bloklama ve determinism.

Bilinçli kapsam dışı:
- ticket pricing'in gerçek season economy row'una yazılması;
- maç/derbi/kupa bazlı dinamik fiyatlama;
- M59 + M63 tek üst-level checkpoint composition;
- M60 transfer-strategy composition.

M64 dosyaları:
- `lib/src/facility/player_president_tenure_gated_ticket_pricing_control.dart`
- `lib/player_president_tenure_gated_ticket_pricing_control.dart`
- `test/m64_player_president_tenure_gated_ticket_pricing_control_test.dart`
- `tool/run_m64_player_president_tenure_gated_ticket_pricing_control.dart`
- `M64_PLAYER_PRESIDENT_TENURE_GATED_TICKET_PRICING_CONTROL_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M64 **IMPLEMENTED / LIVE CI BEKLENİYOR / NOT MERGED**.

## 3. Son kapanan milestone: M63 — Player President Tenure-Gated Promise + Media Composition I

M63, M61 promise ve M62 media-statement player-president kontrollerini tek authoritative president-domain checkpoint/save akışında ve tek M58 tenure ownership state altında compose etti.

Kapanış kanıtı:
- PR #66 — MERGED / CLOSED
- Code-bearing HEAD: `99006dfcb88f76701d8b25780db897dc57b9e9ac`
- Code-bearing PR CI `34764229332`: SUCCESS
- Final exact PR HEAD: `da685282ba96245c2939a9c09bf5c68d4cce6f9f`
- Final exact-head PR CI `34764581816`: SUCCESS
- Squash merge SHA: `72f5387fe416746244eb41cbc6aaaaf179f9442f`
- Post-merge `main` CI `34765651874`: SUCCESS
- Docs close commit: `e1c849eaeae02a988c7858ffbf3c64b751b4ffd0`
- docs-only close CI `34765965394`: SUCCESS
- analyzer clean; **278 tests PASS**; **M0–M63 canonical PASS**; artifacts 0.

Davranış:
- promise + media seçimleri aynı real president-domain sezon akışını paylaşır;
- iki provider yalnız gerçek incumbent player-president aktifken çalışır;
- turnover sonrası iki yüzey aynı anda exact AI path'e döner;
- reelection iki kontrolü de sürdürür;
- persisted loss sticky kalır;
- promise target ve media statement event metadata canonical kalır;
- diğer 47 kulüp exact AI parity'de kalır;
- provider callback'ler runtime-only kalır ve save/resume determinism korunur.

M63 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

- M63 Player President Tenure-Gated Promise + Media Composition I — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifact 0.
- M62 Player President Tenure-Gated Media Statement Control I — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifact 0.
- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifact 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifact 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifact 0.
- M58 Player President Tenure Control Gate Core I — PR #61 merge `fe102d25ff53f598bf5d695f95131e580a7c4523`; 253 tests; M0–M58 PASS; artifact 0.
- M57 Player President Media Statement Decision Override I — PR #60 merge `af5d7c12597ad4a68f2b75251a3c9e70fb09a590`; 248 tests; M0–M57 PASS; artifact 0.
- M56 Player President Promise Decision Override I — PR #59 merge `c61ef1338cc0ab7cfb993827e46bec62524cf308`; 243 tests; M0–M56 PASS; artifact 0.
- M55 Player President Transfer Strategy Decision Override I — PR #58 merge `f4034bf35e11d52dc97d2d5a39abaed6672bbc7c`; 238 tests; M0–M55 PASS; artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 M61+M62 single-domain promise/media composition; M64 tenure-gated matchday ticket pricing decision core.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response + M64 AI ticket-pricing posture
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M58 persisted tenure ownership state'i sağlar.
- M59 M49–M52 nested decision stack'ini gerçek incumbent ownership ile yetkilendirir.
- M60 M55 transfer-strategy kontrolünü gerçek incumbent ownership ile yetkilendirir.
- M61 M56 promise kontrolünü gerçek incumbent ownership ile yetkilendirir.
- M62 M57 media statement stance kontrolünü gerçek incumbent ownership ile yetkilendirir.
- M63 promise + media kararlarını aynı president-domain checkpoint/save akışında compose eder.
- M64 M40/M41 attendance çıktısı üzerinde, tenure-gated ve state-mutating olmayan başkan bilet fiyatlandırma karar yüzeyi ekler.
- M59 ve M63 ile tek üst-level player-president kariyer composition henüz tamamlanmamıştır; M60 da bu composition dışında kalır.

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
