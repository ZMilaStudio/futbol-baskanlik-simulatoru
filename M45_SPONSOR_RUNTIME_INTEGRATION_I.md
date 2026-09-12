# M45 — Sponsor Runtime Integration I

Durum: **PR-VERIFIED / NOT MERGED**
Tarih: 12 Eylül 2026
PR: #48
Branch: `feat/m45-sponsor-runtime-integration`

## Amaç

M42 Sponsor System çekirdeğini gerçek PresidentDomain sezon runtime'ına bağlamak; sponsor kontratlarını ve ödemelerini gerçek ekonomi, başkan turnover'ı ve save/resume continuation zincirine taşımak.

## Temel mimari kararı

M42 sponsor state'i continuation-critical'dır:
- aktif çok yıllı kontratlar,
- `nextSeasonIndex`,
- kümülatif ödenmiş sponsor geliri.

Bu state mevcut `PresidentDomainMemoryCheckpoint` içinde olmadığı için sessizce başka bir checkpoint'e sıkıştırılmadı. M45 explicit composite checkpoint ekler:

- `SponsorPresidentRuntimeCheckpoint`
  - `PresidentDomainMemoryCheckpoint domain`
  - `SponsorRuntimeCheckpoint sponsor`

Season cursor'ları birebir eşleşmek zorundadır ve sponsor kontratlarının kulüp ID'leri gerçek world kulüpleriyle doğrulanır.

## Composite save

`SponsorPresidentRuntimeSaveCodec` eklendi.

- format: `zmila-fbs-sponsor-president-runtime`
- save version: 1
- mevcut `PresidentDomainMemorySaveCodec` ve `SponsorRuntimeSaveCodec` yeniden kullanılır
- iki component envelope tek checksummed composite payload altında tutulur
- deterministik canonical JSON encoding kullanılır

Acceptance testinde encode → decode → encode byte-for-byte aynı doğrulandı.

## Gerçek sezon runtime entegrasyonu

Public opt-in giriş noktası:
- `lib/sponsor_runtime_integration.dart`

Ana wrapper:
- `SponsorRuntimeCareerEngine`

Legacy `PresidentDomainCareerEngine` public davranışı değiştirilmedi.

### İlk sezon

İlk sezon sponsor context'i legacy PresidentDomain başlangıç semantiğiyle aynı deterministik state'lerden üretilir:
- initial president: `PresidentProfileGenerator.generateInitial(...)`
- management profile: `PresidentManagementProfileGenerator`
- fan: `FanState.initial(clubId)`
- media credibility: 65

Böylece sponsor sistemi ilk sezondan itibaren gerçek economy akışında çalışır.

### Resume sezonları

Her resume sezonunda sponsor kararı doğrudan saved PresidentDomain state'inden alınır:
- current president management profile,
- current fan state,
- current media state.

Dolayısıyla gerçek başkan turnover'ı kontrat yenileme anındaki sponsor kararını etkiler.

## Üç lig / tek sezon coordinator

`WorldCareerEngine` ekonomi motorunu her lig için ayrı çağırdığı için bir sezonda 3 economy call vardır.

Naif M42 çağrısı sponsor cursor'ını sezonda üç kez ilerletebilirdi. M45 bunun yerine season-scoped `_SponsorSeasonEconomyEngine` coordinator kullanır:
- üç lig çağrısını aynı sponsor season cursor altında toplar,
- her kulüp bir sezonda yalnız bir kez işlenebilir,
- unknown/duplicate club fail eder,
- 48 kulüp tamamlanmadan global sponsor checkpoint alınamaz,
- lig çağrılarındaki gerçek güncel `Club.strength` ve gerçek `SeasonReport.table` pozisyonları kullanılır,
- sezon sonunda tek global 48-kulüp sponsor checkpoint üretilir.

## Double-counting koruması

