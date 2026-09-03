# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

Temel oyun kimliği: **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** PASS
- **M4 — Basit Transfer Pazarı:** PASS
- **M5 — 48 Kulüp / 3 Lig:** PASS
- **M6 — Teknik Direktör Sistemi:** sıradaki milestone

Flutter bağımlılığı henüz yoktur. Amaç maç, sezon, oyuncu yaşam döngüsü, ekonomi, transfer ve başkanlık sistemlerini mobil arayüzden önce otomatik testlerle doğrulamaktır.

## M0–M4 kısa özet

M0 ile 8 kulüplük deterministik lig ve maç motoru; M1 ile 20 sezon kariyer yaşam döngüsü; M2 ile oyuncu yaşlanması, emeklilik ve genç üretimi; M3 ile nakit/borç/gelir/gider ekonomisi; M4 ile doğrudan bonservisli transfer pazarı doğrulandı.

Kabul edilen M4 seed `20260903` baseline'ı 20 sezonda `32` transfer, `161,68M` transfer hacmi, `96,38M` final nakit, `58,61M` final borç ve `148` final oyuncu üretir. Validation issue `0`dır.

## M5 — 48 Kulüp / 3 Lig

M5 ile çekirdek gerçek oyun ölçeğine çıkarıldı:

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- kulüp başına 30 lig maçı
- 240 maç/lig
- 720 maç/dünya sezonu
- 20 sezonda 14.400 lig maçı
- 864 başlangıç oyuncusu
- 3'er takım terfi/düşme
- 19 sezon arası geçişte toplam 228 lig hareketi
- ortak oyuncu yaşam döngüsü
- ortak 48 kulüplük transfer pazarı
- lig seviyesine göre gelir ve maliyet ölçekleri
- `WorldCareerEngine`, rapor ve validator
- 20 sezon world sanity guard'ları

Kabul edilen geçici lig ekonomi ölçekleri:

| Lig | Gelir | Maliyet |
|---|---:|---:|
| Taç Ligi | %100 | %100 |
| Birlik Ligi | %90 | %85 |
| Ufuk Ligi | %80 | %75 |

`BasicEconomyEngine` varsayılan olarak `%100 / %100` kaldığı için M0–M4 baseline'ları değişmedi.

### Kabul edilen M5 baseline — seed `20260903`

- 20 sezon
- 14.400 maç
- 864 başlangıç oyuncusu
- 906 final oyuncusu
- 228 lig hareketi
- 71 transfer
- `637,91M` transfer hacmi
- `8,98M` ortalama bonservis
- `862,25M` final toplam nakit
- `647,04M` final toplam borç
- `569,03M` toplam acil finansman
- 35 farklı kulüp transfer pazarına katıldı
- 10 farklı Taç Ligi şampiyonu
- validation issue `0`

Final finansal sağlık: 16 `veryStrong`, 14 `solid`, 8 `balanced`, 10 `debtCrisis`.

Final ortalama güç: Taç Ligi `72,01`, Birlik Ligi `65,54`, Ufuk Ligi `59,21`.

M5 ekonomi değerleri nihai oyun dengesi değildir. Özellikle final Ufuk Ligi nakit birikiminin yüksek olması, gerçek oyuncu sözleşmesi/maaş sistemi eklendiğinde yeniden kalibre edilecek açık denge notudur.

Ayrıntılar: `M5_48_KULUP_3_LIG.md`.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_batch.dart 100
dart run tool/run_m1_career.dart 20260903
dart run tool/run_m2_player_career.dart 20260903
dart run tool/run_m3_economy_career.dart 20260903
dart run tool/run_m4_transfer_career.dart 20260903
dart run tool/run_m5_world_career.dart 20260903
```

## CI prensibi

GitHub Actions yalnız Dart bağımlılıklarını kurar, analiz/testleri ve headless simülasyon koşularını çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

Son M5 PR kalite kapısında:

- `dart analyze`: PASS
- test: `23/23 PASS`
- M0–M5 runner'ları: PASS
- M5 validation: `0`
- artifact: `0`

## Sıradaki milestone

**M6 — Teknik Direktör Sistemi.**

Amaç başkanlık kimliğinin ana ayrımını gerçek sisteme taşımaktır: teknik direktör profilleri, işe alma/kovma, bütçe ve transfer beklentileri, genç oyuncuya yaklaşım, yönetim ilişkisi ve takım performansına etkisi. Oyuncu saha içi taktik yönetmeyecek; teknik direktör özerk futbol karakteri olacak.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
