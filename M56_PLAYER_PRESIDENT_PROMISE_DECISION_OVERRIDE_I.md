# M56 — Player President Promise Decision Override I

## Amaç

M11'de vaat sistemi ölçülebilir ve deterministik olarak kuruldu; M12-M16 vaat sonucunu taraftar güveni, medya itibarı ve başkanlık seçimine bağladı. Ancak kontrollü kulübün resmi sezon vaadi hâlâ AI `PromiseGenerator` tarafından otomatik seçiliyordu.

M56 bu gerçek başkanlık kararını oyuncuya açar.

## Kapsam

- Yalnız `controlledClubId` için oyuncu vaat seçimi yapılır.
- Diğer 47 kulüp mevcut M11 AI üretimini birebir korur.
- Provider yoksa controlled club dahil M11 exact parity korunur.
- Oyuncu serbest hedef, puan, taraftar güveni, medya itibarı veya seçim etkisi enjekte edemez.
- Oyuncu yalnız M11'in preseason context'ine göre geçerli olan mevcut `PresidentPromiseType` değerlerinden birini seçebilir.
- `finishTopHalf` genel sportif seçenek olarak kullanılabilir.
- `avoidRelegation` yalnız beklenen sırası son dört bölgesinde olan kulüplerde kullanılabilir.
- `earnPromotion` yalnız alt liglerde ve beklenen sıra ilk 5 ise kullanılabilir.
- `challengeTitle` yalnız birinci ligde ve beklenen sıra ilk 3 ise kullanılabilir.
- `reduceDebt` ve `stabilizeFinances` yalnız M11 `financialStress` koşulunda kullanılabilir.
- Hedefler mevcut M11 semantiğinden türetilir: top-half = lig büyüklüğünün yarısı, promotion = 3, title = 1, debt reduction = normal stres `%8`, ağır stres `%12`.
- Seçim yalnız sezon başında bilinen `PresidentPromiseContext` verisini görür; sezon sonu outcome provider'a verilmez.
- Seçilen vaat mevcut `PromiseResolver`, fan impact, media impact ve election/reputation zincirinden geçer.
- Provider runtime-only'dir; save payload'a eklenmez ve save migration gerekmez.

## Yeni yüzey

- `PlayerPromiseDecisionContext`
- `PlayerPromiseDecisionProvider`
- `PlayerPresidentPromiseGenerator`
- `PlayerPresidentPromiseDomainCareerEngine`

`PlayerPresidentPromiseDomainCareerEngine`, aynı player promise generator'ını hem ilk president-domain simülasyonuna hem resume yoluna bağlayan opt-in kolaylaştırıcıdır.

## Kabul kriterleri

1. Provider yokken mevcut M11 promise generation birebir korunur.
2. Yalnız controlled club'ın vaadi değişebilir; diğer 47 kulüp exact AI parity'de kalır.
3. Canonical hedefler oyuncu tarafından değiştirilemez ve context-invalid vaat reddedilir.
4. Oyuncunun seçtiği vaat gerçek fan/media reputation zincirine akar.
5. Provider serialize edilmeden save/load/resume determinism korunur.

## Kapsam dışı

- Serbest metin vaatler.
- Yeni vaat türleri.
- Çok sezonlu sözleşme/taahhüt sistemi.
- Vaat etkilerini veya skorlarını elle belirleme.
- UI ekranı/yerleşimi.

Bu milestone yalnız mevcut domain karar seam'ini oyuncu başkana açar; M11-M16 denge ve çözümleme semantiğini değiştirmez.
