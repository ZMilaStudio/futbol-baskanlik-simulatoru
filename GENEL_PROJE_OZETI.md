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

**M0–M61 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M62 — Player President Tenure-Gated Media Statement Control I.**

M62 canlı durum:
- Branch: `feat/m62-player-president-tenure-gated-media-statement-control`
- PR #65 — **OPEN / NOT MERGED**
- Base `main`: `ac5fb3a9e2407181a23645b4ee519f816726ea61`
- Verified code-bearing HEAD: `be92d96a18bbc70a333e9f779506f479129e05b2`
- Code-bearing PR CI `34759395413`: **SUCCESS**
- analyzer: `No issues found!`
- **273/273 normal/non-canonical test PASS**
- beş M62 acceptance testinin tamamı PASS
- **M0–M62 canonical PASS**
- canonical marker: `M62_PLAYER_PRESIDENT_TENURE_GATED_MEDIA_STATEMENT_CONTROL_PASS controlled=t1_01 aiParity=47 activeDelegation=true turnoverStopsControl=true reelectionKeepsControl=true stickyLoss=true deterministic=true worldClubs=48`
- artifacts: **0**

M62 seçim gerekçesi: canlı M61 sonrası taramada M57 media statement override'ın yalnız `controlledClubId` + runtime provider varlığıyla yetkilendirildiği ve gerçek incumbent president identity/tenure durumunu bilmediği doğrulandı. M58 persisted player-president identity ve gerçek election turnover sonrası sticky `lost` state sağlıyor. Media statement olayları sezon içinde, election sezon sonunda işlendiği ve turnover sonraki sezon itibarıyla etkili olduğu için M57'yi sezon-sezon M58 gate'iyle bağlamak canonical event üretimini post-hoc değiştirmeden güvenli bir seam oluşturuyor.

M62 çözümü:
- M10/M57 canonical media event generation aynen korunur; player yeni statement event yaratamaz;
- player yalnız gerçek M10 event'inin mevcut `MediaStance` seçeneklerinden birini seçebilir;
- statement existence, id, club, target manager, season ve topic canonical kalır;
- seçilen stance mevcut M10 credibility resolution üzerinden normal biçimde işlenir;
- president-domain runtime birer sezonluk segmentlerle ilerletilir;
- active incumbent sırasında controlled club external media provider'a delege edilir;
- sezon sonu election sonrası M58 gate refresh edilir; gerçek turnover varsa successor'ın ilk sezonundan itibaren provider çağrılmaz;
- blocked/lost durumda aynı M57 engine provider=null ile exact AI media path'e döner;
- reelection aynı incumbent identity'yi koruduğu için player media control devam eder;
- persisted `lost` state sticky kalır ve save/load sonrası reaktive olmaz;
- diğer 47 kulübün media snapshot'ları exact AI parity'de kalır;
- yeni save envelope yalnız president-domain checkpoint + M58 tenure-control state saklar; provider callback runtime-only kalır.

Acceptance:
1. active incumbent gerçek statement stance seçimini uygular, event metadata korunur ve diğer 47 kulüp exact AI parity'de kalır — PASS;
2. gerçek election turnover successor'ın ilk sezonunda provider'ı bloklar ve exact AI president-domain path'ini korur — PASS;
3. reelection player media control'ü sonraki dönemde aktif tutar — PASS;
4. persisted lost tenure save/load sonrası provider'ı yeniden aktive etmez — PASS;
5. runtime-only provider yeniden kurularak split save/resume direct run ile deterministik kalır — PASS.

