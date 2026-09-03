# Futbol Başkanlık Simülatörü — M3 Temel Kulüp Ekonomisi

**Milestone:** M3 — Temel Ekonomi  
**Amaç:** M2 oyuncu/kadro kariyerinin üzerine deterministik ve muhasebe olarak tutarlı bir kulüp finans yaşam döngüsü eklemek.

## Kapsam

- integer minor-unit tabanlı `Money`
- kulüp açılış nakdi ve borcu
- merkezi gelir
- sponsor geliri
- maç günü geliri
- lig derecesine bağlı başarı geliri
- oyuncu kalitesinden türetilen geçici maaş modeli
- temel işletme gideri
- borç faizi
- borç anapara geri ödemesi
- nakit yetersizliğinde açıkça kaydedilen acil finansman
- finansal sağlık sınıflandırması
- 20 sezon ekonomi kariyeri
- nakit/borç denklem validator'ı
- uzun kariyer ekonomi sanity guard'ları
- M0, M1 ve M2 regresyonlarının korunması

## Kapsam dışı

- transfer ücretleri
- gerçek oyuncu sözleşmeleri
- maaş pazarlığı
- transfer taksitleri
- bilet fiyatı kararı
- tesis yatırımı
- sponsor seçimi/pazarlığı
- başkan bütçe kararı
- finansın kadro kararlarını geri beslemesi
- Flutter UI / APK

Bu kapalı döngü M4 transfer pazarıyla başlayacaktır.

## Para sözleşmesi

Parasal değerler `double` olarak saklanmaz.

`Money` bütün değerleri integer `minorUnits` olarak tutar. Yüzde/oran işlemleri basis-point (`10.000 = %100`) üzerinden integer aritmetik ile yapılır.

Bu karar uzun kariyerde kayan nokta birikimini ve muhasebe denklemi sapmalarını önlemek içindir.

## Muhasebe sözleşmesi

Gelirler:

- merkezi gelir
- sponsor
- maç günü
- lig başarı ödülü

Kâr/zarar giderleri:

- oyuncu maaşları
- işletme giderleri
- faiz

**Borç anapara ödemesi gider değildir.** Nakit çıkışı ve borç bakiyesi azalması olarak ayrı tutulur.

Nakit denklemi:

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

Borç denklemi:

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Her sezon her kulüp için bu iki denklem validator tarafından doğrulanır.

## Gelir modeli — M3 baseline

Merkezi gelir tüm M0 lig kulüpleri için başlangıçta sabit tabandır.

Sponsor ve maç günü gelirleri takımın o sezonki kadrodan türetilmiş gücüyle ölçeklenir.

Lig ödülü final sırasına göre farklılaşır; şampiyon daha yüksek ödül alır.

Bu değerler nihai oyun ekonomisi değildir. M3 amacı ekonomik veri akışını ve 20 yıllık sürdürülebilirliği test etmektir.

## Maaş modeli — geçici köprü

M2 oyuncularında henüz sözleşme/maaş alanı bulunmadığı için M3 maaşı oyuncunun:

- mevcut seviyesi
- genç oyuncularda potansiyel farkı
- yaş dönemi

üzerinden deterministik olarak tahmin eder.

Bu **nihai sözleşme sistemi değildir**. Sözleşme ve gerçek maaş pazarlığı geldiğinde bu köprü model değiştirilecektir.

## Borç davranışı

- açılış borcu kulüp gücü ve kariyer seed'iyle deterministik oluşturulur,
- yıllık faiz giderdir,
- her sezon açılış borcunun `%5`i kadar normal anapara geri ödemesi yapılır,
- fazla nakdin otomatik olarak ek borç kapatmasına dönüştürülmesi **reddedildi ve kaldırıldı**,
- sezon sonu nakit minimum güvenlik seviyesinin altına düşerse fark `emergencyBorrowing` olarak yeni borç kaydedilir.

Negatif nakdi görünmez biçimde sıfırlamak yasaktır.

## Finansal sağlık

İlk sınıflar:

- `veryStrong`
- `solid`
- `balanced`
- `tight`
- `debtCrisis`

Sınıflandırma kapanış nakdi, yıllık gider kapsamı, borç/gelir oranı ve acil borçlanma ihtiyacına bakar.

## Denge iterasyonu

İlk gerçek 20 sezon CI koşusu teknik olarak PASS verdi fakat ekonomik olarak reddedildi:

- final toplam nakit: `1.017,03M`
- final toplam borç: `0,00M`
- acil finansman: `0,00M`
- 8/8 kulüp: `veryStrong`

Bu sonuç uzun kariyer için açık biçimde aşırı refah ürettiği için merge edilmedi.

Düzeltme:

- yapısal işletme giderleri yükseltildi,
- fazla nakitle otomatik ek borç kapatma kaldırıldı,
- finansal sağlık eşikleri sıkılaştırıldı.

Kabul edilen seed `20260903` / 20 sezon baseline sonucu:

- final toplam nakit: `124,28M`
- final toplam borç: `104,43M`
- toplam acil finansman: `67,44M`
- `veryStrong`: 2 kulüp
- `solid`: 2 kulüp
- `balanced`: 2 kulüp
- `debtCrisis`: 2 kulüp
- validation issue: `0`

Bu dağılım M3 için kusursuz nihai ekonomi olarak değil, transfer ve başkan kararları gelmeden önce **çeşitlilik üreten, evrensel refah veya evrensel çöküş yaratmayan kabul edilebilir baseline** olarak kilitlenmiştir.

## Kalıcı ekonomi sanity guard'ları

Seed `20260903` 20 sezon baseline için geniş alarm sınırları CI testine eklenmiştir:

- final toplam nakit `20M–500M` aralığında,
- final toplam borç `0–400M` aralığında ve sıfırdan büyük,
- toplam acil finansman `<250M`,
- final sağlık dağılımında en az 2 farklı sınıf,
- `debtCrisis` kulüp sayısı en fazla 4,
- `veryStrong` kulüp sayısı en fazla 4.

Bunlar nihai denge hedefi değildir; gelecekte ekonominin yeniden patlamasını veya tüm ligin aynı sonuca sürüklenmesini yakalayan regresyon alarmlarıdır.

## Kalite kapısı

M3 PR kalite kapısı:

- `dart analyze`: PASS
- toplam otomatik test: `15/15 PASS`
- M0 100 sezon regresyonu: PASS
- M1 20 sezon kariyeri: PASS
- M2 20 sezon oyuncu kariyeri: PASS
- M3 20 sezon ekonomi kariyeri: PASS
- finance validation issue: `0`
- ekonomi sanity guard: PASS
- artifact sayısı: `0`

Sonraki milestone: **M4 — Basit Transfer Pazarı**.
