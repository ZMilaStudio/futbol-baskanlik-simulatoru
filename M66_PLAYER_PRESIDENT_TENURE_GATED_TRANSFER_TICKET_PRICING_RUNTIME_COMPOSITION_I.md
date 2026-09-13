# M66 — Player President Tenure-Gated Transfer + Ticket Pricing Runtime Composition I

## Amaç

M60 player-president transfer-strategy kontrolünü M65 gerçek ticket-pricing/economy runtime'ı ile aynı sezon, aynı incumbent kimliği ve aynı persisted tenure ownership state üzerinde compose etmek.

M66 yeni bir save/checkpoint adası oluşturmaz. M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` ve `PlayerPresidentTicketPricingRuntimeSaveCodec` authoritative kalır.

## Tasarım

- M66, M65 runtime'ını birer sezonluk authoritative segmentler halinde ilerletir.
- Her sezon başında gerçek incumbent `PresidentManagementProfile` map'i mevcut M65 checkpoint'inden alınır.
- M60 `PlayerPresidentTenureGatedTransferStrategyWorldBridge`, M65'in kullandığı aynı `PlayerPresidentTenureControlState` ile `WorldCareerEngine.transferMarketEngine` seam'ine kurulur.
- Ticket-pricing provider M65'in mevcut gerçek economy seam'inde çalışmaya devam eder.
- Transfer ve ticket provider callback'leri runtime-only kalır.
- Persisted `lost` tenure state veya incumbent identity mismatch iki kontrol yüzeyini de bloklar.
- Transfer provider yoksa M66, M65'i birebir korur.
- Save/load/resume için yeni codec yoktur; M65 codec kullanılır.

## Acceptance

1. Transfer provider yokken M66 == M65 exact checkpoint + boundary parity.
2. Active incumbent aynı gerçek sezonda hem transfer-strategy hem ticket-pricing provider'ını kullanabilir.
3. Ticket-pricing kararı gerçek `ClubFinanceSeason.matchdayRevenue` satırına etki etmeye devam eder.
4. Tek persisted lost tenure state hem transfer hem ticket provider'ını bloklar.
5. Incumbent mismatch iki provider'ı da bloklar ve tenure loss sticky hale gelir.
6. M65 save codec ile 2+2 save/resume == uninterrupted 4-season deterministic run.

## Canonical marker

`M66_PLAYER_PRESIDENT_TENURE_GATED_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS`

## Dosyalar

- `lib/src/facility/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart`
- `lib/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart`
- `test/m66_player_president_tenure_gated_transfer_ticket_pricing_runtime_composition_test.dart`
- `tool/run_m66_player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`
