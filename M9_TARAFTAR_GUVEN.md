# M9 — Taraftar Beklentisi + Güven Çekirdeği

**Durum:** PASS adayı — final PR CI ile kilitlenecek  
**Seed:** `20260903`  
**Dünya:** 48 kulüp / 3 lig / 20 sezon / 14.400 maç  
**Fan snapshot:** 960 (`48 × 20`)

## Amaç

M9 projenin imza sistemlerinden birini ilk kez çalışan domain'e taşır:

> **Taraftar aptal bir mutluluk sayacı olmayacak; kulübün bağlamını anlayacak.**

İlk M9 sürümünde taraftar henüz gelir, seyirci veya sponsor parasını değiştirmez. Önce şu soruya headless simülasyonda cevap verilir:

> **Taraftar, kulübün ekonomik ve sportif durumuna göre mantıklı beklenti üretip başkanın davranışını bağlama göre değerlendirebiliyor mu?**

Bu ayrım bilinçlidir. Context motoru kanıtlanmadan ekonomiye taraftar çarpanı eklenmeyecek.

---

## 1. FanState

Her kulübün 4 güven boyutu vardır:

- `sportingTrust`
- `financialTrust`
- `transferTrust`
- `identityTrust`

Başlangıç puanı `60`.

Overall trust ağırlıkları:

- sportif `%35`
- finansal `%30`
- transfer `%25`
- kimlik `%10`

`identityTrust` M9'da nötr tutulur. Çünkü mevcut çekirdekte bilet fiyatı, altyapı kullanım tercihi, kulüp kültürü veya derbi kimliği gibi güvenilir identity sinyalleri henüz yoktur. Sahte sinyal üretmek yerine alan geleceğe hazır bırakılmıştır.

### Hafıza

İlk denemede her alt güven puanı her sezon 60'a doğru bir puan geri çekiliyordu. Bu, 20 sezon sonunda kulüpleri fazla birbirine yaklaştırdı.

Kabul modelinde mean reversion yalnız dış bantlarda çalışır:

- `>75` ise sezonda `-1` yumuşatma,
- `<45` ise sezonda `+1` yumuşatma,
- `45–75` aralığında geçmiş otomatik silinmez.

Böylece taraftar birkaç sezonluk başkanlık geçmişini hatırlar ama uzun kariyerde sınırsız 0/100 kutuplaşması da frenlenir.

---

## 2. FanSeasonContext

Her kulüp-sezon için context snapshot şu gerçek simülasyon verilerini okur:

- lig seviyesi,
- sezon sonu sıra,
- lig büyüklüğü,
- takım gücü,
- finansal sağlık,
- kapanış nakdi,
- kapanış borcu,
- emergency borrowing,
- kalıcı alım/satım sayısı,
- taksitli alım sayısı,
- kiralık giriş/çıkış,
- transfer harcaması/geliri,
- terfi/düşme,
- sonraki transfer penceresinin olup olmaması.

Finansal stres yalnız `debtCrisis` etiketi değildir. `tight`, `debtCrisis` veya emergency borrowing + debt>cash birleşimi de stres sayılır.

---

## 3. Bağlamsal beklentiler

`FanExpectationType`:

- `financialDiscipline`
- `smartLoanReinforcement`
- `strengthenSquad`
- `ambitiousReinforcement`
- `rebuildAfterRelegation`
- `prepareForHigherTier`
- `measuredImprovement`
- `none` (son sezon/no next window)

Temel örnekler:

### Borçlu + zayıf takım

Beklenti:

`smartLoanReinforcement`

Taraftar pahalı yıldız istemez. Daha ucuz, maaş paylaşılabilen kiralık veya ölçülü alternatif bekler.

### Borçlu ama sportif olarak daha sağlam takım

Beklenti:

`financialDiscipline`

Öncelik kulübü yeni yükümlülük altına sokmamaktır.

### Üst sıralar + güçlü finans

Beklenti:

`ambitiousReinforcement`

Kulüp kapasitesi varsa taraftar daha iddialı davranış isteyebilir.

### Terfi

- finans sağlıklıysa `prepareForHigherTier`,
- finans sıkıntılıysa `smartLoanReinforcement`.

### Düşme

- finans sıkıntılıysa `financialDiscipline`,
- finans sağlıklıysa `rebuildAfterRelegation`.

---

