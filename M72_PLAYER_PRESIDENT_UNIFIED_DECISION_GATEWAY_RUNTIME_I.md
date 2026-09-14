# M72 — Player President Unified Decision Gateway Runtime I

## Amaç

M71 ile gerçek runtime'da birleşen sekiz player-president karar alanını uygulama/UI katmanının tek bir başkan karar arayüzü üzerinden kullanabilmesini sağlamak; mevcut M49–M71 domain provider semantiklerini, tenure gate'lerini ve M65 persistence authority'sini değiştirmemek.

## Kapsam

- Yeni `PlayerPresidentDecisionGateway` tek application-facing karar yüzeyidir.
- Gateway facility, sponsor, crisis, manager review/replacement, promise, media, transfer strategy ve ticket pricing kararlarını tek interface altında toplar.
- M72 adapter'ları gateway çağrılarını mevcut M49–M64 provider tiplerine dönüştürür; domain doğrulama ve canonical etkiler eski motorlarda kalır.
- Gateway yalnız controlled club ve aktif persisted player-president tenure için çağrılır; successor/persisted loss davranışı M58–M71 tarafından korunur.
- Gateway yokken M72 exact M71 davranışı verir.
- Yeni checkpoint, save codec veya persisted gateway state yoktur.
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek authoritative persistence katmanı olmaya devam eder.
- Bu milestone Flutter/UI eklemez; UI'nin bağlanabileceği deterministic application boundary'yi hazırlar.

## Acceptance

1. Gateway yokken M72 checkpoint + boundary signature'ları exact M71 parity verir.
2. Tek gateway sekiz player-president karar domain'ini aynı gerçek sezon runtime'ında yönlendirir.
3. Gateway yalnız controlled club context'lerini alır; diğer 47 kulüp canonical AI yolunda kalır.
4. Existing provider validation, tenure-loss ve successor bloklama semantiği adapter tarafından bypass edilmez.
5. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run; gateway runtime-only kalır.

## Persistence

Authoritative checkpoint/save:
- `PlayerPresidentTicketPricingRuntimeCheckpoint`
- `PlayerPresidentTicketPricingRuntimeSaveCodec`

M72 yeni persisted state eklemez.
