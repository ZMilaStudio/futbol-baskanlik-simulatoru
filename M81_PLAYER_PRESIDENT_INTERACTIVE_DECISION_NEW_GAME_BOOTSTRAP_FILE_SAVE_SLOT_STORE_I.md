# M81 — Player President Interactive Decision New-Game Bootstrap File Save Slot Store I

Status: **CLOSED / MERGED / PASS**

## Amaç

M80 replay-only pre-checkpoint new-game bootstrap snapshot'ını yerel dosya slotunda güvenli ve deterministik biçimde saklamak.

## Çözüm

Yeni adapter:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore`

Özellikler:
- exact M80 bootstrap envelope bytes saklar,
- ayrı `.fbs.bootstrap.json` namespace kullanır,
- M77 `.fbs.json` checkpoint slotlarını değiştirmez,
- atomic temp → target replacement + committed backup recovery uygular,
- invalid/path-traversal slot ID'lerini fail-closed reddeder,
- checkpoint-backed application session bootstrap slotuna yazılmadan önce fail-closed olur; disk mutation oluşmaz,
- load sırasında M80 checksum/format validation + world fingerprint guard aynen çalışır,
- list/delete/contains yalnız bootstrap namespace'ini görür.

## Authority sınırı

Değişmedi:
- M65 tek persisted game-state authority.
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 M75-only checkpoint file-slot store.
- M78 M75-backed read-only checkpoint catalog.
- M80 pre-checkpoint bootstrap/replay snapshot.
- M81 yalnız exact M80 bytes file adapter; yeni game-state authority değildir.

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

## Final PRE-MERGE kanıtı

Final approved exact PR HEAD:
`fb343a41cba6f79fb8b64c8590b8d4a57f8af3f5`

PR workflow run:
`34976042057`

- analyzer `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- canonical aynı exact SHA üzerinde timeout retry sonrası **M0–M81 SUCCESS**
- M81 step SUCCESS
- exact M81 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**
- PR Ready / mergeable
- kullanıcı exact HEAD için açık squash-merge onayı verdi

## Merge

PR:
**#84 — MERGED**

Squash merge SHA:
`76566493c7f5999487b53db4794088a75bbe6a7b`

Merge `expected_head_sha=fb343a41cba6f79fb8b64c8590b8d4a57f8af3f5` lock ile yapıldı.

## POST-MERGE gerçek main kanıtı

Push workflow run:
`34986135432`

Test job:
- checkout exact real `main` SHA `76566493c7f5999487b53db4794088a75bbe6a7b`
- analyzer `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- Post Checkout + Complete job SUCCESS

Canonical ilk deneme:
- M0–M77 SUCCESS
- M78 strict 7 dakikalık outer envelope sırasında cancelled
- M79–M81 skipped
- fonksiyonel hata değildi; M81 hiç çalışmadığı için evidence gap bırakıyordu

Canonical retry:
- aynı real merge SHA üzerinde
- job `104441763719`
- **M0–M81 tüm executable adımlar SUCCESS**
- M81 step SUCCESS
- exact M81 marker PASS
- Post Checkout + Complete job SUCCESS

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

## Sonuç

**M81 CLOSED / MERGED / PASS.**

M65 persisted game-state authority olarak korunmuştur; M81 yalnız M80 replay-only bootstrap bytes için file adapter'dır ve M77 checkpoint persistence namespace'inden izoledir.

**Aktif milestone yoktur. M82 ancak fresh live-main gap scan ile seçilebilir.**
