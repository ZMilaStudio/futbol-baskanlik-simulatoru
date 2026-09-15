# M79 — Player President Interactive Decision Application New-Game Session I

Durum: **ACTIVE / PRE-MERGE**

Son güncelleme: 15 Eylül 2026

## 1. Başlangıç kanıtı

M79 seçilmeden önce canlı `main` HEAD:

`30b41f027b45cdf11df9f0a5851faa12aa1ebb68`

Bu HEAD üzerinde M0–M78 **CLOSED / MERGED / PASS** idi ve açık milestone PR'ı yoktu.

Fresh live-main gap scan sonucu şu ürün açığı doğrulandı:
- M73 sezon 0'dan deterministic interaktif yeni oyun oturumu başlatabiliyordu,
- M76 application lifecycle owner ise yalnız M65 checkpoint üzerinden `resume/restore` yüzeyi sunuyordu,
- bu nedenle gerçek application/UI katmanı yeni oyunu M76 üzerinden başlatamıyor ve M73'e doğrudan inmek zorunda kalıyordu,
- M75 persistence envelope ise M65 checkpoint authority'sine bağlı olduğundan pre-checkpoint yeni oyun save'i bu milestone'a güvenli biçimde dahil edilemezdi.

M79 en küçük doğru halkayı kapatır: application katmanı yeni oyunu sahiplenir, fakat persistence authority veya save formatı büyütülmez.

## 2. Çözüm

`PlayerPresidentInteractiveDecisionApplicationSession` üzerine yeni application-facing başlangıç yüzeyi eklendi:

`PlayerPresidentInteractiveDecisionApplicationSession.start(...)`

Yeni origin:
- `PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame`
- `PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint`

Yeni durum yüzeyi:
- `isNewGame`
- `canPersist`
- `checkpointOrNull`
- `newGameElectionInterval`

Mevcut checkpoint-backed `checkpoint` contract'ı korunur. New-game/pre-checkpoint oturumunda bu getter fail-closed davranır.

## 3. Persistence ve authority sınırı

M79 yeni save representation oluşturmaz.

Pre-checkpoint new-game session:
- `canPersist == false`,
- `checkpointOrNull == null`,
- M75 `persistenceBundle` / encode isteği açık `StateError` ile fail-closed olur.

Yeni oyun tamamlandığında üretilen gerçek M65 checkpoint, mevcut M76 checkpoint-backed lifecycle'a handoff edilebilir. Böylece sonraki save/restore M75/M77 zincirinden devam eder.

Authority zinciri değişmez:
- M65 tek persisted **game-state authority**,
- M74 accepted-answer replay metadata,
- M75 atomik application persistence bundle/save formatı,
- M76/M79 application-session lifecycle owner,
- M77 exact M75 bytes local file slot storage adapter,
- M78 read-only load-game catalog projection.

M79 şunları eklemez:
- pre-checkpoint save codec,
- ikinci game-state authority,
- M75 format değişikliği,
- M77 storage format değişikliği,
- metadata sidecar,
- database/cloud sync,
- Flutter/provider state.

## 4. Dosyalar

- `lib/src/application/player_president_interactive_decision_application_session.dart`
- `test/m79_player_president_interactive_decision_application_new_game_session_test.dart`
- `tool/run_m79_player_president_interactive_decision_application_new_game_session.dart`
- `.github/workflows/m0-tests.yml`
- `M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_I.md`

## 5. Acceptance

1. Application `start(...)`, M73'ün deterministic sezon-0 ilk pending request'ini sahiplenir.
2. New-game application oturumu tamamlandığında raw M73 new-game sonucu ile exact parity verir.
3. Pre-checkpoint M75 persistence açık biçimde fail-closed olur; yeni authority üretilmez.
4. Tamamlanan new-game sonucu mevcut M76 checkpoint lifecycle'a handoff olur.
5. New-game input validation korunur.
6. M65/M75/M77 authority sınırı korunur.

## 6. İlk executable CI kanıtı

Executable code/workflow HEAD:

`2cc2fa74b40ac8321e7e75b567715517b14f3aa7`

PR:
- #82 — `M79: interactive decision application new-game session`
- branch: `feat/m79-interactive-decision-application-new-game-session`
- bu aşamada DRAFT / OPEN / PRE-MERGE

Workflow run:
- `34931609477`
- event `pull_request`

`test` job latest successful attempt:
- **SUCCESS**
- analyzer: `No issues found!`
- **360/360 tests PASS**
- 5 M79 acceptance testi logda PASS
- Post Checkout + Complete job SUCCESS

Canonical zamanlama:
- attempt 1 M72 civarında strict 7 dakika timeout — M79 çalışmadı, merge kanıtı sayılmadı,
- attempt 2 M71 civarında timeout — M79 çalışmadı,
- attempt 3 M70 civarında timeout — M79 çalışmadı,
- attempt 4 M71 civarında timeout — M79 çalışmadı,
- attempt 5 aynı exact code HEAD üzerinde **SUCCESS**.

Attempt 5 canonical job:
- job `104291384887`
- **M0–M79 tüm executable adımları SUCCESS**
- M79 exact marker PASS
- Post Checkout SUCCESS
- Complete job SUCCESS

Artifacts:
- **0**

Exact marker:

`M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_PASS controlled=t1_01 decisions=9 startOwned=true deterministic=true persistenceBlocked=true parityM73=true checkpointHandoff=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 7. Merge gate

Bu doküman ile proje/devir dosyaları executable CI'dan sonra eklenecektir. Bu docs commit'i PR HEAD'ini ilerletir.

M79 henüz CLOSED/PASS değildir.

Merge öncesi zorunlu sıra:
1. docs dahil **final exact PR HEAD** yeniden kilitlenir,
2. aynı exact HEAD için analyzer + 360 test + M0–M79 canonical + exact marker + cleanup + artifacts=0 doğrulanır,
3. strict 7 dakika nedeniyle M79 çalışmazsa aynı exact HEAD'de canonical retry yapılır; sırf süre için kod patch'i atılmaz,
4. PR ready hale getirilir,
5. ready sonrası exact HEAD ve mergeable durumu tekrar okunur,
6. kullanıcıdan **o exact HEAD SHA için açık merge onayı** alınır,
7. yalnız onaylanan exact HEAD `squash` + `expected_head_sha` ile merge edilir,
8. post-merge gerçek `main` executable CI doğrulanmadan M79 CLOSED yazılmaz.

M79 aktifken M80 seçilmez.
