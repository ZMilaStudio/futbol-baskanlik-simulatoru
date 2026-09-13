# M60 — Player President Tenure-Gated Transfer Strategy Control I

## Amaç

M55 ile oyuncu başkanın controlled club transfer stratejisini seçebilmesi sağlandı. M58 ise player-president kontrolünü gerçek incumbent `presidentId` kimliğine bağlayan persisted ownership state'ini kurdu. M59 bu gate'i M49–M52 nested runtime kararlarına bağladı.

M60, aynı ownership kuralını M55 transfer stratejisi yüzeyine uygular.

## Davranış

- Transfer stratejisi kararı yalnız `tenureControl.active == true` iken ve controlled club'ın gerçek AI management profile `presidentId` değeri captured `playerPresidentId` ile aynıyken oyuncuya gider.
- Gerçek successor profile görüldüğünde player provider çağrılmaz; M55/M54'ün untouched AI profile yolu kullanılır.
- Reelection aynı incumbent kimliğini koruduğu için player transfer-strategy kontrolü devam eder.
- Persist edilmiş `lost` tenure state'i, eski başkan kimliği daha sonra tekrar görünse bile kontrolü yeniden açmaz.
- Diğer 47 kulübün AI profile'ları aynen korunur.
- M54 explicit transfer policy map'leri mevcut precedence/bypass davranışını korur ve profile/provider katmanını tamamen atlar.
- Provider callback runtime-only kalır; yeni callback veya fonksiyon save'e yazılmaz.
- M55'in dört bounded transfer trait'i dışında yeni transfer yetkisi eklenmez.

## Acceptance

1. Active incumbent gerçek transfer window'da player strategy kararını uygular.
2. Successor `presidentId` görüldüğünde player provider çağrılmaz ve exact AI transfer path korunur.
3. Reelection aynı incumbent kimliğiyle yalnız controlled club profile'ını override eder; diğer 47 kulüp AI parity'de kalır.
4. Persisted `lost` state save/load sonrası sticky kalır ve eski kimlik geri görünse bile control reaktive olmaz.
5. Explicit caller transfer policy precedence/bypass aynen korunur.

## Dosyalar

- `lib/src/transfer/player_president_tenure_gated_transfer_strategy_control.dart`
- `lib/player_president_tenure_gated_transfer_strategy_control.dart`
- `test/m60_player_president_tenure_gated_transfer_strategy_control_test.dart`
- `tool/run_m60_player_president_tenure_gated_transfer_strategy_control.dart`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

## Kapsam dışı

M56 promise ve M57 media statement tenure gating bu milestone'a zorla dahil edilmez. Bu yüzeyler farklı runtime composition noktalarında çalıştığı için canlı mimari üzerinden ayrı milestone olarak ele alınacaktır.
