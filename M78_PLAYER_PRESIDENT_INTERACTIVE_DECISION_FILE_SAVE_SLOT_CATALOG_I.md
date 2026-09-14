# M78 — Player President Interactive Decision File Save Slot Catalog I

Durum: **ACTIVE / PRE-MERGE**

Son güncelleme: 15 Eylül 2026

## 1. Başlangıç kanıtı

M78 seçilmeden önce canlı `main` HEAD:

`952bc9768629195d5d19ab7559170915f080ec31`

Bu HEAD üzerinde M0–M77 **CLOSED / MERGED / PASS** idi ve açık milestone PR'ı yoktu.

Fresh live-main gap scan sonucu M77 sonrasında şu ürün açığı doğrulandı:
- M77 gerçek local file slot'larını save/load edebiliyor,
- fakat load-game yüzeyi yalnız ham `slotId` listesine erişebiliyor,
- uygulama katmanının kulüp, sezon, cevaplanmış karar sayısı, player-control durumu ve pending decision gibi bilgileri gösterebilmesi için M75/M65 nesne ağacını elle açması gerekiyordu,
- ayrı bir deterministic application-facing slot catalog / summary surface'i yoktu.

## 2. Neden yeni-oyun/pre-checkpoint persistence bu milestone değil?

Fresh scan sırasında M73'ün ham world/config üzerinden sezon 0 interaktif oturum başlatabildiği, M76'nın ise yalnız checkpoint-backed `resume/restore` surface'i sunduğu da görüldü.

Bu gerçek bir sonraki ürün açığıdır; ancak M75 persistence formatı M65 checkpoint authority'sine dayanır. Sezon 0 / pre-checkpoint save desteği mevcut checkpoint-backed envelope dışında yeni bir persistence representation tasarımı gerektirir ve authority/save-format sınırına dokunur.

M78 bundan daha küçük ve güvenli halkayı kapatır: mevcut M77 slotlarını **read-only** biçimde load-game ekranı için özetler. Yeni save formatı veya pre-checkpoint authority oluşturmaz.

## 3. Çözüm

Yeni read-only application projection:

`PlayerPresidentInteractiveDecisionFileSaveSlotCatalog`

Surface:
- `inspect(String slotId)`
- `list()`

Yeni immutable summary:

`PlayerPresidentInteractiveDecisionSaveSlotSummary`

Alanlar:
- `slotId`
- `controlledClubId`
- `controlledClubName`
- `completedSeasons`
- `nextSeasonIndex`
- `answeredDecisionCount`
- `playerControlActive`
- `pendingDecisionKind`
- `sessionCompleted`
- `resumeSeasonCount`
- `hasFutureSeasonAfterReport`
- deterministic `signature`

## 4. Persistence ve authority sınırı

M78 hiçbir metadata sidecar yazmaz.

Her summary, M77 `store.load(slotId)` üzerinden exact M75 bundle restore edilerek türetilir. Böylece load-game metadata'sı authoritative save bytes'tan kopamaz.

Authority zinciri değişmez:
- M65 tek persisted **game-state authority**,
- M74 accepted-answer deterministic replay metadata,
- M75 versioned/checksummed atomik application persistence bundle/save format,
- M76 interactive application-session lifecycle owner,
- M77 M75 bytes'ının file-backed local save-slot storage adapter'ı,
- M78 yalnız M77 üzerinden restore edilen authoritative state'in read-only load-game projection'ıdır.

M78 şunları eklemez:
- metadata sidecar,
- filesystem timestamp authority,
- yeni save formatı,
- ikinci game-state authority,
- Flutter/provider state,
- Android platform channel,
- database,
- cloud sync.

Corrupt veya divergent slot M75/M74 restore zinciri üzerinden fail-closed olur; stale summary üretilmez.

## 5. Dosyalar

- `lib/src/player_president/player_president_interactive_decision_file_save_slot_catalog.dart`
- `lib/player_president_interactive_decision_file_save_slot_catalog.dart`
- `test/m78_player_president_interactive_decision_file_save_slot_catalog_test.dart`
- `tool/run_m78_player_president_interactive_decision_file_save_slot_catalog.dart`
- `.github/workflows/m0-tests.yml`
- `M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_I.md`

## 6. Acceptance

1. Bir slot authoritative M75/M65 state'ten deterministic load-game metadata'ya inspect edilir.
2. Birden fazla slot M77'nin deterministic slot-id sırasını koruyarak summary listesi verir.
3. Overwrite sonrasında catalog ayrı metadata cache/sidecar olmadan yalnız en güncel exact M75 bundle'ı yansıtır.
4. Missing slot `null`, invalid slot ID ise M77 validation contract'ına göre fail-closed davranır.
5. Corrupt slot stale metadata göstermeden M75 validation üzerinden fail-closed olur.
6. Catalog inspect/list işlemleri save bytes'ını mutate etmez.
7. M65/M75/M76/M77 authority sınırı korunur.

## 7. İlk executable CI kanıtı

İlk executable code/workflow HEAD:

`1514f1e20d21e8d9b80b6edab26d6024a0fa3d84`

PR:
- #81 — `M78: interactive decision file save slot catalog`
- branch: `feat/m78-interactive-decision-file-save-slot-catalog`
- bu aşamada DRAFT / OPEN / PRE-MERGE

Workflow run:
- `34903156421`
- run number `497`
- event `pull_request`

`test` job `104173594556`:
- **SUCCESS**
- analyzer: `No issues found!`
- **355/355 tests PASS**
- 5 M78 acceptance testi logda açıkça PASS
- Post Checkout + Complete job SUCCESS

`canonical` job `104173594298`:
- **SUCCESS**
- M0–M78 executable adımlarının tamamı SUCCESS
- exact M78 marker PASS
- Post Checkout + Complete job SUCCESS

Artifacts:
- **0**

Exact marker:

`M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 slots=2 ordered=true metadata=true latestBundle=true nonMutating=true missingNull=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 8. Merge gate

Bu doküman ve devir dosyaları executable CI'dan sonra eklenmiştir. Dolayısıyla docs commit'i PR HEAD'ini ilerletecektir.

M78 henüz CLOSED/PASS değildir.

Merge öncesi zorunlu sıra:
1. docs dahil **final exact PR HEAD** yeniden kilitlenir,
2. aynı exact HEAD için analyzer + 355 test + M0–M78 canonical + exact marker + cleanup + artifacts=0 doğrulanır,
3. PR ready hale getirilir,
4. ready sonrası exact HEAD ve mergeable durumu yeniden okunur,
5. kullanıcıdan **o exact HEAD SHA için açık merge onayı** alınır,
6. yalnız onaylanan exact HEAD `squash` + `expected_head_sha` ile merge edilir,
7. post-merge gerçek `main` executable CI doğrulanmadan M78 CLOSED yazılmaz.

M78 aktifken M79 seçilmez.
