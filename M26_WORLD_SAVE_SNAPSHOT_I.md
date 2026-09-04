# M26 — World Save Snapshot I

## Amaç

M25'in sürümlü save/load sözleşmesini, `WorldCareerEngine`'in gerçekten sahip olduğu sezon-sınırı dünya state'ine genişletmek.

M26 platform dosya sistemi veya tam advanced-world save değildir. İlk hedef, core world state'in kaydedilip geri yüklendikten sonra kesintisiz simülasyonla birebir aynı deterministik kariyeri sürdürebildiğini kanıtlamaktır.

## State sahipliği sınırı

M26 yalnız `WorldCareerEngine` tarafından sahip olunan state'i snapshot'a alır:

- orijinal `SimulationConfig`
- tamamlanan sezon sayısı / next season index
- 48 base club
- 3 lig × 16 kulüp next-season üyeliği
- next-season player/lifecycle state
- 48 kulübün next-season finance state'i

Aşağıdaki state farklı hook/controller katmanlarına ait olduğu için bilinçli olarak M26 dışında tutulmuştur:

- player contracts
- transfer installment obligations
- active loan agreements
- manager pool / assignments
- fan/media/promise memory
- president/reputation/election timeline

Bunlar M27+ advanced runtime snapshot milestone'larında ele alınacaktır.

## Kritik offseason problemi

Eski `WorldCareerEngine.simulate()` davranışında:

```text
hasNextSeason = offset < seasonCount - 1
```

Bu nedenle çağrının son sezonundan sonra offseason hazırlanmaz. Son sezonda:

- promotion/relegation
- player lifecycle
- retirement/youth intake
- transfer window
- next-season finance/window state

yürütülmez.

Bu davranış M0–M25 regresyon yüzeyinin parçasıdır ve değiştirilmemiştir.

M26 için ayrı checkpoint-capable yol eklendi. Bu yol segmentin son sezonundan sonra da offseason hazırlayarak gerçek **next-season opening state** üretir.

Sonuç:

- `WorldCareerEngine.simulate(...)` → eski davranış korunur.
- `WorldCareerEngine.simulateWithCheckpoint(...)` → son segment offseason'u hazırlanır.
- `WorldCareerEngine.resume(...)` → checkpoint'teki next-season opening state'ten devam eder.

## Yeni domain

### `WorldCheckpoint`

Taşınan alanlar:

- `SimulationConfig config`
- `int completedSeasons`
- `List<Club> baseClubs`
- `List<WorldLeague> nextSeasonLeagues`
- `List<Player> nextSeasonPlayers`
- `List<ClubFinanceState> nextSeasonFinanceStates`

`nextSeasonIndex = config.seasonIndex + completedSeasons`.

Checkpoint validation:

- completed seasons negatif olamaz
- tam 48 benzersiz kulüp gerekir
- tam 3 lig gerekir
- her lig 16 kulüptür
- 48 kulübün tamamı liglerde tam bir kez bulunur
- oyuncu ID'leri benzersizdir
- aktif oyuncular bilinen bir kulübe bağlıdır; free agent istisnası korunur
- yaş/ability/potential state'i geçerlidir
- tam 48 finance state gerekir
- her kulübün finance state'i tam bir kez bulunur

### `WorldCareerSimulationResult`

- `WorldCareerReport report`
- `WorldCheckpoint checkpoint`

## Save formatı

Yeni codec:

`WorldSaveCodec`

Format:

`zmila-fbs-world`

Current save version:

`1`

Envelope:

- `format`
- `saveVersion`
- `payload`
- `checksum`

Payload:

- full simulation config
- completed seasons
- base clubs
- next-season leagues
- next-season players
- next-season finance states

Para değerleri integer minor unit olarak kaydedilir.

Checksum mevcut `SaveChecksum` canonical JSON + FNV-1a 32-bit mekanizmasını kullanır. Bu yalnız accidental corruption detection içindir; kriptografik imza veya anti-cheat değildir.

## Versiyonlama ve hata davranışı

M26 doğrular:

- deterministic canonical encode
- encode → decode → encode birebir eşitliği
- malformed JSON için explicit failure
- checksum bozulmasının payload yüklenmeden reddi
- checksum-valid unsupported future version'ın güvenli reddi
- sentetik `v0 → v1` migration yolu

## Deterministik devam kabul testi

Canonical seed:

`20260903`

Karşılaştırma:

```text
20 sezon checkpoint-capable uninterrupted world
=
8 sezon → world save → load → 12 sezon resume
```

Karşılaştırılan alanlar:

- season index
- league season seed
- champion
- her fixture sonucu
- home/away goals
- expected goals
- match seed
- transfer history
- retirement
- youth intake
- finance window state
- promotion/relegation movement
- next-season league membership
- final player state
- final finance state
- final club strength
- final next-season checkpoint

Tamamı birebir eşittir.

## Regresyon kanıtı

Özel test, eski `WorldCareerEngine.simulate()` yolunun çağrının son sezonunda offseason üretmediğini doğrular. M26 checkpoint API'si eklenirken mevcut M5+ world semantiği sessizce değiştirilmemiştir.

İlk analyzer hatası M26 davranışından kaynaklanmadı. Public barrel export yeniden düzenlenirken mevcut `WorldCareerValidator` export'u yanlışlıkla atlandı; yalnız bu export geri kondu ve davranış koduna dokunulmadı.

## Canonical runner sonucu

CI run:

`33930202369`

Canonical seed `20260903`:

- analyzer: PASS
- normal/non-canonical tests: `94` PASS
- M0–M18 runners: PASS
- combined M19–M24 canonical runner: PASS
- M25 save/load continuation: PASS
- M26 world save continuation: PASS
- artifact: `0`
- timeout: `5 dk` altında PASS

M26 runner:

- save version: `1`
- checksum: `0645c8a5`
- save size: `187664 bytes`
- split: `8 + 12`
- loaded next season index: `8`
- season replay match: `true`
- final players match: `true`
- final finance match: `true`
- final leagues match: `true`
- next checkpoint match: `true`
- synthetic legacy fixture: `v0 → v1`

## Kabul sonucu

**M26 davranış ve deterministik continuation kriterleri PASS.**

Final merge öncesinde bu dokümantasyon HEAD'i aynı tam CI kapısından yeniden geçirilecektir.

## Sonraki yön

M27 adayı:

> **Advanced World Runtime Snapshot I**

İlk mantıklı state sahipleri:

1. player contracts
2. transfer installment obligations
3. active loan agreements
4. manager pool / assignments

President/reputation/election state kapsam büyüklüğüne göre M27 veya ayrı M28 milestone'una bırakılabilir.
