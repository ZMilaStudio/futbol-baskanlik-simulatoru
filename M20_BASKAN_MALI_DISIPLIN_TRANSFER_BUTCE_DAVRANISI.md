# M20 — Başkan Mali Disiplini → Transfer Bütçe Davranışı I

## Amaç

M17'de üretilen `financialDiscipline` trait'ini ilk kez gerçek transfer harcama sınırlarına bağlamak:

> **Mali disiplinli ve savurgan başkan aynı kasa koşulunda aynı transfer bütçesine sahip olmamalı.**

M20 yalnız mali disiplini bağlar. `transferAmbition`, `riskAppetite`, `youthOrientation` ve oyuncu seçim mantığı bu milestone'da değiştirilmez.

## Bütçe politikası

Nötr referans `financialDiscipline = 60` ve M8–M19 transfer davranışını birebir korur:

- nakit rezervi: `2,0M`
- transfer penceresi harcama tavanı: mevcut kasanın `%35`i
- taksitli transfer toplam taahhüt tavanı: mevcut kasanın `%90`ı

Trait `20..90` aralığına clamp edilir. `d = financialDiscipline - 60` olmak üzere:

- reserve cash = `2.000.000 + d × 30.000`
- window spend cap bps = `3500 - d × 25`, clamp `2500..4700`
- installment commitment cap bps = `9000 - d × 50`, clamp `7000..11500`

Örnek uçlar:

| Mali disiplin | Nakit rezerv | Pencere tavanı | Taksit taahhüt tavanı |
| ---: | ---: | ---: | ---: |
| 20 | 0,8M | %45,0 | %110 |
| 60 | 2,0M | %35,0 | %90 |
| 90 | 2,9M | %27,5 | %75 |

Düşük disiplin daha fazla nakdi transfer için açar; yüksek disiplin daha fazla nakit tamponu tutar ve toplam harcama/taahhüt sınırını düşürür.

## Bilinçli olarak değiştirilmeyenler

M20'nin etkisini izole tutmak için şunlara dokunulmadı:

- transfer aday sıralaması,
- pozisyon ihtiyacı,
- satıcının istediği fiyat,
- alıcının maksimum teklif oranı,
- transfer sayısı hedefi,
- `transferAmbition`,
- `riskAppetite`,
- `youthOrientation`.

Dolayısıyla M20 'daha çok transfer yapmak isteyen başkan' modeli değildir. Yalnız mevcut transfer kararlarının finansal olarak ne kadarının karşılanabileceğini değiştirir.

## Başkanlık zamanlaması

Transfer penceresi sezon sonu `seasonIndex` sırasında açılır fakat kadro **sonraki sezon** için kurulur. Bu nedenle bütçe politikası `seasonIndex + 1` tarihinde görevde olan başkandan alınır.

Sonuç: seçim kaybından sonra gelen yeni başkan, göreve başlayacağı sezonun yaz transfer bütçesini kontrol eder. Giden başkan gelecekteki pencereye politika taşımaz.

## M19 üzerine feedback

M20 sıfırdan yeni başkanlık zinciri kurmaz. Önce M19'un yakınsamış final dünyasını baseline olarak çözer; ardından aynı fixed-point mantığını iki trait ile yeniden yürütür:

`president timeline → managerPatience + financialDiscipline → manager/world/transfer → promise/fan/media/reputasyon → election → president timeline`

- `managerPatience` teknik direktör görev güvenliğini etkiler.
- `financialDiscipline` transfer bütçe sınırlarını etkiler.
- Timeline değişirse aynı seed ile yeniden replay edilir.
- Timeline sabitse convergence.
- Daha önce görülen timeline tekrar oluşursa cycle ve validation FAIL.
- Varsayılan maksimum iterasyon `8`.

## Neutral regresyon

Ayrı test, `TransferBudgetPolicy.neutral` provider'ı ile çalışan advanced world'ün provider olmadan çalışan eski advanced world ile aynı signature'ı üretmesini zorunlu tutar.

Bu test M20 kapalı/nötr olduğunda M0–M19 transfer davranışının bit-bit değişmediğini korur.

## Canonical kabul adayı — seed 20260903

M19 baseline:

- reelected/lost `160 / 80`
- manager changes `84`
- transfers `168`
- transfer volume `1.562,93M`
- installment deals `81`
- installment commitment `278,90M`
- final cash `1.191,15M`
- final debt `347,04M`
- emergency borrowing `148,22M`

M20 ilk sonuç:

- iterations `5`
- converged `true`
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

| Tur | Timeline | Manager | Transfer | Hacim | Taksitli | Cash | Debt | Seçim | Diff |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | değişti | 98 | 158 | 1.461,45M | 82 | 1.222,04M | 395,97M | 157/83 | 53 |
| 2 | değişti | 88 | 150 | 1.401,56M | 74 | 1.212,68M | 357,45M | 157/83 | 34 |
| 3 | değişti | 84 | 160 | 1.466,16M | 84 | 1.217,73M | 355,75M | 156/84 | 27 |
| 4 | değişti | 83 | 153 | 1.387,32M | 80 | 1.226,59M | 363,58M | 158/82 | 12 |
| 5 | sabit | 83 | 153 | 1.387,32M | 80 | 1.226,59M | 363,58M | 158/82 | 0 |

## Sonucun yorumu

Mali disiplin davranışının devreye girmesi canonical dünyada transfer sayısını `168 → 153`, hacmi yaklaşık `%11,2` düşürdü. Manager değişimi `84 → 83` ile hemen hemen sabit kaldı; yani etki teknik direktör sistemini domine etmedi.

Toplam final cash yükselirken debt ve emergency borrowing de hafif yükseldi. Bu çelişki değildir ve 'yüksek mali disiplin borcu artırır' sonucu çıkarılamaz. Dünya aynı anda düşük, orta ve yüksek disiplinli başkanlar içerir; bütçe farkı oyuncu hareketlerini, sportif sonuçları, lig geçişlerini, vaatleri ve sonraki başkanları değiştirir. M20'nin hedefi her kariyerde toplam borcu mekanik olarak azaltmak değil, **başkan karakterine göre gerçek harcama sınırı üretmektir**.

Trait'in nedensel yönü politika seviyesinde monotonic testlerle; eski davranışın korunması ise neutral-world signature testiyle kilitlenir. Aggregate dünya ekonomisi ayrı balance guard'larıyla izlenir.

## Canonical balance guard'ları

- convergence zorunlu, cycle yasak,
- canonical iteration `3–7`,
- son tur timeline stable ve election diff `0`,
- M19 baseline `160/80`, manager `84`, transfers `168`,
- final election difference `25–90`,
- final reelections `140–175`, losses `65–100`,
- final manager changes `70–105`, delta mutlak `≤25`,
- final transfers `130–190`, delta mutlak `≤50`,
- transfer volume `1,10B–1,70B`, baseline sapması mutlak `≤400M`,
- installment deals `60–100`,
- installment commitment `200M–360M`,
- final cash `900M–1,50B`,
- final debt `250M–500M`,
- emergency borrowing `80M–250M`,
- unique final presidents `110–145`,
- world signature değişmeli.

## Sonraki yön

M21 adayı: **Başkan Transfer Hırsı → Transfer Aktivitesi I**.

Yalnız `transferAmbition` bağlanmalı. `riskAppetite` yine ayrı tutulmalı; böylece 'ne kadar harcayabilirim?' ile 'ne kadar aktif transfer yapmak istiyorum?' birbirine karıştırılmaz.
