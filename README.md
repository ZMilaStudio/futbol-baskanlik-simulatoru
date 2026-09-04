# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

**M0–M19 tamamlandı. M20 — Başkan Mali Disiplini → Transfer Bütçe Davranışı I, final kalite kapısındadır.**

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9–M13: taraftar, medya ve vaat reputasyonu
- M14: başkanlık seçimi
- M15: başkan kimliği + görev süresi + gerçek devir
- M16: başkan devrinde kişisel itibar handover
- M17: başkan yönetim profili + 6 arketip / 5 trait
- M18: `managerPatience` → gerçek teknik direktör dismissal kararları
- M19: manager/world → reputasyon → seçim fixed-point feedback
- **M20: `financialDiscipline` → gerçek transfer bütçe sınırları + M19 feedback — PASS adayı**

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

Düşük disiplin daha düşük nakit rezervi ve daha geniş harcama/taahhüt sınırı; yüksek disiplin daha yüksek rezerv ve daha sert sınır üretir. Oyuncu aday sıralaması, maksimum teklif, `transferAmbition` ve `riskAppetite` değiştirilmez.

Transfer penceresi kadroyu sonraki sezon için kurduğu için politika `seasonIndex + 1` tarihinde görevde olan başkandan alınır. Böylece seçim sonrası yeni başkan kendi ilk yaz penceresini kontrol eder.

## M19 baseline

Seed `20260903`:

- `4` iterasyonda convergence, cycle `false`
- elections `240`
- reelected/lost `160 / 80`
- manager changes `84`
- transfers `168`
- transfer volume `1.562,93M`
- installment deals `81`
- installment commitment `278,90M`
- final cash `1.191,15M`
- final debt `347,04M`
- emergency borrowing `148,22M`

## M20 ilk kabul baseline'ı

Seed `20260903`:

- `5` iterasyonda convergence
- cycle `false`
- elections `240`
- reelected/lost `158 / 82`
- M19/M20 election outcome differences `52 / 240`
- manager changes `83`
- transfers `153`
- transfer volume `1.387,32M`
- installment deals `80`
- installment commitment `279,65M`
- final cash `1.226,59M`
- final debt `363,58M`
- emergency borrowing `159,05M`
- unique final presidents `130`
- world changed `true`
- validation `0`

Iteration path:

`98/158/157-83 → 88/150/157-83 → 84/160/156-84 → 83/153/158-82 → sabit 83/153/158-82`

Sıra: `manager changes / transfers / reelected-lost`.

Canonical aggregate sonuçta transfer sayısı `168 → 153`, hacim yaklaşık `%11,2` düştü. Borç ve emergency borrowing ise hafif yükseldi; bu, mali disiplinin borcu artırdığı anlamına gelmez. Dünya düşük ve yüksek disiplinli başkanları birlikte içerir ve değişen transfer yolu sportif/ekonomik sonuçları, seçimleri ve sonraki başkanları değiştirir. M20'nin hedefi her dünyada toplam borcu mekanik düşürmek değil, başkan karakterine göre gerçek bütçe sınırı üretmektir.

Neutral-provider regresyonu, `financialDiscipline=60` yolunun eski advanced-world signature'ını birebir korumasını zorunlu tutar.

Ayrıntılar:

- `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`
- `M19_BASKAN_SABRI_SECIM_GERI_BESLEME_DONGUSU.md`
- `M20_BASKAN_MALI_DISIPLIN_TRANSFER_BUTCE_DAVRANISI.md`

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
- APK/AAB/artifact üretmeyen hafif CI.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m18_president_manager_patience_career.dart 20260903
dart run tool/run_m19_president_manager_election_feedback.dart 20260903
dart run tool/run_m20_president_financial_discipline_feedback.dart 20260903
```

## CI

Tek workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M20 20 sezon runner zinciri. Büyük binary ve `actions/upload-artifact` yok; artifact hedefi `0`.

## Sıradaki milestone adayı

**M21 — Başkan Transfer Hırsı → Transfer Aktivitesi I.**

Yalnız `transferAmbition` trait'ini transfer arama/aktivite seviyesine bağlamak. `riskAppetite` ayrı milestone'da tutulacak; böylece “ne kadar harcayabilirim?” ile “ne kadar aktif transfer yapmak istiyorum?” ayrıştırılacak.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
