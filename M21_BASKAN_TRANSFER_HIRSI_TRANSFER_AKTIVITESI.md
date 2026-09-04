# M21 — Başkan Transfer Hırsı → Transfer Aktivitesi I

## Amaç

M17'de üretilen `transferAmbition` trait'ini ilk kez gerçek transfer davranışına bağlamak.

Temel ürün ilkesi:

> **Aynı bütçeye sahip iki başkan aynı transfer hareketliliğini göstermek zorunda değildir.**

M20 `financialDiscipline` ile **ne kadar harcanabileceğini** belirler. M21 `transferAmbition` ile **bir transfer penceresinde ne kadar aktif olunacağını** belirler. Bu iki kavram bilinçli olarak ayrıdır.

## Davranış politikası

Yeni `TransferActivityPolicy` yalnız `maxDealsPerWindow` taşır.

`PresidentTransferAmbitionActivityPolicy`:

- `transferAmbition < 45` → `1` tamamlanmış transfer slotu,
- `45..74` → `2` slot,
- `>=75` → `3` slot.

Trait `20..90` aralığına clamp edilir.

Neutral davranış `transferAmbition=60` için eski transfer motorundaki sabit `2` slotu birebir korur.

## Bilinçli olarak değiştirilmeyenler

M21 yalnız aktivite seviyesini değiştirir. Şunlara dokunmaz:

- candidate shortlist: `8`,
- pozisyon ihtiyacı hesabı,
- oyuncu aday skoru,
- seller ask,
- buyer maximum bid,
- transfer bütçe/affordability sınırları,
- taksit kabul olasılığı,
- `riskAppetite`,
- `youthOrientation`.

Bu ayrım sayesinde M21 sonucu doğrudan `transferAmbition` etkisine bağlanabilir.

## Sezon/president zamanlaması

Transfer penceresi sonraki sezon kadrosunu kurduğu için activity provider da M20 bütçe provider'ı gibi `seasonIndex + 1` başkanını kullanır.

Seçim sonrası gelen yeni başkan kendi ilk yaz transfer penceresinin hem mali disiplinini hem transfer hırsını kontrol eder.

## Feedback mimarisi

M21 baseline olarak M20'nin yakınsamış final president/world çözümünü kullanır:

`M20 final president timeline`
→ `managerPatience + financialDiscipline + transferAmbition`
→ `manager decisions + budget policy + activity slots`
→ `advanced transfer world`
→ `promise/fan/media/reputation`
→ `election/turnover`
→ `new president timeline`
→ sabitlenene kadar replay.

Timeline sabitlenirse convergence. Daha önce görülen timeline tekrar oluşursa cycle. Varsayılan maksimum iterasyon `8`.

## Neutral regresyon

Activity provider verilmezse `TransferActivityPolicy.neutral` kullanılır ve eski `2` slot davranışı korunur.

Ayrıca 4 sezonluk advanced-world testinde:

- provider olmayan eski dünya,
- her kulüp/sezon için neutral activity provider döndüren dünya

aynı signature'ı üretmek zorundadır.

## Canonical seed — 20260903

M20 baseline:

- reelected/lost: `158 / 82`
- manager changes: `83`
- transfers: `153`
- transfer volume: `1.387,32M`
- installment deals: `80`
- installment commitment: `279,65M`
- final cash: `1.226,59M`
- final debt: `363,58M`
- emergency borrowing: `159,05M`

M21 ilk kabul ölçümü:

- iterations: `4`
- converged: `true`
- cycle: `false`
- elections: `240`
- reelected/lost: `150 / 90`
- M20/M21 election outcome differences: `48`
- manager changes: `80`
- transfers: `161`
- transfer volume: `1.461,55M`
- installment deals: `73`
- installment commitment: `247,61M`
- final cash: `1.180,63M`
- final debt: `330,25M`
- emergency borrowing: `123,89M`
- unique final presidents: `138`
- world changed: `true`
- validation: `0`

Iteration path:

1. `manager=88`, `transfer=145`, `volume=1.313,98M`, `158/82`, diff `48`
2. `manager=82`, `transfer=148`, `volume=1.356,44M`, `151/89`, diff `35`
3. `manager=80`, `transfer=161`, `volume=1.461,55M`, `150/90`, diff `7`
4. stable `manager=80`, `transfer=161`, `volume=1.461,55M`, `150/90`, diff `0`

## Sonuç yorumu

M21 aggregate transfer sayısını `153 → 161` ve hacmi yaklaşık `%5,35` artırdı. Bu artış kontrollüdür; piyasa ne dondu ne hiperaktif hale geldi.

Ancak M21'in ürün doğruluğu aggregate artışa bağlı değildir. Dünya aynı anda düşük, orta ve yüksek ambition başkanları içerir. Doğrudan causal invariant şudur:

`low ambition slot < neutral slot < high ambition slot`.

Aggregate dünya sonucu yalnız denge/regresyon metriğidir.

Aynı nedenle installment, cash, debt ve emergency borrowing değişimleri tek başına `transferAmbition` için evrensel ekonomik yasa olarak yorumlanmaz. Transfer yolu sportif sonuçları ve seçimleri değiştirdiği için sonraki president timeline da değişir.

## Canonical guard'lar

Seed `20260903`, 20 sezon için:

- convergence zorunlu, cycle yasak,
- iteration `3–6`,
- son iteration stable, election diff `0`,
- baseline M20 `158/82`, manager `83`, transfer `153`,
- final-vs-baseline election diff `25–80`,
- final reelections `135–165`, losses `75–105`,
- final manager changes `70–95`, manager delta mutlak `≤20`,
- final transfers `140–185`, transfer delta mutlak `5–35`,
- transfer volume `1,2B–1,7B`, volume delta mutlak `≤300M`,
- installment deals `55–95`,
- installment commitment `180M–330M`,
- final cash `1,0B–1,4B`,
- final debt `250M–430M`,
- emergency borrowing `80M–200M`,
- unique final presidents `120–150`,
- world değişmeli.

## CI ve performans notu

İlk M21 PR CI'sında analyzer + `79` test + M0–M20 runner zinciri yaklaşık `4 dk 48 sn` sürdü. M21 canonical runner eklendiği için workflow timeout'u `5` dakikadan `7` dakikaya çıkarıldı.

Bu sadece M21'i güvenli biçimde tamamlamak için kabul edilen geçici ölçekleme alanıdır. M22 ve sonrası için her yeni trait milestone'unun içeride M19 → M20 → M21 → yeni fixed-point zincirini tekrar tekrar baştan çözmesi sürdürülebilir değildir.

M22 öncesi/başında değerlendirilmesi gereken teknik borç:

- ortak profile-feedback orchestration katmanı,
- önceki converged baseline'ın yeniden kullanılabilmesi,
- nested milestone engine çağrılarının azaltılması,
- canonical runner'larda aynı full-career hesabının gereksiz tekrarlanmasının önlenmesi.

Kalite azaltılmayacak; optimizasyon aynı deterministik sonucu daha az tekrar hesaplayarak elde edilecek.