`BasicEconomyEngine.simulateSeason` mevcut `sponsorRevenueByClub` parametresini legacy strength-only sponsor gelirinin **replacement** kaynağı olarak kullanır.

M45 M42 sponsor ödemesini bu parametre üzerinden geçirir. Böylece sponsor geliri legacy sponsor gelirinin üstüne eklenmez.

Ayrıca M45 economy wrapper başka bir `sponsorRevenueByClub` override ile birlikte çağrılırsa fail eder; iki sponsor kaynağının sessizce çakışmasına izin verilmez.

Acceptance testi her 48 kulüp için:
- runtime sponsor `revenueByClub[clubId]`
- gerçek `ClubFinanceSeason.sponsorRevenue`

alanlarının birebir aynı olduğunu doğrular.

## Başkan turnover ve kontrat yaşam döngüsü

Çok yıllı aktif kontrat yeni başkan geldiğinde bozulmaz; M42 kontratın kendi süresi dolana kadar aynı contract signature ile devam eder.

Kontrat bittiğinde yeni teklif/kontrat mevcut başkan profiliyle seçilir ve `acceptedByPresidentId` o anda görevde olan başkana eşit olur.

Final canonical 4-sezon / electionInterval=1 senaryosu:
- kontrat sayısı: **48 / sezon**
- turnover boyunca korunmuş kontrat örneği: **2**
- yeni başkan tarafından yenilenen kontrat: **57**

Bu iki olay da canonical gate tarafından `> 0` zorunluluğuyla korunur.

## Save/resume parity

M45 2 + 2 sezon save/resume senaryosu ile uninterrupted 4 sezonu karşılaştırır.

Zorunlu eşitlikler:
- final composite checkpoint encoded equality,
- her sezon sponsor boundary signature equality,
- contract lifecycle,
- sponsor revenue,
- PresidentDomain continuation state.

Final canonical:
- `finalCheckpointMatch=true`
- `boundaryMatch=true`

## Test kapsamı

M45 5 normal acceptance testi ekler:
1. sponsor geliri gerçek economy satırında replacement olarak kullanılır,
2. multi-year kontrat gerçek başkan turnover'ı boyunca korunur,
3. expired kontrat renewal'ı current president profile ile yapılır,
4. composite save deterministik round-trip eder,
5. 2 + 2 save/resume = uninterrupted 4 sezon.

Normal test toplamı: **189**.

## Canonical gate

`tool/run_m45_sponsor_runtime_integration.dart` eklendi ve `.github/workflows/m0-tests.yml` zinciri M0–M45'e uzatıldı.

Final code-bearing canonical çıktı:
- seasons=4
- contractsPerSeason=48
- revenueBySeason=`291473844.75,294374236.50,295295994.50,299016546.25`
- cumulativeRevenue=`1180160622.00`
- preservedAcrossTurnover=2
- renewedByNewPresident=57
- composite save bytes=730919
- financeReplacementMatch=true
- finalCheckpointMatch=true
- boundaryMatch=true
- PASS

## CI kanıtı

Code-bearing HEAD: `55433d670a5e875d2587751cbc66eaf5fe6d26c5`
Run: `34684029096`

- test job `103527769818`: **SUCCESS**
- analyzer: `No issues found!`
- **189 normal/non-canonical test PASS**
- canonical job `103527769663`: **SUCCESS**
- **M0–M45 canonical PASS**
- artifacts: **0**
- iki job da 7 dakika sınırının altında

Önceki acceptance-only run `34683829753` de analyzer clean + 189 test PASS + M0–M44 canonical PASS verdi.

## Sonuç

M45 kod ve canonical kabul kriterleri açısından **PR-VERIFIED / NOT MERGED**. Sponsor sistemi artık opt-in runtime yolunda gerçek PresidentDomain sezon akışına, gerçek ekonomi sponsor satırına, başkan turnover/renewal yaşam döngüsüne ve composite save/resume continuation zincirine deterministik biçimde bağlıdır.
