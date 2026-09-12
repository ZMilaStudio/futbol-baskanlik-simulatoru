# M47 — Facility + Sponsor + Crisis Runtime Composition I

Status: **PR-VERIFIED / NOT MERGED**

PR: #50
Branch: `feat/m47-facility-sponsor-crisis-runtime-composition`
Canonical seed: `20260903`

## Amaç

M38 facility portfolio etkilerini M46 sponsor+crisis PresidentDomain continuation runtime'ına tek top-level sezon akışı içinde bağlamak.

M47 her sezonu yalnız bir kez simüle eder:
1. Persist edilmiş academy + training ground state oyuncu lifecycle'a uygulanır.
2. Persist edilmiş stadium state + current fan trust matchday gelir multiplier'ını üretir.
3. M45 sponsor coordinator gerçek sponsor gelirini economy'de legacy sponsor gelirinin replacement kaynağı olarak uygular.
4. PresidentDomain sezonu tamamlanır.
5. M44 kriz boundary'si tamamlanmış sponsor/facility-aware domain state'e uygulanır.
6. Crisis-adjusted domain + sponsor checkpoint + facility portfolio birlikte continuation state olarak taşınır.

M39 otomatik president facility investment kararı M47 kapsamına alınmamıştır. M47 facility seviyelerini continuation-critical fakat statik state olarak taşır.

## Kalıcı state

Yeni `FacilitySponsorCrisisRuntimeCheckpoint`:
- mevcut `SponsorPresidentRuntimeCheckpoint`
- `FacilityPortfolioRuntimeState`
  - 48 academy state
  - 48 stadium state
  - 48 training-ground state
  - cumulative `totalInvestmentSpent`

World state ikinci kez kopyalanmaz.

Yeni save codec:
- format: `zmila-fbs-facility-sponsor-crisis-runtime`
- save version: 1
- mevcut `SponsorPresidentRuntimeSaveCodec` nested string olarak yeniden kullanılır
- checksum doğrulaması korunur

## Acceptance testleri

5 yeni normal test:
1. neutral facility portfolio M46 ile birebir parity verir
2. stadium gerçek sponsor-aware matchday revenue'yu değiştirir
3. training ground gerçek player development'ı değiştirir
4. crisis facility+sponsor-aware economy sonrasında uygulanır, sponsor state ve debt invariants korunur
5. non-zero academy/stadium/training portfolio save/load + 2+2 resume parity verir

Normal test toplamı: **198 PASS**.

## CI / canonical kanıtı

Code-bearing HEAD: `a23d623d7a89e1e9172e71f0aabd8c7b3a67ee40`
Run: `34691699235`

- analyzer: **No issues found**
- test job: **SUCCESS**, yaklaşık 2:01
- canonical job: **SUCCESS**, yaklaşık 3:49
- **198 normal test PASS**
- **M0–M47 canonical PASS**
- artifacts: **0**
- her iki job da `timeout-minutes: 7` altında

İlk PR run `34691443880` analyzer'da 5 public-export hatasıyla kırmızıydı. Gerçek log incelendi; M47 public shim'e `StadiumFacilityState` ve `TrainingGroundFacilityState` exportları eklenerek kök neden düzeltildi. Sonraki analyzer/test run'ı yeşil oldu.

## M47 canonical sonucu

- seasons=4
- target=`t1_01`
- target facility levels=`academy 2 / stadium 2 / training 2`
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

## Merge kapısı

M47 henüz `main` üzerinde değildir.

Merge öncesi kalan zorunlu adımlar:
1. bu doküman + `GENEL_PROJE_OZETI.md` commitlerinden oluşan final PR HEAD CI'ını doğrula
2. analyzer + normal tests + M0–M47 + artifact 0 kanıtını exact HEAD için al
3. PR head değişmediğini ve mergeable olduğunu doğrula
4. kullanıcıdan PR #50 için açık merge onayı al
5. yalnız onaydan sonra squash merge et
6. post-merge `main` CI yeşil olmadan M47'yi CLOSED sayma
