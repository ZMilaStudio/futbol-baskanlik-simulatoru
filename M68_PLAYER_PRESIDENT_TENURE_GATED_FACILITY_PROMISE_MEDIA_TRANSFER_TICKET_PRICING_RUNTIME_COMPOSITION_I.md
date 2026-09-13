# M68 — Player President Tenure-Gated Facility + Promise/Media + Transfer/Ticket Pricing Runtime Composition I

## Amaç

M67'nin promise + media + transfer + ticket-pricing player-president kontrollerine M49 facility yatırım kontrolünü eklemek; bunu yeni checkpoint/save codec oluşturmadan M65'in authoritative `PlayerPresidentTicketPricingRuntimeCheckpoint` akışı üzerinde yapmak.

## Canlı boşluk

M67 sonrası M59 facility/sponsor/crisis/manager kontrol zinciri M65/M67 authoritative runtime'dan ayrı kalıyordu. M65'in M48 next-season investment seam'i facility kontrolü için mevcut ve düşük riskli bir birleşim noktası sağlıyor. M68 bu nedenle M59'un ilk parçası olarak facility kontrolünü taşır; sponsor/crisis/manager birleşimi sonraki canlı-main taramasına bırakılır.

## Tasarım

- Yeni checkpoint veya save codec yoktur.
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` authoritative kalır.
- M67 promise/media source engine'i aynen korunur.
- M60 transfer bridge ve M65 ticket-pricing/economy seam'i aynen korunur.
- Facility provider yalnız controlled club için ve yalnız persisted tenure aktifken + post-election gerçek incumbent ID captured player-president ID ile eşleşiyorsa çağrılır.
- Kontrol kaybı veya incumbent mismatch olduğunda facility tarafı exact M48 AI investment yoluna düşer.
- Diğer 47 kulübün facility yatırım kararları canonical AI path üzerinde kalır.
- Provider runtime-only kalır; M65 codec save/load/resume için kullanılmaya devam eder.

## Acceptance

1. Facility provider yokken exact M67 checkpoint + season-boundary parity.
2. Aktif incumbent için aynı gerçek sezon akışında facility + promise + media + transfer + ticket provider delegation.
3. Facility override yalnız controlled club yatırımını değiştirirken diğer 47 kulübün yatırım kararlarının exact AI parity'si.
4. Persisted lost tenure ve incumbent identity mismatch facility provider'ını bloklar; mismatch sticky loss'a dönüşür.
5. M65 codec ile 2+2 save/resume, uninterrupted 4-season run ile deterministic eşitlik.
6. Mevcut M0–M67 canonical zinciri bozulmaz; M68 canonical marker eklenir.
7. Artifact hedefi 0.

## Dosyalar

- `lib/src/facility/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `lib/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `test/m68_player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition_test.dart`
- `tool/run_m68_player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

## Durum

IMPLEMENTATION IN PROGRESS / NOT MERGED.
