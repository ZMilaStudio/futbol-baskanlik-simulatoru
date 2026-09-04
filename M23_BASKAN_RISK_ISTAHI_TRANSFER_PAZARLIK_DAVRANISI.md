# M23 — Başkan Risk İştahı → Transfer Pazarlık Davranışı I

## Amaç

M17'de üretilen `riskAppetite` trait'ini gerçek bir karar noktasına bağlamak:

> **Başkan, mevcut bütçe/affordability sınırları içinde bir oyuncu için ne kadar yukarı çıkmaya razı?**

M23 yalnız alıcının maksimum teklif / pazarlık tavanını değiştirir. Aynı anda başka transfer davranışlarını değiştirmez.

## Trait ayrımı

M23 sonrasında transfer tarafındaki başkan profili ayrımı:

- `financialDiscipline` → ne kadarını karşılayabilir / ne kadar rezerv bırakır (M20)
- `transferAmbition` → kaç tamamlanmış transfer slotu kovalar (M21)
- `riskAppetite` → mevcut affordability içinde maksimum teklif tavanı (M23)

M23'te değiştirilmez:

- seller ask
- candidate shortlist (`8`)
- pozisyon ihtiyacı
- transfer slotu
- cash reserve / spend cap / installment commitment cap
- installment acceptance olasılığı
- oyuncu candidate scoring
- `youthOrientation`

## Policy

`PresidentRiskAppetiteNegotiationPolicy`:

- trait clamp: `20..90`
- `adjustmentBps = (riskAppetite - 60) × 20`
- clamp: `-800..+600 bps`

Örnekler:

- risk `20` → `-800 bps`
- risk `60` → `0 bps`
- risk `90` → `+600 bps`

Neutral `riskAppetite=60`, eski maksimum teklif hesabını birebir korur.

Maksimum teklif:

`10300 bps + shortage premium + deterministic negotiation noise + risk adjustment`

Policy transfer penceresi için `seasonIndex + 1` tarihinde görevde olan başkandan okunur. Böylece seçim sonrası gelen başkan kendi ilk yaz pazarlık yaklaşımını belirler.

## Neutral regresyon

4 sezonluk canonical advanced-world testinde neutral negotiation provider:

`negotiationPolicyProvider => TransferNegotiationPolicy.neutral`

provider olmayan eski advanced world ile birebir aynı signature üretmek zorundadır.

Bu test PASS'tir.

## Feedback mimarisi

M23, M21'in yakınsamış dünyasını baseline alır.

Her iterasyonda aynı president timeline'dan:

- `managerPatience`
- `financialDiscipline`
- `transferAmbition`
- `riskAppetite`

okunur ve aynı advanced-world replay içinde uygulanır.

Ardından:

`advanced world → promise/media/fan/reputation → election/turnover → yeni president timeline`

zinciri tekrar çözülür. Timeline sabitlenirse convergence; daha önce görülen timeline tekrar ederse cycle kabul edilir.

M22'nin duplicate-free canonical yapısı korunur. Normal test turunda full-career canonical M23 testi çalıştırılmaz; tek M23 runner nested M19/M20/M21 ve M23 guard'larını birlikte uygular.

## Canonical kabul baseline'ı

Seed `20260903`, 20 sezon:

- iterations `5`
- converged `true`
- cycle `false`
- elections `240`
- M21 baseline reelected/lost `150/90`
- M23 final reelected/lost `156/84`
- election outcome differences `44`
- manager changes `80 → 85`
- transfers `161 → 133`
- transfer volume `1.461,55M → 1.201,05M`
- installment deals `73 → 66`
- installment commitment `247,61M → 230,59M`
- final cash `1.180,63M → 1.195,96M`
- final debt `330,25M → 381,94M`
- emergency borrowing `123,89M → 189,81M`
- unique final presidents `132`
- world changed `true`
- validation `0`

Iteration path:

1. `91 manager / 148 transfer / 1.345,13M / 156-84 / diff52`
2. `88 / 147 / 1.325,29M / 157-83 / diff37`
3. `82 / 140 / 1.267,85M / 159-81 / diff18`
4. `85 / 133 / 1.201,05M / 156-84 / diff9`
5. stable `85 / 133 / 1.201,05M / 156-84 / diff0`

## Yorum sınırı

Canonical dünyada başkanların ortalama `riskAppetite` değeri 60'ın biraz altındadır; M23 aggregate transfer adedini ve hacmini düşürdü. Ancak bu aggregate yön ürün invariant'ı değildir.

Doğrudan causal invariant:

> **low risk max-bid ceiling < neutral risk max-bid ceiling < high risk max-bid ceiling**

Benzer şekilde final debt/emergency borrowing değişimi doğrudan `riskAppetite` için normatif causal iddia olarak yorumlanmaz; dünya sonuçları manager, transfer, finans, vaat, reputasyon ve seçim geri beslemesinin birleşik sonucudur.

## Canonical guard'lar

- convergence zorunlu, cycle yasak
- iteration `3..7`
- total elections `240`
- M21 baseline exact: `150/90`, manager `80`, transfer `161`
- final timeline stable, election diff `0`
- total election difference `20..75`
- final reelections `140..170`, losses `70..100`
- manager `70..100`, delta magnitude `≤20`
- transfers `115..165`, transfer delta magnitude `10..55`
- transfer volume `1.00B..1.45B`, delta magnitude `≤400M`
- installment deals `50..85`
- installment commitment `170M..300M`
- cash `1.00B..1.40B`
- debt `280M..480M`
- emergency borrowing `100M..260M`
- unique presidents `115..150`
- world must change

## İlk CI sonucu

PR #24 ilk canonical CI `33920196320`:

- analyzer PASS
- `78` hızlı/non-canonical test PASS
- M0–M18 runner PASS
- birleşik M19–M23 canonical runner PASS
- M19 nested final `160/80`
- M20 nested final `158/82`
- M21 nested final `150/90`
- M23 `5 iterasyon / 156-84 / 85 manager / 133 transfer`
- validation `0`

Final merge öncesinde sıkı M23 guard'larının bulunduğu branch HEAD aynı kalite kapısından tekrar geçirilecektir.
