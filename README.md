# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

Temel oyun kimliği: **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** CI doğrulamasında

Flutter bağımlılığı henüz yoktur. Amaç maç, sezon ve uzun kariyer sistemlerini mobil arayüzden önce otomatik testlerle doğrulamaktır.

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
- deterministik sezonlar arası kulüp gücü evrimi
- kariyer raporu ve validator
- aynı seed ile aynı kariyer sonucu

M1'de oyuncu, transfer, ekonomi, teknik direktör, taraftar, UI ve APK henüz yoktur.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_batch.dart 100
dart run tool/run_m1_career.dart 20260903
```

## CI prensibi

GitHub Actions yalnızca Dart bağımlılıklarını kurar, analiz/testleri ve headless simülasyon koşularını çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
