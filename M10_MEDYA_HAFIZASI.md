# Futbol Başkanlık Simülatörü — M10 Medya Hafızası + Başkan Açıklamaları

**Milestone:** M10 — Medya Hafızası + Başkan Açıklamaları Çekirdeği  
**Durum:** PASS adayı — kabul baseline CI ile doğrulandı; final kapanış commit'i bekleniyor.

## Amaç

Projenin temel farklarından birini simülasyon seviyesinde kanıtlamak:

> **Medya başkanın dün söylediğini unutmayacak.**

M10 ilk sürümde medya davranışını gözlemsel katman olarak ekler. Maç, ekonomi veya teknik direktör kararlarını henüz geri beslemez; önce açıklama hafızasının doğru çalışması kanıtlanır.

## Kapsam

- `MediaStatement`
- `MediaState`
- 0–100 media credibility
- `managerFuture` konusu
- `strongSupport`, `measuredSupport`, `pressure`, `noComment` duruşları
- açıklama ile sonraki manager kararının consistency / contradiction çözümlemesi
- neden kodlu credibility değişimi
- deterministic statement generation
- 20 sezon / 48 kulüp media history
- `MediaCareerReport`
- `MediaCareerValidator`
- headless M10 runner

M10'da vaat, seçim, serbest metin, basın toplantısı UI'sı ve medyanın ekonomik geri beslemesi yoktur.

## İmza davranışı

Aynı başlangıç credibility `60` iken:

- **“Hocanın arkasındayız”** (`strongSupport`) denip hoca değiştirilirse `supportBroken`, contradiction ve `-10` credibility oluşur.
- **“Sonuçların düzelmesini bekliyoruz / herkes performansından sorumludur”** çizgisindeki pressure açıklamasından sonra hoca değiştirilirse `pressureFollowedByChange`, consistent ve `+3` credibility oluşur.
- güçlü destek verilip hoca tutulursa küçük pozitif güvenilirlik katkısı oluşur.

Bu, açıklamanın yalnız dekoratif metin değil sonraki yönetim kararına bağlı hafıza kaydı olduğunu kanıtlar.

## Statement üretimi

Açıklama sıklığı kulüp/hoca bağlamına göre değişir:

- baskı altındaki hoca: event chance `%78`
- rahat/başarılı hoca: `%55`
- normal bağlam: `%22`

Baskı altında pressure açıklaması daha olasıdır; rahat durumda strong/measured support daha olasıdır.

## Reddedilen ilk M10 kalibrasyonu

İlk teknik PASS'e çok yaklaşan model:

- statement `847 / 960 kulüp-sezon`
- contradiction `42`
- strong-support contradiction `20`
- consistent `624`
- avg credibility `79,31`
- aralık `31–91`

Problem: açıklama neredeyse her kulüp/sezon otomatik olaya dönüşüyordu. Medya kararı özel olmaktan çıkıyordu. **Reddedildi.**

## M10 kabul baseline — seed `20260903`

- sezon `20`
- kulüp `48`
- potansiyel kulüp-sezon `960`
- statement `556`
- contradiction `22`
- strong-support contradiction `9`
- consistent statement `385`
- stance dağılımı:
  - strong support `230`
  - measured support `155`
  - pressure `121`
  - no comment `50`
- final credibility ortalaması `75,52`
- final credibility min `49`
- final credibility max `87`
- boundary club `0`
- manager change `82`
- validation `0`

M10 media katmanı aynı seed'de deterministic replay üretir ve manager-only simülasyonunun imzasını değiştirmez.

## Kalite kapısı

Geniş regresyon guard hedefleri:

- statement `300–700`
- contradiction `10–80`
- strong-support contradiction `3–50`
- consistent statement `200–550`
- dört stance tipinin de görülmesi
- final avg credibility `55–82`
- final min `25–60`
- final max `75–92`
- boundary club `<=2`
- validation `0`
- M0–M9 regresyonları PASS
- CI artifact `0`

Bu aralıklar nihai medya dengesi değil; sistemi donmuş veya aşırı aktif hale getiren regresyonları yakalayan erken alarm sınırlarıdır.

## Sonraki milestone

**M11 — Başkan Vaatleri + Takip Çekirdeği**.

İlk hedef, sezon başında verilen ölçülebilir vaatleri kaydetmek; sezon sonunda gerçekleşti / gerçekleşmedi / kısmen ilerledi durumuna çözmek ve daha sonra fan/media sistemlerine bağlanabilecek deterministik bir promise history üretmektir.
