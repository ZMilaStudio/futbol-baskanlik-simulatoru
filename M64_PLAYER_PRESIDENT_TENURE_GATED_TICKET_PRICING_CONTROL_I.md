# M64 — Player President Tenure-Gated Ticket Pricing Control I

## Amaç

M40/M41 stadyum kapasitesi + fan trust attendance modelinde maç günü geliri vardır; ancak `ticketYieldBps` stadyum seviyesine sabittir ve başkanın ticari fiyatlandırma kararı yoktur.

M64, oyuncu-başkan için ilk açık maç günü bilet fiyatlandırma yüzeyini ekler. Oyuncu teknik direktör değildir; karar sportif taktik değil, kulüp ticari politikasıdır.

## Tasarım

Üç canonical fiyat seviyesi vardır:

- `supporterFriendly`: daha düşük fiyat, daha yüksek talep;
- `balanced`: mevcut M40/M41 davranışı birebir korunur;
- `premium`: daha yüksek fiyat, daha düşük talep.

M40/M41 `StadiumInvestmentPolicy.attendanceProfile` authoritative kaynak olarak kalır. M64 bu sonucu yeniden simüle etmez; yalnız fiyat elastikiyetini bounded biçimde uygular.

### AI kararı

AI fiyat seçimi mevcut başkan profili, fan trust ve baz doluluk üzerinden deterministiktir:

- düşük fan trust veya çok düşük doluluk → supporter-friendly;
- yüksek fan trust + yüksek doluluk + yeterli financial discipline → premium;
- diğer durumlar → balanced.

### Player-president yetkilendirme

M58 `PlayerPresidentTenureControlState` kullanılır.

Player provider yalnızca:

1. controlled club için,
2. tenure state `active` iken,
3. real `PresidentManagementProfile.presidentId` captured player-president id ile eşleşirken

çalışır.

Successor identity veya persisted `lost` state provider'ı tamamen bloklar ve exact AI path kullanılır. Provider callback runtime-only'dir; M64 yeni save formatı oluşturmaz.

## Korunan semantik

- balanced pricing = exact M40/M41 attendance/yield/revenue multiplier parity;
- diğer 47 kulüp exact AI pricing path;
- stadium level, fan state, finance, president state veya world state mutate edilmez;
- mevcut public simulation semantiği değiştirilmez;
- fiyat etkileri bounded kalır;
- determinism korunur.

## Acceptance

1. balanced fiyat M40/M41 attendance + yield + revenue multiplier değerlerini birebir korur;
2. supporter-friendly ve premium fiyatlar beklenen demand/yield elastikiyetini bounded biçimde üretir;
3. AI fiyat politikası fan trust, doluluk ve financial discipline bağlamına deterministik tepki verir;
4. active incumbent player yalnız controlled club fiyatını override eder; diğer 47 kulüp exact AI parity'de kalır;
5. successor mismatch ve persisted lost tenure player provider'ı bloklar; aynı input aynı sonucu üretir.

## Bilinçli kapsam dışı

- gerçek sezon economy row'una bilet fiyatı multiplier entegrasyonu;
- sezonluk/maçlık fiyat takvimi;
- kupa/derbi/dinamik rakip fiyatlaması;
- M59/M63 üst-level checkpoint composition;
- M60 transfer-strategy composition.

Bu entegrasyonlar sonraki canlı `main` taramalarında ayrı milestone olarak değerlendirilmelidir.
