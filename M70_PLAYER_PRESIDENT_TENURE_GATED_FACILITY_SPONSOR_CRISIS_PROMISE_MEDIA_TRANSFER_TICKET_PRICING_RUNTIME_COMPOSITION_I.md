# M70 — Player President Tenure-Gated Facility + Sponsor + Crisis + Promise/Media + Transfer/Ticket Pricing Runtime Composition I

## Amaç

M51 player-president crisis response kontrolünü M69'un gerçek sezon runtime'ına yeni checkpoint veya save codec oluşturmadan eklemek.

## Tasarım

- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` ve `PlayerPresidentTicketPricingRuntimeSaveCodec` authoritative kalır.
- M65→M68→M69 zincirine default-neutral `CrisisRuntimeIntegrationEngine` injection seam'i geçirilir.
- Crisis provider yokken M69 exact parity korunur.
- Crisis provider yalnız controlled club için, gerçek crisis tespit edildiğinde ve persisted player-president incumbent kimliği hâlâ geçerliyken çağrılır.
- Persisted loss başlangıçtan bloklar; incumbent mismatch aynı runtime oturumunda sticky biçimde AI fallback'e geçer.
- Diğer 47 kulüp exact canonical M43 AI crisis yolunda kalır.
- Seçilen crisis action M44/M47 üzerinden gerçek finance/fan/media continuation state'ine yazılır.
- Crisis provider runtime-only'dir; serialize edilmez.
- Facility + sponsor + crisis + promise + media + transfer strategy + ticket pricing aynı M65 persisted tenure/checkpoint akışında compose edilir.
- Manager player-control entegrasyonu M70 kapsamı dışındadır.

## Acceptance

1. Crisis provider yokken M69 checkpoint ve boundary exact parity.
2. Yedi player provider aynı gerçek sezon boundary'sinde çalışır.
3. Crisis override yalnız controlled club'u değiştirir; diğer 47 club exact AI crisis parity'de kalır ve seçilen action gerçek continuation state'ine yazılır.
4. Crisis yoksa player crisis provider çağrılmaz ve AI runtime parity korunur.
5. Persisted loss ve incumbent mismatch crisis player-control'u bloklar; mismatch persisted tenure loss'a dönüşür.
6. M65 codec ile 2+2 save/resume, uninterrupted 4-season deterministic run ile aynıdır.

## CI hedefi

- analyzer clean
- 315/315 non-canonical tests PASS
- M0–M70 canonical PASS
- M70 marker PASS
- artifact 0
