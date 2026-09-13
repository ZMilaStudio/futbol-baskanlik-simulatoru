# M65 — Player President Tenure-Gated Ticket Pricing Runtime Integration I

## Amaç

M64'te eklenen tenure-gated bilet fiyatlandırma kararını gerçek sezon ekonomisine bağlamak.

M65 yeni bir paralel ekonomi simülasyonu kurmaz. Mevcut M47/M48 facility + sponsor + crisis + president facility-investment zincirinin kullandığı `BasicEconomyEngine.matchdayRevenueMultiplierBpsByClub` seam'ine M64 fiyatlandırma sonucunu enjekte eder.

## Mimari

- M47'nin authoritative stadium + fan-trust attendance modeli aynen korunur.
- M65 economy wrapper, M47'den gelen matchday revenue multiplier'ın aynı M40/M41 attendance modeliyle birebir uyuştuğunu doğrular.
- Ardından yalnız matchday revenue multiplier M64 sonucu ile değiştirilir.
- Sponsor geliri, prize revenue, wage/operating/interest giderleri, crisis akışı, facility yatırımları, election, fan/media ve world simülasyonu mevcut runtime zincirinde kalır.
- M48 facility yatırımları sonraki sezonun stadium level bağlamına doğal olarak yansır.
- Player provider runtime-only kalır.
- M58 tenure ownership state M65 checkpoint'inde persist edilir ve her tamamlanan sezondan sonra gerçek incumbent president identity ile refresh edilir.
- Successor mismatch ve persisted lost state player provider'ı bloklar.
- Diğer 47 kulüp exact AI ticket-pricing path'inde kalır.

## Legacy / parity garantisi

`balanced` fiyat seviyesi M64'te M40/M41 multiplier'ını birebir koruduğu için, AI politikası zorla `balanced` olduğunda M65 runtime sonucu M48 ile exact parity üretmelidir.

## Acceptance

1. Forced-balanced pricing exact M48 runtime parity.
2. Player premium pricing gerçek `ClubFinanceSeason.matchdayRevenue` satırını değiştirir ve multiplier bounded kalır.
3. Active incumbent yalnız controlled club ekonomisini değiştirebilir; diğer 47 kulüp exact AI finance parity'de kalır.
4. Successor identity mismatch ve persisted lost tenure player provider'ı bloklar.
5. Save round-trip + 2+2 resume, uninterrupted 4-season run ile deterministik eşleşir.

## Kapsam dışı

- maç/derbi/kupa bazlı ayrı fiyatlama;
- UI/UX ticket-pricing ekranı;
- M59 + M60 + M63 + M65 tek üst-level player-president checkpoint composition;
- yeni fiyat kategorileri veya dynamic pricing algoritması.

## Canonical

Seed: `20260903`

Beklenen marker:

`M65_PLAYER_PRESIDENT_TENURE_GATED_TICKET_PRICING_RUNTIME_INTEGRATION_PASS`
