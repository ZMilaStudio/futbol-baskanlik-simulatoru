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
- Merge sonrası `main` CI yeşil olmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M68 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M69 — Player President Tenure-Gated Facility + Sponsor + Promise/Media + Transfer/Ticket Pricing Runtime Composition I — MERGE READY / NOT MERGED.**

M69 canlı durum:
- PR #72 — **OPEN / NOT MERGED / mergeable=true**
- Branch: `feat/m69-sponsor-unified-player-president-runtime`
- Base `main`: `642d08f4de4af2e48012d03a32c3977c2ca716be`
- Doğrulanmış code-bearing commit: `c7bff604ad43affacef97b275e1e36ce80b530ab`
- Merge-ready docs öncesi exact PR HEAD: `555085091fa1cb1e2db58373532555d7bbc28b22`
- Exact-head PR CI `34787267876`: **SUCCESS**
- analyzer: `No issues found!`
- **309/309 normal/non-canonical test PASS**
- altı M69 acceptance testinin tamamı PASS
- **M0–M69 canonical PASS**
- canonical marker: `M69_PLAYER_PRESIDENT_TENURE_GATED_FACILITY_SPONSOR_PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS controlled=t1_01 m68ParityWithoutSponsor=true sixProviders=true sponsorChanged=true aiParity=47 lostBlocksSponsor=true singleCheckpoint=true saveResume=true worldClubs=48 seed=20260903`
- artifacts: **0**

M69 seçim gerekçesi: M68 kapanışı sonrası canlı `main` taramasında M59'un sponsor/crisis/manager player-control parçalarının M68/M65 authoritative checkpoint altında hâlâ ayrı olduğu doğrulandı. Sponsor tarafında M47 zaten public `SponsorSystemEngine` injection seam'ine sahip olduğu ve M50 kontrollü kulüp sponsor semantiğini sağlam biçimde tanımladığı için, crisis/manager'a göre en düşük riskli sıradaki birleşim sponsor olarak seçildi.

M69 çözümü:
- yeni checkpoint veya save codec oluşturulmadı;
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` authoritative kaldı;
- M50 sponsor player-control motoru reusable yapıldı; mevcut davranışı korunur;
- M65/M68'e default-neutral `SponsorSystemEngine` injection seam'i eklendi;
- sponsor + facility + promise + media + transfer strategy + ticket pricing aynı persisted tenure ownership state üzerinde compose edilir;
- controlled club sponsor kararı yalnız persisted tenure aktifken ve gerçek incumbent profile ID captured player-president ID ile eşleşirken oyuncuya delege edilir;
- persisted loss veya incumbent mismatch sponsor tarafını canonical AI sponsor yoluna düşürür;
- aktif çok yıllı sponsor kontratı yeniden seçilmez / bozulmaz;
- diğer 47 kulübün sponsor kararları exact canonical AI parity'de kalır;
- bütün provider callback'leri runtime-only kalır;
- crisis ve manager player-control birleşimi M69 kapsamı dışındadır.

M69 acceptance:
1. sponsor provider yokken exact M68 checkpoint + boundary parity — PASS;
2. altı provider aynı gerçek sezon boundary'sinde çalışır — PASS;
3. sponsor override yalnız controlled club'u değiştirirken diğer 47 kulübün exact AI sponsor parity'si korunur — PASS;
4. aktif multi-year sponsor kontratı yeniden seçilmez — PASS;
5. persisted loss ve incumbent mismatch sponsor kontrolünü bloklar; mismatch sticky loss üretir — PASS;
6. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run — PASS.

M69 dosyaları:
- `lib/src/facility/player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `lib/player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `test/m69_player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition_test.dart`
- `tool/run_m69_player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `M69_PLAYER_PRESIDENT_TENURE_GATED_FACILITY_SPONSOR_PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

**M69 henüz merge edilmemiştir.** Merge için PR #72'ye özel açık kullanıcı onayı gerekir. Merge sonrası `main` CI yeşil olmadan CLOSED yazılmaz.

## 3. Son kapanan milestone: M68 — Player President Tenure-Gated Facility + Promise/Media + Transfer/Ticket Pricing Runtime Composition I

M68, M49 facility player-president yatırım kontrolünü M67'nin promise/media/transfer/ticket gerçek runtime'ına yeni checkpoint/save adası oluşturmadan bağladı. Facility, promise, media, transfer ve ticket kararları aynı authoritative M65 checkpoint ve aynı persisted `PlayerPresidentTenureControlState` üzerinde çalışır.

Kapanış kanıtı:
- PR #71 — **MERGED / CLOSED**
- Final pre-merge PR HEAD: `c46e33e628bf894b102a7a02fd13e8d4d0c87769`
- Final exact-head PR CI `34784696380`: **SUCCESS**
- Squash merge SHA: `779a0eb4d5c79b80d5afc743b9a53341bf56fcf2`
- Post-merge `main` CI `34785306302`: **SUCCESS**
- analyzer clean; **303 tests PASS**; **M0–M68 canonical PASS**; artifacts 0.

M68 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

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

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate; M63 M61+M62 single-domain promise/media composition; M64 tenure-gated matchday ticket pricing decision core; M65 M64 pricing → real M47/M48 matchday economy runtime integration; M66 M60 transfer strategy + M65 ticket-pricing/economy aynı authoritative checkpoint/tenure state composition; M67 M63 promise/media + M66 transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M68 M49 facility control + M67 promise/media/transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition; M69 M50 sponsor control + M68 facility/promise/media/transfer/ticket aynı authoritative M65 checkpoint/tenure state/gerçek sezon composition.

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
- M59'un crisis ve manager player-control parçaları M69/M65 authoritative checkpoint altında hâlâ birleşmemiştir; sıradaki gerçek entegrasyon boşluğu canlı `main` üzerinden yeniden doğrulanmalıdır.

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
