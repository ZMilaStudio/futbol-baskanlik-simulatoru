# M8 — Gelişmiş Transfer Yapıları I: Kiralık + Taksit

**Durum:** PASS adayı — final PR CI ile kilitlenecek  
**Seed:** `20260903`  
**Dünya:** 48 kulüp / 3 lig / 20 sezon / 14.400 maç

## Amaç

M8, projenin ana transfer ilkesini ilk kez gelişmiş finansman yapılarıyla gerçek sisteme taşır:

> **Paran yoksa transfer yapamazsın değil; paran yoksa daha akıllı transfer yapmak zorundasın.**

M8 yalnız iki yapı ekler:

1. sezonluk kiralık,
2. upfront + gelecek sezon taksitli kalıcı transfer.

Satın alma opsiyonu/zorunluluğu, bonus, satıştan pay, takas ve oyuncu+para bilinçli olarak kapsam dışıdır.

---

## 1. Taksitli bonservis

### Domain

- `TransferInstallment`
- `TransferInstallmentObligation`
- `TransferDeal.upfrontFee`
- `TransferDeal.installments`

Toplam transfer bedeli şu invariantı korur:

`upfront + taksitler = toplam bonservis`

Taksit yükümlülüğü **banka borcu değildir**. Kulübün finansal borç bakiyesine eklenmez; ayrı transfer yükümlülüğü olarak tutulur ve vade sezonunda gerçek nakit akışı yaratır.

Bu ayrım önemlidir: banka kredisi ile başka kulübe ödenecek gelecekteki bonservis taksiti aynı ekonomik kavram değildir.

### Ödeme davranışı

M8 ilk kalibrasyonunda:

- yalnız `5M+` bonservislerde taksit değerlendirilebilir,
- upfront yaklaşık `%58–73`,
- kalan tutar iki gelecek sezona bölünür,
- toplam taahhüt alıcının mevcut nakdinin yaklaşık `%90`ını aşamaz,
- satıcının taksiti kabul etmesi zorunludur,
- satıcı ekonomisi kabul olasılığını etkiler.

Final ilk kabul oranları:

- normalde peşin ödeyebilen alıcı için satıcı taksit kabul ihtimali `%10`,
- peşin sınırı aşılmış ve satıcı finans baskısı altındaysa `%48`,
- peşin sınırı aşılmış ama satıcı rahat durumdaysa `%25`.

Bu değerler nihai oyun tasarımı değil, taksidin "varsayılan ödeme şekline" dönüşmesini engelleyen ilk simülasyon kalibrasyonudur.

### Finans akışı

Vadesi gelen taksit:

- alıcı nakdından çıkar,
- satıcı nakdına girer,
- normal işletme gideri/geliri gibi sezon performansını şişirmez,
- nakit yetersizse mevcut emergency-finance davranışı devreye girebilir,
- raporda ödenmiş ve açık gelecek yükümlülük ayrı izlenir.

---

## 2. Kiralık sistemi

### Domain

`LoanAgreement` şunları taşır:

- player ID,
- parent club,
- loan club,
- başlangıç sezonu,
- bitiş sezonu,
- loan fee,
- loan-club wage share.

Oyuncunun kalıcı kontratı parent club'da kalır. Kiralık boyunca oyuncu loan club kadrosunda oynar; sezon sonunda otomatik olarak parent club'a döner.

### Maaş paylaşımı

Loan club maaşın deterministik olarak `%45–80` aralığını üstlenir. Kalan bölüm parent club üzerinde kalır. Böylece kiralama yalnız kadro hareketi değil gerçek maliyet kararıdır.

### Loan fee

- piyasa değerinin yaklaşık `%3,5–7` aralığından türetilir,
- minimum `100K`, maksimum `1,5M`,
- borrower kulüp en az `2M` rezerv korur,
- loan fee mevcut nakdin `%8`inden fazla olamaz,
- para borrower'dan parent club'a birebir taşınır.

### Bağlamsal kiralama

Her kulüp otomatik kiralık yapmaz.

Borrower:

- önce en ihtiyaç duyduğu mevkiyi belirler,
- mevki açığı yok ve kalite ortalaması yeterliyse pazara girmez,
- gerçek ihtiyaç seviyesine göre deterministik katılım kapısından geçer.

Parent club tarafında aday oyuncu:

