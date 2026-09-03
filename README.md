# Futbol Başkanlık Simülatörü — M0 Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik simülasyon çekirdeği.

Bu repo şu anda yalnızca **M0 — Deterministik Mini Lig Çekirdeği** aşamasını içerir. Flutter bağımlılığı yoktur; amaç simülasyon mantığını UI'dan bağımsız test etmektir.

## M0 hedefi

- 8 hayalî kulüp
- 14 maç haftası
- toplam 56 maç
- çift devreli lig
- deterministik seed sistemi
- Poisson tabanlı maç motoru
- puan tablosu
- sezon doğrulama kuralları
- 100 sezon otomatik test

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_simulation.dart 20260903
dart run tool/run_m0_batch.dart 100
```

## CI prensibi

GitHub Actions yalnızca Dart bağımlılıklarını kurar, analiz ve testleri çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
