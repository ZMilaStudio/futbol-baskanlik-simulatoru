# M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi

## Amaç

M7'nin amacı M3'ten beri kullanılan geçici kadro maaşı tahminini gerçek oyuncu sözleşmelerine dönüştürmek ve sözleşme süresini ekonomi ile transfer pazarının gerçek girdisi yapmaktır.

M7 ile oyuncu artık yalnız kulübe bağlı bir kayıt değildir; aktif kulüp ilişkisi süreli ve maaşlı bir kontratla temsil edilir.

## Kapsam

### PlayerContract

Her aktif kulüp kontratı şunları taşır:

- `playerId`
- `clubId`
- `startSeasonIndex`
- `endSeasonIndex`
- `annualWage`

Para yine integer minor-unit `Money` ile tutulur.

### Başlangıç kontratları

Kariyer başında 864 oyuncunun tamamına career seed, simulation version, sezon ve oyuncu ID'sinden türetilen deterministik sözleşme yazılır.

Süre yaşa göre değişir. Genç oyuncular daha uzun, 31+ oyuncular daha kısa kontrat alma eğilimindedir.

### Gerçek maaş gideri

`BasicEconomyEngine`, M7 kontrat controller'ı aktifken kulüp bazında gerçek sözleşme maaş toplamını kullanır.

Geriye dönük uyumluluk için gerçek maaş map'i verilmezse eski `WageModel` yolu aynen çalışır. Böylece M0–M6 baseline'ları değişmez.

### Sözleşme bitişi

Sezon geçişinde biten kontrat için iki sonuç vardır:

1. yenileme
2. serbest kalma

Kararda oyuncunun yaşı, mevcut seviyesi, potansiyel farkı, deterministik varyasyon ve kadro güvenliği dikkate alınır. Kadrosu kritik seviyeye düşmüş kulüp oyuncuyu otomatik bırakmaz.

### Serbest oyuncu

`Player.freeAgentClubId = '__free_agent__'` özel kimliği kullanılır. `clubId` nullable yapılmamıştır; böylece mevcut oyuncu yaşam döngüsü ve veri modeli gereksiz yere kırılmamıştır.

Serbest oyuncu:

- normal bonservis pazarında satıcı kulüp gibi değerlendirilmez,
- maaş giderine dahil edilmez,
- kontratı yoktur,
- kulüpler tarafından ayrı free-agent imza adımında alınabilir.

Free-agent alımları mevki ihtiyacı, yaş/kalite ve maaş karşılanabilirliği dikkate alınarak yapılır.

### Genç oyuncu kontratı

Her youth intake oyuncusu yeni sezon için ilk profesyonel sözleşmesini alır. M5 dünya ölçeğinde her offseason 48 youth intake olduğu için 19 geçişte 912 genç kontratı oluşur.

### Transfer sonrası kontrat

Normal bonservis transferi tamamlandığında oyuncunun eski kontratı yeni kulüpte devam etmez. Alıcı kulüple yeni 3–5 yıllık kontrat ve maaş yazılır.

### Kontrat süresi ve piyasa değeri

`MarketValueModel.value` opsiyonel `contractYearsRemaining` kabul eder.

Geniş ilk katsayılar:

| Kalan süre | Değer katsayısı |
|---|---:|
| 0 veya altı | %25 |
| 1 yıl | %70 |
| 2 yıl | %90 |
| 3 yıl | %103 |
| 4 yıl | %110 |
| 5+ yıl | %115 |

Parametre verilmezse eski M4–M6 market value davranışı korunur.

Bu, temel tasarım ilkesini ilk kez gerçek sisteme taşır:

> **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**

Sözleşme süresi piyasa değerini etkiler; satıcı talebi ve alıcı maksimumu hâlâ transfer pazarlığının ayrı katmanlarıdır.

## Mimari

M6'nın manager hook'u ile kontrat sistemi birbirine gömülmemiştir.

Yeni `WorldRosterHooks` katmanı şunları sağlar:

- sezonluk gerçek maaş toplamı
- offseason kadro hazırlığı
- transfer öncesi kontrat süresi bilgisi
- transfer sonrası kontrat güncellemesi

Varsayılan `NoopWorldRosterHooks` tamamen etkisizdir. `WorldCareerEngine` aynı anda:

- `WorldCareerHooks` → manager gibi sportif/season lifecycle sistemleri
- `WorldRosterHooks` → kontrat/kadro/maaş sistemleri

kullanabilir.

Otomatik test manager + contract hook'larının aynı world motorunda birlikte çalıştığını doğrular.

## Kabul edilen baseline — seed 20260903

20 sezon / 48 kulüp / 3 lig:

- maç: `14.400`
- başlangıç kontratı: `864`
- final aktif kontrat: `874`
- yenileme: `3.757`
- serbest kalma: `1.143`
- serbest oyuncu imzası: `776`
- final serbest oyuncu: `32`
- youth kontratı: `912`
- transfer sonrası kontrat: `103`
- final yıllık toplam maaş: `491,27M`
- final ortalama yıllık oyuncu maaşı: `562.091`
- bonservis transferi: `103`
- transfer hacmi: `868,67M`
- final toplam nakit: `1.060,80M`
- final toplam borç: `554,81M`
- toplam emergency borrowing: `428,76M`
- validation issue: `0`

Bu değerler nihai oyun dengesi değildir. M7 için amaç kontrat piyasasının donmaması/patlamaması ve ekonominin 20 sezonda yaşamaya devam etmesidir.

## Geniş regresyon kapıları

Seed baseline'ın birebir sayıları test şartı yapılmamıştır. İleride denge değişikliklerine alan bırakmak için geniş guard'lar kullanılır:

- yenileme: `1.500–7.000`
- release: `300–2.500`
- free-agent signing: `200–2.000`
- final free agent: `5–100`
- bonservis transferi: `40–300`
- final toplam yıllık maaş: `200M–900M`
- final nakit: `100M–2B`
- final borç: `100M–2B`

## Geriye dönük uyumluluk

M7 CI içinde eski yollar ayrıca çalıştırılır.

Seed `20260903` M5 baseline'ı M7 eklenmesine rağmen aynen kalmıştır:

- transfer `71`
- hacim `637,91M`
- final cash `862,25M`
- final debt `647,04M`
- emergency `569,03M`
- validation `0`

M6 manager baseline'ı da değişmemiştir.

## Bilinçli kapsam dışı

M7'de henüz yok:

- imza parası
- performans bonusu
- serbest kalma maddesi
- oyuncu menajeri/temsilcisi
- oyuncuyla etkileşimli maaş pazarlığı
- kiralık
- taksitli bonservis
- satın alma opsiyonu/zorunluluğu
- satıştan pay
- takas
- maaş paylaşımı
- Flutter UI/APK

## Sonraki adım

**M8 — Gelişmiş Transfer Yapıları I: Kiralık + Taksit.**

M7 ile gerçek kontrat ve maaş tabanı oluştuğu için artık borçlu veya nakdi sınırlı kulüplerin transfer pazarında daha akıllı davranmasını sağlayan ilk iki yapı güvenli biçimde eklenebilir.
