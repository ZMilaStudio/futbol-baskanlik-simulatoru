# M77 — Player President Interactive Decision File Save Slot Store I

Durum: **ACTIVE / PRE-MERGE / FINAL EXACT-HEAD CI BEKLİYOR**

## 1. Fresh live-main gap

M76, checkpoint-backed interactive president session için application-facing `advance / submit / save / restore` lifecycle owner'ını sağladı. Ancak `save` çıktısı hâlâ yalnız M75 atomik bundle'ının encoded `String` temsilidir.

Canlı `main` taramasında:
- concrete save-slot/storage adapter bulunmadı,
- repo genelinde `dart:io` tabanlı save backend bulunmadı,
- M76'nın encoded bundle'ını gerçek bir local slot'a yazan/yükleyen application katmanı bulunmadı.

Bu nedenle M77'nin kapsamı, yeni authority yaratmadan M75 bundle'ını dosya-backed slot lifecycle'ına bağlamak olarak seçildi.

## 2. Çözüm

Yeni application adapter:

`PlayerPresidentInteractiveDecisionFileSaveSlotStore`

Surface:
- `save(slotId, session)`
- `load(slotId)`
- `contains(slotId)`
- `delete(slotId)`
- `listSlotIds()`

Store:
- slot kimliğini `^[A-Za-z0-9_-]{1,64}$` ile sınırlar,
- path traversal / slash / backslash / whitespace içeren slot adlarını reddeder,
- exact M75 persistence bundle bytes'ını `<slot>.fbs.json` dosyasına yazar,
- overwrite sırasında temp + backup replacement kullanır,
- interrupted replacement sonrasında backup'tan recovery yapar,
- corrupt bundle'ı M75 checksum/validation zinciri üzerinden fail-closed reddeder,
- slot listesini deterministic alfabetik sırada döndürür.

## 3. Authority sınırı

M77 yeni persisted game-state authority veya yeni save formatı oluşturmaz.

Authority zinciri değişmez:
- **M65**: tek persisted game-state authority,
- **M74**: accepted-answer deterministic replay metadata,
- **M75**: versioned/checksummed atomic application persistence bundle,
- **M76**: interactive application-session lifecycle owner,
- **M77**: M75 bundle bytes'ını local filesystem slot'una materialize eden application storage adapter.

Flutter state/provider, Android platform channel, database, cloud sync veya ikinci bir game-state serialization katmanı eklenmez.

## 4. Ana dosyalar

- `lib/src/player_president/player_president_interactive_decision_file_save_slot_store.dart`
- `lib/player_president_interactive_decision_file_save_slot_store.dart`
- `test/m77_player_president_interactive_decision_file_save_slot_store_test.dart`
- `tool/run_m77_player_president_interactive_decision_file_save_slot_store.dart`
- `.github/workflows/m0-tests.yml`

## 5. Acceptance

1. Save edilen slot yeni bir store instance'ından yüklenir; exact pending request ve exact encoded M75 bundle korunur.
2. Aynı slot overwrite edildiğinde yalnız en yeni exact M75 bundle authoritative target olarak kalır.
3. Path traversal ve invalid slot kimlikleri fail-closed reddedilir.
4. Interrupted replacement sonrasında committed backup recovery edilir.
5. Corrupt target bundle M75 validation üzerinden fail-closed reddedilir.
6. Slot listesi deterministic sıralıdır ve delete slot state'ini tamamen kaldırır.
7. M65/M75/M76 authority sınırı korunur.

## 6. Canonical marker

`M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true interruptedRecovery=true invalidBlocked=true stableSave=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 7. İlk executable CI kanıtı

İlk code/workflow exact HEAD:
`e217f7bcb937e8bd83bad3cda8d6c80c4460d4fb`

PR:
- #80 — `M77: interactive decision file save slot store`
- branch: `feat/m77-interactive-decision-file-save-slot-store`
- bu aşamada DRAFT / PRE-MERGE

Workflow run:
`34898142811`

`test` job:
- job `104157272601`
- **SUCCESS**
- analyzer: `No issues found!`
- **350/350 tests PASS**
- 6 M77 acceptance testi PASS
- Post Checkout + Complete job SUCCESS

`canonical` job:
- job `104157272375`
- M0–M77 executable adımlarının tamamı SUCCESS
- exact M77 marker PASS
- Post Checkout + Complete job SUCCESS

Artifacts:
- **0**

Bu run source/test/canonical executable kanıtıdır. Bu doküman ve proje devir dosyaları branch HEAD'ini ilerleteceği için **merge öncesi final exact-head CI yeniden doğrulanmalıdır**.

## 8. Merge gate

M77 şu anda CLOSED değildir.

Merge öncesi zorunlu sıra:
1. docs dahil final PR HEAD SHA canlı GitHub'dan kilitlenir,
2. o exact HEAD için analyzer + 350 test + M0–M77 canonical + exact M77 marker + artifacts=0 doğrulanır,
3. PR ready/mergeable durumu doğrulanır,
4. kullanıcıdan o exact HEAD SHA için açık merge onayı alınır,
5. yalnız squash + exact-head lock ile merge edilir,
6. post-merge gerçek `main` executable CI doğrulanmadan M77 CLOSED / MERGED / PASS yazılmaz.
