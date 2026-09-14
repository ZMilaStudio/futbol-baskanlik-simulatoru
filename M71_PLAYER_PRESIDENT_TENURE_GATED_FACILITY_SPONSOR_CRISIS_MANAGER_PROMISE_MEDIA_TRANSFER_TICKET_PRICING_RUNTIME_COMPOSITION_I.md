# M71 — Player President Tenure-Gated Facility + Sponsor + Crisis + Manager + Promise/Media + Transfer/Ticket Pricing Runtime Composition I

## Amaç

M52 player-president manager kararını M70'ın yedi player-president karar alanıyla aynı gerçek sezon runtime'ında birleştirmek; yeni checkpoint/save adası oluşturmadan M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` ve `PlayerPresidentTicketPricingRuntimeSaveCodec` zincirini tek authoritative persistence katmanı olarak korumak.

## Kapsam

- M70 runtime authoritative kaynak olarak korunur.
- Manager review/replacement yalnız tamamlanmış sezon ile gerçek bir sonraki sezon arasındaki boundary'de uygulanır.
- Controlled club için aktif persisted player-president tenure varsa M52 manager provider devreye girer.
- President turnover / persisted loss halinde manager player-control uygulanmaz; M70'ın canonical AI manager sonucu aynen korunur.
- Forced retirement retain edilemez; replacement gerçek manager pool içindeki deterministic adaylardan seçilir.
- Manager override yalnız controlled club assignment + ilgili manager-season/change history kaydını değiştirir; diğer 47 kulüp exact AI manager parity'de kalır.
- Facility, sponsor, crisis, promise, media, transfer strategy ve ticket pricing M70 semantiğiyle aynı şekilde çalışmaya devam eder.
- Yeni checkpoint veya save codec yoktur; provider callback runtime-only kalır.

## Acceptance

1. Manager provider yokken M71 checkpoint ve source boundary'leri exact M70 parity verir.
2. Manager override yalnız controlled club manager assignment'ını değiştirir; diğer 47 AI assignment exact kalır.
3. Facility + sponsor + crisis + manager + promise + media + transfer strategy + ticket pricing aynı gerçek sezon boundary'sinde compose olur.
4. Son sezondan sonra future season yoksa manager provider çağrılmaz ve exact M70 checkpoint korunur.
5. Gerçek president turnover successor boundary'sinde manager player-control'u bloklar.
6. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run.

## Persistence

Authoritative checkpoint/save:
- `PlayerPresidentTicketPricingRuntimeCheckpoint`
- `PlayerPresidentTicketPricingRuntimeSaveCodec`

M71 yeni persisted state eklemez.
