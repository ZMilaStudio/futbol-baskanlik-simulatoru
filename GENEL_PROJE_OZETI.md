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

**M0–M59 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yok. M60 henüz seçilmedi.**

M59 kapanış kanıtı:
- Milestone: `M59 — Player President Tenure-Gated Runtime Controls I`
- Branch: `feat/m59-player-president-tenure-gated-runtime-controls`
- PR #62 — **MERGED / CLOSED**
- Final exact PR HEAD: `e393439e96729f05102ed4c478476a01c62a0ab5`
- Final exact-head PR CI `34752195656`: **SUCCESS**
- Squash merge SHA: `d49424573d7db1c2f02554bffec2e3b13c40b6dd`
- Post-merge `main` CI `34752676581`: **SUCCESS**
- analyzer: `No issues found!`
- **258/258 normal/non-canonical test PASS**
- beş M59 acceptance testinin tamamı PASS
- **M0–M59 canonical PASS**
- canonical marker: `M59_PLAYER_PRESIDENT_TENURE_GATED_RUNTIME_CONTROLS_PASS turnoverClub=t1_01 reelectedClub=t1_03 activeDelegation=true turnoverStopsControl=true reelectionKeepsControl=true exactAiAfterLoss=true deterministic=true worldClubs=48`
- artifacts: **0**

Bu dosya, post-merge `main` CI `34752676581` tamamen SUCCESS olduktan sonra M59 kapanış durumuna güncellenmiştir. Bu docs-only kapanış commit'inin CI'ı bir kez doğrulanacaktır; sırf docs-close run ID'sini bu dosyaya yazmak için ikinci bir docs commit atılmayacaktır.

Bir sonraki adım: canlı `main` kodunu ve bu özeti inceleyip M60 kapsamını gerçek ürün boşluğundan seçmek. M55 transfer strategy, M56 promise ve M57 media statement player kararlarının M58 tenure gate ile yetkilendirilmesi güçlü adaydır; ancak kapsam canlı kod incelenmeden kesinleştirilmez.

## 3. Son kapanan milestone: M59 — Player President Tenure-Gated Runtime Controls I

M59, M58'de kurulan gerçek incumbent president ownership gate'ini M49–M52 facility/sponsor/crisis/manager player decision stack'ine bağladı.

Davranış:
- M52 nested control checkpoint'i ile M58 tenure state'i M59 checkpoint içinde birlikte persist edilir;
- active state sırasında M49–M52 dış provider'ları ortak runtime tenure session üzerinden yalnız gerçek incumbent president identity geçerliyken çalışır;
- gerçek election turnover boundary içinde successor id ilk görüldüğü anda player provider çağrıları kapanır;
- bloke edilen facility/sponsor/crisis/manager kararları kendi kanonik AI kararına düşer;
- reelection aynı incumbent kimliğini koruduğu için player control aktif kalır;
- state `lost` olduktan sonraki sezonlar untouched no-provider M52 AI path'ine döner;
- provider callback'leri runtime-only kalır ve save'e yazılmaz;
- eski M49–M52 public engine/save formatları değiştirilmez.

Acceptance:
1. active incumbent iken M49–M52 dış provider'ları çağrılır — PASS;
2. gerçek election turnover boundary içinde dış provider'lar successor görülür görülmez kapanır — PASS;
3. reelection player control'ü aktif tutar — PASS;
4. lost checkpoint resume exact AI path'e eşittir ve dış provider çağrılmaz — PASS;
5. M59 save round-trip + 2+2 resume deterministik parity korur — PASS.

M59 dosyaları:
- `lib/src/election/player_president_tenure_gated_runtime_controls.dart`
- `lib/player_president_tenure_gated_runtime_controls.dart`
- `test/m59_player_president_tenure_gated_runtime_controls_test.dart`
- `tool/run_m59_player_president_tenure_gated_runtime_controls.dart`
- `M59_PLAYER_PRESIDENT_TENURE_GATED_RUNTIME_CONTROLS_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M59 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

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

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control; M58 player-president tenure ownership/control gate core; M59 M49–M52 tenure-gated runtime controls.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M49–M57 player-president kararları controlled club üzerinde runtime-only provider'larla çalışır; diğer kulüpler AI kalır.
- M58 persisted tenure ownership state'i sağlar.
- M59 M49–M52 nested decision stack'ini gerçek incumbent ownership ile yetkilendirir; presidency loss sonrası bu yüzeyler exact AI path'e döner.
- M55–M57 tenure gating henüz ayrı runtime yüzeylerinde tamamlanmalıdır.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
9. Docs-only kapanış/refresh commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
