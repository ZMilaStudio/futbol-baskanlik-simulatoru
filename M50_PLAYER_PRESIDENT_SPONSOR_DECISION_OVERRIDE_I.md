# M50 — Player President Sponsor Decision Override I

## Amaç

M49 ile açılan ilk gerçek player-president karar yüzeyini sponsorluk sözleşmelerine genişletmek.

Oyuncu teknik direktör değildir; kulüp başkanıdır. Bu milestone ile oyuncu, kontrol ettiği kulüpte yeni sponsor sözleşmesi gerektiğinde M42'nin ürettiği gerçek ve deterministic teklifler arasından seçim yapabilir.

## Kapsam

- `controlledClubId` M49 checkpoint zincirinden aynen korunur.
- Yalnız kontrollü kulübün yeni/yenilenen sponsor kontratı player provider tarafından seçilebilir.
- Diğer 47 kulüp mevcut `PresidentSponsorDecisionPolicy` yolunu birebir sürdürür.
- Aktif çok yıllı kontratlar bozulmaz; kontrat bitmeden oyuncuya yeni seçim sorulmaz.
- Oyuncu yalnız M42 `SponsorOfferEngine` tarafından o sezon üretilmiş gerçek tekliflerden birini seçebilir.
- Karar context'i sezon, kulüp, current president, yönetim profili, lig pozisyonu, fan trust, media credibility, bütün teklifler ve AI önerisini içerir.
- Seçilen kontrat mevcut sponsor runtime checkpoint'ine girer ve gerçek economy `sponsorRevenue` satırını değiştirir.
- Player provider serialize edilmez; seçilmiş aktif kontrat ve `controlledClubId` save state içinde persist eder.
- M49 facility player-control kabiliyeti korunur ve aynı M50 engine içinde birlikte kullanılabilir.
- Provider yokken M50, M49 ile exact checkpoint/boundary parity verir.

## Güvenlik / invariants

- Oyuncu listede olmayan sponsor teklifini seçemez.
- Sponsor bonus, süre ve gelir semantiği M42'den aynen gelir; M50 yeni gizli para üretmez.
- Aktif kontrat başkan değişse bile M45 davranışıyla korunur.
- Save/load/resume deterministic kalır.
- Eski public simulation semantiği provider yokken değişmez.

## Acceptance

1. Sponsor provider yokken M49 exact parity.
2. Player seçimi yalnız `controlledClubId` kontratını değiştirir; diğer 47 kulüp AI parity.
3. Stable/bold gibi farklı gerçek teklif seçimleri gerçek economy `sponsorRevenue` satırına ulaşır.
4. Çok yıllı player kontratı aktifken yeniden seçim yapılmaz ve save/load ile persist eder.
5. Aynı deterministic sponsor + facility provider ile `2+2 == uninterrupted 4` exact checkpoint, boundary ve player-decision parity.

## Kalıcı doğrulama

- Test: `test/m50_player_president_sponsor_control_test.dart`
- Canonical gate: `tool/run_m50_player_president_sponsor_control.dart`
- CI: `Run M50 player president sponsor control`