M62 dosyaları:
- `lib/src/media/player_president_tenure_gated_media_statement_control.dart`
- `lib/player_president_tenure_gated_media_statement_control.dart`
- `test/m62_player_president_tenure_gated_media_statement_control_test.dart`
- `tool/run_m62_player_president_tenure_gated_media_statement_control.dart`
- `M62_PLAYER_PRESIDENT_TENURE_GATED_MEDIA_STATEMENT_CONTROL_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

Bu merge-ready docs refresh'i final PR HEAD'ini değiştirecektir. Bu commit'ten sonra branch'e yeni commit atılmayacak; yeni exact HEAD üzerinde analyzer + 273 test + M0–M62 canonical + M62 marker + artifact=0 ve `mergeable=true` yeniden doğrulanacaktır. Sonucu sırf özete yazmak için ikinci docs commit atılmayacaktır.

M62 **CODE-BEARING PASS / FINAL EXACT-HEAD CI BEKLENİYOR / NOT MERGED**.

## 3. Son kapanan milestone: M61 — Player President Tenure-Gated Promise Control I

M61, M56 player-president promise override'ını M58 persisted incumbent-president ownership state'iyle yetkilendirdi.

Kapanış kanıtı:
- Branch: `feat/m61-player-president-tenure-gated-promise-control`
- PR #64 — MERGED / CLOSED
- Final exact PR HEAD: `b58d8c2b73d4eb0787348eda567e2adda1862d2a`
- Final exact-head PR CI `34755745646`: SUCCESS
- Squash merge SHA: `0a00895a185e4dc2b8a97485767be888a8bfde85`
- Post-merge `main` CI `34758193189`: SUCCESS
- Docs close commit: `ac5fb3a9e2407181a23645b4ee519f816726ea61`
- Docs CI `34758492972`: SUCCESS
- analyzer clean; **268 tests PASS**; **M0–M61 canonical PASS**; artifacts 0.

Davranış:
- active incumbent sırasında controlled club player promise provider'ına delege edilir;
- player yalnız mevcut canonical promise tiplerinden context-valid seçim yapar, target'lar canonical generation tarafından korunur;
- gerçek successor identity sonrası player provider çağrılmaz ve exact AI promise path korunur;
- reelection player control'ü sürdürür;
- persisted `lost` state save/load sonrası sticky kalır ve reaktive olmaz;
- diğer 47 kulüp exact AI parity'de kalır;
- provider callback runtime-only kalır.

M61 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

- M61 Player President Tenure-Gated Promise Control I — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifact 0.
- M60 Player President Tenure-Gated Transfer Strategy Control I — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifact 0.
- M59 Player President Tenure-Gated Runtime Controls I — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifact 0.
- M58 Player President Tenure Control Gate Core I — PR #61 merge `fe102d25ff53f598bf5d695f95131e580a7c4523`; 253 tests; M0–M58 PASS; artifact 0.
- M57 Player President Media Statement Decision Override I — PR #60 merge `af5d7c12597ad4a68f2b75251a3c9e70fb09a590`; 248 tests; M0–M57 PASS; artifact 0.
- M56 Player President Promise Decision Override I — PR #59 merge `c61ef1338cc0ab7cfb993827e46bec62524cf308`; 243 tests; M0–M56 PASS; artifact 0.
- M55 Player President Transfer Strategy Decision Override I — PR #58 merge `f4034bf35e11d52dc97d2d5a39abaed6672bbc7c`; 238 tests; M0–M55 PASS; artifact 0.
- M54 Transfer Strategy World Runtime Bridge I — PR #57 merge `837198d3480be5571d4eeae1934c72454f47dec1`; 233 tests; M0–M54 PASS; artifact 0.
- M53 President Transfer Strategy Runtime Hook I — PR #56 merge `f83e159793f80d7f53c40a0845e795339e400d3c`; 228 tests; M0–M53 PASS; artifact 0.
- M52 Player President Manager Decision Override I — PR #55 merge `bce9efe6c214526b0018110c5a10d2fa9e7ec5c8`; 223 tests; M0–M52 PASS; artifact 0.
- M51 Player President Crisis Decision Override I — PR #54 merge `4b2832f3bfb091ae3adaeb504a7369b1190b2438`; 218 tests; M0–M51 PASS; artifact 0.
- M50 Player President Sponsor Decision Override I — PR #53 merge `f8519d4f0be247f7029a2e29d4de10588d97736f`; 213 tests; M0–M50 PASS; artifact 0.
- M49 Player President Facility Decision Override I — PR #52 merge `c0c40bada13e3dd83c06cded64ead38dc2f30d8`; 208 tests; M0–M49 PASS; artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls; M60 M55 transfer strategy tenure gate; M61 M56 promise tenure gate; M62 M57 media statement tenure gate.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M49–M57 player-president kararları controlled club üzerinde runtime-only provider'larla çalışır; diğer kulüpler AI kalır.
- M58 persisted tenure ownership state'i sağlar.
- M59 M49–M52 nested decision stack'ini gerçek incumbent ownership ile yetkilendirir; presidency loss sonrası bu yüzeyler exact AI path'e döner.
- M60 M55 transfer-strategy kontrolünü gerçek incumbent ownership ile yetkilendirir ve explicit caller transfer policy precedence'ini korur.
- M61 M56 promise kontrolünü gerçek incumbent ownership ile yetkilendirir; turnover sonrası successor preseason'ında exact AI path'e döner.
- M62 M57 media statement stance kontrolünü gerçek incumbent ownership ile yetkilendirir; canonical M10 event metadata'sını korur ve turnover sonrası successor sezonunda exact AI path'e döner.
- M49–M57 player-president karar yüzeylerinin M58 tenure ownership entegrasyonu M59–M62 ile tamamlanmıştır; sonraki milestone otomatik seçilmez, canlı `main` taraması gerekir.

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
