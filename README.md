# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** PASS
- **M4 — Basit Transfer Pazarı:** PASS
- **M5 — 48 Kulüp / 3 Lig:** PASS
- **M6 — Teknik Direktör Sistemi:** PASS
- **M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi:** PASS
- **M8 — Gelişmiş Transfer Yapıları I / Kiralık + Taksit:** sıradaki milestone

Flutter bağımlılığı henüz yoktur. Öncelik, başkanlık simülasyonunun uzun kariyer boyunca sağlam çalışan çekirdeğini mobil arayüzden önce otomatik testlerle kanıtlamaktır.

## Dünya ölçeği

M5 ile çekirdek ilk gerçek oyun ölçeğine çıktı:

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi ve transfer pazarı

Seed `20260903` M5 baseline: 71 transfer, `637,91M` transfer hacmi, `862,25M` final nakit, `647,04M` final borç, validation `0`.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi

M6, başkanın saha içini yönetmek yerine doğru teknik direktörü seçmesi fikrini gerçek sisteme taşıdı.

- 96 deterministik teknik direktör
- 5 profil
- coaching / youth development / man management / board cooperation / budget demand
- kulüp-kadro-lig-finans bağlamına göre uyum
- maç gücüne sınırlı `-2,5...+2,5` etki
- yönetim ilişkisi
- performans / yönetim kopması / emeklilik nedeniyle görev değişimi
- kovulan hocanın başka kulüpte yeniden çalışabilmesi

Seed `20260903`: 82 görev değişimi, 60 farklı hoca, ortalama etki `+0,922`, final ortalama board relationship `72,22`, validation `0`.

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi

M7 ile geçici maaş tahmini yerine gerçek oyuncu kontratları devreye girdi.

- oyuncu bazlı başlangıç/bitiş sezonu
- gerçek yıllık maaş
- kontrat bitişinde yenileme veya serbest kalma
- serbest oyuncu havuzu ve mevki ihtiyacına göre imza
- youth intake için ilk profesyonel kontrat
- transfer sonrası yeni kontrat
- kontrat süresinin piyasa değerine etkisi
- normal bonservis pazarında free-agent ayrımı
- manager ve contract sistemlerinin aynı world engine'de bağımsız hook'larla birlikte çalışması

### M7 kabul baseline — seed `20260903`

- 20 sezon / 14.400 maç
- başlangıç kontratı `864`
- final aktif kontrat `874`
- yenileme `3.757`
- release `1.143`
- free-agent signing `776`
- final free agent `32`
- youth contract `912`
- transfer sonrası kontrat `103`
- final toplam yıllık maaş `491,27M`
- ortalama final yıllık maaş `562.091`
- bonservis transferi `103`
- transfer hacmi `868,67M`
- final nakit `1.060,80M`
- final borç `554,81M`
- emergency borrowing `428,76M`
- validation `0`

M7 sayıları nihai oyun ekonomisi değildir; CI'da geniş regresyon bantları kullanılır. Amaç sözleşme/free-agent pazarının ne donması ne de patlamasıdır.

Ayrıntı: `M7_OYUNCU_SOZLESMESI_MAAS.md`.

## Mimari

Temel yön:

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

`WorldCareerEngine` iki bağımsız genişleme noktası kullanır:

- `WorldCareerHooks`: teknik direktör gibi sezon/sportif lifecycle sistemleri
- `WorldRosterHooks`: kontrat, kadro ve gerçek maaş gibi roster/economy sistemleri

Her ikisinin varsayılanı no-op'tur. Bu sayede eski milestone baseline'ları yeni sistemler eklendiğinde de regresyon testi olarak korunur.

Deterministik RNG, cihaz saatinden bağımsız `GameDate` ve integer minor-unit `Money` temel teknik kurallardır.

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
dart run tool/run_m6_manager_career.dart 20260903
dart run tool/run_m7_contract_career.dart 20260903
```

## CI prensibi

Tek hafif GitHub Actions workflow'u kullanılır. CI:

- `dart analyze`
- tüm otomatik testler
- M0 100 sezon batch
- M1–M7 20 sezon headless runner'ları

çalıştırır.

APK/AAB, büyük binary veya `actions/upload-artifact` yoktur. Artifact hedefi `0`dır.

## Sıradaki milestone

**M8 — Gelişmiş Transfer Yapıları I: Kiralık + Taksit.**

Amaç nakdi sınırlı veya borçlu kulüpler için transfer pazarını kapatmak yerine daha akıllı finansman yolları açmaktır. İlk aşamada yalnız kiralık ve taksitli bonservis eklenecek; satın alma opsiyonu, satıştan pay, bonus, takas ve maaş paylaşımı sonraki katmanlarda değerlendirilecek.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
