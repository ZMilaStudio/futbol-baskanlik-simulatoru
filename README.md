# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

M0–M14 tamamlandı ve otomatik regresyon zincirinde tutuluyor.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9: taraftar beklentisi + güven
- M10: medya hafızası + başkan açıklamaları
- M11: ölçülebilir başkan vaatleri
- M12: vaat sonuçları → taraftar güveni
- M13: vaat sonuçları → medya güvenilirliği
- **M14: başkanlık seçimi çekirdeği — PASS**

Flutter bağımlılığı henüz yoktur. Öncelik uzun kariyerde sağlam çalışan başkanlık simülasyonunu mobil arayüzden önce kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

## Reputasyon ve seçim zinciri

### M9 — Taraftar
Sporting / financial / transfer / identity güven boyutları ve bağlamsal beklentiler. Seed `20260903`: 960 snapshot, avg trust `64,88`, aralık `44–75`.

### M10 — Medya
ManagerFuture açıklaması sonraki eylemle consistency/contradiction olarak çözülür. Seed `20260903`: 556 statement, 22 contradiction, avg credibility `75,52`.

### M11 — Başkan vaatleri
Sezon başı bilgiden ölçülebilir vaat; sezon sonunda fulfilled / partial / broken. Seed: 960 vaat, 435 fulfilled, 169 partial, 356 broken, avg score `54,84`.

### M12 — Vaat → taraftar
M9 overall `64,88` → M12 `65,31`; identity avg `61,83`, aralık `38–88`.

### M13 — Vaat → medya
Manager + advanced transfer + promise + media tek shared world üzerinde. Baseline credibility `74,88` → final `72,38`; aralık `36–93`.

### M14 — Başkanlık seçimi
Dört sezonluk dönem sonunda fan overall `%35`, fan identity `%15`, media credibility `%25`, son dört sezon promise score `%25` ile approval üretilir ve deterministik challenger ile karşılaştırılır.

Seed `20260903`: `240` seçim, `158` reelected, `82` lost, reelection `%65,8`; avg approval `63,24`, avg challenger `60,08`, approval aralığı `37–84`, `72` yakın seçim, boundary `0`, validation `0`.

Ayrıntı: `M14_BASKANLIK_SECIMI.md`.

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

Gözlemsel/itibar katmanlarında aynı alt dünya mümkün olduğunca paylaşılır. M14, M13 reputation raporunu temel alır ve taraftarı aynı advanced-transfer world üzerinden türetir; seçim için dünya tekrar simüle edilmez.

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
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M14 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone

**M15 — Başkanlık Görev Süresi + Devir Çekirdeği.**

İlk hedef seçim sonuçlarını AI kulüplerinde gerçek görev süresi/devir state'ine bağlamak; kullanıcı game-over ve UI davranışını daha sonraki aşamaya bırakmaktır.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
