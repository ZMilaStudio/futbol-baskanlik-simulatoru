# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Güncel durum

**M0–M24 tamamlandı ve `main` üzerinde doğrulandı.** Sıradaki aktif milestone: **M25 — Save/Load + Kayıt Versiyonlama I**.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9–M13: taraftar, medya ve vaat reputasyonu
- M14–M17: seçim, başkan kimliği/görev süresi, reputasyon handover, yönetim profili
- M18: `managerPatience` → teknik direktör görev güvenliği
- M19: manager/world → reputasyon → seçim fixed-point feedback
- M20: `financialDiscipline` → transfer affordability/bütçe sınırları
- M21: `transferAmbition` → transfer aktivite slotları
- M22: canonical feedback CI/orchestration optimizasyonu
- M23: `riskAppetite` → buyer max-bid pazarlık tavanı
- **M24: `youthOrientation` → transfer candidate genç/potansiyel tercihi — PASS**

Flutter bağımlılığı henüz yoktur. Öncelik uzun kariyerde sağlam çalışan başkanlık simülasyonunu mobil arayüzden önce kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ekonomi, kontrat, transfer, manager, reputasyon ve seçim zinciri

## Başkan yönetim profili

M17 her başkana 6 arketip ve 5 trait bağlar:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Arketipler: `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist`.

**M24 itibarıyla beş trait'in tamamının en az bir gerçek ve izole karar etkisi vardır:**

| Trait | İlk gerçek etki |
|---|---|
| `managerPatience` | teknik direktör dismissal eşikleri |
| `financialDiscipline` | transfer rezerv/harcama/taahhüt sınırları |
| `transferAmbition` | pencere başına tamamlanmış transfer slotu |
| `riskAppetite` | buyer max-bid pazarlık tavanı |
| `youthOrientation` | candidate score içindeki gençlik/potansiyel sinyali |

Her trait ilk bağlandığında tek karar noktasına etki eder. Neutral değer `60`, ilgili eski davranışı birebir korur.

## Transfer profile politikaları

### M20 — Financial discipline

Neutral `60`:

- reserve cash `2,0M`
- window spend cap `%35`
- installment commitment cap `%90`

### M21 — Transfer ambition

- `<45` → `1` transfer slotu
- `45..74` → `2` slot
- `>=75` → `3` slot

Neutral `60` → eski `2` slot.

### M23 — Risk appetite

- trait clamp `20..90`
- max-bid adjustment = `(riskAppetite - 60) × 20 bps`
- clamp `-800..+600 bps`
- neutral `60` → `0 bps`

Seller ask, shortlist ve affordability değiştirilmez.

### M24 — Youth orientation

Youth signal ölçeği:

- `20` → `%60`
- `60` → `%100` / neutral
- `90` → `%130`

Youth signal yalnız candidate score içindeki gelişim payı + yaş bonusunu ölçekler. Budget, slot, max-bid, seller ask, taksit ve shortlist büyüklüğü değiştirilmez.

Doğrudan causal testte aynı buyer/seller dünyasında:

- düşük yönelim hazır 27 yaş / 79 ability oyuncuyu,
- yüksek yönelim 20 yaş / 72 ability / 92 potential oyuncuyu

ilk transfer adayı olarak seçer.

Transfer penceresi sonraki sezonun kadrosunu kurduğu için profile transfer politikaları `seasonIndex + 1` tarihinde görevdeki başkanı okur.

## Fixed-point feedback

M19'dan itibaren zincir:

`president timeline → profile traits → manager/transfer/world → promise/fan/media/reputation → election/turnover → president timeline`

Timeline sabitlenirse convergence; eski timeline tekrar oluşursa cycle kabul edilir. Varsayılan maksimum iterasyon `8`.

Bu literal tek-geçişli sezon orkestratörü değildir; aynı seed üzerinde tarihsel olarak self-consistent deterministik replay çözümüdür. Gelecekteki başkan geçmiş sezona sızmaz.

## Canonical profile-feedback baselinelar

Seed `20260903`, 20 sezon:

