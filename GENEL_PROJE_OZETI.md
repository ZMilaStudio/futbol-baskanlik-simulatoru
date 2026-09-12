# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 12 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
Canonical seed: `20260903`
Dünya: 48 özgün kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 14.400 maç/20 sezon, 864 başlangıç oyuncusu.

Kalıcı kurallar:
- Live GitHub > proje dosyaları > eski sohbetler
- deterministic seed/replay; `GameDate`; integer minor-unit `Money`
- eski public simulation semantiği sessizce değiştirilmez
- save/load/resume determinism ve parity korunur
- PASS yalnız canlı CI kanıtıyla yazılır
- CI iki paralel job: `test` + `canonical`; her job `timeout-minutes: 7`
- artifact hedefi `0`
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz
- her anlamlı proje durumu/kararı sonrası bu özet güncel tutulur
- docs→CI→docs sonsuz döngüsü üretilmez

## 2. CANLI DURUM — buradan devam et

**M0–M44 CLOSED / MERGED / PASS ve `main` üzerindedir.**

Son merge edilmiş milestone:
**M44 — Crisis Runtime Integration I**

PR #47 squash merge: `43149da199e74e41dabe47534e4e4e887d8862e7`

Post-merge main CI `34683153804` — **SUCCESS**:
- test job `103525370907` — SUCCESS
- analyzer: `No issues found!`
- **184 normal/non-canonical test PASS**
- canonical job `103525370623` — SUCCESS
- **M0–M44 canonical PASS**
- artifacts: **0**
- iki job da 7 dakika sınırının altında

M44 canonical final:
- seasons=4
- crises=**17/192** (%8,9)
- real president turnovers=42
- policyChanges=35
- legacyParity=true
- finalCheckpointMatch=true
- boundaryMatch=true

Kalıcı doküman: `M44_CRISIS_RUNTIME_INTEGRATION_I.md`.

### Sıradaki seçilmiş milestone

**M45 — Sponsor Runtime Integration I**

Canlı repoda açık bir M45 tanımı bulunmadı. README eski M25/M26 durumunda kaldığı için roadmap kaynağı olarak kullanılmadı. M45, mevcut canlı mimarideki en belirgin entegrasyon boşluğuna göre seçildi:
- M42 sponsor çekirdeği gerçek teklif/kontrat/gelir üretir ve ayrı `SponsorRuntimeCheckpoint` taşır,
- ancak sponsor kontrat yaşam döngüsü henüz tam PresidentDomain sezon runtime/checkpoint akışına bağlı değildir,
- M44 kriz sistemi için bu “core → gerçek continuation runtime” boşluğunu kapattı; sponsor sistemi için aynı sınıf entegrasyon hâlâ eksiktir.

M45 ilk hedefleri:
- gerçek sezon akışında mevcut fan/media/current-president state'leriyle sponsor çözümlemek,
- kabul edilen sponsor gelirini gerçek kulüp ekonomisine **double-counting olmadan** bağlamak,
- çok yıllı sponsor kontratlarını gerçek başkan turnover'ları boyunca korumak,
- kontrat bittiğinde yeni başkan profilinin yeni sponsor seçimini gerçekten etkileyebilmesini sağlamak,
- sponsor runtime state'ini uzun kariyer continuation/save-resume akışında deterministik taşımak,
- legacy sponsor/economy davranışını explicit opt-in veya ayrı wrapper ile korumak,
- canonical gate + normal acceptance testleri eklemek.

Kullanıcı bu oturumda yeşil milestone PR'larının ayrıca sorulmadan squash merge edilmesine ve kapanıştan sonra sonraki mantıklı milestone'a geçilmesine izin verdi. Exact-head CI, post-merge main CI, 7 dakika, determinism ve artifact=0 kuralları zorunludur.

## 3. Son kapalı milestone'lar

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
PR #47 squash merge: `43149da199e74e41dabe47534e4e4e887d8862e7`
Post-merge main CI `34683153804`: analyzer clean, **184 test PASS**, **M0–M44 PASS**, artifact **0**.

Kapsam:
- ayrı opt-in `CrisisRuntimeCareerEngine`; legacy `PresidentDomainCareerEngine` değiştirilmedi
- gerçek sezon sonunda finance/fan/media/current-president state'inden M43 crisis context
- cash etkisi gerçek `WorldCheckpoint.nextSeasonFinanceStates` continuation state'ine
- fan/media etkisi gerçek `PresidentRuntimeCheckpoint.clubs` continuation state'ine
- debt değişmez; gizli borrowing yok
- mevcut PresidentDomain save codec yeterli; save-version bump yok
- 2+2 save/resume = uninterrupted 4 sezon
- gerçek president turnover crisis policy'yi değiştirebilir
- runtime threshold 55; M43 core defaultu değişmedi
- kalıcı frequency guard kriz oranının %75'e ulaşmasını reddeder

Failure/düzeltme geçmişi:
- ilk PR analyzer failure: testte var olmayan `FictionalWorld`; gerçek tip `FictionalWorldSetup` ile düzeltildi
- ilk teknik yeşil runtime 164/192 kriz üretti; ürün dengesi için M44 threshold 55 yapıldı
- final 17/192 kriz ile tüm parity/legacy gate'leri PASS

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 squash merge: `27474a731aa73d291859828a1657d06579e69269`
Post-merge main CI `34680783652`: analyzer clean, **179 test PASS**, **M0–M43 PASS**, artifact **0**.

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 squash merge: `2868d725c4ba68601a732d98b913195d3c58a4a3`
Post-merge main CI `34660280556`: analyzer clean, **173 test PASS**, **M0–M42 PASS**, artifact **0**.

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 squash merge: `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`; post-merge CI `34656211019`: 167 test PASS, M0–M41 PASS, artifact 0.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`; post-merge CI `34652843932`: 162 tests, M0–M40 PASS, artifact 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`; post-merge CI `34649669246`: 157 tests, M0–M39 PASS, artifact 0.

## 4. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime integration.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + crisis pressure
- `MediaState.credibility`: sponsor offer quality + crisis pressure
- finance cash/debt: crisis pressure + bounded cash effect
- M44: crisis output gerçek next-season continuation state'ine taşınır
- M42 sponsor core: `SponsorSystemEngine.resolveSeason(...)` gerçek kontrat ve `revenueByClub` üretir; `SponsorRuntimeCheckpoint` active contracts + cumulative paid revenue taşır; M45 bunu gerçek full runtime'a bağlayacaktır

## 5. M45 çalışma yönü

M45 implementasyondan önce canlı `main` üstünde şu yüzeyler birlikte okunmalıdır:
1. `BasicEconomyEngine.simulateSeason` sponsor geliri override/parametre semantiği,
2. facility/attendance economy wrapper'larının sponsor parametresini nasıl forward ettiği,
3. `PresidentDomainCareerEngine` + resume/checkpoint sezon sınırı,
4. gerçek season report içinden league position erişimi,
5. M42 `SponsorRuntimeCheckpoint` ve sponsor save codec/testleri.

Kritik kabul noktası: sponsor-aware runtime eski strength-only sponsor gelirini üstüne ekleyip geliri iki kez saymamalıdır. Sponsor kontrat geliri gerçek economy `sponsorRevenue` satırının tek kaynağı olmalı veya açıkça tanımlı replacement semantiği kullanmalıdır.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu oturumda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi.
