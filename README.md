# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

**M0–M22 tamamlandı. Sıradaki aktif milestone: M23 — Başkan Risk İştahı → Transfer Pazarlık Davranışı I.**

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9–M13: taraftar, medya ve vaat reputasyonu
- M14: başkanlık seçimi
- M15: başkan kimliği + görev süresi + gerçek devir
- M16: başkan devrinde kişisel itibar handover
- M17: başkan yönetim profili + 6 arketip / 5 trait
- M18: `managerPatience` → gerçek teknik direktör dismissal kararları
- M19: manager/world → reputasyon → seçim fixed-point feedback
- M20: `financialDiscipline` → gerçek transfer affordability/bütçe sınırları
- M21: `transferAmbition` → gerçek transfer aktivite slotları + M20 feedback
- M22: M19–M21 canonical profile-feedback doğrulamasını tek-pass orchestration'a indirir; oyun davranışı değişmez

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

M18 `managerPatience` trait'ini gerçek teknik direktör görev güvenliğine bağladı. M19 değişen world'ü reputasyon ve seçimlere geri besleyerek president timeline ile world'ü deterministik fixed point'te buluşturdu.

M20 yalnız `financialDiscipline` trait'ini transfer affordability katmanına bağlar. Nötr `60` eski transfer davranışını birebir korur:

- reserve cash `2,0M`
- window spend cap `%35`
- installment commitment cap `%90`

M21 yalnız `transferAmbition` trait'ini transfer aktivite seviyesine bağlar:

- `<45` → buyer başına `1` tamamlanmış transfer slotu,
- `45..74` → `2` slot,
- `>=75` → `3` slot.

Nötr `transferAmbition=60` eski sabit `2` slot davranışını birebir korur. Candidate shortlist, pozisyon ihtiyacı, seller ask, buyer max bid, affordability ve taksit kabul mantığı değiştirilmez.

Transfer penceresi kadroyu sonraki sezon için kurduğu için mali disiplin ve transfer hırsı `seasonIndex + 1` tarihinde görevde olan başkandan alınır. Böylece seçim sonrası yeni başkan kendi ilk yaz penceresini kontrol eder.

## M20 baseline

Seed `20260903`:

- `5` iterasyonda convergence, cycle `false`
- elections `240`
- reelected/lost `158 / 82`
- manager changes `83`
- transfers `153`
- transfer volume `1.387,32M`
- installment deals `80`
- installment commitment `279,65M`
- final cash `1.226,59M`
- final debt `363,58M`
- emergency borrowing `159,05M`

## M21 kabul baseline'ı

Seed `20260903`:

- `4` iterasyonda convergence
- cycle `false`
- elections `240`
- reelected/lost `150 / 90`
- M20/M21 election outcome differences `48 / 240`
- manager changes `80`
- transfers `161`
- transfer volume `1.461,55M`
- installment deals `73`
- installment commitment `247,61M`
- final cash `1.180,63M`
- final debt `330,25M`
- emergency borrowing `123,89M`
- unique final presidents `138`
- world changed `true`
- validation `0`

Iteration path:

`88/145/158-82 → 82/148/151-89 → 80/161/150-90 → sabit 80/161/150-90`

Sıra: `manager changes / transfers / reelected-lost`.

M21 aggregate transfer sayısını `153 → 161`, hacmi yaklaşık `%5,35` artırdı. Bu kontrollü bir değişimdir; M21'in asıl causal invariant'ı aggregate artış değil, `low ambition slot < neutral slot < high ambition slot` ilişkisidir.

Neutral activity-provider regresyonu, `transferAmbition=60` yolunun eski advanced-world signature'ını birebir korumasını zorunlu tutar.

M21 final kalite:

- PR #22 squash merge: `d24670a5ea9dfa51ee32f7fe0bdda894e0972856`
- final PR CI `33916301967`: PASS
- analyzer PASS
- `79` test PASS
- M0–M21 runner zinciri PASS
- artifact `0`
- final CI süresi yaklaşık `6 dk 10 sn`

## M22 profile-feedback orchestration — PASS

