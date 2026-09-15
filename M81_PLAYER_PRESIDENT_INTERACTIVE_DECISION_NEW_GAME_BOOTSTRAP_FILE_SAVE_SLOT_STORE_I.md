# M81 — Player President Interactive Decision New-Game Bootstrap File Save Slot Store I

## Amaç

M80 replay-only pre-checkpoint new-game bootstrap snapshot'ını yerel dosya slotunda güvenli ve deterministik biçimde saklamak.

## Neden M81?

M80 ile pre-checkpoint yeni oyun ilerlemesi artık versioned/checksummed bootstrap + M74 transcript olarak encode edilebiliyor. Ancak mevcut M77 file save-slot store yalnız M75 checkpoint bundle kabul ediyor ve bilinçli olarak pre-checkpoint new-game session'ı saklamıyor.

Fresh live-main gap scan sonucu en küçük authority-safe açık bu bootstrap bytes'ının disk persistence katmanıdır.

## Çözüm

Yeni adapter:

`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore`

Özellikler:
- exact M80 bootstrap envelope bytes saklar,
- ayrı `.fbs.bootstrap.json` namespace kullanır,
- M77 `.fbs.json` checkpoint slotlarını değiştirmez,
- atomic temp → target replace + committed backup recovery uygular,
- slot ID path traversal korumasını M77 ile aynı sınırda tutar,
- load sırasında M80 checksum/format validation ve world fingerprint guard aynen çalışır,
- checkpoint-backed application session'ı bootstrap slotuna yazmayı disk mutation öncesi fail-closed reddeder,
- list/delete/contains yalnız bootstrap namespace'ini görür.

## Authority sınırı

Değişmedi:
- M65 tek persisted game-state authority.
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 M75-only checkpoint file slot store.
- M78 M75-backed read-only checkpoint catalog.
- M80 pre-checkpoint bootstrap/replay snapshot.
- M81 yalnız M80 bytes için file adapter; yeni game-state authority değildir.

## Non-scope

- M77 formatını dual-format envelope'a çevirmek,
- M78 catalog'a bootstrap metadata eklemek,
- checkpoint ve bootstrap slotlarını tek load-game catalog altında birleştirmek,
- timestamp / nondeterministic metadata,
- database/cloud/Flutter/provider state.

## Acceptance

1. Bootstrap slot fresh store instance üzerinden exact pending request ve stable M80 bytes ile restore edilir.
2. Aynı slot overwrite edildiğinde yalnız latest M80 bootstrap kalır.
3. Invalid slot ID'ler ve checkpoint-backed session bootstrap write'ı fail-closed; disk mutation oluşmaz.
4. Interrupted replacement sonrası committed backup otomatik recover edilir.
5. Corrupted bootstrap bytes ve divergent supplied world fail-closed olur.
6. Bootstrap list/delete/contains M77 checkpoint slot namespace'inden deterministik olarak izole kalır.

## Canonical marker

`M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_PASS`
