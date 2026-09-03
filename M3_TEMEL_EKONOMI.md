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
- yüksek nakitte sınırlı ek borç azaltımı
- nakit yetersizliğinde açıkça kaydedilen acil finansman
- finansal sağlık sınıflandırması
- 20 sezon ekonomi kariyeri
- nakit/borç denklem validator'ı
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
- her sezon zorunlu anapara azaltımı yapılır,
- nakit rezervi yüksekse kalan borca sınırlı ekstra ödeme yapılabilir,
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

## Kalite kapısı

M3 ancak GitHub Actions üzerinde aşağıdakilerin tamamı PASS olduğunda kapanır:

- `dart analyze`
- tüm M0 + M1 + M2 + M3 testleri
- M0 100 sezon regresyonu
- M1 20 sezon kariyeri
- M2 20 sezon oyuncu kariyeri
- M3 20 sezon ekonomi kariyeri
- sıfır finance validation issue
- artifact sayısı 0

Sonraki milestone: **M4 — Basit Transfer Pazarı**.