## 4. Güven nedenleri

Her güven değişimi yalnız sayı olarak değil `FanTrustReason` ile saklanır.

Boyutlar:

- sporting
- financial
- transfer
- identity

Örnek neden kodları:

- `promotion`
- `relegation`
- `league_champion`
- `top_quarter_finish`
- `bottom_quarter_finish`
- `very_strong_finances`
- `debt_crisis`
- `emergency_borrowing`
- `used_smart_loan`
- `overspent_in_financial_stress`
- `squad_strengthened`
- `ambition_not_backed`
- `promotion_squad_prepared`
- `rebuild_not_started`

Bu nedenler ileride UI'da "Taraftar güveni neden değişti?" sorusunun gerçek kaynağı olacak.

---

## 5. Aynı bağlamda farklı karar

M9 için kritik unit test:

**Aynı borç krizi + 14/16 lig sırası bağlamında:**

- kiralık oyuncu alan kulüp → `used_smart_loan`, transfer güveni `+4`
- yüksek harcama + 2 taksitli alım yapan kulüp → `overspent_in_financial_stress`, transfer güveni `-4`

Yani taraftar yalnız "transfer yaptın/yapmadın" bakmıyor; kararın kulüp bağlamına uygun olup olmadığını değerlendiriyor.

---

## 6. Kalibrasyon geçmişi

### Reddedilen ilk PASS

- snapshot `960`
- ortalama final trust `61,06`
- final aralık `46–68`
- boundary `0`
- reason `2.143`
- smart-loan expectation `9`
- financial-discipline expectation `58`

Teknik olarak her şey geçti fakat güven aralığı yalnız 22 puandı. Her sezon 60'a mean reversion geçmişi fazla siliyordu. **Denge reddedildi.**

### Kabul adayı

Mean reversion yalnız dış bantlara taşındı.

Seed `20260903`:

- snapshot `960`
- ortalama final trust `64,88`
- final trust aralığı `44–75`
- aralık genişliği `31`
- boundary final state `0`
- trust reason `2.143`
- smart-loan expectation `9`
- financial-discipline expectation `58`

Expectation dağılımı:

- measured improvement `465`
- strengthen squad `108`
- rebuild after relegation `99`
- prepare for higher tier `111`
- ambitious reinforcement `62`
- smart loan reinforcement `9`
- financial discipline `58`
- none `48`

`none=48` yalnız her kulübün son sezonunda bir sonraki transfer penceresi olmamasından gelir.

---

## 7. CI denge guard'ları

Seed `20260903` için geniş regresyon bantları:

- snapshots `960`
- final state `48`
- average trust `50–75`
- min trust `25–60`
- max trust `65–90`
- final spread en az `25`
- boundary (`<=5` veya `>=95`) en fazla `2`
- reason count `1.500–3.000`
- smart-loan expectation `5–100`
- financial-discipline expectation `20–180`
- en az 7 expectation tipi
- final no-window `none = 48`
- measured improvement `250–650`

Bunlar nihai oyun dengesi değildir; 20 sezonluk taraftar motorunun nötre çökmesini, kutuplaşmasını veya context kategorilerinden birinin sessizce kaybolmasını engeller.

---

## 8. Validator

`FanCareerValidator`:

- M8 advanced-transfer validator'ını da çalıştırır,
- tam `club × season` snapshot kapsamasını doğrular,
- duplicate season/club snapshot engeller,
- her güven puanını `0–100` doğrular,
- transfer penceresi olmayan final sezonda beklenti olmamasını doğrular,
- transfer penceresi varken expectation eksikliğini yakalar,
- reason delta aralığını doğrular,
- final state ile kulübün son snapshot'ını eşleştirir.

Same-seed replay ve different-seed divergence korunur.

---

## 9. Bilinçli kapsam dışı

M9'da yok:

- taraftarın maç günü gelirine etkisi,
- seyirci sayısı,
- ürün/forma satışı etkisi,
- sponsor ilgisi etkisi,
- protesto,
- bilet fiyatı,
- derbi özel hafızası,
- altyapı/kimlik kararlarının identity trust'a etkisi,
- medya,
- başkan vaatleri,
- seçim,
- Flutter UI/APK.

Önce context + trust çekirdeği kanıtlandı. Ekonomik geri besleme daha sonra kontrollü biçimde bağlanacaktır.
