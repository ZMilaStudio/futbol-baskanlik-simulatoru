# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

M0–M15 tamamlandı ve otomatik regresyon zincirinde tutuluyor.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9: taraftar beklentisi + güven
- M10: medya hafızası + başkan açıklamaları
- M11: ölçülebilir başkan vaatleri
- M12: vaat sonuçları → taraftar güveni
- M13: vaat sonuçları → medya güvenilirliği
- M14: başkanlık seçimi çekirdeği
- **M15: başkan kimliği + görev süresi + gerçek devir — PASS**

Flutter bağımlılığı henüz yoktur. Öncelik uzun kariyerde sağlam çalışan başkanlık simülasyonunu mobil arayüzden önce kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

## Reputasyon → seçim → görev devri zinciri

M9–M13 taraftar, medya ve vaat hafızasını üretir. M14 dört sezonluk dönem sonunda fan overall `%35`, fan identity `%15`, media credibility `%25`, son dört sezon promise score `%25` ile approval üretip deterministik challenger ile karşılaştırır.

Seed `20260903` M14: `240` seçim, `158` reelected, `82` lost, reelection `%65,8`, avg approval `63,24`, avg challenger `60,08`.

M15 seçim sonucunu değiştirmeden başkan kimliğini ve tenure state'ini ekler. Yeniden seçimde aynı incumbent devam eder; kayıpta challenger yeni incumbent olur.

Seed `20260903` M15:

- `82` seçim kaybı → `82` gerçek başkan devri
- `130` benzersiz başkan
- `35` kulüpte en az bir devir
- `24` kulüpte birden fazla devir
- maksimum `5` devir/kulüp
- biten görev süresi ortalaması `6,93` sezon
- görev süresi aralığı `4–20`
- validation `0`

Ayrıntı: `M15_BASKANLIK_GOREV_SURESI_DEVIR.md`.

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

Gözlemsel/itibar katmanlarında aynı alt dünya mümkün olduğunca paylaşılır. M15, M14 election report'unu değiştirmeden tenure/devir katmanı olarak çalışır.

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
dart run tool/run_m8_advanced_transfer_career.dart 20260903
dart run tool/run_m9_fan_career.dart 20260903
dart run tool/run_m10_media_career.dart 20260903
dart run tool/run_m11_promise_career.dart 20260903
dart run tool/run_m12_promise_fan_career.dart 20260903
dart run tool/run_m13_promise_media_career.dart 20260903
dart run tool/run_m14_president_election_career.dart 20260903
dart run tool/run_m15_president_tenure_career.dart 20260903
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M15 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone

**M16 — Başkan Devrinde Kişisel İtibar Devri.**

Yeni incumbent predecessor'ın kişisel media credibility ve fan identity geçmişini olduğu gibi miras almamalı. M16, kulüp temelli güveni korurken başkana özgü reputasyonu kontrollü biçimde resetleyip sonraki seçimlere gerçek tenure bağlamı verecek.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
