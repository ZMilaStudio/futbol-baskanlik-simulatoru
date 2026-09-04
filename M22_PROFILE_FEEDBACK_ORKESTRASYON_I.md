# M22 — Profile Feedback Orkestrasyon I

## Amaç

M21 sonrası profile-feedback doğrulaması doğruydu ancak pahalıydı. Aynı canonical 20 sezonluk zincir:

1. `dart test` içinde M19 full feedback,
2. `dart test` içinde M20 full feedback,
3. `dart test` içinde M21 full feedback,
4. bağımsız M19 runner,
5. bağımsız M20 runner,
6. bağımsız M21 runner

olarak tekrar çözülüyordu.

M22 davranış değiştiren bir milestone değildir. Amaç aynı guard kapsamını koruyup aynı deterministic canonical dünyayı daha az tekrar hesaplamaktır.

## Temel gözlem

`PresidentTransferAmbitionFeedbackReport` zaten `m20Baseline` taşır. `PresidentFinancialDisciplineFeedbackReport` da `m19Baseline` taşır.

Bu nedenle tek canonical M21 simülasyonu aynı anda üç milestone için yeterli kanıtı içerir:

`M21 final -> M20 baseline -> M19 baseline`

## Uygulama

Yeni `tool/profile_feedback_canonical_guard.dart`:

- M19 canonical guard'larını,
- M20 canonical guard'larını,
- M21 canonical guard'larını

ortaklaştırır.

M19/M20/M21 runner'ları canonical seed `20260903` için bu guard'ları kullanır.

M21 runner canonical seed'de tek simülasyondan:

- `report.m20Baseline.m19Baseline` ile M19,
- `report.m20Baseline` ile M20,
- `report` ile M21

doğrulamasını yapar.

Üç pahalı full-career test `canonical-feedback` tag'i aldı. CI normal test turu:

`dart test --exclude-tags canonical-feedback`

ile çalışır. Bu yalnız pahalı duplicate canonical testleri dışarı alır. Şunlar normal test turunda kalır:

- M20 financial discipline monotonic policy testi,
- M20 neutral-world signature regresyonu,
- M21 transfer ambition monotonic slot testi,
- M21 neutral-world signature regresyonu,
- M19 temsilî multi-seed convergence testi,
- M19 deterministic + seed-sensitive testi,
- M0–M18 bütün mevcut testleri.

Canonical M19/M20/M21 guard'ları ise tek birleşik runner'da çalışmaya devam eder.

## İlk ölçüm — CI 33917924101

M21 final CI öncesi durum:

- süre yaklaşık `6 dk 10 sn`,
- timeout `7 dk`,
- M19, M20 ve M21 full canonical tekrarları vardı.

M22 ilk ölçüm:

- analyzer PASS,
- `76` hızlı/non-duplicate test PASS,
- M0–M18 runner PASS,
- tek M19–M21 canonical runner PASS,
- toplam süre yaklaşık `2 dk 06 sn`,
- yaklaşık `4 dk 04 sn` kazanç,
- yaklaşık `%66` süre azalması.

Bu nedenle workflow timeout tekrar `5 dk` seviyesine indirildi.

## Davranış regresyonu

Canonical seed `20260903` sonuçları değişmedi.

M19 nested baseline:

- final reelected/lost `160 / 80`.

M20 nested baseline:

- final reelected/lost `158 / 82`,
- manager changes `83`,
- transfers `153`.

M21 final:

- iterations `4`,
- converged `true`,
- cycle `false`,
- reelected/lost `150 / 90`,
- manager changes `80`,
- transfers `161`,
- transfer volume `1.461,55M`,
- installment deals `73`,
- installment commitment `247,61M`,
- final cash `1.180,63M`,
- final debt `330,25M`,
- emergency borrowing `123,89M`,
- unique final presidents `138`,
- validation issues `0`.

Dolayısıyla M22 performans kazanımı simülasyon davranışını değiştirmeden elde edildi.

## Kabul kuralı

M22 için ana invariant:

> Aynı canonical seed aynı M19/M20/M21 dünyasını üretmeli; yalnız aynı dünyanın gereksiz tekrar çözümü kaldırılmalıdır.

Yeni profile trait milestone'ları mevcut nested baseline'ı körlemesine yeni full-career CI tekrarlarıyla büyütmemelidir. M22 sonrası sıradaki davranış adayı `riskAppetite` olabilir; yeni etki mevcut birleşik profile-feedback doğrulama yapısını yeniden kullanmalıdır.
