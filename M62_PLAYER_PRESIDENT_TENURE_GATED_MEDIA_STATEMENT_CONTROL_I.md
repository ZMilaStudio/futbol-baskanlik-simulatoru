# M62 — Player President Tenure-Gated Media Statement Control I

## Amaç

M57 player-president media statement stance override davranışını M58 gerçek başkan görev süresi/ownership state'i ile yetkilendirmek.

## Canlı mimari gerekçe

M57 `PlayerPresidentMediaStatementEngine`, controlled club için yalnız `controlledClubId` ve runtime provider varlığını kontrol ediyor; gerçek incumbent president kimliğini bilmiyor. M58 ise player başkan kimliğini persist ediyor ve gerçek election turnover sonrası state'i kalıcı `lost` durumuna geçiriyor.

President-domain akışında medya açıklamaları sezon içinde değerlendirilir, seçim sezon sonunda yapılır ve turnover sonraki sezon itibarıyla etkili olur. Bu nedenle M62 M10/M57 medya olaylarını post-hoc değiştirmez; president-domain runtime'ı sezon-sezon ilerletir ve her sezon sonunda M58 gate'ini yeniler.

## Davranış

- Active player-president görev süresinde M57 provider controlled club için çalışır.
- Player yalnız gerçek M10 statement event'inin mevcut `MediaStance` seçeneklerinden birini seçebilir.
- Statement event existence, id, club, manager target, season ve topic canonical kalır.
- M10 credibility resolution seçilen stance üzerinden normal biçimde çalışmaya devam eder.
- Sezon sonu gerçek election turnover sonrası M58 state `lost` olur ve successor'ın ilk sezonundan itibaren provider çağrılmaz.
- Blocked/lost durumda aynı M57 engine provider=null ile exact AI media path'e döner.
- Reelection aynı incumbent identity'yi koruduğu için player media control devam eder.
- Persisted `lost` state save/load sonrası sticky kalır ve reaktive olmaz.
- Diğer 47 kulüp exact AI parity'de kalır.
- Yeni save envelope yalnız president-domain checkpoint + M58 tenure-control state saklar; provider callback runtime-only kalır.

## Acceptance

1. Active incumbent gerçek statement stance seçimini uygular; event metadata korunur ve diğer 47 kulüp exact AI parity'de kalır.
2. Gerçek election turnover successor'ın ilk sezonunda provider'ı bloklar ve exact AI president-domain path'ini korur.
3. Reelection player media control'ü sonraki dönemde aktif tutar.
4. Persisted lost tenure save/load sonrası provider'ı yeniden aktive etmez.
5. Runtime-only provider yeniden kurularak split save/resume direct run ile deterministik kalır.

## Dosyalar

- `lib/src/media/player_president_tenure_gated_media_statement_control.dart`
- `lib/player_president_tenure_gated_media_statement_control.dart`
- `test/m62_player_president_tenure_gated_media_statement_control_test.dart`
- `tool/run_m62_player_president_tenure_gated_media_statement_control.dart`
- `M62_PLAYER_PRESIDENT_TENURE_GATED_MEDIA_STATEMENT_CONTROL_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`
