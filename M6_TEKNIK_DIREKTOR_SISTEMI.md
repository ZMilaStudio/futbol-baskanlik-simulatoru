# Futbol Başkanlık Simülatörü — M6 / Teknik Direktör Sistemi

**Milestone:** M6 — Teknik Direktör Sistemi  
**Durum:** **PASS**  
**Amaç:** Oyuncunun teknik direktör değil kulüp başkanı olduğu ürün kimliğini ilk kez yaşayan bir simülasyon sistemiyle desteklemek.

## 1. Tasarım sınırı

M6 teknik direktörü taktik ekranına dönüştürmez. Başkanın gördüğü ve karar verdiği katman şudur:

- hangi hocanın kulübe uygun olduğu,
- hocanın kalitesi ve profili,
- ne kadar bütçe talep eden yapıda olduğu,
- genç oyuncuya yaklaşımı,
- yönetimle ilişkisi,
- sportif sonucun yönetim ilişkisine etkisi,
- ne zaman görevde tutulacağı veya gönderileceği.

Diziliş, duran top, maç içi değişiklik ve antrenman mikro yönetimi M6 kapsamına alınmadı.

## 2. Manager domain modeli

Her teknik direktör kalıcı benzersiz `id` ile yaşayan ayrı bir varlıktır.

Alanlar:

- isim
- profil
- başlangıç yaşı
- emeklilik yaşı
- itibar
- coaching
- youth development
- man management
- board cooperation
- budget demand

Profiller:

1. `balanced`
2. `youthDeveloper`
3. `budgetBuilder`
4. `starManager`
5. `resultsFirst`

96 kişilik havuz career seed ve simulation version üzerinden deterministik oluşturulur. İlk sezonda 48 manager kulüplere atanır; kalanlar serbest havuzda tutulur.

## 3. Kulüp uyumu

`ManagerFitModel` yalnız manager kalitesine bakmaz. Şunları birlikte değerlendirir:

- manager profili
- manager bütçe talebi
- kulübün nakit/borç durumu
- lig seviyesi
- takımın ham kadro gücü
- oyuncuların yaş ortalaması
- potansiyel gelişim boşluğu

Örnek davranış:

- yüksek bütçe isteyen `starManager`, borç baskısındaki alt lig kulübünde uyum kaybeder,
- `budgetBuilder`, borçlu ve alt lig kulübünde değer kazanır,
- `youthDeveloper`, genç ve gelişim payı yüksek kadroda daha iyi uyum üretir,
- `starManager`, güçlü ve likit üst lig kulübünde daha anlamlı hale gelir.

Uyum skoru `15–95` arasında tutulur.

## 4. Sportif etki

Teknik direktör katkısı takımın ham kadro gücünün üzerine uygulanır ancak kadro kalitesinin önüne geçemez.

Etkenler:

- coaching
- man management
- manager-club fit
- board relationship
- genç oyuncu oranı × youth development
- profile özgü küçük etkiler

Toplam manager etkisi kesin olarak `-2,5...+2,5` aralığına clamp edilir.

Önemli mimari kural:

> Manager bonusu yalnız sezon maç gücüne uygulanır. Oyuncu yaşlanması, genç üretimi ve transfer değerlemesi ham kadro gücünden beslenmeye devam eder.

Bu sayede manager bonusu yanlışlıkla oyuncu üretimi veya piyasa değerini katlayamaz.

AI rasyonel manager seçtiği için seed `20260903` 20 sezon baseline'ında gözlenen fiili aralık `-0,371...+1,977` oldu. Buna karşılık doğrudan model testi, kötü bir başkanlık tercihi ve çökmüş yönetim ilişkisiyle `-2,5`; elit uyumla `+2,5` üretilebildiğini doğrular.

## 5. WorldCareer hook mimarisi

M5 motoru kopyalanmadı.

`WorldCareerEngine` artık opsiyonel `WorldCareerHooks` kabul eder. Varsayılan:

`NoopWorldCareerHooks`

Bu varsayılan tamamen etkisizdir ve M5 sonucunu değiştirmez.

M6, `ManagerCareerController` ile iki noktaya bağlanır:

1. sezon başlamadan `adjustClubsForSeason`: manager etkili maç strength'i türetilir,
2. sezon sonunda `onSeasonCompleted`: sportif sonuç, yönetim ilişkisi ve görev değişimi işlenir.

Bu mimari ileride taraftar, medya, vaat ve kriz sistemlerinin de world engine'i kopyalamadan bağlanabilmesi için temel sağlar.

## 6. Sezon sonu değerlendirmesi