- 24 yaş veya altında,
- en az `+5` gelişim potansiyeline sahip,
- geçerli parent kontratına sahip,
- parent kadrosunda gerçek fazlalık yaratan mevkide olmalı,
- parent kulüp aynı pencerede en fazla 2 oyuncu kiraya verebilir.

Bu yapı genç oyuncuya süre verirken parent club'ın kadrosunu anlamsız biçimde boşaltmasını önler.

---

## 3. Hook mimarisi

M8 mevcut world engine'i kopyalamadı. İki yeni no-op varsayılanlı genişleme noktası eklendi:

- `WorldFinanceHooks`: sezon içindeki transfer taksit nakit akışları,
- `WorldTransferHooks`: transfer penceresi sonrası kiralık gibi ek hareketler.

M0–M7 bu hook'ları kullanmadığında eski davranışını korur.

`AdvancedTransferController`, M7 kontrat/maaş lifecycle'ını M8 kiralık ve taksit lifecycle'ıyla tek kariyerde birleştirir.

---

## 4. Validator / invariantlar

M8 validator şu sınıflardaki hataları yakalar:

- upfront + taksit toplamı bonservise eşit değil,
- vade/ödeme akışı bozuk,
- alıcı/satıcı taksit nakit hareketi eşleşmiyor,
- loan fee para korunumunu bozuyor,
- kiralık oyuncu yanlış kulüpte,
- parent kontratı kaybolmuş/değişmiş,
- sezon sonu dönüş gerçekleşmemiş,
- aynı oyuncu aynı pencerede çakışan hareketlere girmiş,
- free-agent meşru durumunun yanlış invariant olarak görülmesi.

Same-seed replay ve different-seed divergence testleri de korunur.

---

## 5. Kalibrasyon geçmişi

İlk teknik PASS denge kabulü değildi. Özellikle taksit ve kiralık kullanım sıklığı birkaç kez reddedildi.

### Reddedilen 1

- kalıcı transfer `183`
- taksitli `146`
- kiralık `755`

Sorun: iki gelişmiş yapı da seçenek değil neredeyse varsayılan davranıştı.

### Reddedilen 2

- kalıcı transfer `189`
- taksitli `145`
- kiralık `482`

Kiralık düzeldi; taksit hâlâ aşırı yaygındı.

### Reddedilen 3

- kalıcı transfer `147`
- taksitli `108`
- kiralık `462`

Satıcı ekonomisi taksit kabulüne bağlandı; oran yine çoğunluktu.

### Reddedilen 4

- kalıcı transfer `156`
- taksitli `86`
- kiralık `491`

Taksit oranı `%55` civarında kaldı. Kendi ürün kriterimiz olan "taksit çoğunluk olmayacak" sağlanmadığı için kabul edilmedi.

---

## 6. M8 kabul baseline — seed `20260903`

- sezon `20`
- maç `14.400`
- kalıcı transfer `140`
- taksitli transfer `68` (`%48,6`)
- gelecek taksit taahhüdü `234,79M`
- ödenmiş taksit `232,77M`
- açık gelecek taksit `2,02M`
- toplam kiralık `478`
- final aktif kiralık `32`
- loan fee hacmi `113,15M`
- ortalama loan-club maaş payı `6218 bps` (`%62,18`)
- final toplam nakit `1.017,61M`
- final toplam borç `378,97M`
- emergency borrowing `185,61M`
- validation `0`

### CI denge guard'ları

Nihai ekonomi hedefi değil; büyük regresyonları durdurur:

- kalıcı transfer `80–260`,
- taksitli transfer `20–120`,
- taksitli transfer **kalıcı transferlerin yarısından az**,
- kiralık `250–700`,
- aktif final kiralık `5–48`,
- ortalama loan wage share `4500–8000 bps`,
- taksit taahhüdü `50M–600M`,
- açık taksit en fazla `100M`,
- loan fee hacmi `40M–250M`,
- final cash `300M–2B`,
- final debt `100M–1,2B`.

---

## 7. Bilinçli kapsam dışı

M8'de yok:

- satın alma opsiyonu,
- zorunlu satın alma,
- performans bonusu,
- satıştan pay,
- takas / oyuncu + para,
- çok sezonlu kiralık,
- recall,
- oyuncu/menajer pazarlığı,
- Flutter UI/APK.

Bunlar yalnız temel transfer yaşam döngüsü uzun kariyerde sağlıklı kaldığı sürece sonraki katmanlarda değerlendirilecek.
