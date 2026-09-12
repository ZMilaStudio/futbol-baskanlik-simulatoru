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

**M0–M45 CLOSED / MERGED / PASS ve `main` üzerindedir.**

### M46 — Sponsor + Crisis Runtime Composition I — MERGE-READY / NOT MERGED

Branch: `feat/m46-sponsor-crisis-runtime-composition`
PR: **#49**
Kod + canonical gate HEAD: `afd0381139356eff59d399023a169e10bf60ffff`

PR CI `34685617385` — **SUCCESS**:
- analyzer: `No issues found!`
- **193 normal/non-canonical test PASS**
- canonical: **M0–M46 PASS**
- M46 canonical PASS
- artifacts: **0**
- test job yaklaşık 3:13
- canonical job yaklaşık 4:51
- iki job da 7 dakika sınırının altında

M46 canonical final:
- seasons=4
- contractsPerSeason=48
- sponsorRevenueBySeason=`291473844.75,294173445.25,295481959.00,299331748.00`
- cumulativeSponsorRevenue=`1180460997.00`
- crises=`46/192`
- forcedWiring=true
- debtPreserved=true
- sponsorStatePreserved=true
- financeReplacementMatch=true
- neutralM45Parity=true
- saveResumeMatch=true
- boundaryMatch=true
- saveBytes=731311

M46 kapsamı:
- M45 sponsor-aware ekonomi ve M44 kriz boundary'si aynı top-level runtime'da compose edildi
- PresidentDomain/world sezonu yalnız bir kez simüle ediliyor
- kriz sponsor-aware finance tamamlandıktan sonra uygulanıyor
- sponsor contract state krizden bağımsız korunuyor
- kriz-adjusted finance/fan/media gerçek continuation state'ine yazılıyor
- sonraki sponsor sezonu kriz-adjusted fan/media + current president context'ini okuyor
- M44 debt-preservation ve M45 sponsor replacement/double-counting korumaları korunuyor
- kriz etkisiz konfigürasyonda M45 ile birebir parity var
- mevcut `SponsorPresidentRuntimeCheckpoint` + `SponsorPresidentRuntimeSaveCodec` yeterli; save-version bump yok
- 2+2 save/resume = uninterrupted 4 sezon
- 4 yeni normal acceptance testi eklendi; toplam 193 test
- kalıcı canonical gate: `tool/run_m46_sponsor_crisis_runtime_composition.dart`
- kalıcı doküman: `M46_SPONSOR_CRISIS_RUNTIME_COMPOSITION_I.md`

M46 dokümanları eklendiği için **docs-inclusive exact HEAD CI yeniden doğrulanmadan merge yapılmayacaktır**. Kullanıcı PR #49 için merge onayı verdi.

### Son merge edilmiş milestone: M45 — Sponsor Runtime Integration I

PR #48 squash merge: `92f4f1b99fa841866587a8067dd529735400c035`
Post-merge main CI `34684676105` — **SUCCESS**:
- analyzer clean
- **189 test PASS**
- **M0–M45 canonical PASS**
- artifact **0**
- iki job da 7 dakika sınırının altında

Kalıcı doküman: `M45_SPONSOR_RUNTIME_INTEGRATION_I.md`.

## 3. Son kapalı milestone'lar

### M45 — Sponsor Runtime Integration I — CLOSED / MERGED / PASS
- explicit `PresidentDomainMemoryCheckpoint + SponsorRuntimeCheckpoint` composite checkpoint/save codec
- sponsor geliri gerçek economy `sponsorRevenue` alanında legacy gelirin replacement kaynağı; double-counting yok
- current president + fan + media sponsor seçim context'i
- multi-year kontrat president turnover boyunca korunur; expiry sonrası renewal current president ile yapılır
- 2+2 save/resume parity
- PR #48 merge `92f4f1b99fa841866587a8067dd529735400c035`
- post-merge CI `34684676105`: 189 tests, M0–M45 PASS, artifact 0

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
- opt-in `CrisisRuntimeCareerEngine`
- gerçek sezon sonu finance/fan/media/current-president context'i
- cash/fan/media etkileri gerçek continuation state'ine
- debt değişmez; gizli borrowing yok
- save-version bump yok
- 2+2 save/resume parity
- president turnover crisis policy'yi değiştirebilir
- runtime threshold 55, frequency guard <%75
- PR #47 merge `43149da199e74e41dabe47534e4e4e887d8862e7`
- post-merge CI `34683153804`: 184 tests, M0–M44 PASS, artifact 0

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 squash merge: `27474a731aa73d291859828a1657d06579e69269`
Post-merge CI `34680783652`: 179 tests, M0–M43 PASS, artifact 0.

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 squash merge: `2868d725c4ba68601a732d98b913195d3c58a4a3`
Post-merge CI `34660280556`: 173 tests, M0–M42 PASS, artifact 0.

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 squash merge: `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`; post-merge CI `34656211019`: 167 tests, M0–M41 PASS, artifact 0.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`; post-merge CI `34652843932`: 162 tests, M0–M40 PASS, artifact 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`; post-merge CI `34649669246`: 157 tests, M0–M39 PASS, artifact 0.

## 4. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime integration; M45 sponsor runtime integration; M46 sponsor+crisis runtime composition.

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
- M45: sponsor contract lifecycle + revenue gerçek PresidentDomain continuation/economy akışına bağlıdır
- M46: M44 + M45 aynı season boundary/continuation runtime'ında compose edilir; kriz etkisi sonraki sponsor context'ine ulaşır

## 5. M46 kabul zinciri

1. Sponsor-aware economy coordinator 48 kulüp kontrat/gelirini gerçek economy çağrılarında çözer.
2. PresidentDomain sezonu bir kez tamamlanır.
3. `CrisisRuntimeIntegrationEngine.apply(...)` tamamlanmış domain checkpoint'e uygulanır.
4. Crisis-adjusted domain checkpoint mevcut sponsor checkpoint ile composite olarak taşınır.
5. Sonraki sponsor sezonu kriz-adjusted fan/media + current president state'ini okur.
6. Neutral kriz yolu M45 parity verir.
7. 2+2 save/resume uninterrupted 4 sezonla aynıdır.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Kullanıcı PR #49 için merge onayı verdi; exact docs-inclusive HEAD yeşilse squash merge edilebilir. Merge sonrası `main` CI doğrulanmadan M46 CLOSED sayılmaz.
