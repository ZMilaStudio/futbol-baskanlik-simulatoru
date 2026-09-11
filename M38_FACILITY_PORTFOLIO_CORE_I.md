# M38 — Facility Portfolio Core I

Durum: **PR doğrulandı / henüz `main` üzerinde CLOSED değil**

PR: `#41` — `M38: facility portfolio core with stadium and training ground`

Branch: `feat/m38-facility-portfolio-core`

Canonical seed: `20260903`

## Amaç

M33–M37 ile academy için kurulan tesis altyapısını, eski simülasyon semantiğini bozmadan gerçek bir tesis portföyüne genişletmek.

M38 kapsamı iki yeni tesis türüdür:

- stadium
- training ground

Başkanın stadium/training için otomatik yatırım kararı M38 kapsamına dahil değildir. Bu milestone yalnız facility portfolio core, gerçek runtime etkisi, persistence ve save/resume parity kurar.

## Facility modeli

Her üç tesis türü 48 kulübün tamamı için ayrı state olarak tutulur:

- academy
- stadium
- training ground

Stadium ve training ground level aralığı: `0..5`.

Level `0` neutral/legacy davranıştır. Yeni facility-aware runtime açıkça kullanılmadıkça eski public simulation davranışı değiştirilmez.

## Stadium

Upgrade maliyetleri:

- L1: `5M`
- L2: `10M`
- L3: `18M`
- L4: `28M`
- L5: `40M`

Gerçek etkisi mevcut ekonomi motorundaki `matchdayRevenue` hattına bağlanır.

Multiplier:

- L0: `10000 bps` — legacy davranış
- her level: `+750 bps`

Canonical L1 sonucu:

- matchday revenue: `3.49M → 3.75M`
- revenue raised: `true`

## Training ground

Upgrade maliyetleri:

- L1: `4M`
- L2: `8M`
- L3: `14M`
- L4: `22M`
- L5: `32M`

Gerçek etkisi offseason oyuncu gelişim hattına bağlanır.

Multiplier:

- L0: `10000 bps` — legacy davranış
- her level: pozitif gelişim delta'sına `+500 bps`

Negatif/yaşa bağlı gerileme artırılmaz ve tersine çevrilmez.

Canonical L1 sonucu:

- player: `y_t3_05_s4`
- ability: `57.4905 → 57.5290`
- development raised: `true`

## Finansman kuralları

Stadium ve training-ground upgrade'leri mevcut gerçek club cash state'ini kullanır.

Kurallar:

- upgrade maliyeti cash'ten tam olarak düşer
- debt otomatik artırılmaz
- yetersiz nakitte upgrade uygulanmaz
- diğer tesis state'leri korunur
- `totalInvestmentSpent` gerçek harcamayı takip eder

Canonical yatırım:

- club: `t3_05`
- checkpoint: season `8`
- stadium: `0 → 1`
- training ground: `0 → 1`
- total spend: `9.00M`
- immediate cash delta: `9.00M`
- debt unchanged: `true`

## Persistence / save versioning

`FacilityRuntimeCheckpoint` artık üç facility listesi taşır:

- `academyFacilities`
- `stadiumFacilities`
- `trainingGroundFacilities`

Facility save version:

- önceki current version: `v1`
- M38 current version: `v2`

v2 payload:

- world save
- academy facilities
- stadium facilities
- training-ground facilities
- total investment spent

Migration:

- `v0 → v1 → v2`
- `v1 → v2`

Eski save'ler için stadium ve training-ground state'leri kulüp başına level `0` oluşturulur; böylece eski save davranışı neutral kalır.

Canonical:

- save version: `2`
- save bytes: `217572`
- v1 migration neutral: `true`
- direct vs save-load resume: `true`

## Legacy zinciri

Aynı PR CI koşusunda M33–M37 runner'ları yeniden PASS oldu.

Özellikle:

- M34 gerçek cash-funded academy persistence: PASS
- M35 academy runtime youth integration: PASS
- M36 president-driven academy investment: PASS
- M37 president facility decision loop / turnover replanning: PASS

M34 save formatı yeni portfolio payload nedeniyle `v2` ve canonical `217572 bytes` oldu; academy davranışı ve resume parity değişmedi.

## Testler

Yeni M38 testleri:

1. 48 kulüp için neutral stadium + training portfolio oluşur.
2. Stadium upgrade gerçek cash kullanır ve gerçek matchday revenue'yu artırır.
3. Training-ground upgrade gerçek pozitif player-development delta'sını artırır.
4. Full portfolio save/load/resume deterministik kalır.
5. v1 facility save v2'ye neutral yeni tesislerle migrate olur.

PR CI toplamı:

- analyzer: `No issues found!`
- normal/non-canonical tests: **152 PASS**
- M0–M38 canonical runner zinciri: **PASS**
- artifacts: **0**

## Canlı PR CI kanıtı

Code-bearing HEAD:

`5bbcfa85b1abc9f56bdef7704577cc46e20636b8`

Run:

`34620636024`

Jobs:

- `test` — `103333639427` — **SUCCESS**, yaklaşık `2m54s`
- `canonical` — `103333639253` — **SUCCESS**, yaklaşık `3m33s`

Her iki job da sabit `7 dk` timeout sınırının rahat altındadır.

`actions/upload-artifact` kullanılmadı; artifact sayısı `0`.

## Kapanış koşulu

Bu dokümanın mevcut durumu PR seviyesinde doğrulanmıştır. M38 ancak:

1. kullanıcı açık merge onayı verdikten,
2. PR #41 merge edildikten,
3. post-merge `main` CI M0–M38 dahil SUCCESS olduktan,
4. artifact sayısı `0` doğrulandıktan

sonra **CLOSED / PASS on main** sayılacaktır.
