# M46 — Sponsor + Crisis Runtime Composition I

Durum: **MERGE-READY / NOT MERGED**
Tarih: 12 Eylül 2026
PR: #49

## Amaç

M45 sponsor-aware PresidentDomain runtime ile M44 kriz boundary entegrasyonunu aynı kariyer/sezon continuation yolunda birleştirmek; aynı sezonu iki ayrı top-level runtime ile tekrar simüle etmeden sponsor ekonomisi → PresidentDomain → kriz → sonraki sezon sponsor context zincirini deterministik hale getirmek.

## Mimari karar

M46 ayrı bir save formatı yaratmaz. M45 `SponsorPresidentRuntimeCheckpoint` zaten iki continuation-critical state'i birlikte taşır:
- `PresidentDomainMemoryCheckpoint domain`
- `SponsorRuntimeCheckpoint sponsor`

M44 kriz motoru stateless'tir ve etkilerini doğrudan PresidentDomain continuation state'ine yazar. Bu nedenle kriz sonrası domain checkpoint, mevcut M45 composite checkpoint içine yeniden yerleştirilir; save-version bump gerekmez.

## Tek sezon composition sırası

Birleşik runtime her sezon şu sırayı uygular:
1. M45 sponsor-aware economy coordinator 48 kulübün sponsor kontrat/gelirini gerçek economy çağrılarında çözer.
2. PresidentDomain sezonu bir kez tamamlanır ve next-season domain checkpoint oluşur.
3. M44 `CrisisRuntimeIntegrationEngine.apply(...)` tamamlanmış domain checkpoint'e uygulanır.
4. Kriz etkileri finance/fan/media continuation state'ine yazılır; debt-preservation kuralı korunur.
5. Sponsor state değiştirilmeden korunur ve kriz-adjusted domain ile yeniden `SponsorPresidentRuntimeCheckpoint` oluşturulur.
6. Sonraki sezonda sponsor sistemi current president + kriz-adjusted fan/media context'ini okur.

Bu akış aynı sezonun world/PresidentDomain simülasyonunu iki kez çalıştırmaz.

## Legacy / neutral parity

Kriz etkisiz konfigürasyonda birleşik runtime M45 ile birebir parity vermek zorundadır.

Acceptance testi:
- composite checkpoint equality,
- sponsor boundaries,
- sponsor contracts/revenue,
- PresidentDomain continuation state
alanlarını karşılaştırır.

Final canonical: `neutralM45Parity=true`.

## Sponsor-aware finance sonrası kriz

Kriz M45 sponsor-aware ekonomi tamamlandıktan sonra uygulanır. Böylece kriz context'i gerçek sponsor replacement gelirini içeren finance state'i görür.

Korunan invariantlar:
- sponsor revenue double-counting yok,
- sponsor contract lifecycle kriz nedeniyle sessizce değişmez,
- debt gizlice artırılmaz,
- kriz cash/fan/media etkileri bounded kalır.

Final canonical:
- `financeReplacementMatch=true`
- `sponsorStatePreserved=true`
- `debtPreserved=true`

## Sonraki sezon sponsor context etkisi

M46 acceptance testi kriz sonrası fan/media state'inin bir sonraki sponsor sezonuna gerçekten taşındığını doğrular. Böylece kriz yalnız raporlanan bir olay değildir; gelecekteki sponsor teklif/renewal context'ini etkileyen gerçek continuation state üretir.

## Save/resume parity

Mevcut `SponsorPresidentRuntimeSaveCodec` aynen kullanılır.

2 + 2 sezon save/resume ile uninterrupted 4 sezon karşılaştırılır:
- final encoded composite checkpoint equality,
- sezon boundary signature equality,
- sponsor contract/revenue state,
- kriz-adjusted domain continuation state.

Final canonical:
- `saveResumeMatch=true`
- `boundaryMatch=true`
- save bytes=`731311`

## Test kapsamı

M46 4 normal acceptance testi ekler:
1. neutral kriz composition M45 sponsor runtime'ı aynen korur,
2. kriz sponsor-aware ekonomi sonrasında uygulanır ve sponsor state'i korunur,
3. kriz-adjusted fan/media sonraki sponsor context'ine taşınır,
4. 2 + 2 save/resume = uninterrupted 4 sezon.

Normal test toplamı: **193**.

## Canonical gate

`tool/run_m46_sponsor_crisis_runtime_composition.dart` ve `.github/workflows/m0-tests.yml` içindeki `Run M46 sponsor crisis runtime composition` step'i kalıcı kabul kapısıdır.

Final canonical seed `20260903` çıktısı:
- seasons=4
- contractsPerSeason=48
- sponsorRevenueBySeason=`291473844.75,294173445.25,295481959.00,299331748.00`
- cumulativeSponsorRevenue=`1180460997.00`
- crises=`46/192`
- `forcedWiring=true`
- `debtPreserved=true`
- `sponsorStatePreserved=true`
- `financeReplacementMatch=true`
- `neutralM45Parity=true`
- `saveResumeMatch=true`
- `boundaryMatch=true`
- saveBytes=`731311`
- PASS

## Final PR CI kanıtı

Kod + canonical gate HEAD: `afd0381139356eff59d399023a169e10bf60ffff`
PR CI `34685617385` — **SUCCESS**:
- analyzer: `No issues found!`
- **193 normal/non-canonical test PASS**
- canonical job SUCCESS
- **M0–M46 canonical PASS**
- M46 canonical PASS
- artifact **0**
- test job yaklaşık 3:13
- canonical job yaklaşık 4:51
- iki job da 7 dakika sınırının altında

Bu doküman ve genel özet eklendikten sonra docs-inclusive exact HEAD CI yeniden doğrulanacaktır.

## Sonuç

M46 kod ve davranış olarak merge-ready durumdadır. Sponsor ve kriz sistemleri artık aynı opt-in top-level runtime içinde tek sezon/world simülasyonu üzerinden compose edilir; kriz-adjusted continuation state gelecekteki sponsor context'ine taşınır ve mevcut M45 composite save formatı ile deterministik olarak resume edilebilir.
