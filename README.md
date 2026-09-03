# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

Temel oyun kimliği: **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** geliştirme / CI doğrulama aşaması

Flutter bağımlılığı henüz yoktur. Amaç maç, sezon, oyuncu yaşam döngüsü ve ekonomi sistemlerini mobil arayüzden önce otomatik testlerle doğrulamaktır.

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
- deterministik sezonlar arası kulüp gücü evrimi
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
- nakit yetersizliğinde açık `emergencyBorrowing`
- finansal sağlık sınıfları
- 20 sezon ekonomi kariyeri ve muhasebe validator'ı

M3'te transfer, gerçek sözleşme/maaş pazarlığı, tesis, sponsor seçimi, taraftar, UI ve APK henüz yoktur.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_batch.dart 100
dart run tool/run_m1_career.dart 20260903
dart run tool/run_m2_player_career.dart 20260903
dart run tool/run_m3_economy_career.dart 20260903
```

## CI prensibi

GitHub Actions yalnızca Dart bağımlılıklarını kurar, analiz/testleri ve headless simülasyon koşularını çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
