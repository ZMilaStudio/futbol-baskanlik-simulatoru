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
- her kullanıcı mesajından sonra bu özet güncel tutulur
- docs→CI→docs sonsuz döngüsü üretilmez

## 2. CANLI DURUM — buradan devam et

**M0–M43 PASS ve `main` üzerindedir.**

Aktif milestone:
**M44 — Crisis Runtime Integration I**

Branch: `feat/m44-crisis-runtime-integration`
PR: **#47**
Durum: **CODE PR-VERIFIED / DOCS-INCLUSIVE EXACT-HEAD CI PENDING**

Final code-bearing HEAD: `295bbd4a7967e25c16bf8b72c4f67c0317159298`
Code-bearing CI `34682359483` — **SUCCESS**:
- test job `103523238562` — SUCCESS
- analyzer: `No issues found!`
- **184 normal/non-canonical test PASS**
- canonical job `103523238501` — SUCCESS
- **M0–M44 canonical PASS**
- artifacts: **0**
- iki job da 7 dakika sınırının altında

M44 canonical final:
- seasons=4
- crises=**17/192**
- crisis type: `liquiditySqueeze=17`
- actions: `bridgeSpending=4`, `balancedRecovery=10`, `austerityPlan=3`
- real president turnovers=42
- policyChanges=35
- legacyParity=true
- finalCheckpointMatch=true
- boundaryMatch=true

Kullanıcı bu oturumda yeşil milestone PR'larının ayrıca sorulmadan squash merge edilmesine ve kapanıştan sonra sonraki mantıklı milestone'a geçilmesine izin verdi. Exact-head CI, post-merge main CI, 7 dakika, determinism ve artifact=0 kuralları zorunludur.

### M44 kapsamı
- ayrı opt-in `CrisisRuntimeCareerEngine`; legacy `PresidentDomainCareerEngine` değiştirilmedi
- her gerçek sezon sonunda M43 context mevcut finance/fan/media/current-president state'inden kurulur
- kriz cash sonucu gerçek `WorldCheckpoint.nextSeasonFinanceStates` içine yazılır
- fan/media sonucu gerçek `PresidentRuntimeCheckpoint.clubs` continuation state'ine yazılır
- debt değiştirilmez; gizli borrowing yok
- mevcut `PresidentDomainMemorySaveCodec` crisis-adjusted state'i persist eder; save-version bump yok
- 2+2 save/resume = uninterrupted 4 sezon
- gerçek president turnover yeni management profile üzerinden kriz policy'sini değiştirebilir
- activation threshold M44 runtime defaultunda 55; M43 core defaultu değiştirilmedi
- canonical frequency guard: kriz oranı kulüp-sezonlarının %75'ine ulaşırsa FAIL

Failure/düzeltme geçmişi:
- ilk PR run `34681997922`: analyzer testte var olmayan `FictionalWorld` tipinden kırıldı; gerçek factory return tipi `FictionalWorldSetup` olarak log/koddan doğrulanıp düzeltildi
- ikinci run `34682061772` teknik olarak tam yeşildi fakat canonical kriz sıklığı **164/192** idi; ürün dengesi için M44 runtime threshold 55'e yükseltildi ve frequency guard eklendi
- final code-bearing run `34682359483`: kriz sıklığı **17/192**'ye indi ve tüm gate'ler yeşil kaldı

Kalıcı doküman: `M44_CRISIS_RUNTIME_INTEGRATION_I.md`.

Sıradaki adım: bu docs-inclusive branch HEAD'inin exact CI'ını doğrula. Yeşil + artifact 0 + mergeable ise PR #47 kullanıcı yetkisiyle squash merge edilebilir; sonra post-merge `main` CI doğrulanıp M44 CLOSED/PASS yapılır.

## 3. Son kapalı milestone'lar

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 squash merge: `27474a731aa73d291859828a1657d06579e69269`
Post-merge main CI `34680783652`: analyzer clean, **179 test PASS**, **M0–M43 PASS**, artifact **0**.
Kalıcı doküman: `M43_CRISIS_DECISION_CORE_I.md`.

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

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor system; M43 crisis decision core; M44 crisis runtime integration (aktif).

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + crisis pressure
- `MediaState.credibility`: sponsor offer quality + crisis pressure
- finance cash/debt: crisis pressure + bounded cash effect
- M44: crisis output artık gerçek next-season continuation state'ine taşınıyor

## 5. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu oturumda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi.