M21 sonrası aynı canonical profile-feedback kariyerleri hem testlerde hem M19/M20/M21 runner'larında tekrar çözülüyordu. M22 bu tekrarı davranış değiştirmeden kaldırdı.

Temel gözlem:

- M21 raporu `m20Baseline` taşır,
- M20 raporu `m19Baseline` taşır.

Dolayısıyla tek M21 canonical simülasyonu M19, M20 ve M21 için gereken bütün nested raporları içerir.

M22:

- ortak `tool/profile_feedback_canonical_guard.dart` ekledi,
- üç pahalı full-career testi `canonical-feedback` etiketiyle normal CI test turundan ayırdı,
- policy, neutral-regression, determinism ve multi-seed convergence testlerini normal turda tuttu,
- M19/M20/M21 canonical guard'larını tek M21 runner içinde uyguladı,
- ayrı M19 ve M20 canonical CI runner tekrarlarını kaldırdı.

İlk M22 ölçüm CI `33917924101`:

- analyzer PASS,
- `76` hızlı/non-duplicate test PASS,
- M0–M18 runner PASS,
- tek M19–M21 canonical profile-feedback runner PASS,
- M19 nested final `160/80`,
- M20 nested final `158/82`,
- M21 final yine `4 iterasyon / 150-90 / 80 manager / 161 transfer`,
- validation `0`,
- artifact `0`,
- toplam süre yaklaşık `2 dk 06 sn`.

M21 finaline göre yaklaşık `4 dk 04 sn`, yani yaklaşık `%66` CI süresi kazanıldı. Timeout `7` dakikadan tekrar `5` dakikaya indirildi.

M22 final PR CI `33918259144`, `5 dk` timeout altında analyzer + `76` hızlı test + M0–M18 + birleşik M19–M21 canonical kapısının tamamını PASS geçti; artifact `0`.

PR #23 squash merge: `4ec358cf7131087176426ba5767ab4e4e65a36b3`.

Ayrıntılar:

- `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`
- `M19_BASKAN_SABRI_SECIM_GERI_BESLEME_DONGUSU.md`
- `M20_BASKAN_MALI_DISIPLIN_TRANSFER_BUTCE_DAVRANISI.md`
- `M21_BASKAN_TRANSFER_HIRSI_TRANSFER_AKTIVITESI.md`
- `M22_PROFILE_FEEDBACK_ORKESTRASYON_I.md`

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

Temel teknik kurallar:

- deterministik seed/replay,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- banka borcundan ayrı transfer taksit yükümlülüğü,
- uzun kariyer invariant + denge guard'ları,
- geri besleme döngülerinde convergence/cycle kontrolü,
- neutral profile regresyonu,
- APK/AAB/artifact üretmeyen CI.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m19_president_manager_election_feedback.dart 20260903
dart run tool/run_m20_president_financial_discipline_feedback.dart 20260903
dart run tool/run_m21_president_transfer_ambition_feedback.dart 20260903
```

## CI

Tek workflow:

- `dart analyze`,
- `dart test --exclude-tags canonical-feedback`,
- M0 100 sezon batch,
- M1–M18 20 sezon runner zinciri,
- tek M19–M21 canonical profile-feedback runner.

Canonical guard kapsamı azaltılmadı; duplicate full-career hesaplar kaldırıldı. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`. Timeout `5` dakikadır.

## Sıradaki milestone — M23

**Başkan Risk İştahı → Transfer Pazarlık Davranışı I.**

M23'te ayrım korunacak:

- `financialDiscipline` = ne kadarını karşılayabilir / ne kadar rezerv bırakır,
- `transferAmbition` = kaç transfer slotu kovalar,
- `riskAppetite` = mevcut affordability içinde pazarlıkta ne kadar yukarı çıkmaya razı olur.

İlk hedef buyer max-bid/negotiation ceiling davranışıdır. Neutral risk mevcut teklif davranışını birebir korumalıdır. Seller ask, candidate shortlist, pozisyon ihtiyacı, slot sayısı, affordability ve `youthOrientation` M23'te değişmeyecektir. M23 yeni duplicate full-career CI katmanı oluşturmayacak; M22 birleşik canonical profile-feedback kapısını genişletecektir.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.