# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Güncel durum

**M0–M23 tamamlandı ve `main` üzerinde doğrulandı.** Sıradaki aktif davranış milestone'u: **M24 — Başkan Altyapı Yönelimi I**.

- M0–M5: lig, kariyer, oyuncu, ekonomi, transfer, 48 kulüp / 3 lig
- M6–M8: teknik direktör, sözleşme/maaş, kiralık+taksit
- M9–M13: taraftar, medya ve vaat reputasyonu
- M14–M17: seçim, başkan kimliği/görev süresi, itibar handover, yönetim profili
- M18: `managerPatience` → teknik direktör görev güvenliği
- M19: manager/world → reputasyon → seçim fixed-point feedback
- M20: `financialDiscipline` → transfer affordability/bütçe sınırları
- M21: `transferAmbition` → transfer aktivite slotları
- M22: canonical profile-feedback CI/orchestration optimizasyonu
- **M23: `riskAppetite` → transfer pazarlık / maksimum teklif tavanı — PASS**

Flutter bağımlılığı henüz yoktur. Öncelik uzun kariyerde sağlam çalışan başkanlık simülasyonunu mobil arayüzden önce kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

## Başkan yönetim profili

M17 her başkana tutarlı bir arketip ve beş trait bağlar:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Arketipler: `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist`.

Gerçek davranışa bağlanan trait'ler:

- `managerPatience` — M18
- `financialDiscipline` — M20
- `transferAmbition` — M21
- `riskAppetite` — M23

Henüz davranışa bağlanmayan:

- `youthOrientation`

## Transfer davranışındaki trait ayrımı

Başkan profili transfer pazarında birbirine karıştırılmayan üç ayrı karar alanını kontrol eder:

- **M20 / financialDiscipline:** ne kadarını karşılayabilir, ne kadar rezerv bırakır?
- **M21 / transferAmbition:** pencere başına kaç tamamlanmış transfer kovalar?
- **M23 / riskAppetite:** affordability içinde bir oyuncu için ne kadar yukarı çıkmaya razıdır?

### M20 neutral mali disiplin

`financialDiscipline=60`:

- reserve cash `2,0M`
- window spend cap `%35`
- installment commitment cap `%90`

### M21 transfer hırsı

- `<45` → `1` tamamlanmış transfer slotu
- `45..74` → `2` slot
- `>=75` → `3` slot

Neutral `60` eski sabit `2` slot davranışını korur.

### M23 risk iştahı

`PresidentRiskAppetiteNegotiationPolicy`:

- trait clamp `20..90`
- adjustment = `(riskAppetite - 60) × 20 bps`
- clamp `-800..+600 bps`

Örnek:

- risk `20` → max-bid `-800 bps`
- risk `60` → `0 bps` / eski davranış
- risk `90` → `+600 bps`

M23 yalnız buyer max-bid ceiling'i değiştirir. Seller ask, shortlist, pozisyon ihtiyacı, transfer slotu, affordability, installment acceptance ve candidate scoring değişmez.

Transfer penceresi sonraki sezonun kadrosunu kurduğu için M20/M21/M23 policy'leri `seasonIndex + 1` tarihinde görevdeki başkanı okur.

## Fixed-point feedback

M19'dan itibaren president timeline ile world karşılıklı geri beslenir:

`president timeline → profile traits → manager/transfer/world → promise/fan/media/reputation → election/turnover → president timeline`

Timeline sabitlenirse convergence, eski bir timeline tekrar oluşursa cycle kabul edilir. Varsayılan maksimum iterasyon `8`.

Bu literal tek-geçişli sezon orkestratörü değildir; aynı seed üzerinde tarihsel olarak self-consistent deterministik replay çözümüdür. Provider yalnız ilgili sezonda yürürlükteki başkanı uygular; gelecekteki başkan geçmişe sızmaz.

## Canonical profile-feedback baselinelar

Seed `20260903`, 20 sezon:

