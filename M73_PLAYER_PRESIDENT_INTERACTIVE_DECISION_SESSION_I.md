# M73 — Interactive Player-President Decision Session I

## Amaç

M72 tek bir `PlayerPresidentDecisionGateway` ile sekiz player-president karar domain'ini application-facing bir yüzeyde birleştirdi; ancak gateway çağrıları senkron olduğu için bir mobil UI karar anında simülasyonu durdurup kullanıcıdan daha sonra cevap alamıyordu.

M73 bu application-boundary boşluğunu kapatır. Yeni oyun kuralı eklemez. M72'nin mevcut domain validation, tenure gate, AI parity, deterministic replay ve M65 save authority semantiğini koruyarak UI-drivable bir **pending decision → response → continue** session yüzeyi ekler.

## Kapsam

- `PlayerPresidentInteractiveDecisionSession`
  - yeni oyun başlangıcından veya mevcut M65 checkpoint'inden çalışabilir;
  - ilk cevapsız M72 gateway çağrısında tek bir `PlayerPresidentInteractiveDecisionRequest` üretir;
  - cevap gelene kadar completed checkpoint üretmez;
  - cevap sonrası immutable başlangıç girdilerinden/checkpoint'ten deterministik replay yapar;
  - kayıtlı cevapları tüketip bir sonraki cevapsız kararda yeniden durur;
  - bütün kararlar cevaplandığında normal M72 result + M65 checkpoint döndürür.
- `PlayerPresidentInteractiveDecisionKind`
  - facility investment
  - sponsor
  - crisis
  - manager review
  - manager replacement
  - promise
  - media statement
  - transfer strategy
  - ticket pricing
- Her request sıra numarası, karar türü, controlled club, canonical context signature ve typed context nesnesi taşır.
- `submit` stale/mismatched request'leri ve domain-invalid choice'ları tüketmeden reddeder.
- Session transcript runtime-only'dir; save formatına yeni state eklenmez.
- Tamamlanan authoritative state hâlâ M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` ile persist edilir.
- Flutter/UI bu milestone kapsamında değildir.

## Deterministik replay modeli

M72 motoruna continuation/coroutine semantiği eklemek yerine M73 mevcut senkron gateway'i adapter olarak kullanır:

1. Session M72'yi immutable başlangıç state'inden çalıştırır.
2. Önceden cevaplanmış kararlar request key ile birebir eşleşerek replay edilir.
3. İlk cevapsız gateway çağrısı runtime-only bir pending signal ile run'ı durdurur.
4. UI cevabı session'a verir.
5. Session aynı başlangıç state'inden tekrar çalışır; önceki cevapları deterministik olarak tüketir ve sonraki karara ulaşır.
6. Son karar sonrası normal M72 run tamamlanır.

Bu yaklaşım M49–M72 motorlarının public semantiğini değiştirmez ve partial-mutated checkpoint saklamaz.

## Acceptance

1. İlk cevapsız karar tek pending request olarak dışarı çıkar; cevap verilmeden session progress commit etmez ve aynı `advance()` aynı request key'i döndürür.
2. Scripted request/response session tamamlandığında checkpoint ve boundary signature doğrudan aynı choices ile çalışan M72 gateway ile exact parity verir.
3. Session gerçek bir interaktif sezon akışında M72'nin bilinen karar türlerini tek tek route eder; request key'leri benzersiz ve sıralıdır.
4. Stale/mismatched response ve yanlış choice tipi pending request'i tüketmeden reddedilir.
5. M65 checkpoint'ten başlayan M73 resume, aynı choices ile doğrudan M72 `resume()` sonucuyla exact deterministic parity verir.
6. Session/transcript runtime-only kalır; M65 save authority değişmez.

## Dosyalar

- `lib/src/player_president/player_president_interactive_decision_session.dart`
- `lib/player_president_interactive_decision_session.dart`
- `test/m73_player_president_interactive_decision_session_test.dart`
- `tool/run_m73_player_president_interactive_decision_session.dart`
- `.github/workflows/m0-tests.yml`
- `M73_PLAYER_PRESIDENT_INTERACTIVE_DECISION_SESSION_I.md`

## Non-goals

- Flutter widget/screen eklemek
- async/Future tabanlı domain engine rewrite yapmak
- yeni president decision domain'i eklemek
- M65 checkpoint/save formatını değiştirmek
- seçim, tenure-loss veya AI karar semantiğini değiştirmek
