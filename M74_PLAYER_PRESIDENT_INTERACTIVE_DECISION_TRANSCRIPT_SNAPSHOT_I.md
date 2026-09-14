# M74 — Player President Interactive Decision Transcript Snapshot I

## Amaç

M73 mobil UI'nin karar anında simülasyonu durdurup daha sonra cevap verebilmesini sağladı; ancak cevap transcript'i yalnız RAM'de tutuluyordu. Uygulama süreç/lifecycle nedeniyle kapanırsa aynı sezon içinde daha önce verilmiş player-president cevapları kayboluyor ve M73 aynı başlangıçtan ilk kararı yeniden soruyordu.

M74 bu boşluğu, M65 oyun-state authority'sini çoğaltmadan kapatır. Yalnız M73'ün kabul edilmiş cevap transcript'i versioned/checksummed bir **application replay sidecar** olarak saklanır. Restore sırasında game state, pending request ve context dosyadan okunmaz; aynı immutable başlangıç girdileri veya authoritative M65 checkpoint'i kullanılarak M73 tarafından yeniden hesaplanır.

## Kapsam

- `PlayerPresidentInteractiveDecisionTranscriptEntry`
  - deterministic request key
  - decision kind
  - domain choice'un minimal JSON payload'u
- `PlayerPresidentInteractiveDecisionTranscriptSnapshot`
  - yalnız sıralı kabul edilmiş cevapları taşır
  - game state, pending context veya partial checkpoint taşımaz
- `PlayerPresidentInteractiveDecisionTranscriptSaveCodec`
  - format/version/checksum
  - canonical JSON
  - bozuk/future/invalid transcript fail-closed
- `PlayerPresidentInteractiveDecisionTranscriptSession`
  - M73 session'ını sarar
  - yalnız başarılı `submit` cevaplarını kaydeder
  - snapshot/encoded transcript üretir
  - restore sırasında her entry için M73'ün yeniden türettiği request key + kind ile exact eşleşme ister
  - stale/divergent transcript'i tüketmeden reddeder
- Choice serialization dokuz M73 karar türünün tamamını kapsar:
  - facility investment
  - sponsor
  - crisis
  - manager review
  - manager replacement
  - promise
  - media statement
  - transfer strategy
  - ticket pricing

## Persistence authority

M74 ikinci bir game-state save değildir.

Authoritative oyun state'i değişmeden:
- `PlayerPresidentTicketPricingRuntimeCheckpoint`
- `PlayerPresidentTicketPricingRuntimeSaveCodec`

olarak M65'te kalır.

M74 sidecar yalnız M73 replay metadata'sıdır. Restore için uygulama aynı fresh-start girdilerini veya aynı M65 checkpoint'ini ayrıca sağlamalıdır. Pending request dosyaya yazılmaz; deterministic replay ile yeniden türetilir.

## Acceptance

1. Fresh-start session'da birkaç cevap sonrası transcript encode/decode canonical round-trip verir ve restore aynı pending request key'ini yeniden üretir.
2. Restore edilen fresh-start session tamamlandığında uninterrupted M73 ile exact M65 checkpoint + boundary parity verir.
3. M65 checkpoint üstünde başlayan kısmi session transcript restore edildiğinde aynı pending key'e döner ve uninterrupted M73 resume ile exact parity verir.
4. Checksum corruption replay başlamadan reddedilir.
5. Checksum-valid fakat stale/divergent request key restore sırasında fail-closed olur.
6. Transcript yalnız cevap metadata'sı taşır; M65 save authority ve formatı değişmez.

## Dosyalar

- `lib/src/player_president/player_president_interactive_decision_transcript_snapshot.dart`
- `lib/player_president_interactive_decision_transcript_snapshot.dart`
- `test/m74_player_president_interactive_decision_transcript_snapshot_test.dart`
- `tool/run_m74_player_president_interactive_decision_transcript_snapshot.dart`
- `.github/workflows/m0-tests.yml`
- `M74_PLAYER_PRESIDENT_INTERACTIVE_DECISION_TRANSCRIPT_SNAPSHOT_I.md`

## Non-goals

- M65 game-state checkpoint/save formatını değiştirmek
- partial simulation state persist etmek
- pending decision context nesnelerini serialize etmek
- Flutter widget/screen eklemek
- Android dosya sistemi/cloud save/save-slot UI eklemek
- yeni player-president decision domain'i eklemek