| Milestone | Iterasyon | Reelected/Lost | Manager | Transfer | Hacim |
|---|---:|---:|---:|---:|---:|
| M19 | 4 | `160/80` | 84 | 168 | — |
| M20 | 5 | `158/82` | 83 | 153 | `1.387,32M` |
| M21 | 4 | `150/90` | 80 | 161 | `1.461,55M` |
| M23 | 5 | `156/84` | 85 | 133 | `1.201,05M` |
| **M24** | **4** | **`159/81`** | **86** | **157** | **`1.417,94M`** |

M24 ayrıca:

- election outcome differences `49`
- installment deals `79`
- installment commitment `261,26M`
- final cash `1.217,05M`
- final debt `347,57M`
- emergency borrowing `144,39M`
- unique final presidents `129`
- validation `0`

M24 iteration path:

`91/141/156-84 → 88/154/155-85 → 86/157/159-81 → stable 86/157/159-81`

Sıra: `manager changes / transfers / reelected-lost`.

Aggregate transfer/hacim/borç yönü `youthOrientation` için causal ürün kuralı değildir. Causal invariant candidate preference yönüdür.

## Canonical CI orchestration

M22 aynı nested full-career dünyalarının tekrar tekrar çözülmesini kaldırdı:

- ortak `tool/profile_feedback_canonical_guard.dart`
- full canonical testler `canonical-feedback` tag'li
- normal test turu `dart test --exclude-tags canonical-feedback`
- en yeni profile-feedback runner nested önceki canonical guard'ları tek çözümde doğrular
- artifact üretimi yok
- timeout `5 dk`

M24 runner: `tool/run_m24_president_youth_orientation_feedback.dart`.

## M24 kalite sonucu

PR #25 squash merge:

`cfdca8f63dfa6c91fd2432031e0e2c34a8101a06`

Final PR CI `33923631356`:

- analyzer PASS
- normal/non-canonical tests PASS
- doğrudan candidate-selection causal testi PASS
- M0–M18 runner PASS
- combined M19–M24 canonical runner PASS
- nested M19/M20/M21/M23 guard'ları PASS
- validation `0`
- artifact `0`
- 5 dakikalık timeout altında PASS

Ayrıntı:

- `M22_PROFILE_FEEDBACK_ORKESTRASYON_I.md`
- `M23_BASKAN_RISK_ISTAHI_TRANSFER_PAZARLIK_DAVRANISI.md`
- `M24_BASKAN_ALTYAPI_YONELIMI_TRANSFER_GENCLIK_TERCIHI.md`

## Mimari kurallar

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

- deterministik seed/replay
- cihaz saatinden bağımsız `GameDate`
- integer minor-unit `Money`
- banka borcundan ayrı transfer taksit yükümlülüğü
- uzun kariyer invariant + balance guard
- feedback döngülerinde convergence/cycle kontrolü
- neutral trait regresyonu
- her trait ilk bağlantıda tek karar noktasına bağlanır
- duplicate canonical full-career hesapları büyütülmez
- APK/AAB/actions artifact üretilmez

## Çalıştırma

```bash
dart pub get
dart analyze
dart test --exclude-tags canonical-feedback
dart run tool/run_m24_president_youth_orientation_feedback.dart 20260903
```

## Sıradaki milestone — M25

**Save/Load + Kayıt Versiyonlama I**.

Başkan profilindeki beş trait artık gerçek davranışa bağlandığı için yeni davranış katmanlarını üst üste eklemek yerine uzun kariyerin kritik teknik riskine geçiyoruz.

İlk hedef:

- UI/Flutter bağımsız saf Dart save snapshot formatı,
- açık `saveVersion`,
- deterministic serialize/deserialize,
- checksum/signature doğrulaması,
- bozuk veya desteklenmeyen save'i güvenli reddetme,
- en az bir migration fixture altyapısı,
- save→load sonrası aynı kariyer devamının kesintisiz replay ile aynı sonucu vermesi.

İlk sürüm cihaz dosya sistemi veya cloud save içermez; önce format ve migration sözleşmesi kanıtlanır.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
