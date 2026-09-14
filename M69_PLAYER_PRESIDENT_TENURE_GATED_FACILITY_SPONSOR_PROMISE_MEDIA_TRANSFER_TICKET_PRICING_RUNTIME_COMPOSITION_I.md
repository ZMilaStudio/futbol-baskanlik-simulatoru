# M69 — Player President Tenure-Gated Facility + Sponsor + Promise/Media + Transfer/Ticket Pricing Runtime Composition I

## Amaç
M50 sponsor seçimini M68'in authoritative M65 checkpoint/runtime akışına yeni bir save adası oluşturmadan eklemek.

## Kapsam
- Authoritative checkpoint/save codec M65 olarak kalır.
- Sponsor, facility, promise, media, transfer-strategy ve ticket-pricing player provider'ları aynı persisted `PlayerPresidentTenureControlState` altında çalışır.
- Sponsor seçimi yalnız controlled club ve gerçek incumbent player-president identity eşleşirken oyuncuya delege edilir.
- Persisted loss veya incumbent mismatch sponsor tarafını exact M42 AI sponsor yoluna düşürür.
- Aktif çok yıllı sponsor kontratı bozulmaz ve yeniden seçilmez.
- Diğer 47 kulübün sponsor kararları exact AI parity'de kalır.
- Sponsor provider runtime-only kalır; M65 codec ile save/load/resume determinism korunur.
- Crisis ve manager player-control birleşimi bu milestone kapsamında değildir.

## Acceptance
1. Sponsor provider yokken exact M68 checkpoint + boundary parity.
2. Aynı gerçek sezon boundary'sinde sponsor + facility + promise + media + transfer + ticket provider delegation.
3. Sponsor override yalnız controlled club kontrat/revenue satırını değiştirir; 47 AI sponsor kontratı exact parity.
4. Aktif çok yıllı player sponsor kontratı yeniden seçilmez.
5. Persisted lost tenure ve incumbent mismatch sponsor provider'ını bloklar; mismatch sticky loss üretir.
6. M65 codec ile 2+2 save/resume == uninterrupted 4-season deterministic run.
