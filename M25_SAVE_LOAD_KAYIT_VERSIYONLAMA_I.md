# M25 — Save/Load + Kayıt Versiyonlama I

## Amaç

M25'in amacı Android dosya sistemi veya UI save-slot ekranı yapmak değil; uzun kariyer için **sürüm kontrollü, deterministik ve migration uygulanabilir kayıt sözleşmesini** saf Dart çekirdeğinde kanıtlamaktır.

Bu milestone bilinçli olarak temel `CareerEngine` sezon-sınırı state'i ile sınırlıdır. M24'ün tam 48-kulüp world state'i henüz serialize edilmez.

## Ana karar: checkpoint bir sonraki sezonun başlangıcıdır

`CareerCheckpoint` aşağıdaki devam state'ini taşır:

- orijinal `SimulationConfig`
- kariyer başlangıç tarihi
- tamamlanan sezon sayısı
- kulüp başlangıç güç baseline'ları
- bir sonraki sezonun kulüp state'i

Türetilen alanlar:

- `nextSeasonIndex`
- `nextSeasonStartDate`

Bu semantik sayesinde checkpoint yüklendiğinde bir sonraki sezon tekrar veya atlama olmadan başlar.

## CareerEngine API

Mevcut API korunur:

```dart
CareerReport simulate(...)
```

Yeni API:

```dart
CareerSimulationResult simulateWithCheckpoint(...)
CareerSimulationResult resume({
  required CareerCheckpoint checkpoint,
  required int seasonCount,
})
```

`simulate()` yeni checkpoint yoluna delege eder ama eski çağrı sözleşmesini ve M1 baseline davranışını değiştirmez.

## Save formatı — v1

Envelope:

```text
format      = zmila-fbs-career
saveVersion = 1
payload     = {...}
checksum    = 8 haneli hex
```

V1 payload:

- tam temel `SimulationConfig`
- `careerStartDate`
- `completedSeasons`
- `baselineStrengths`
- `nextSeasonClubs`

JSON canonical olarak yazılır; map anahtarları deterministik sıraya sokulur. Encode → decode → tekrar encode aynı byte-string sonucunu üretir.

## Checksum

Checksum mevcut stabil FNV-1a 32-bit hash üzerinden üretilir.

Amaç:

- eksik/bozuk kayıt verisini fark etmek
- payload üzerinde kazara değişikliği yakalamak

Bu checksum **kriptografik imza, anti-cheat veya güvenlik garantisi değildir**. Tehdit modeli gerektirirse daha güçlü doğrulama daha sonra eklenebilir.

## Güvenli yükleme hataları

`SaveLoadFailure` açık hata sınıfları:

- `malformedJson`
- `invalidEnvelope`
- `checksumMismatch`
- `unsupportedVersion`
- `migrationFailed`
- `invalidPayload`

Checksum doğrulaması migration'dan önce yapılır. Desteklenenden yeni, checksum-valid bir kayıt güvenli şekilde `unsupportedVersion` ile reddedilir.

## Migration

İlk migration yolu:

```text
v0 → v1
```

Repository içinde sentetik legacy fixture vardır:

`test/fixtures/m25_save_v0.json`

V0 fixture eski alan adlarını kullanır; codec bunu V1 checkpoint yapısına dönüştürür ve yeniden encode edildiğinde `saveVersion=1` üretir.

## En kritik kabul testi

Canonical seed:

`20260903`

İki yol karşılaştırılır:

```text
A) 20 sezon kesintisiz
B) 8 sezon → save → load → 12 sezon resume
```

Karşılaştırma yalnız final şampiyona bakmaz. Resume edilen 12 sezon için:

- season index
- season seed
- champion
- club strengths
- her fixture'ın skorları
- expected goals
- match seed
- final report club state
- sonraki checkpoint club state

birebir eşit olmak zorundadır.

Sonuç:

```text
Season replay match: true
Final report clubs match: true
Next checkpoint clubs match: true
```

## Canonical runner sonucu

Runner:

```bash
dart run tool/run_m25_save_load.dart 20260903
```

Kabul çıktısı:

```text
Save version: 1
Checksum: 536de64d
Save bytes: 1039
Split: 8 + 12 seasons
Loaded next season index: 8
Loaded next season date: 2034-07-01
Season replay match: true
Final report clubs match: true
Next checkpoint clubs match: true
Legacy fixture migrated to: v1
```

## CI kanıtı

Runner dahil PR koşusu:

`33925868414`

Sonuç:

- analyzer PASS
- `87` normal/non-canonical test PASS
- 6 M25 save/load testi PASS
- M0–M18 runner PASS
- combined M19–M24 canonical runner PASS
- M25 save/load runner PASS
- M24 canonical sonucu değişmedi
- artifact `0`
- 5 dakikalık timeout içinde PASS

## Bilinçli kapsam dışı

M25 henüz şunları save etmez:

- 48 kulübün tam world/league assignment state'i
- oyuncu havuzu ve yaş/lifecycle state'i
- gerçek kulüp finans state'i
- oyuncu kontratları
- kiralık ve transfer taksit yükümlülükleri
- manager assignment/history
- fan/media/promise state
- president/election/profile timeline
- Android dosya sistemi
- cloud save
- otomatik/yedek save slot UI'sı
- encryption / anti-cheat

Dolayısıyla M25'i **tam oyun save sistemi** olarak tanımlamak yanlıştır. M25 kayıt formatı, sürümleme, checksum, migration ve deterministic continuation temelini kanıtlar.

## Sonraki yön — M26

Önerilen sonraki milestone:

**M26 — World Save Snapshot I**

Amaç sezon sınırındaki save snapshot kapsamını gerçek dünya state'ine genişletmektir. İlk genişleme için öncelik:

- lig/kulüp assignment
- club finance
- player roster/lifecycle
- contracts
- transfer installment/loan obligations
- manager assignment

President/reputation zinciri aynı milestone'a sığdırılmayacaksa ayrı takip milestone'una bırakılabilir. Temel kabul kuralı değişmez:

> **save → load → devam, aynı seed'deki kesintisiz simülasyonla aynı sonucu üretmelidir.**
