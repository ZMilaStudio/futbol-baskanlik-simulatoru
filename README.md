# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

Temel oyun kimliği: **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** PASS
- **M4 — Basit Transfer Pazarı:** PASS
- **M5 — 48 Kulüp / 3 Lig:** sıradaki milestone

Flutter bağımlılığı henüz yoktur. Amaç maç, sezon, oyuncu yaşam döngüsü, ekonomi ve transfer sistemlerini mobil arayüzden önce otomatik testlerle doğrulamaktır.

## M0

- 8 hayalî kulüp
- 14 maç haftası / 56 maç
- çift devreli lig
- deterministik seed sistemi
- Poisson tabanlı maç motoru
- puan tablosu ve sezon validator
- 100 sezon otomatik regresyon testi

## M1

- cihaz saatinden bağımsız `GameDate`
- 20 sezonluk kariyer yaşam döngüsü
- ardışık sezon index'leri
- deterministik kariyer
- kariyer raporu ve validator

## M2

- 8 kulüp × 18 oyuncu = 144 başlangıç oyuncusu
- yaş, pozisyon, mevcut seviye ve potansiyel
- deterministik gelişim / düşüş
- emeklilik ve genç üretimi
- kadronun ilk 11 kalitesinden takım gücü
- 20 sezon oyuncu nüfusu korunum testi

## M3

- integer minor-unit tabanlı `Money`
- kulüp nakdi ve borcu
- merkezi, sponsor, maç günü ve başarı gelirleri
- oyuncu kalitesinden türetilen geçici maaş yükü
- işletme gideri ve faiz
- borç anapara geri ödemesi
- açık `emergencyBorrowing`
- finansal sağlık sınıfları
- muhasebe denklem validator'ı
- 20 sezon ekonomi sanity guard'ları

M3'ün ilk 20 sezon denemesi 1,017 milyar toplam nakit ve sıfır borç ürettiği için ekonomik olarak reddedildi. Düzeltilmiş baseline seed `20260903` için 20 sezon sonunda toplam nakit `124,28M`, toplam borç `104,43M`, toplam acil finansman `67,44M` ve sağlık dağılımı 2 `veryStrong` / 2 `solid` / 2 `balanced` / 2 `debtCrisis` oldu.

## M4

- deterministik `MarketValueModel`
- piyasa değeri ile gerçek bonservisin ayrılması
- pozisyon ihtiyacına göre transfer hedefi
- satıcı kabul fiyatı / alıcı maksimum fiyatı
- finansal baskıda satıcı fiyat esnekliği
- 2M minimum nakit rezervi
- pencere başına mevcut nakdin en fazla %35'i kadar harcama
- kulüp başına en fazla 2 satın alma
- kadro ve pozisyon satış tabanları
- doğrudan bonservis nakit hareketi
- oyuncunun kulüp değiştirmesi
- transfer sonrası takım gücünün yeniden türetilmesi
- transfer finans sürekliliği validator'ı
- 20 sezon transfer pazarı sanity guard'ı

Kabul edilen M4 baseline seed `20260903` için 20 sezonda `32` transfer, `161,68M` toplam transfer hacmi, `5,05M` ortalama bonservis, `96,38M` final toplam nakit, `58,61M` final toplam borç ve `148` final aktif oyuncu üretir. Transfer validation issue sayısı `0`dır.

M4'te kiralık, taksit, bonus, takas, satıştan pay ve gerçek oyuncu sözleşmesi/maaş pazarlığı henüz yoktur.

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
```

## CI prensibi

GitHub Actions yalnızca Dart bağımlılıklarını kurar, analiz/testleri ve headless simülasyon koşularını çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

Son M4 kalite kapısında `dart analyze` PASS, toplam `19/19` test PASS, M0–M4 runner'ları PASS, M4 sanity guard PASS ve artifact sayısı `0`dır.

## Sıradaki milestone

**M5 — 48 Kulüp / 3 Lig**: yaklaşık 48 özgün hayalî kulüp, üç lig, yükselme/düşme ve mevcut oyuncu-ekonomi-transfer çekirdeğinin gerçek oyun ölçeğine taşınması. İlk hedef yine 20 sezon deterministik headless kariyer doğrulamasıdır.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
