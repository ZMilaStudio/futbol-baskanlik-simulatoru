# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

M0–M17 tamamlandı ve otomatik regresyon zincirinde tutuluyor.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9: taraftar beklentisi + güven
- M10: medya hafızası + başkan açıklamaları
- M11: ölçülebilir başkan vaatleri
- M12: vaat → taraftar güveni
- M13: vaat → medya güvenilirliği
- M14: başkanlık seçimi
- M15: başkan kimliği + görev süresi + gerçek devir
- M16: başkan devrinde kişisel itibar handover
- **M17: başkan yönetim profili + felsefe çeşitliliği — PASS**

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

M14 seçim üretir, M15 kaybı gerçek başkan devrine çevirir, M16 kişisel fan identity / media credibility state'ini incumbent'a göre ardışık yürütür.

M17, bu gerçek başkan zincirine beş yönetim trait'i bağlar:

- mali disiplin,
- risk iştahı,
- transfer hırsı,
- altyapı yönelimi,
- teknik direktöre sabır.

Trait'ler bağımsız rastgele sayı değildir; `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist` arketiplerinden türetilir. M17 gözlemseldir; M16 seçim/turnover davranışını değiştirmez.

Seed `20260903` M17:

- `127` management profile
- 6/6 arketip aktif: `23 / 25 / 24 / 15 / 18 / 22`
- financial avg `60,48`, range `28–90`
- risk avg `54,98`, range `20–90`
- transfer avg `56,54`, range `29–90`
- youth avg `59,90`, range `30–90`
- manager patience avg `57,94`, range `20–90`
- `67/79` turnover arketip değiştiriyor
- `57/79` turnover anlamlı trait değişimi yaratıyor
- avg turnover profile distance `22,47`
- validation `0`

Ayrıntı: `M17_BASKAN_PROFILI_YONETIM_FELSEFESI.md`.

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

Gözlemsel katmanlar mevcut kariyer raporlarını yeniden kullanır. M17, M16 kaynak raporunu yalnız profiller; dünya, election veya turnover sonucunu yeniden yazmaz.

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
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M17 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone

**M18 — Başkan Sabri → Teknik Direktör Karar Eşiği I.**

İlk gerçek yönetim-profili geri beslemesi yalnız `managerPatience` ile yapılacak. Amaç sabırlı başkanların hocaya daha uzun süre vermesi, düşük sabırlı başkanların daha erken değişime gitmesi; manager piyasasını hiperaktif veya donmuş hale getirmeden kontrollü bir fark yaratmaktır.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
