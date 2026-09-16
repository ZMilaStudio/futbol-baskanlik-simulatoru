# M83 — Player President Interactive Decision Mixed File Save Slot Catalog I

Status: **ACTIVE / PRE-MERGE**

## Amaç

M78 checkpoint load-game catalog ile M82 pre-checkpoint bootstrap load-game catalog yüzeylerini tek deterministic, read-only ve authority-safe application projection altında birleştirmek.

## Seçim gerekçesi

M82 kapanışından sonra fresh live-main gap scan yapıldı. Checkpoint yaşam evresi M78 ile, pre-checkpoint new-game yaşam evresi M82 ile ayrı ayrı güvenli ve deterministic catalog yüzeylerine sahipti; ancak uygulamanın tek bir “yüklenebilir oyunlar” görünümü için ortak read-only projection yoktu.

Save/load router, namespace migration veya dual-format store daha geniş ve mutating kapsam gerektirecekti. En küçük doğal authority-safe adım, mevcut M78 ve M82 doğrulamalarını yeniden kullanan mixed read-only catalog oldu.

## Çözüm

Yeni catalog:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog`

Yeni source kimliği:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSource`

Yeni ortak summary:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSummary`

Davranış:
- M78 checkpoint catalog ve M82 bootstrap catalog sonuçlarını tek listede projekte eder,
- physical save namespace’lerini birleştirmez,
- her entry source olarak `checkpoint` veya `newGameBootstrap` taşır,
- aynı human-facing `slotId` iki namespace’te varsa iki ayrı typed identity olarak korunur,
- stable identity `source:slotId` biçimindedir,
- deterministic sıra önce `slotId`, eşitlikte checkpoint → bootstrap kullanır,
- source-specific M78/M82 summary objesi korunur,
- checksum/decode/replay/world validation doğrudan child cataloglara delege edilir,
- inspect/list hiçbir save byte’ı mutate etmez,
- metadata sidecar veya yeni persisted schema oluşturmaz.

Ortak projection alanları en az:
- `source`
- `slotId`
- `controlledClubId`
- `controlledClubName`
- `answeredDecisionCount`
- `pendingDecisionKind`
- `sessionCompleted`
- `resumeSeasonCount`
- `hasFutureSeasonAfterReport`
- source-specific exact summary

## Authority sınırı

Değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 M75-only checkpoint file-slot store.
- M78 checkpoint read-only catalog/projection.
- M80 pre-checkpoint replay-only bootstrap snapshot.
- M81 exact M80 bootstrap bytes file-slot store.
- M82 bootstrap read-only catalog/projection.
- M83 yalnız M78 + M82 read-only projection composition katmanıdır; ikinci bir persisted state authority değildir.

## Non-scope

- save routing,
- checkpoint/bootstrap migration,
- namespace replacement policy,
- dual-format physical store,
- metadata sidecar/timestamp,
- save byte mutation,
- database/cloud/Flutter/provider state,
- yeni persisted game-state authority.

## Acceptance

1. Her iki child catalog boşken mixed catalog deterministic empty sonuç üretir — **PASS**.
2. Checkpoint + bootstrap summary’lerini deterministic order ile birleştirir — **PASS**.
3. Aynı raw `slotId` iki namespace’te varsa iki typed identity de korunur — **PASS**.
4. Corrupt checkpoint child catalog üzerinden fail-closed kalır — **PASS**.
5. Divergent bootstrap world child catalog üzerinden fail-closed kalır ve mixed catalog hiçbir yeni write/file üretmez — **PASS**.

## PRE-MERGE executable kanıt zinciri

Executable exact branch HEAD:
`9474bfc179d724c3001112babe93b564ffdf66e0`

PR:
**#86 — OPEN / DRAFT / PRE-MERGE**

Branch:
`feat/m83-mixed-file-save-slot-catalog`

Exact-head workflow run:
`35016802229` — run #519 — event `pull_request`

Test job:
`104721007080`

Test evidence:
- analyzer `No issues found!`
- **382/382 tests PASS**
- **5/5 M83 acceptance PASS**
- Post Checkout + Complete job SUCCESS

Canonical evidence:
- strict 7 dakikalık envelope nedeniyle önceki attempt’lerde target M83 çalışmadan timing-only cancellation görüldü,
- target çalışmayan denemeler PASS sayılmadı,
- source/docs patch’i atmadan aynı exact SHA üzerinde canonical job retry edildi,
- başarılı canonical job: `104721005168`,
- **M0–M83 tüm executable adımlar SUCCESS**,
- M83 step SUCCESS,
- Post Checkout + Complete job SUCCESS,
- exact M83 marker logda doğrulandı.

Artifacts:
- run `35016802229` → **0**

Exact canonical marker:
`M83_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_CATALOG_PASS total=2 checkpoint=1 bootstrap=1 collision=2 deterministic=true readOnly=true saveAuthority=M65`

## Ana dosyalar

- `lib/src/player_president/player_president_interactive_decision_mixed_file_save_slot_catalog.dart`
- `lib/player_president_interactive_decision_mixed_file_save_slot_catalog.dart`
- `test/m83_player_president_interactive_decision_mixed_file_save_slot_catalog_test.dart`
- `tool/run_m83_player_president_interactive_decision_mixed_file_save_slot_catalog.dart`
- `.github/workflows/m0-tests.yml`

## Merge gate

M83 **henüz merge edilmemiştir** ve **CLOSED değildir**.

Bu PRE-MERGE docs commit’i branch HEAD’ini değiştirecektir. Yeni docs-included final candidate SHA için yeniden:
1. analyzer,
2. **382/382 tests**,
3. **5/5 M83 acceptance**,
4. canonical **M0–M83**,
5. exact M83 marker,
6. cleanup,
7. artifacts `0`
kanıtı alınacaktır.

Ancak bundan sonra PR #86 Ready for review yapılacak ve final exact SHA kullanıcıya açıkça squash-merge için onaylatılacaktır.

## Sonuç

M83 executable kapsamı ve parent evidence hazırdır; milestone **ACTIVE / PRE-MERGE** durumundadır.

M65 persisted game-state authority olarak korunmuştur. M83 yalnız checkpoint + bootstrap load-game summary’lerini typed, deterministic ve read-only biçimde birleştirir.
