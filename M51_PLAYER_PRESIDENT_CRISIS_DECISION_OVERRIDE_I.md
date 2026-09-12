# M51 — Player President Crisis Decision Override I

## Amaç

M49 facility ve M50 sponsor ile açılan player-president karar yüzeyini, M43/M44 kriz sisteminin gerçek aksiyon seçimine genişletmek.

Oyuncu teknik direktör değildir; kulüp başkanıdır. Bu milestone başkanın kriz anındaki yönetim tercihini oyuncuya verir.

## Kapsam

- yalnız `controlledClubId` için gerçek kriz oluştuğunda player decision provider çağrılır
- kriz yoksa oyuncudan karar istenmez
- diğer 47 kulüp mevcut `CrisisDecisionEngine` AI yolunu aynen sürdürür
- oyuncu yalnız tespit edilen kriz tipine ait M43 kanonik üç aksiyondan birini seçebilir
- keyfi cash/fan/media delta enjekte edilemez
- seçilen aksiyon mevcut M44 continuation akışında gerçek finance/fan/media state'ine uygulanır
- debt değişmez; hidden borrowing yoktur
- M50 sponsor ve M49 facility player-control aynı runtime zincirinde korunur
- crisis provider serialize edilmez
- `controlledClubId` mevcut nested checkpoint/save zinciri üzerinden persist eder
- deterministic provider ile save/load/resume parity korunur
- provider yokken M50 exact parity korunur

## Public karar context'i

`PlayerCrisisDecisionContext` şunları taşır:

- season index
- club / current president
- management profile
- mevcut finance state
- mevcut fan state
- mevcut media state
- tespit edilen crisis scenario + severity
- o scenario için izin verilen kanonik decisions
- mevcut AI decision

## Acceptance hedefleri

1. crisis provider yokken M50 exact checkpoint/source parity
2. yalnız controlled club crisis seçimi override; diğer 47 kulüp exact AI parity
3. seçilen crisis action gerçek continuation finance/fan/media state'ine yazılır; debt korunur
4. kriz yoksa provider çağrılmaz ve no-crisis M50 parity korunur
5. sponsor + facility + crisis deterministic provider zincirinde save round-trip ve `2+2 == uninterrupted 4` checkpoint/boundary/decision parity

## Kalıcı gate

`tool/run_m51_player_president_crisis_control.dart`

Canonical gate forced activation (`activationThreshold: 0`) kullanarak controlled club için her sezonda gerçek bir karar penceresi üretir. Bu yalnız test/gate konfigürasyonudur; production/default M44 eşik semantiği `55` olarak korunur.

## CI

`.github/workflows/m0-tests.yml` içinde:

`Run M51 player president crisis control`

Milestone yalnız PR exact HEAD CI ve post-merge `main` CI canlı olarak yeşil doğrulanırsa CLOSED / MERGED / PASS sayılır.
