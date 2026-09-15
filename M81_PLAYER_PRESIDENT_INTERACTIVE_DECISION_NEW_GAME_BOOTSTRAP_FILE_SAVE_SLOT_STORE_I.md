# M81 — Player President Interactive Decision New-Game Bootstrap File Save Slot Store I

Status: **ACTIVE / PRE-MERGE**

## Amaç

M80 replay-only pre-checkpoint new-game bootstrap snapshot'ını yerel dosya slotunda güvenli ve deterministik biçimde saklamak.

## Neden M81?

M80 ile pre-checkpoint yeni oyun ilerlemesi versioned/checksummed bootstrap + M74 transcript olarak encode edilebiliyor. Ancak M77 file save-slot store yalnız M75 checkpoint bundle kabul ediyor ve pre-checkpoint new-game session'ı saklamıyor.

Fresh live-main gap scan sonucu en küçük authority-safe açık M80 bootstrap bytes için disk persistence katmanıdır.

## Çözüm

Yeni adapter:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore`

Özellikler:
- exact M80 bootstrap envelope bytes saklar,
- ayrı `.fbs.bootstrap.json` namespace kullanır,
- M77 `.fbs.json` checkpoint slotlarını değiştirmez,
- atomic temp → target replacement + committed backup recovery uygular,
- slot ID path traversal korumasını M77 ile aynı sınırda tutar,
- load sırasında M80 checksum/format validation ve world fingerprint guard aynen çalışır,
- checkpoint-backed application session bootstrap slotuna yazılmadan önce fail-closed olur; disk mutation oluşmaz,
- list/delete/contains yalnız bootstrap namespace'ini görür.

## Authority sınırı

Değişmedi:
- M65 tek persisted game-state authority.
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 M75-only checkpoint file-slot store.
- M78 M75-backed read-only checkpoint catalog.
- M80 pre-checkpoint bootstrap/replay snapshot.
- M81 yalnız M80 bytes file adapter; yeni game-state authority değildir.

## Non-scope

- M77 formatını dual-format envelope'a çevirmek,
- M78 catalog'a bootstrap metadata eklemek,
- checkpoint ve bootstrap slotlarını tek load-game catalog altında birleştirmek,
- timestamp / nondeterministic metadata,
- database/cloud/Flutter/provider state.

## Acceptance

1. Bootstrap slot fresh store instance üzerinden exact pending request ve stable M80 bytes ile restore edilir — **PASS**.
2. Aynı slot overwrite edildiğinde yalnız latest M80 bootstrap kalır — **PASS**.
3. Invalid slot ID'ler ve checkpoint-backed session bootstrap write fail-closed; disk mutation oluşmaz — **PASS**.
4. Interrupted replacement sonrası committed backup otomatik recover edilir — **PASS**.
5. Corrupted bootstrap bytes ve divergent supplied world fail-closed olur — **PASS**.
6. Bootstrap list/delete/contains M77 checkpoint slot namespace'inden deterministik olarak izole kalır — **PASS**.

## İlk executable CI kanıtı

Exact HEAD:
`b59bf5c23ce7a1b73683068a9aebcf32d395edb8`

PR workflow run:
`34974945110`

Test job:
- analyzer `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- Post Checkout + Complete job SUCCESS
- job SUCCESS

Canonical job:
- **M0–M81 tüm executable adımlar SUCCESS**
- M81 step SUCCESS
- Post Checkout + Complete job SUCCESS
- job SUCCESS

Artifacts:
- **0**

Exact canonical marker:
`M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true stableSave=true interruptedRecovery=true invalidBlocked=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 worldClubs=48 seed=20260903`

## Ana dosyalar

- `lib/src/player_president/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart`
- `lib/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart`
- `test/m81_player_president_interactive_decision_new_game_bootstrap_file_save_slot_store_test.dart`
- `tool/run_m81_player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart`
- `.github/workflows/m0-tests.yml`

## PRE-MERGE kapanış kapıları

Bu doküman commit'i PR HEAD'ini ilk executable SHA'dan sonra ilerletecektir. Merge öncesi:
1. canlı PR #84 final HEAD yeniden okunacak,
2. o exact HEAD için analyzer + 372 tests + 6 acceptance doğrulanacak,
3. canonical M0–M81 + exact marker + cleanup doğrulanacak,
4. artifacts=0 doğrulanacak,
5. PR Ready for review yapılacak,
6. HEAD değişmedi + mergeable doğrulanacak,
7. kullanıcıdan exact final SHA için açık merge onayı alınacak.

**Onay olmadan merge yok. M81 kapanmadan M82 yok.**
