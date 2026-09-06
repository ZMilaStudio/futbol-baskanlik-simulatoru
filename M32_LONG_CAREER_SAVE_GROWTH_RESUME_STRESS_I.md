# M32 — Long-Career Save Growth / Resume Stress I

Tarih: 6 Eylül 2026

## Amaç

M31 ile kanıtlanan president-domain resume zincirini daha uzun kariyerde ve birden fazla save/load checkpoint’i üzerinden strese sokmak; deterministic continuation’ın bozulmadığını ve save boyutunun kontrolsüz büyümediğini kanıtlamak.

## PR / branch / CI

- PR: `#33` — `M32: long-career save resume stress`
- branch: `m32-long-career-save-resume-stress`
- final PR HEAD: `6aad9a828c7a14b307110a2c42243c79ca2ab1e6`
- final PR CI: run `34040555580`
- final PR job: `101506407496`
- PR CI sonucu: SUCCESS
- squash merge commit: `e2db172feda810173b1710a37e53c7550823ba6f`
- post-merge main CI: run `34043191414`
- post-merge main job: `101513506266`
- post-merge main CI sonucu: SUCCESS
- analyzer: PASS
- normal/non-canonical tests: `129 PASS`
- M0–M32 runner zinciri: PASS
- artifact: `0`

## Canonical stres senaryosu

Seed: `20260903`

Toplam kariyer: `30 sezon`

Split zinciri:

`6 + 7 + 9 + 8`

Checkpoint sezonları:

`6, 13, 22, 30`

Her checkpoint’te:
1. President-domain checkpoint encode edilir.
2. Save decode edilir.
3. Sonraki segment decode edilen state üzerinden resume edilir.
4. 30. sezondaki final checkpoint kesintisiz 30 sezon simülasyonuyla birebir karşılaştırılır.

Sonuç:

- completed seasons: `30`
- president states: `48`
- recent fan records: `96`
- recent media records: `96`
- final checkpoint match: `true`
- bounded save size: `true`
- repeated encode/decode idempotency: PASS
- **30-season multi-checkpoint stress: PASS**

## Save boyutu ölçümü

Canonical save byte serisi:

| Sezon | Total M32 save | Nested president | Nested compact runtime | Manager pool | Raw manager seasons |
|---:|---:|---:|---:|---:|---:|
| 6 | 793.813 | 733.821 | 715.462 | 96 | 6 |
| 13 | 898.786 | 842.262 | 823.798 | 96 | 13 |
| 22 | 741.371 | 680.032 | 661.468 | 96 | 2 |
| 30 | 762.296 | 703.242 | 684.649 | 117 | 2 |

- ilk → final büyüme: `-31.517 bytes`
- maksimum save: `898.786 bytes`
- hard guard: her checkpoint `< 1.300.000 bytes`
- growth guard: final - first `< 300.000 bytes`

Önemli sonuç: manager pool 30. sezonda `117` kişiye çıkmasına rağmen manager raw history compaction sayesinde final save 6. sezon save’inden daha küçüktür.

## M32’nin yakaladığı gerçek uzun-kariyer problemleri

### 1. Manager pool tükenmesi

İlk 30-sezon testinde simülasyon `No eligible manager available` ile kırıldı.

Çözüm:
- legacy manager havuzu gerçekten uygun aday üretemediğinde deterministic successor manager oluşturulur.
- successor kimliği, özellikleri ve giriş yaşı career seed + simulation version + season + pool index üzerinden deterministic üretilir.
- yeni manager normal runtime manager state’ine eklenir; save/load zincirinde aynen korunur.
- ilk 20 sezonun mevcut candidate davranışı korunur; replenishment yalnız gerçekten havuz tükendiğinde devreye girer.

### 2. Manager history save bloat

İlk çalışan 30-sezon continuation testinde final save büyümesi `373.417 bytes` ile M32 growth guard’ını aştı.

Kaynak:
- M28 contract/loan history’yi compact ederken manager season history M27 strict invariantı nedeniyle tam tutuluyordu.

Çözüm:
- `completedSeasons <= 20` için eski full manager history invariantı aynen korunur.
- `completedSeasons > 20` için compact runtime manager history contiguous suffix olabilir.
- M32 politikası 21+ sezonda yalnız son 2 manager season detail’ini tutar.
- all-time manager season/change sayıları `AdvancedHistorySummary` içinde korunur.
- current manager pool + current 48 assignments continuation-critical olarak tam tutulmaya devam eder.

Bu çözüm eski canonical 20-sezon semantiğini değiştirmeden uzun-kariyer save büyümesini sınırlar.

## Validation değişikliği

Dynamic future entrant manager’larda `startAge`, simülasyon kariyer başlangıcındaki biyolojik yaşı temsil eder. Bu nedenle uzun kariyerde sonradan 34–44 yaşında sisteme giren bir manager’ın `startAge` değeri 20’nin altında olabilir.

Validator artık:
- negatif `startAge` değerini reddeder,
- `retirementAge > startAge` şartını korur,
- duplicate/invalid manager ID kontrollerini korur.

## Korunan geriye uyumluluk

M32 özellikle aşağıdakileri korur:
- M27 full advanced runtime save davranışı
- M28’in 20-sezon canonical manager-history invariantı
- tüm M0–M31 canonical runner sonuçları
- save codec format/version zinciri
- 20-sezon president-domain continuation

Post-merge main CI’da bütün M0–M32 zinciri tekrar PASS olmuştur.

## Sonuç

M32 ile artık yalnız tek split değil, birden fazla gerçek save/load boundary üzerinden 30 sezonluk full president-domain continuation kanıtlanmıştır. Manager havuzu uzun kariyerde tükenmez, long-career manager history bounded tutulur ve save boyutu 30. sezonda kontrolsüz büyümez.

**M32 durumu: CLOSED / PASS / MERGED.**
