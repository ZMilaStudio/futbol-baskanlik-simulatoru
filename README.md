# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

M0–M18 tamamlandı ve otomatik regresyon zincirinde tutuluyor.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9–M13: taraftar, medya ve vaat reputasyonu
- M14: başkanlık seçimi
- M15: başkan kimliği + görev süresi + gerçek devir
- M16: başkan devrinde kişisel itibar handover
- M17: başkan yönetim profili + 6 arketip / 5 trait
- **M18: managerPatience → gerçek teknik direktör dismissal kararları — PASS**

Flutter bağımlılığı henüz yoktur. Öncelik uzun kariyerde sağlam çalışan başkanlık simülasyonunu mobil arayüzden önce kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

## Başkanlık ve yönetim zinciri

M14 seçim üretir, M15 kaybı gerçek başkan devrine çevirir, M16 kişisel reputasyonu incumbent'a göre ardışık yürütür. M17 her başkana tutarlı bir yönetim arketipi ve beş trait bağlar:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Arketipler: `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist`.

M18 ilk gerçek profile-feedback katmanıdır. M17 president timeline sabit referans alınır ve aynı seed ile ikinci advanced-world geçişinde incumbent `managerPatience`, teknik direktör dismissal eşiklerini değiştirir. Nötr patience `60`, eski manager davranışını birebir korur.

Seed `20260903` M18:

- `960` manager decision snapshot
- manager changes `81 → 88`
- dismissal decision differences `93`
- downstream manager identity differences `446 / 960`
- final manager assignment differences `37 / 48`
- düşük sabır dismissal rate `%16,4`
- yüksek sabır dismissal rate `%6,2`
- dismissal anında avg patience `50,52`
- retained manager sezonlarında avg patience `61,52`
- transfer sayısı `173 → 153`
- world changed `true`
- validation `0`

Toplam hoca değişimi yalnız `+7` olduğu için piyasa hiperaktif hale gelmedi; buna karşılık düşük ve yüksek sabır grupları belirgin biçimde ayrışıyor.

Ayrıntı: `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`.

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

M18 iki geçişlidir:

1. canonical M17 → president / turnover / profile timeline,
2. aynı seed advanced-world replay → president-aware manager dismissal kararları.

Bu bilinçli ara mimaridir. M18'in değişen dünyasından seçimler henüz yeniden hesaplanmaz; döngü M19'da kapatılacaktır.

Temel teknik kurallar:

- deterministik seed/replay,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- banka borcundan ayrı transfer taksit yükümlülüğü,
- uzun kariyer invariant + denge guard'ları,
- APK/AAB/artifact üretmeyen hafif CI.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m16_president_reputation_career.dart 20260903
dart run tool/run_m17_president_management_career.dart 20260903
dart run tool/run_m18_president_manager_patience_career.dart 20260903
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M18 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone

**M19 — Başkan Sabrı + Seçim Geri Besleme Döngüsü.**

M18'in patience-aware manager/world patikasını taraftar, medya, vaat ve seçim state'ine geri bağlayarak `president → manager → world → reputasyon → election → president` döngüsünü tek tutarlı kariyer simülasyonuna dönüştürmek.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
