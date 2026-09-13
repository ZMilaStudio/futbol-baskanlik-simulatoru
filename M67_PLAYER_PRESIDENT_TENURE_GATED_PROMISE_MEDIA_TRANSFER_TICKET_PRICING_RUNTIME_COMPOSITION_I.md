# M67 — Player President Tenure-Gated Promise/Media + Transfer/Ticket Pricing Runtime Composition I

## Amaç

M63 promise/media oyuncu başkan kontrollerini M66 transfer-strategy + ticket-pricing gerçek ekonomi runtime'ına, yeni checkpoint veya yeni save codec oluşturmadan bağlamak.

M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` ve `PlayerPresidentTicketPricingRuntimeSaveCodec` authoritative kalır. Dört external karar yüzeyi aynı persisted `PlayerPresidentTenureControlState` üzerinden yetkilendirilir.

## Mimari

- M47 `FacilitySponsorCrisisRuntimeCareerEngine`, varsayılanı canonical `PromiseMediaCareerEngine()` olan opsiyonel source-engine enjeksiyon seam'i alır.
- M65 bu source engine'i M47 runtime'ına geçirir; varsayılan davranış M0–M66 ile aynıdır.
- M67 her sezon başında authoritative checkpoint'ten gerçek incumbent management profile map'ini ve tenure state'i okur.
- M60 transfer bridge aynı tenure state ile gerçek transfer-market seam'inde çalışır.
- M65 ticket-pricing provider aynı tenure state ile gerçek matchday economy seam'inde çalışır.
- M56 promise generator ve M57 media statement engine aynı controlled club için aynı sezon source report'una compose edilir.
- Promise/media provider'ları yalnız tenure aktifken **ve** gerçek incumbent profile ID captured player-president ID ile eşleşirken açılır.
- Persisted `lost` state veya incumbent mismatch dört external provider'ı da bloklar.
- Provider callback'leri runtime-only kalır.
- Yeni save formatı yoktur; M65 codec kullanılmaya devam eder.

## Acceptance

1. Promise/media provider yokken exact M66 checkpoint + boundary parity.
2. Aktif incumbent aynı gerçek sezonda promise + media + transfer + ticket provider delegation.
3. Media event kimliği/topic metadata canonical kalırken stance değişebilir; ticket seçimi gerçek `ClubFinanceSeason.matchdayRevenue` etkisini korur.
4. Tek persisted lost tenure state dört external provider'ı da bloklar.
5. Incumbent identity mismatch dört provider'ı da bloklar ve sticky loss üretir.
6. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run.
7. M0–M67 canonical PASS, analyzer clean, normal test suite PASS, artifacts 0.