| Milestone | Iterasyon | Reelected/Lost | Manager | Transfer | Hacim |
|---|---:|---:|---:|---:|---:|
| M19 | 4 | `160/80` | 84 | 168 | — |
| M20 | 5 | `158/82` | 83 | 153 | `1.387,32M` |
| M21 | 4 | `150/90` | 80 | 161 | `1.461,55M` |
| **M23** | **5** | **`156/84`** | **85** | **133** | **`1.201,05M`** |

M23 ayrıca:

- election differences `44`
- installment deals `66`
- installment commitment `230,59M`
- final cash `1.195,96M`
- final debt `381,94M`
- emergency borrowing `189,81M`
- unique final presidents `132`
- validation `0`

M23 iteration path:

`91/148/156-84 → 88/147/157-83 → 82/140/159-81 → 85/133/156-84 → stable 85/133/156-84`

Sıra: `manager changes / transfers / reelected-lost`.

Aggregate transfer veya borç yönü `riskAppetite` için causal ürün kuralı değildir. Doğrudan invariant yalnız şudur:

> **low risk max-bid < neutral max-bid < high risk max-bid**

## M22 CI/orchestration optimizasyonu

M22, aynı M19/M20/M21 canonical 20-sezon dünyalarının test ve runner katmanlarında tekrar tekrar çözülmesini kaldırdı.

- ortak `tool/profile_feedback_canonical_guard.dart`
- full canonical testler `canonical-feedback` tag'li
- normal test turu: `dart test --exclude-tags canonical-feedback`
- tek en yeni profile-feedback runner nested önceki baselineları doğrular
- artifact üretimi yok

M21 final CI yaklaşık `6:10` iken M22 final güvenli koşusu yaklaşık `2:51` oldu. Timeout tekrar `5 dk`.

M23 aynı yapıyı genişletti: tek M23 canonical runner nested M19, M20, M21 ve M23 guard'larını birlikte doğrular.

## M23 kalite sonucu

PR #24 squash merge:

`17142c39bfeed20fce931e8810f30ba4ba98a322`

Final PR CI `33920702055`:

- analyzer PASS
- `78` non-canonical/hızlı test PASS
- M0–M18 runner PASS
- birleşik M19–M23 canonical runner PASS
- nested M19 `160/80`
- nested M20 `158/82`
- nested M21 `150/90`
- M23 `5 iterasyon / 156-84 / 85 manager / 133 transfer`
- validation `0`
- artifact `0`

Ayrıntı:

- `M22_PROFILE_FEEDBACK_ORKESTRASYON_I.md`
- `M23_BASKAN_RISK_ISTAHI_TRANSFER_PAZARLIK_DAVRANISI.md`

## Mimari kurallar

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

- deterministik seed/replay
- cihaz saatinden bağımsız `GameDate`
- integer minor-unit `Money`
- banka borcundan ayrı transfer taksit yükümlülüğü
- uzun kariyer invariant + balance guard
- feedback döngülerinde convergence/cycle kontrolü
- neutral trait regresyonu
- her trait yalnız tek karar noktasına bağlanır
- duplicate canonical full-career hesapları büyütülmez
- APK/AAB/actions artifact üretilmez

## Çalıştırma

```bash
dart pub get
dart analyze
dart test --exclude-tags canonical-feedback
dart run tool/run_m23_president_risk_appetite_feedback.dart 20260903
```

Tek M23 canonical runner nested M19–M23 guard'larını birlikte doğrular.

## Sıradaki milestone — M24

**Başkan Altyapı Yönelimi → Genç Oyuncu / Transfer Tercihi I**.

İlk bağlantı tek kontrol noktasında tutulmalı. Önerilen en temiz başlangıç: `youthOrientation` yalnız transfer candidate scoring içindeki genç/potansiyel ağırlığını değiştirsin.

İlk sürümde aynı anda academy üretim kalitesi, genç oyuncu sayısı ve transfer AI hedefleri birlikte değiştirilmemeli. Neutral `youthOrientation=60` mevcut M23 dünyasını birebir korumalı ve M22'nin duplicate-free canonical orchestration yapısı genişletilmelidir.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md`.
