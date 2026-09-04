# Futbol Başkanlık Simülatörü — M11 Başkan Vaatleri + Takip Çekirdeği

**Milestone:** M11 — Başkan Vaatleri + Takip Çekirdeği  
**Durum:** PASS — kabul baseline ve sıkı kalite guard'ları tanımlandı.

## Amaç

> **Başkan verdiği sözü sezon sonunda unutamayacak.**

M11, başkan vaatlerini serbest metin/dekorasyon olmaktan çıkarıp ölçülebilir ve sonradan çözümlenebilir domain kayıtlarına dönüştürür.

## Temel tasarım kararı — geleceği okumak yasak

Vaat üretimi yalnız sezon başında bilinen verileri kullanır:

- lig seviyesi ve lig büyüklüğü,
- sezon başı kulüp gücü,
- aynı ligde güç sıralamasından türetilen beklenen pozisyon,
- açılış nakit,
- açılış borç.

Sezon sonu lig sırası, closing debt, emergency borrowing, terfi/düşme gibi sonuçlar vaat seçerken **kullanılmaz**. Bunlar yalnız çözümleme aşamasında okunur.

Bu ayrım M11'in kritik invariantıdır: sistem sonradan gerçekleşmiş sonucu biliyormuş gibi kolay vaat seçemez.

## Domain

- `PresidentPromise`
- `PresidentPromiseType`
- `PresidentPromiseContext`
- `PresidentPromiseOutcome`
- `PromiseResolution`
- `PromiseStatus`
- `PromiseResolutionReason`
- `PromiseGenerator`
- `PromiseResolver`
- `PromiseSeasonSnapshot`
- `PromiseCareerReport`
- `PromiseCareerValidator`
- `PromiseCareerEngine`

AI dünya simülasyonunda her kulüp için sezon başına bir resmi vaat üretilir. 48 kulüp × 20 sezon = `960` promise snapshot. Bu sayı oyuncu UI'sında gösterilecek vaat sayısı değildir; headless dünya dengesi için tüm AI başkanların yıllık taahhüt geçmişidir.

## Vaat türleri ve çözümleme

### `reduceDebt`

Yalnız finansal stres bağlamında üretilebilir.

- normal stres hedefi: borcu en az `%8` azalt,
- ağır stres hedefi: en az `%12` azalt,
- hedef aşılırsa `fulfilled`,
- borç azalır ama hedef kaçarsa `partial`,
- borç azalmıyorsa `broken`.

### `stabilizeFinances`

Yalnız finansal stres bağlamında üretilebilir.

Tam başarı için:

- emergency borrowing olmamalı,
- closing debt açılış borcunun `%105` sınırını aşmamalı.

İki koşuldan yalnız biri sağlanırsa `partial`.

### `finishTopHalf`

16 kulüplü ligde hedef ilk `8`.

- ilk 8 → fulfilled,
- 9–10 → partial,
- daha altı → broken.

### `avoidRelegation`

Yalnız sezon başı güç beklentisi son dört sıraya yakın kulüplerde seçilir.

- ligde kalmak → fulfilled,
- düşmek → broken.

### `earnPromotion`

Yalnız 2. veya 3. ligde sezon başı beklenen pozisyon ilk 5 ise seçilebilir.

- gerçek terfi → fulfilled,
- ilk 5 içinde kalıp terfi kaçırmak → partial,
- diğer → broken.

### `challengeTitle`

Yalnız en üst ligde sezon başı güç beklentisi ilk 3 ise seçilebilir.

- şampiyon → fulfilled,
- 2–3 → partial,
- diğer → broken.

## Determinizm

Vaat tipi seçimi `careerSeed + simulationVersion + seasonIndex + clubId + "president-promise"` üzerinden kararlı hash/`SeededRng` ile türetilir.

Aynı seed aynı promise history'yi üretir. Farklı seed farklı dünya ve farklı vaat geçmişi oluşturur.

`PromiseCareerEngine` M8 `AdvancedTransferWorldCareerEngine` raporunu gözlemsel olarak işler; promise katmanı dünya sonucunu değiştirmez.

## M11 kabul baseline — seed `20260903`

- sezon `20`
- kulüp `48`
- promise snapshot `960`
- fulfilled `435`
- partial `169`
- broken `356`
- average resolution score `54,84`
- financial promises `105`
- sporting promises `855`

Vaat tipi dağılımı:

- `challengeTitle`: `60`
- `finishTopHalf`: `388`
- `avoidRelegation`: `227`
- `earnPromotion`: `180`
- `reduceDebt`: `64`
- `stabilizeFinances`: `41`

Bu dağılım kabul edildi. Başarı oranı ne otomatik yüksek ne de anlamsız düşük; `partial` sonucu gerçek bir orta bölge oluşturuyor ve altı vaat tipinin tamamı 20 sezon içinde aktif.

## CI geniş guard'ları

- total promises: `960`
- altı promise tipinin tamamı görülmeli
- financial promises `60–200`
- sporting promises `760–900`
- fulfilled `300–600`
- partial `100–300`
- broken `250–500`
- average score `45–65`
- title `30–100`
- top-half `250–500`
- avoid-relegation `150–300`
- promotion `120–250`
- reduce-debt `30–120`
- stabilize-finances `20–100`
- validator `0`
- M0–M10 regresyonları PASS
- CI artifact hedefi `0`

Bu aralıklar nihai oyun dengesi değildir; promise sisteminin tek tipe, otomatik başarıya veya otomatik başarısızlığa kaymasını yakalayan erken alarm sınırlarıdır.

## Kapsam dışı

M11 henüz şunları içermez:

- oyuncunun UI üzerinden vaat seçmesi,
- serbest metin vaat,
- birden fazla sezon süren taahhüt,
- genç oyuncu dakika vaadi (dakika sistemi henüz yok),
- tesis/stadyum vaadi (tesis çekirdeği henüz yok),
- vaat sonucunun taraftar/media/seçim puanını değiştirmesi.

## Sonraki milestone

**M12 — Vaat Sonuçlarının Taraftar Güvenine Etkisi.**

İlk hedef M11 `fulfilled / partial / broken` sonuçlarını M9 fan modeline bağlamak; özellikle bugüne kadar nötr bırakılan `identityTrust` boyutuna gerçek, neden kodlu vaat güveni sinyali vermektir. Medya ve seçim bağlantısı daha sonraki katmanda ele alınacaktır.
