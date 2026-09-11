# M42 — Sponsor System I

## Amaç

M42, kulüp başkanlığı kararlarını gerçek kulüp gelirine bağlayan deterministik ve tamamen kurgusal sponsor sistemini ekler.

## Kapsam

- Sponsor isimleri ve teklifler tamamen kurgusaldır.
- Teklif değeri kulüp gücü, taraftar güveni ve medya güvenilirliğinden deterministik olarak türetilir.
- Üç teklif profili vardır:
  - stable: 3 sezon, daha yüksek garanti, düşük performans bonusu
  - balanced: 2 sezon, dengeli garanti/bonus
  - bold: 1 sezon, daha düşük garanti, yüksek performans bonusu
- Başkanın `financialDiscipline` ve `riskAppetite` trait'leri teklif seçimini etkiler.
- Kabul edilmiş çok yıllı kontrat başkan değişse bile kontrat süresi bitene kadar kulübü bağlar.
- Performans bonusu lig derecesi hedefi sağlanırsa gelir olarak eklenir.
- Sponsor kontrat geliri `BasicEconomyEngine` içindeki gerçek `sponsorRevenue` satırına girebilir.
- Sponsor sistemi çağrılmazsa eski strength-only sponsor gelir semantiği birebir korunur.
- Sponsor runtime checkpoint'i aktif kontratları ve toplam ödenen sponsor gelirini taşır.
- Sponsor save formatı v1, checksum korumalıdır; sentetik v0→v1 migration vardır.
- Save/load continuation deterministiktir.

## Test / canonical

6 yeni normal test:
1. fan/media gücü teklifleri maddi olarak etkiler
2. prudent/risky başkan farklı kontrat seçer
3. çok yıllı kontrat başkan değişiminden etkilenmez
4. sponsor checkpoint round-trip ve resume deterministiktir
5. v0→v1 sponsor save migration çalışır
6. kabul edilen sponsor geliri gerçek kulüp ekonomisine akar

Canonical seed: `20260903`.

M42 canonical:
- target: `t1_01`
- contracts: `48`
- prudent: `t1_01-s0-stable:3`
- bold: `t1_01-s0-bold:1`
- target sponsor revenue: `12.33M`
- legacy sponsor revenue: `13.28M`
- save/resume match: `true`
- result: `PASS`

## CI kanıtı

Code-bearing HEAD: `dc2828828a0cc9120d96981a54c7c05c2da3c73d`

Run `34659455731` — **SUCCESS**
- test job `103458732601` — SUCCESS
- analyzer — `No issues found!`
- **173 normal/non-canonical test PASS**
- canonical job `103458732736` — SUCCESS
- **M0–M42 canonical PASS**
- artifacts — **0**
- test ≈ `1m54s`
- canonical ≈ `4m32s`
- iki job da sabit `timeout-minutes: 7` sınırının altında

İlk run `34659361772` yalnızca yeni economy parametresinin facility wrapper override imzasına eklenmemesi nedeniyle derleme aşamasında kırıldı. `_FacilityAwareEconomyEngine.simulateSeason` imzası yeni opsiyonel sponsor parametresini forward edecek şekilde düzeltilerek legacy facility/attendance davranışı korunmuştur.

## Durum

PR #45 üzerinde uygulanmıştır. Merge için final docs-inclusive exact HEAD CI doğrulaması gerekir.
