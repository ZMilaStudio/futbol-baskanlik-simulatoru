# M24 — Başkan Altyapı Yönelimi → Transfer Gençlik Tercihi I

## Amaç

M17'de tanımlanan `youthOrientation` başkan trait'ini ilk kez gerçek transfer davranışına bağlamak.

Bu milestone altyapı üretim kalitesini veya genç oyuncu sayısını değiştirmez. Tek causal bağlantı transfer adaylarının sıralanmasındaki **gençlik + gelişim potansiyeli sinyali**dir.

## Politika

`PresidentYouthOrientationTransferPolicy` trait değerini `20..90` aralığına clamp eder.

Youth signal ölçeği:

- `20` → `6000 bps` / `%60`
- `60` → `10000 bps` / `%100` / neutral
- `90` → `13000 bps` / `%130`

Transfer candidate scoring'deki temel youth signal:

- gelişim payı: `potential - ability`, clamp `0..20`
- gelişim katkısı: `upside × 0.25`
- yaş `<=23`: `+4`
- yaş `>=31`: `-4`

`youthOrientation` yalnız bu sinyali ölçekler.

## Bilinçli olarak değişmeyen alanlar

M24 aşağıdakilere dokunmaz:

- transfer bütçesi / rezerv / affordability
- pencere başına transfer slotu
- seller asking price
- buyer max-bid ceiling
- installment acceptance
- candidate shortlist büyüklüğü
- pozisyon ihtiyacı
- oyuncu değerleme modeli
- altyapıdan genç üretim sayısı veya kalitesi

Bu sınır causal etkinin izole kalması için zorunludur.

## Başkan zamanlaması

Transfer penceresi sonraki sezon kadrosunu kurduğu için policy `seasonIndex + 1` tarihinde görevdeki başkanın `youthOrientation` değerini kullanır.

## Neutral regresyon

`youthOrientation=60` → `10000 bps` ve eski candidate scoring'i birebir korur.

4 sezonluk advanced-world signature testi neutral provider ile eski world'ün aynı olduğunu zorunlu tutar.

## Doğrudan causal test

Kontrollü gerçek transfer penceresinde aynı buyer/seller ve aynı iki ana aday kullanılır:

- daha hazır, 27 yaşında, ability `79` oyuncu
- 20 yaşında, ability `72`, potential `92` oyuncu

Beklenti:

- düşük youth orientation (`20`) ilk olarak hazır oyuncuyu seçer,
- yüksek youth orientation (`90`) ilk olarak genç/yüksek potansiyelli oyuncuyu seçer.

Bu test aggregate transfer sayısına bakmadan ürün davranışını doğrudan kanıtlar.

## İlk kabul baseline'ı

Canonical seed `20260903`, 20 sezon:

- convergence: `4` iterasyon
- cycle: `false`
- elections: `240`
- reelected/lost: `156/84 → 159/81`
- election outcome differences: `49`
- manager changes: `85 → 86`
- transfers: `133 → 157`
- transfer volume: `1.201,05M → 1.417,94M`
- installment deals: `66 → 79`
- installment commitment: `230,59M → 261,26M`
- final cash: `1.195,96M → 1.217,05M`
- final debt: `381,94M → 347,57M`
- emergency borrowing: `189,81M → 144,39M`
- unique final presidents: `129`
- world changed: `true`
- validation: `0`

Iteration path:

`91/141/156-84 → 88/154/155-85 → 86/157/159-81 → stable 86/157/159-81`

Sıra: `manager changes / transfers / reelected-lost`.

## Yorum sınırı

M24 aggregate transfer sayısını `133 → 157` artırdı. Bu, feedback dünyasının sonucu olabilir; **causal ürün kuralı değildir**.

Kalıcı causal invariant:

> düşük youth orientation < neutral youth signal < yüksek youth orientation

ve kontrollü seçim testinde yüksek yönelimli başkanın genç/yüksek potansiyelli adayı öne almasıdır.

## Orchestration

M22 duplicate-free canonical yaklaşımı genişletilir. En yeni M24 runner tek çözümde nested M19/M20/M21/M23 baselinelarını ve M24 sonucunu doğrular.

## İlk CI sonucu

İlk M24 ölçüm koşusu `33923054029`:

- analyzer PASS
- normal/non-canonical testler PASS
- M0–M18 PASS
- combined M19–M24 PASS
- validation `0`

Final merge kararı, sıkı guard + doğrudan causal test içeren son branch HEAD CI'sinden sonra verilecektir.
