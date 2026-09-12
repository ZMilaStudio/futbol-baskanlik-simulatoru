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

**M0–M46 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**M47 — Facility + Sponsor + Crisis Runtime Composition I aktif; PR #50 PR-VERIFIED / NOT MERGED.**

### M47 — Facility + Sponsor + Crisis Runtime Composition I — PR-VERIFIED / NOT MERGED

Branch: `feat/m47-facility-sponsor-crisis-runtime-composition`
PR: #50
Code-bearing verified HEAD: `a23d623d7a89e1e9172e71f0aabd8c7b3a67ee40`
CI run `34691699235` — **SUCCESS**:
- analyzer: `No issues found!`
- **198 normal/non-canonical test PASS**
- **M0–M47 canonical PASS**
- M47 canonical PASS
- artifacts: **0**
- test job yaklaşık **2:01**
- canonical job yaklaşık **3:49**
- iki job da 7 dakika sınırının altında

İlk PR run `34691443880` analyzer'da 5 public-export hatasıyla kırmızıydı. Gerçek failure logu incelendi; `StadiumFacilityState` ve `TrainingGroundFacilityState` M47 public shim'den export edilerek kök neden düzeltildi. Sonraki analyzer/test ve canonical run'ları yeşil oldu.

M47 canonical final:
- seasons=4
- target=`t1_01`
- facility levels=`2/2/2` (academy/stadium/training)
- target matchday revenue=`9,911,400 -> 11,398,110`
- crises=`40/192`
- forcedWiring=true
- debtPreserved=true
- sponsorStatePreserved=true
- financeReplacementMatch=true
- facilitiesPreserved=true
- stadiumEffect=true
- neutralM46Parity=true
- saveResumeMatch=true
- boundaryMatch=true
- saveBytes=935220

M47 kapsamı:
- M38 academy/stadium/training facility etkileri M46 sponsor+crisis PresidentDomain continuation runtime'ına aynı sezon simülasyonu içinde bağlandı
- her sezon yalnız bir kez world/PresidentDomain simülasyonu çalışır
- academy + training real player lifecycle'a, stadium + current fan trust real matchday revenue'ya etki eder
- sponsor geliri economy'de legacy sponsor gelirinin replacement kaynağıdır; double-counting yok
- kriz facility+sponsor-aware economy sonrasında uygulanır
- sponsor state krizden bağımsız korunur; debt preservation korunur
- facility portfolio continuation-critical state olarak M46 runtime'ın yanında persist edilir; world state ikinci kez kopyalanmaz
- neutral facility level 0 yolu M46 ile birebir parity verir
- non-zero academy/stadium/training state save/load ve 2+2 resume determinism verir
- M39 otomatik president facility investment decision loop M47 kapsamına bilinçli olarak alınmadı; sonraki milestone adayıdır
- 5 yeni acceptance testi; toplam 198 test
- kalıcı canonical gate: `tool/run_m47_facility_sponsor_crisis_runtime_composition.dart`
- kalıcı doküman: `M47_FACILITY_SPONSOR_CRISIS_RUNTIME_COMPOSITION_I.md`

M47 henüz `main` üzerinde değildir. Sıradaki zorunlu kapı:
1. docs-inclusive exact PR HEAD CI
2. analyzer + 198 test + M0–M47 + artifact 0
3. head/mergeable doğrulaması
4. **PR #50 için açık kullanıcı merge onayı**
5. yalnız onaydan sonra squash merge + post-merge main CI

### Son merge edilmiş milestone: M46 — Sponsor + Crisis Runtime Composition I

PR #49 squash merge: `f0455db0fd5f33dd1d50bb89aeabcb14e3d5d694`
Post-merge main CI `34686218278` — **SUCCESS**:
- analyzer: `No issues found!`
- **193 normal/non-canonical test PASS**
- **M0–M46 canonical PASS**
- artifacts: **0**
- test job yaklaşık **2:30**
- canonical job yaklaşık **4:50**

M46 **CLOSED / MERGED / PASS**.

## 3. Son kapalı milestone'lar

### M46 — Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- M44 crisis runtime + M45 sponsor runtime tek top-level career continuation yolunda compose edildi
- aynı PresidentDomain/world sezonu iki kez simüle edilmiyor
- sponsor-aware finance sonrası kriz uygulanıyor
- sponsor state korunuyor; kriz-adjusted finance/fan/media sonraki sponsor context'ine taşınıyor
- neutral kriz yolu M45 parity veriyor
- mevcut M45 composite save formatı yeterli; save version bump yok
- 2+2 save/resume parity
- PR #49 merge `f0455db0fd5f33dd1d50bb89aeabcb14e3d5d694`
- post-merge CI `34686218278`: 193 tests, M0–M46 PASS, artifact 0

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

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime integration; M45 sponsor runtime integration; M46 sponsor+crisis runtime composition; M47 facility+sponsor+crisis runtime composition (PR #50, henüz merge edilmedi).

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + crisis pressure
- `MediaState.credibility`: sponsor offer quality + crisis pressure
- finance cash/debt: crisis pressure + bounded cash effect
- facility academy/training: real lifecycle/youth-development etkisi
- facility stadium + fan trust: real matchday revenue etkisi
- M44: crisis output gerçek next-season continuation state'ine taşınır
- M45: sponsor contract lifecycle + revenue gerçek PresidentDomain continuation/economy akışına bağlıdır
- M46: M44 + M45 aynı season boundary/continuation runtime'ında compose edilir; kriz etkisi sonraki sponsor context'ine ulaşır
- M47: M38 facility portfolio state ve etkileri M46 runtime ile aynı tek-season simulation yolunda compose edilir

## 5. M47 kabul zinciri

1. Full 48-club academy/stadium/training portfolio exact coverage ile açılır veya restore edilir.
2. Academy + training facility map real `PlayerLifecycleEngine` call'ına uygulanır.
3. Stadium + current fan trust real matchday revenue multiplier'ını üretir.
4. Sponsor coordinator 48 kulüp kontrat/gelirini gerçek economy çağrılarında çözer; sponsor geliri replacement olarak uygulanır.
5. PresidentDomain sezonu yalnız bir kez tamamlanır.
6. `CrisisRuntimeIntegrationEngine.apply(...)` tamamlanmış facility+sponsor-aware domain checkpoint'e uygulanır.
7. Crisis-adjusted domain + sponsor checkpoint + facility portfolio composite continuation state olarak taşınır.
8. Neutral facility portfolio M46 ile birebir parity verir.
9. Non-zero facility portfolio save/load round-trip ve 2+2 resume uninterrupted 4 sezonla aynıdır.
10. Debt, sponsor-state, finance-replacement ve boundary parity invariants korunur.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