Her kulüp için sezon başında ham kadro gücünden beklenen lig sırası çıkarılır. Sezon sonunda gerçek sıra ile karşılaştırılır.

Yönetim ilişkisi şunlardan etkilenir:

- beklentiye göre sportif performans
- ilk üç başarısı
- çok kötü lig sırası
- kulüp-hoca uyumu
- manager board cooperation

İlişki `0–100` aralığında tutulur.

Görev değişimi nedenleri:

- `performance`
- `boardBreakdown`
- `retirement`

Kovulan manager aynı kulübe anında geri atanmaz ancak ileride başka kulüpte yeniden görev alabilir. Emeklilik yaşına ulaşan manager yeniden atanamaz.

## 7. Validator

`ManagerCareerValidator` M5 world validator'ını da çalıştırır ve ayrıca şunları kontrol eder:

- manager pool ID benzersizliği
- her sezonda 48 kulüp / 48 aktif manager
- aynı manager'ın aynı sezonda iki kulüpte olmaması
- fit, relationship ve strength impact sınırları
- manager raporundaki gerçek sıralamanın lig tablosuyla eşleşmesi
- emeklilik yaşından sonra görev yapılmaması
- görev değişimi continuity'si
- değişim kaydı olmadan manager değişmemesi
- final assignment ile final sezon manager'ının aynı olması

## 8. Kabul edilen baseline — seed `20260903`

20 sezon / 14.400 maç:

- manager pool: `96`
- farklı görev yapan manager: `60`
- manager değişimi: `82`
- dismissal: `80`
- retirement: `2`
- `performance`: `51`
- `boardBreakdown`: `29`
- `retirement`: `2`
- ortalama manager strength etkisi: `+0,922`
- gözlenen etki min/max: `-0,371 / +1,977`
- negatif etkili kulüp-sezon: `29 / 960`
- `+1,5` ve üstü güçlü pozitif kulüp-sezon: `77 / 960`
- final ortalama board relationship: `72,22`
- transfer: `84`
- transfer hacmi: `777,02M`
- final cash: `1.048,02M`
- final debt: `582,36M`
- emergency borrowing: `473,40M`
- validation issue: `0`

82 değişim, 19 gerçek sezon arası pencereye bölündüğünde dünya genelinde sezon başına yaklaşık `4,32` manager değişimine karşılık gelir. Bu nihai gerçekçilik hedefi değil; yalnız ilk sağlıklı kariyer baseline'ıdır.

## 9. M5 geriye dönük uyumluluğu

Aynı CI koşusunda manager'sız M5 seed `20260903` sonucu değişmeden kaldı:

- transfer `71`
- hacim `637,91M`
- cash `862,25M`
- debt `647,04M`
- emergency `569,03M`
- validation `0`

Bu, `NoopWorldCareerHooks` yolunun M5'i bozmadığını doğrular.

## 10. Açık sınırlar

M6 henüz şunları içermez:

- teknik direktör maaşı ve sözleşme süresi
- teknik direktörün başka kulüpten teklif alması
- zam talebi
- transfer listesi veya spesifik oyuncu talebi
- yönetimi medyada eleştirme
- taraftarın teknik direktör kararına tepkisi
- bireysel oyuncu gelişim hızının manager youthDevelopment ile değiştirilmesi
- taktik ekranı / maç içi müdahale

`youthDevelopment` şu anda manager fit ve genç oyuncu oranına bağlı sınırlı sportif etkide kullanılır. Bireysel gelişim etkisi daha sonra player development sistemi genişletilirken bağlanacaktır.

## 11. Kalite kapısı

M6 kabul kriterleri:

- `dart analyze` PASS
- M0–M6 otomatik testleri PASS
- M0–M6 headless runner zinciri PASS
- 20 sezon / 14.400 maç
- deterministic same-seed replay
- farklı seed divergence
- manager etkili dünya, manager'sız dünyadan ayrışmalı
- en az bir negatif manager etkili kulüp-sezon
- en az bir `+1,5` üzeri güçlü pozitif manager etkili kulüp-sezon
- doğrudan impact modelinde `-2,5` ve `+2,5` uçlarının çalışması
- manager validation issue `0`
- artifact `0`

## 12. Sonraki milestone

**M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi**.

M3'teki geçici `WageModel` kaldırılacak. Oyuncuların gerçek sözleşme süresi, maaşı, bitişi, yenileme davranışı ve serbest kalması ekonomiye bağlanacak. Market value ve transfer AI sözleşme süresini gerçek veriden okuyacak.

Bu temel kurulmadan kiralık, taksit, bonus, satıştan pay ve diğer gelişmiş transfer yapıları eklenmeyecek.
