# M55 — Player President Transfer Strategy Decision Override I

## Amaç

M54 ile gerçek `WorldCareerEngine` transfer penceresine taşınan başkan transfer stratejisini, oyuncunun kontrol ettiği kulüp için doğrudan başkan kararına açmak.

Oyuncu teknik direktör değildir. M55 oyuncuya tek tek kadro/taktik yönetimi vermez; kulüp başkanı olarak transfer politikasının dört yönetim eksenini belirletir:

- mali disiplin / transfer bütçesi yaklaşımı,
- transfer aktivitesi / hırsı,
- pazarlık risk iştahı,
- genç oyuncu tercihi.

## Tasarım

`PlayerTransferStrategyDecisionProvider`, yalnız kontrollü kulübün transfer penceresi açıldığında `PlayerTransferStrategyDecisionContext` alır ve `PlayerTransferStrategyChoice` döndürür.

`PlayerPresidentTransferStrategyProfileProvider`, M54 `PresidentTransferStrategyProfileProvider` yüzeyini compose eder:

- AI provider önce tüm kulüpler için gerçek başkan profillerini üretir.
- Player provider yoksa AI map'i aynen geri döner; M54 parity korunur.
- Player provider varsa yalnız `controlledClubId` için dört transfer trait'i oyuncu seçimiyle değiştirilir.
- Başkan `presidentId`, `archetype` ve `managerPatience` değerleri korunur.
- Diğer 47 kulübün AI profili byte/signature seviyesinde değişmez.
- Seçim değerleri M53 politika aralığıyla uyumlu olarak `20..90` sınırındadır.
- Explicit transfer policy map'leri M54 davranışı gereği profile/player provider zincirini tamamen bypass eder.

`PlayerPresidentTransferStrategyWorldBridge`, bu provider kompozisyonunu M54 world bridge'e bağlayan opt-in kolaylık katmanıdır. Default `WorldCareerEngine` değiştirilmez.

## Persistence

M55 yeni save alanı veya migration eklemez. Decision provider runtime/UI bağımlılığıdır ve serialize edilmez. Kontrollü kulüp kimliği M49–M52 player-president runtime state tarafından zaten persist edilmektedir; M55 kompozisyonuna yeniden enjekte edilir.

## Acceptance

1. Player provider yokken M54 transfer sonucu exact parity.
2. Player seçimi yalnız kontrollü kulübün dört transfer trait'ini değiştirir; başkan kimliği/archetype/manager sabrı ve diğer 47 AI kulübü korunur.
3. Youth strategy override gerçek transfer market seam'inde `ready_forward` yerine `young_forward` seçimini üretebilir.
4. Explicit market policy map'leri AI ve player provider'ları bypass eder.
5. Gerçek 48-kulüp world bridge, AI ile aynı seçim verildiğinde M54 report/checkpoint parity ve fixed-input determinism korur.

## Canonical gate

`tool/run_m55_player_president_transfer_strategy_control.dart`

Beklenen marker:

`M55_PLAYER_TRANSFER_STRATEGY_CONTROL_PASS`
