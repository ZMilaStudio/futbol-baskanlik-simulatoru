# Futbol Başkanlık Simülatörü — M4 Basit Transfer Pazarı

**Milestone:** M4 — Basit Transfer Pazarı  
**Durum:** Kabul edilen baseline / kalite kapısı adayı  
**Amaç:** M2 oyuncu yaşam döngüsü ile M3 kulüp ekonomisini ilk kez kapalı döngüde birbirine bağlamak.

## Kapsam

- deterministik oyuncu piyasa değeri
- kulüp pozisyon ihtiyacı
- satıcı kabul fiyatı
- alıcı maksimum fiyatı
- doğrudan bonservis
- nakit rezervi ve harcama limiti
- oyuncunun kulüp değiştirmesi
- bonservisin alıcı/satıcı nakdine işlenmesi
- transfer sonrası takım gücünün sonraki sezonda yeniden türetilmesi
- sezonlar arası transfer penceresi
- 20 sezon transfer kariyeri
- transfer muhasebe validator'ı
- uzun kariyer transfer pazarı sanity guard'ı

## Kapsam dışı

- kiralık transfer
- transfer taksiti
- performans bonusu
- satıştan pay
- takas
- oyuncu sözleşmesi
- maaş pazarlığı
- menajer komisyonu
- oyuncunun kişisel transfer tercihi

Bunlar M4'ün doğruluğu kanıtlandıktan sonra ayrı sistemler olarak eklenebilir.

## Piyasa değeri

`MarketValueModel` oyuncunun:

- mevcut yeteneği
- yaşı
- potansiyel farkı

üzerinden deterministik `Money` değeri üretir.

Temel prensip:

> **Piyasa değeri ile gerçek transfer fiyatı aynı değildir.**

Genç ve gelişim payı yüksek oyuncular aynı yetenekteki yaşlı oyunculardan daha değerlidir.

## Kulüp ihtiyacı

M4 kadro hedefleri:

- kaleci: 2
- defans: 6
- orta saha: 6
- forvet: 4

Alıcı kulüp pozisyon açığı ve pozisyon kalitesini birlikte değerlendirir. Transfer hedefi yalnız en yüksek overall oyuncu değildir; kadronun en çok ihtiyaç duyduğu bölge önceliklidir.

## Transfer güvenlik sınırları

- kulüp başına bir pencerede en fazla 2 satın alma
- minimum 2M nakit rezervi
- tek transfer penceresinde kullanılabilecek tutar mevcut nakdin en fazla `%35`i
- satıcı kulübün kadrosu 15 oyuncunun altına indirilemez
- pozisyon bazında minimum satış tabanı korunur
- aynı oyuncu aynı transfer penceresinde iki kez taşınamaz
- oyuncu kendi kulübüne transfer edilemez

## Pazarlık modeli

Satıcı fiyatı aşağıdaki sinyallerden türetilir:

- piyasa değeri
- pozisyon kıtlığı
- genç oyuncu / yüksek potansiyel primi
- kulübün finansal baskısı
- seed tabanlı küçük deterministik pazarlık farkı

Finansal baskı davranışı:

- nakit `<=3M` ise satıcı talebi yaklaşık `%8` aşağı yumuşayabilir,
- borç nakitten yüksekse yaklaşık `%4` aşağı yumuşayabilir.

Alıcı maksimum fiyatı:

- piyasa değeri
- pozisyon açığının büyüklüğü
- deterministik pazarlık farkı

üzerinden belirlenir.

Transfer yalnız:

`Satıcı talebi <= Alıcı maksimumu <= Kulübün ödeyebileceği sınır`

mantığıyla gerçekleşir.

## Transfer muhasebesi

Transfer ücreti yeni para yaratmaz.

Bir `fee` için:

`Alıcı nakit = Alıcı nakit - fee`

`Satıcı nakit = Satıcı nakit + fee`

Transfer işlemi sırasında kulüp borcu değişmez.

Bonservis, sezon kapanış finansından sonra transfer penceresinde işlenir. Ortaya çıkan transfer sonrası nakit/borç bakiyesi bir sonraki sezonun açılış finansıdır.

`TransferCareerValidator` her sezon şunları doğrular:

- aynı oyuncu aynı pencerede bir kez hareket eder,
- self-transfer yoktur,
- bonservis pozitiftir,
- kulüpler geçerlidir,
- alıcı/satıcı nakit hareketi tam bonservis kadar gerçekleşir,
- transfer borcu doğrudan değiştirmez,
- negatif transfer sonrası nakit oluşmaz,
- sonraki sezon açılış finansı önceki transfer sonrası finansla birebir eşleşir,
- final finans durumu son sezon durumuyla tutarlıdır.

## Kabul edilen M4 baseline

Seed `20260903` / 20 sezon son CI sonucu:

- sezon: `20`
- transfer: `32`
- toplam transfer hacmi: `161,68M`
- ortalama bonservis: `5,05M`
- final toplam nakit: `96,38M`
- final toplam borç: `58,61M`
- final aktif oyuncu: `148`
- validation issue: `0`

Final takım güçleri:

- Kuzey Yıldızı SK: `79,30`
- Vadişehir FK: `74,13`
- Demirkent 1912: `73,65`
- Mavi Liman: `68,20`
- Çınarspor: `67,79`
- Ufukşehir FK: `62,92`
- Gölova SK: `61,15`
- Hisar Birliği: `59,48`

Bu değerler nihai oyun ekonomisi değildir. M4'ün amacı transfer pazarının donmadan, hiperaktif olmadan ve kulüp ekonomisini bozmadan 20 sezon yaşayabildiğini doğrulamaktır.

## Kalıcı M4 sanity guard

Seed `20260903` 20 sezon baseline için CI geniş alarm aralıkları:

- toplam transfer: `15–120`
- toplam transfer hacmi: `40M–500M`
- final toplam nakit: `20M–500M`
- final toplam borç: `>0` ve `<400M`
- en az 4 farklı kulüp transfer piyasasına katılmalı
- final kulüp nakit/borçları negatif olamaz

Bu sınırlar ince oyun dengesi değil, transfer pazarının donmasını veya ekonomik patlamasını yakalayan regresyon bariyerleridir.

## Kalite kapısı

M4 ancak aşağıdakilerin tamamı PASS olduğunda kapanır:

- `dart analyze`
- tüm M0 + M1 + M2 + M3 + M4 testleri
- M0 100 sezon regresyonu
- M1 20 sezon kariyeri
- M2 20 sezon oyuncu kariyeri
- M3 20 sezon ekonomi kariyeri
- M4 20 sezon transfer kariyeri
- transfer validation issue `0`
- M4 sanity guard PASS
- artifact sayısı `0`

Sonraki milestone: **M5 — 48 Kulüp / 3 Lig**.
