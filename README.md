# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

M0–M16 tamamlandı ve otomatik regresyon zincirinde tutuluyor.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9: taraftar beklentisi + güven
- M10: medya hafızası + başkan açıklamaları
- M11: ölçülebilir başkan vaatleri
- M12: vaat sonuçları → taraftar güveni
- M13: vaat sonuçları → medya güvenilirliği
- M14: başkanlık seçimi çekirdeği
- M15: başkan kimliği + görev süresi + gerçek devir
- **M16: başkan devrinde kişisel itibar devri — PASS**

Flutter bağımlılığı henüz yoktur. Öncelik uzun kariyerde sağlam çalışan başkanlık simülasyonunu mobil arayüzden önce kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

## Başkanlık zinciri

M9–M13 taraftar, medya ve vaat hafızasını üretir. M14 dört sezonluk dönem sonunda fan overall `%35`, fan identity `%15`, media credibility `%25`, son dört sezon promise score `%25` ile approval üretip deterministik challenger ile karşılaştırır. M15 seçim kaybını gerçek başkan devrine dönüştürür.

M16 ile akış artık ardışıktır:

**sezon → reputasyon → seçim → devir → kişisel reputasyon handover → sonraki sezon**

Yeni başkan kulübün sportif/mali/transfer güven bagajını devralır; predecessor'ın kişisel `identityTrust` ve `media credibility` geçmişini ise birebir miras almaz. İlk handover politikası `%25 predecessor izi + %75 nötr başlangıç`tır. Fan identity nötr referansı `60`, medya nötr referansı `65`tir.

Seed `20260903` M16:

- `240` seçim
- `161` yeniden seçim / `79` kayıp ve devir
- yeniden seçim oranı `%67,1`
- `127` benzersiz başkan
- final media credibility ortalaması `72,42`, aralık `59–93`
- final fan identity ortalaması `65,00`, aralık `56–81`
- ortalama handover media değişimi `+0,13`
- ortalama handover identity değişimi `+2,18`
- validation `0`

M14–M15 eski baseline'ı regresyon olarak aynen korunur; M16 ardışık kişisel itibar semantiği nedeniyle kendi seçim baseline'ına sahiptir.

Ayrıntı: `M16_BASKAN_DEVRI_KISISEL_ITIBAR.md`.

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

Gözlemsel/itibar katmanlarında aynı alt dünya paylaşılır. M16, M13'ün manager + advanced transfer + promise + media dünyasını tekrar simüle etmez; mevcut sezon olaylarını yeni incumbent reputasyon state'i üzerinde replay eder.

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
dart run tool/run_m16_president_reputation_career.dart 20260903
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M16 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone

**M17 — Başkan Profili + Yönetim Felsefesi Çekirdeği.**

Başkan değişimi artık kimlik ve kişisel itibar değiştiriyor. Sıradaki adım, başkanların mali disiplin, transfer iştahı ve uzun vadeli yapılanma gibi deterministik yönetim eğilimlerine sahip olmasıdır. İlk M17 bu eğilimleri ölçülebilir profil/state olarak kuracak; ekonomi ve transfer AI'ına geri besleme kontrollü ve ayrı guard'larla eklenecek.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
