# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

Temel oyun kimliği: **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **Sıradaki:** M3 — Temel Kulüp Ekonomisi

Flutter bağımlılığı henüz yoktur. Amaç maç, sezon, oyuncu yaşam döngüsü ve ileride ekonomi/transfer sistemlerini mobil arayüzden önce otomatik testlerle doğrulamaktır.

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

## M2

- 8 kulüp × 18 oyuncu = 144 başlangıç oyuncusu
- yaş, pozisyon, mevcut seviye ve potansiyel
- deterministik gelişim / düşüş
- 34–38 yaş arası deterministik emeklilik
- her sezon geçişinde kulüp başına 1 genç üretimi
- kadronun ilk 11 kalitesinden türetilen takım gücü
- 20 sezon oyuncu nüfusu korunum testi
- seed `20260903`: 20 sezon / 1.120 maç / 148 final oyuncu / 148 emeklilik / 152 youth intake / validation 0

M2'de transfer, sözleşme, maaş, ekonomi, teknik direktör, taraftar, UI ve APK henüz yoktur.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_batch.dart 100
dart run tool/run_m1_career.dart 20260903
dart run tool/run_m2_player_career.dart 20260903
```

## CI prensibi

GitHub Actions yalnızca Dart bağımlılıklarını kurar, analiz/testleri ve headless simülasyon koşularını çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
