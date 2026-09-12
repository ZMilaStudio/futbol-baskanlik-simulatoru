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

**M0–M54 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M55 — Player President Transfer Strategy Decision Override I.**

- Branch: `feat/m55-player-president-transfer-strategy-control`
- PR #58 — **OPEN / NOT MERGED**
- Base `main`: `51182060e462a3abf6aa252e3ace28d106b5d7f3`
- Verified code-bearing HEAD: `d767506553a5f0f1dce71a320abdd2486a38d897`
- Code-bearing PR CI `34724117874`: **SUCCESS**
- analyzer: `No issues found!`
- **238 normal/non-canonical test PASS**
- beş M55 acceptance testinin tamamı PASS
- **M0–M55 canonical PASS**
- `Run M55 player president transfer strategy control`: **SUCCESS**
- canonical marker: `M55_PLAYER_TRANSFER_STRATEGY_CONTROL_PASS controlled=t1_01 aiParity=47 ai=ready_forward player=young_forward deterministic=true identityPreserved=true worldClubs=48`
- artifacts: **0**
- PR `mergeable=true`

Bu özet refresh commit'i final PR HEAD'i değiştirecektir. Yeni exact HEAD üzerinde `test` + `canonical` CI, M55 marker ve artifact=0 yeniden doğrulanacaktır. Sonucu yalnız PR metadata'sına yazmak için ikinci bir docs commit atılmayacaktır.

M55 henüz merge edilmedi. Final exact-head CI + artifact 0 + mergeable=true yeniden doğrulandıktan sonra kullanıcıdan **PR #58'e özel açık merge onayı** alınmalıdır.

## 3. M55 kapsamı — Player President Transfer Strategy Decision Override I

M53 başkanın transfer trait'lerini gerçek transfer-market politikalarına çevirdi; M54 bu stratejiyi gerçek `WorldCareerEngine` transfer penceresine opt-in pre-window bridge ile bağladı. M55 bu seam'i yalnız oyuncunun kontrol ettiği kulüp için gerçek başkan kararına açar.

Oyuncu tek tek taktik/kadro yönetmez. Başkan olarak transfer politikasının dört yönetim eksenini seçer:
- `financialDiscipline`: transfer bütçesi ve mali disiplin yaklaşımı,
- `transferAmbition`: transfer aktivitesi/hırsı,
- `riskAppetite`: pazarlık risk iştahı,
- `youthOrientation`: genç oyuncu tercihi.

M55 çözümü:
- `PlayerTransferStrategyDecisionProvider`, kontrollü kulüp için transfer-window kararını üretir.
- `PlayerTransferStrategyDecisionContext`, gerçek M54 window context'i + controlled club + AI başkan profilini taşır.
- `PlayerTransferStrategyChoice`, dört transfer trait'ini `20..90` aralığında sınırlar.
- `PlayerPresidentTransferStrategyProfileProvider`, AI profile map'i üzerine yalnız kontrollü kulübün dört transfer trait'ini bindirir.
- Başkan `presidentId`, `archetype` ve `managerPatience` aynen korunur.
- Diğer 47 kulübün AI profile signature'ları değişmez.
- Player provider yoksa M54 exact parity korunur.
- Explicit transfer policy map verilirse M54 semantiği gereği AI/player provider zinciri bypass edilir.
- `PlayerPresidentTransferStrategyWorldBridge`, M54 bridge kompozisyonunu kolaylaştıran opt-in wrapper'dır.
- Default `WorldCareerEngine` değiştirilmez.
- Yeni save alanı/migration yoktur; player provider serialize edilmez.

M55 acceptance:
1. player provider yokken M54 exact transfer parity — PASS
2. yalnız controlled club dört transfer trait'i değişir; başkan kimliği/archetype/manager patience ve diğer 47 AI kulübü korunur — PASS
3. youth override gerçek market seam'inde `ready_forward` → `young_forward` seçimini değiştirir — PASS
4. explicit market policy map AI ve player provider'ları bypass eder — PASS
5. gerçek 48-kulüp world bridge AI-parity seçiminde report/checkpoint parity ve fixed-input determinism korur — PASS

M55 dosyaları:
- `lib/src/transfer/player_president_transfer_strategy_control.dart`
- `lib/player_president_transfer_strategy_control.dart`
- `test/m55_player_president_transfer_strategy_control_test.dart`
- `tool/run_m55_player_president_transfer_strategy_control.dart`
- `M55_PLAYER_PRESIDENT_TRANSFER_STRATEGY_DECISION_OVERRIDE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

## 4. Son kapanan milestone: M54 — Transfer Strategy World Runtime Bridge I

- Branch: `feat/m54-transfer-strategy-world-runtime-bridge`
- PR #57 — MERGED
- Final PR HEAD: `45405585e2263a1377c2d62b14a2e1449bdd3962`
- Merge SHA: `837198d3480be5571d4eeae1934c72454f47dec1`
- Post-merge `main` CI `34723247609`: SUCCESS
- closure docs commit: `51182060e462a3abf6aa252e3ace28d106b5d7f3`
- docs-close CI `34723519127`: SUCCESS
- analyzer clean; **233 tests PASS**; **M0–M54 canonical PASS**; artifacts **0**
- canonical marker: `M54_TRANSFER_STRATEGY_WORLD_BRIDGE_PASS neutralParity=true low=ready_forward high=young_forward worldWired=true deterministic=true worldClubs=48`

M54, M53 stratejisini gerçek `WorldCareerEngine` transfer penceresine opt-in ve stateless pre-window market bridge ile bağladı. Neutral parity, explicit-policy bypass, 48-club world wiring ve determinism kanıtlandı.

M54 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

- M53 President Transfer Strategy Runtime Hook I — PR #56 merge `f83e159793f80d7f53c40a0845e795339e400d3c`; 228 tests; M0–M53 PASS; artifact 0.
- M52 Player President Manager Decision Override I — PR #55 merge `bce9efe6c214526b0018110c5a10d2fa9e7ec5c8`; 223 tests; M0–M52 PASS; artifact 0.
- M51 Player President Crisis Decision Override I — PR #54 merge `4b2832f3bfb091ae3adaeb504a7369b1190b2438`; 218 tests; M0–M51 PASS; artifact 0.
- M50 Player President Sponsor Decision Override I — PR #53 merge `f8519d4f0be247f7029a2e29d4de10588d97736f`; 213 tests; M0–M50 PASS; artifact 0.
- M49 Player President Facility Decision Override I — PR #52 merge `c0c40bada13e3dd83c06cded64ead38dc2f30d8`; 208 tests; M0–M49 PASS; artifact 0.
- M48 President Facility Investment Runtime Integration I — PR #51 merge `63950ab4ad728fe6b6f4f0deb42323590ce5180a`; 203 tests; M0–M48 PASS; artifact 0.

## 6. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M49–M52 controlled club oyuncu başkan facility/sponsor/crisis/manager kararlarıdır; diğer kulüpler AI kalır
- M53 transfer trait'lerini gerçek transfer-market API'sinde birleştirir
- M54 M53 stratejisini gerçek world transfer window'a opt-in pre-window bridge ile taşır
- M55 aynı real transfer seam'inde yalnız controlled club için dört transfer stratejisi eksenini oyuncu başkana açar; diğer 47 kulüp AI kalır

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
9. Docs-only kapanış/refresh commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
