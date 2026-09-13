# M61 — Player President Tenure-Gated Promise Control I

## Amaç

M56 player-president promise override davranışını M58 gerçek başkan görev süresi/ownership state'i ile yetkilendirmek.

## Canlı mimari gerekçe

M56 `PlayerPresidentPromiseGenerator`, controlled club için yalnız `controlledClubId` kontrolü yapıyor; gerçek incumbent president kimliğini bilmiyor. M58 ise player başkan kimliğini persist ediyor ve gerçek election turnover sonrası state'i kalıcı `lost` durumuna geçiriyor.

Başkanlık zincirinde vaat sezon içinde değerlendirilir, seçim sezon sonunda yapılır ve turnover sonraki sezon itibarıyla etkili olur. Bu nedenle M61 post-hoc promise değiştirmez; president-domain runtime'ı sezon-sezon ilerletir ve her sezon sonunda M58 gate'ini yeniler.

## Davranış

- Active player-president görev süresinde M56 provider controlled club için çalışır.
- Player yalnız mevcut M11 context-valid promise type'larından seçim yapabilir; target üretimi M56 canonical kurallarında kalır.
- Election loss sonrası successor'ın ilk sezonundan itibaren external promise provider çağrılmaz.
- Kaybedilen kontrol exact AI promise path'ine döner.
- Reelection aynı incumbent identity'yi korursa player promise kontrolü devam eder.
- `lost` state save/load sonrası sticky kalır ve reaktive olmaz.
- Diğer 47 kulübün AI promise üretimi değişmez.
- Provider callback runtime-only kalır; save codec yalnız president-domain state + M58 tenure-control state saklar.

## Acceptance

1. Active incumbent player promise choice'u uygular ve diğer 47 kulüp AI parity'de kalır.
2. Gerçek election turnover successor'ın ilk sezonunda provider'ı bloklar ve exact AI path'i korur.
3. Reelection player promise kontrolünü sonraki dönemde aktif tutar.
4. Persisted lost tenure save/load sonrası provider'ı yeniden aktive etmez.
5. Runtime-only provider yeniden kurularak save/resume deterministik kalır.

## Dosyalar

- `lib/src/promise/player_president_tenure_gated_promise_control.dart`
- `lib/player_president_tenure_gated_promise_control.dart`
- `test/m61_player_president_tenure_gated_promise_control_test.dart`
- `tool/run_m61_player_president_tenure_gated_promise_control.dart`
- `.github/workflows/m0-tests.yml`

M57 media statement tenure gating bu milestone kapsamına dahil değildir.
