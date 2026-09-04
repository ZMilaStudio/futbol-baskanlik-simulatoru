# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

**M0–M19 tamamlandı ve otomatik regresyon zincirinde tutuluyor.** Sıradaki aktif milestone: **M20 — Başkan Mali Disiplini → Transfer Bütçe Davranışı I.**

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9–M13: taraftar, medya ve vaat reputasyonu
- M14: başkanlık seçimi
- M15: başkan kimliği + görev süresi + gerçek devir
- M16: başkan devrinde kişisel itibar handover
- M17: başkan yönetim profili + 6 arketip / 5 trait
- M18: `managerPatience` → gerçek teknik direktör dismissal kararları
- **M19: patience-aware world → reputasyon → seçim → yeni president timeline fixed-point feedback — PASS**

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

M14 seçim üretir, M15 kaybı gerçek başkan devrine çevirir, M16 kişisel reputasyonu incumbent'a göre ardışık yürütür. M17 her başkana beş trait içeren tutarlı yönetim arketipi bağlar:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Arketipler: `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist`.

M18 ilk gerçek profile-feedback katmanıdır. Nötr patience `60`, eski manager davranışını birebir korur; düşük sabır daha erken, yüksek sabır daha geç dismissal üretir.

M19, M18'in iki-geçişli teknik borcunu fixed-point replay ile kapatır:

1. president timeline → `managerPatience`,
2. patience-aware manager/world,
3. world → vaat/taraftar/medya/reputasyon,
4. reputasyon → election/turnover,
5. yeni president timeline ile yeniden simülasyon,
6. timeline sabitlenene kadar tekrar.

Daha önce görülen timeline tekrar oluşursa cycle sayılır ve validator başarısız olur. Varsayılan maksimum iterasyon `8`.

Seed `20260903` M19 kabul sonucu:

- `4` iterasyonda convergence
- cycle `false`
- elections `240`
- reelected/lost `161/79 → 160/80`
- baseline/final election outcome differences `55 / 240`
- manager changes `81 → 84`
- transfers `173 → 168`
- unique final presidents `128`
- world changed `true`
- validation `0`

Iteration path:

`88/153/157-83 → 84/173/160-80 → 84/168/160-80 → sabit 84/168/160-80`

Sıra: `manager changes / transfers / reelected-lost`.

Bu çözüm literal tek-geçişli sezon orkestratörü değildir; final dünya ve final president timeline'ın birbirini üreten deterministik, tarihsel olarak self-consistent fixed point'idir. Gelecek başkanın trait'i geçmiş sezona uygulanmaz.

M19 final kalite:

- analyzer PASS
- `73` test PASS
- temsilî seed `19011`, `19012`, `19013` convergence PASS
- M0–M19 runner zinciri PASS
- artifact `0`
- PR #20 squash merge: `183749baab40403b381003c527ce62fad946a9a6`

Ayrıntılar:

- `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`
- `M19_BASKAN_SABRI_SECIM_GERI_BESLEME_DONGUSU.md`

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

Temel teknik kurallar:

- deterministik seed/replay,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- banka borcundan ayrı transfer taksit yükümlülüğü,
- uzun kariyer invariant + denge guard'ları,
- geri besleme döngülerinde convergence/cycle kontrolü,
- APK/AAB/artifact üretmeyen hafif CI.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m17_president_management_career.dart 20260903
dart run tool/run_m18_president_manager_patience_career.dart 20260903
dart run tool/run_m19_president_manager_election_feedback.dart 20260903
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M19 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone

**M20 — Başkan Mali Disiplini → Transfer Bütçe Davranışı I.**

Yalnız `financialDiscipline` trait'ini gerçek harcama/borç toleransına bağlamak; `transferAmbition` ve `riskAppetite` etkilerini ayrı milestone'larda tutarak davranış etkilerini izole etmek.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
