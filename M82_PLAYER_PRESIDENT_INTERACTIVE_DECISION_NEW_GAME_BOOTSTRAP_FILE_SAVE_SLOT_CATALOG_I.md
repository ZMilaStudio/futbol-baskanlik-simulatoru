# M82 — Player President Interactive Decision New-Game Bootstrap File Save Slot Catalog I

Status: **ACTIVE / PRE-MERGE**

## Amaç

M81'in exact M80 replay-only bootstrap file slotları için deterministic, read-only ve authority-safe load-game catalog/projection yüzeyi sağlamak.

## Seçim gerekçesi

Fresh live-main gap scan sonucu M81 bootstrap bytes'ı diskte güvenli biçimde saklıyor ve slot ID'lerini listeliyordu; ancak checkpoint tarafındaki M78 gibi kullanıcıya/uygulamaya güvenli load-game metadata projeksiyonu yoktu.

Checkpoint + bootstrap slotlarını tek mixed catalog altında birleştirmek daha büyük kapsam olacağından M82 yalnız bootstrap namespace'i için seçildi.

## Çözüm

Yeni catalog:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog`

Özellikler:
- M81 slotunu exact load eder,
- M80 checksum / envelope / world fingerprint guard'ını çalıştırır,
- M74 replay + application-session sonucundan summary türetir,
- metadata sidecar oluşturmaz,
- inspect/list read-only'dir; bootstrap veya checkpoint bytes mutate edilmez,
- deterministic slot-id order kullanılır,
- overwrite sonrası latest persisted bootstrap state'i yansır,
- missing slot `null` contract'ını korur,
- invalid slot ID M81 validation contract'ını korur,
- corrupt bytes fail-closed olur,
- divergent supplied world `SaveLoadFailure.invalidPayload` ile fail-closed olur,
- M77 `.fbs.json` checkpoint namespace'i catalog dışında kalır.

Summary alanları en az:
- `slotId`
- `controlledClubId`
- `controlledClubName`
- `careerSeed`
- `answeredDecisionCount`
- `pendingDecisionKind`
- `resumeSeasonCount`
- `electionInterval`

## Authority sınırı

Değişmedi:
- M65 tek persisted game-state authority.
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 M75-only checkpoint file-slot store.
- M78 M75-backed read-only checkpoint catalog.
- M80 pre-checkpoint replay-only bootstrap snapshot.
- M81 exact M80 bootstrap bytes file adapter.
- M82 yalnız read-only bootstrap catalog/projection; yeni game-state authority değildir.

## Non-scope

- metadata sidecar,
- checkpoint + bootstrap mixed catalog,
- M77 dual-format store,
- timestamp / nondeterministic metadata,
- database/cloud/Flutter/provider state,
- yeni persisted game-state authority.

## Acceptance

Executable parent exact SHA:
`9ae3a13afd017022baca6e76cda56e6e14b56de1`

1. Bootstrap slot deterministic load-game metadata üretir ve underlying bytes değişmez — **PASS**.
2. Catalog deterministic slot-id order kullanır ve overwrite sonrası latest state'i yansıtır — **PASS**.
3. Missing/invalid slot davranışı M81 contract'ını korur — **PASS**.
4. Corrupt bytes ve divergent supplied world fail-closed olur — **PASS**.
5. Catalog M77 checkpoint namespace'inden izole kalır — **PASS**.

## Executable PRE-MERGE kanıtı

PR:
**#85 — OPEN / DRAFT / PRE-MERGE**

Branch:
`feat/m82-new-game-bootstrap-file-save-slot-catalog`

Base `main`:
`e1d90a20702a9bcfcc46aae3e9d779121cfa297e`

Executable parent branch HEAD:
`9ae3a13afd017022baca6e76cda56e6e14b56de1`

PR workflow run:
`34990552222`

Test:
- analyzer `No issues found!`
- **377/377 tests PASS**
- **5/5 M82 acceptance PASS**
- Post Checkout + Complete job SUCCESS

Canonical:
- strict 7 dakikalık envelope içinde önceki attempt'ler M77/M79/M78 civarında timing-only cancelled oldu,
- M82 target çalışmadığı attempt'ler PASS olarak kabul edilmedi,
- code patch'i yapılmadan exact aynı SHA retry edildi,
- başarılı canonical job: `104504219474`,
- **M0–M82 tüm executable adımlar SUCCESS**,
- M82 step SUCCESS,
- Post Checkout + Complete job SUCCESS,
- exact marker logda doğrulandı.

Artifacts:
- **0**

Exact canonical marker:
`M82_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 summaries=2 primaryAnswers=4 deterministicOrder=true readOnly=true metadataExact=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 store=M81 worldClubs=48 seed=20260903`

## Ana dosyalar

- `lib/src/player_president/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart`
- `lib/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart`
- `test/m82_player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog_test.dart`
- `tool/run_m82_player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart`
- `.github/workflows/m0-tests.yml`

## PRE-MERGE gate

Bu doküman commit'i executable parent SHA'yı ilerletecektir. Bu nedenle `9ae3a13...` merge approval SHA değildir.

Sonraki adım:
1. docs-included final candidate exact PR HEAD için CI tekrar çalıştırılır,
2. analyzer / 377 tests / 5 M82 / canonical M0–M82 / exact marker / cleanup / artifacts 0 tekrar doğrulanır,
3. PR #85 Ready yapılır,
4. HEAD değişmediği ve mergeable olduğu tekrar doğrulanır,
5. kullanıcıdan **o exact final SHA** için açık squash-merge onayı istenir.

## Sonuç

**M82 henüz CLOSED değildir ve merge edilmemiştir.**

M65 persisted game-state authority olarak korunmuştur; M82 yalnız M81 bootstrap saves için read-only load-game projection katmanıdır.

**M82 kapanmadan M83 seçilmez.**
