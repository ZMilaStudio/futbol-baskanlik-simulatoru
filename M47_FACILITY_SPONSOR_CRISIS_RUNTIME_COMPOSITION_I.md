# M47 — Facility + Sponsor + Crisis Runtime Composition I

Status: **CLOSED / MERGED / PASS**

PR: #50
Squash merge: `dc26c2782026c6823c91d05015f4f507a7bac2f6`
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

`FacilitySponsorCrisisRuntimeCheckpoint`:
- mevcut `SponsorPresidentRuntimeCheckpoint`
- `FacilityPortfolioRuntimeState`
  - 48 academy state
  - 48 stadium state
  - 48 training-ground state
  - cumulative `totalInvestmentSpent`

World state ikinci kez kopyalanmaz.

Save codec:
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

## PR ve exact-head CI kanıtı

Final PR HEAD: `5fb0c8a0c6de9717d0ba3dd93f0629b8d81bf1de`
Final PR run: `34692763703`

- analyzer: **No issues found**
- **198 normal test PASS**
- **M0–M47 canonical PASS**
- artifacts: **0**
- PR mergeable=true

İlk PR run `34691443880` analyzer'da 5 public-export hatasıyla kırmızıydı. Gerçek log incelendi; M47 public shim'e `StadiumFacilityState` ve `TrainingGroundFacilityState` exportları eklenerek kök neden düzeltildi. Sonraki analyzer/test/canonical run'ları yeşil oldu.

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

## Merge ve post-merge kanıtı

PR #50 explicit kullanıcı onayı sonrası squash merge edildi.

Merge SHA: `dc26c2782026c6823c91d05015f4f507a7bac2f6`
Post-merge main CI: `34693305775` — **SUCCESS**

- analyzer: `No issues found!`
- **198 normal/non-canonical test PASS**
- **M0–M47 canonical PASS**
- artifacts: **0**
- `main` HEAD merge anında merge SHA ile eşleşti

M47 artık **CLOSED / MERGED / PASS** ve `main` üzerindedir.
