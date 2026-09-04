# M14 — Başkanlık Seçimi Çekirdeği I

M14, Futbol Başkanlık Simülatörü'nde ilk kez yıllar boyunca biriken taraftar güveni, medya itibarı ve vaat sicilini görevde kalma riskine bağlar.

## Amaç

Başkanlık seçimi rastgele bir zar veya tek bir kupa kontrolü değildir. Dört sezonluk dönemin sonunda farklı itibar kaynakları birlikte değerlendirilir ve deterministik bir rakip adayla karşılaştırılır.

İlk sürüm **gözlemseldir**: `reelected / lost` sonucu raporlanır fakat dünya simülasyonunu durdurmaz ve incumbent kimliğini henüz değiştirmez.

## Ortak dünya

M14 yeni bir futbol dünyası simüle etmez.

1. M13 `PromiseMediaCareerEngine` manager + advanced transfer + promise + media katmanlarını tek shared world üzerinde üretir.
2. M14 taraftar raporunu aynı `AdvancedTransferCareerReport` üzerinden yeniden türetir.
3. Promise-driven fan nedenleri M12 ile aynı `PromiseFanImpactEngine` üzerinden uygulanır.
4. Seçim girdileri aynı kulüp/sezon gerçekliğinden alınır.

Validator fan ve reputation advanced-report imzalarının aynı olduğunu zorunlu kılar.

## Seçim dönemi

Varsayılan seçim aralığı `4` sezondur.

20 sezon × 48 kulüp:

- kulüp başına 5 seçim,
- toplam 240 seçim.

Takvim mutlak sezon numarasına değil simülasyon başlangıcına göredir. Örneğin kariyer `seasonIndex=7` ile başlarsa ilk seçim dört tamamlanmış sezon sonra `seasonIndex=10` sonunda yapılır.

## Başkan onay skoru

`PresidentElectionEngine` dört girdiyi 0–100 approval skoruna çevirir:

- fan overall trust: `%35`
- fan identity trust: `%15`
- media credibility: `%25`
- son dört sezon promise score ortalaması: `%25`

Formül:

`approval = round(fanOverall*0.35 + fanIdentity*0.15 + media*0.25 + promise*0.25)`

Her girdi ayrıca `PresidentApprovalContribution` olarak saklanır. Böylece seçim sonucunun nedenleri UI veya debug raporunda açıklanabilir.

## Rakip aday

`challengerStrength` cihaz saatinden veya runtime `hashCode`dan üretilmez.

Seed girdileri:

- career seed,
- simulation version,
- sezon,
- term number,
- club ID,
- sabit election salt.

Temel rakip gücü deterministik `50–71` bandından gelir; çok zayıf incumbent daha güçlü, çok güçlü incumbent biraz daha zayıf rakip baskısıyla karşılaşabilir. Son güvenlik bandı `42–78`dir.

`margin = approval - challengerStrength`

- `margin >= 0` → `reelected`
- `margin < 0` → `lost`

## Kabul baseline — seed 20260903

- elections: `240`
- reelected: `158`
- lost: `82`
- reelection rate: `%65,8`
- average approval: `63,24`
- average challenger: `60,08`
- approval range: `37–84`
- competitive (`|margin| <= 5`): `72`
- landslide reelections (`margin >= 10`): `79`
- landslide losses (`margin <= -10`): `41`
- boundary approval: `0`
- validation: `0`

## Kabul gerekçesi

İlk model kabul edildi. Seçim sistemi incumbent lehine doğal bir avantaj taşıyor fakat formalite değil: seçimlerin yaklaşık üçte biri kaybediliyor. Yakın yarışlar anlamlı sayıda; aynı anda hem net zafer hem net yenilgi örnekleri bulunuyor. Approval 0/100 sınırlarına yığılmıyor.

## CI guard

Seed `20260903` için geniş fakat regresyon yakalayan bantlar:

- reelected `130–185`
- lost `55–110`
- reelection rate `0,55–0,78`
- average approval `58–68`
- average challenger `56–64`
- min approval `25–50`
- max approval `75–90`
- competitive `45–100`
- landslide wins `50–115`
- landslide losses `20–70`
- boundary `<=2`

Ayrıca custom initial season index ve deterministic replay test edilir.

## Bilinçli sınırlar

M14 henüz:

- gerçek president profile/isim üretmez,
- seçim kaybında incumbent değiştirmez,
- oyuncu kariyerini bitirmez,
- başka kulübe geçiş sunmaz,
- seçim kampanyası/aday vaatleri üretmez,
- sponsor veya board davranışını geri beslemez.

Bunlar sonraki katmanlardır.

## Sıradaki yön

**M15 — Başkanlık Görev Süresi + Devir Çekirdeği.**

İlk hedef seçim sonucunu gerçek bir `PresidentTenureState` yaşam döngüsüne bağlamak; AI kulüplerinde görev süresi ve seçim kaybı sonrası devir üretmek, fakat kullanıcı game-over/UI davranışını daha sonraya bırakmaktır.
