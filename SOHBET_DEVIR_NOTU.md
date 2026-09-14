# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosyanın amacı yeni bir ChatGPT sohbeti açıldığında **nerede kaldığımızı, hangi kanıtların doğrulandığını ve sıradaki adımın ne olduğunu** hızlıca devretmektir. Ayrıntılı proje tarihi ve milestone zinciri için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

Yeni sohbet şu sırayla başlamalıdır:

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` dosyasını oku.
3. Bu `SOHBET_DEVIR_NOTU.md` dosyasını oku.
4. Branch / PR / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Canlı GitHub ile bu dosyalar çelişirse **canlı GitHub kazanır**.
6. Aktif milestone/PR varsa yeni milestone seçmeden onu tamamla.

## 2. Devredilen canlı durum

M78 başlanmadan önce doğrulanan canlı `main` HEAD:

`952bc9768629195d5d19ab7559170915f080ec31`

Durum:
- **M0–M77 CLOSED / MERGED / PASS**
- **M78 ACTIVE / PRE-MERGE**
- branch: `feat/m78-interactive-decision-file-save-slot-catalog`
- PR: **#81 — OPEN / DRAFT**
- M78 henüz `main` üzerinde değildir

Bu dosya PR branch'i içinde güncellendiği için burada yazan branch HEAD'e körü körüne güvenme; PR #81 canlı head SHA'sını yeniden oku.

## 3. Aktif milestone — M78

**M78 — Player President Interactive Decision File Save Slot Catalog I**

Fresh live-main gap scan sonucu:
- M77 exact M75 bytes'ını gerçek local file slot'larında save/load/list edebiliyor,
- fakat load-game/application katmanına yalnız ham slot ID listesi veriyordu,
- kulüp adı, sezon, answered decision count, player-control state ve pending decision gibi load-game özetleri için M75/M65 object graph'ının elle açılması gerekiyordu,
- deterministic read-only catalog/summary surface'i yoktu.

M78 çözümü:

`PlayerPresidentInteractiveDecisionFileSaveSlotCatalog`

Surface:
- `inspect(slotId)`
- `list()`

Summary:
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

Catalog davranışı:
- summary M77 `load()` ile exact M75 bundle restore edilerek türetilir,
- ayrı metadata sidecar yoktur,
- filesystem timestamp authority yoktur,
- deterministic order M77 `listSlotIds()` sırasını korur,
- overwrite sonrasında yalnız en yeni authoritative M75 bundle yansıtılır,
- missing slot `null`, invalid slot ID M77 validation contract'ı ile reddedilir,
- corrupt/divergent slot stale metadata göstermeden M75/M74 restore validation üzerinden fail-closed olur,
- inspect/list save bytes'ını mutate etmez.

Authority değişmedi:
- M65 tek persisted **game-state authority**,
- M74 accepted-answer deterministic replay metadata,
- M75 atomik application persistence bundle/save format,
- M76 interactive application-session lifecycle owner,
- M77 local filesystem storage adapter,
- M78 yalnız read-only load-game projection.

Flutter/provider state, Android platform channel, database, cloud sync veya yeni game-state/save authority eklenmedi.

Fresh scan'de M73'ün sezon 0'dan `start`, M76/M75'in ise checkpoint-backed olduğu da doğrulandı. Pre-checkpoint/new-game persistence gerçek ama daha büyük bir açık; M65 checkpoint dışı persistence representation gerektirdiğinden M78 kapsamına alınmadı.

M78 ana dosyaları:
- `lib/src/player_president/player_president_interactive_decision_file_save_slot_catalog.dart`
- `lib/player_president_interactive_decision_file_save_slot_catalog.dart`
- `test/m78_player_president_interactive_decision_file_save_slot_catalog_test.dart`
- `tool/run_m78_player_president_interactive_decision_file_save_slot_catalog.dart`
- `M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_I.md`
- `.github/workflows/m0-tests.yml`

## 4. Şu ana kadar doğrulanan M78 CI kanıtı

İlk executable code/workflow HEAD:

`1514f1e20d21e8d9b80b6edab26d6024a0fa3d84`

Workflow run:
`34903156421`

`test` job `104173594556`:
- **SUCCESS**
- analyzer: `No issues found!`
- **355/355 tests PASS**
- M78'nin 5 acceptance testi logda açıkça PASS
- Post Checkout + Complete job SUCCESS

`canonical` job `104173594298`:
- **SUCCESS**
- M0–M78 executable adımlarının tamamı SUCCESS
- exact M78 marker PASS
- Post Checkout + Complete job SUCCESS

Artifacts:
- **0**

Exact M78 marker:

`M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 slots=2 ordered=true metadata=true latestBundle=true nonMutating=true missingNull=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

Bu run ilk executable source/test/canonical kanıtıdır. Ardından milestone dokümanı + proje özeti + bu devir notu eklendi/güncellendi. Bu yüzden **docs dahil final exact-head CI ayrıca canlı GitHub'dan doğrulanmalıdır**.

## 5. M78 acceptance

1. Slot authoritative M75/M65 state'ten deterministic load-game metadata'ya inspect edilir — ilk CI PASS.
2. Summary listesi deterministic slot-id sırasını korur — ilk CI PASS.
3. Overwrite sonrası yalnız en güncel exact M75 bundle yansıtılır; metadata sidecar üretilmez — ilk CI PASS.
4. Missing/invalid slot M77 contract'ını korur — ilk CI PASS.
5. Corrupt slot stale metadata üretmeden fail-closed olur — ilk CI PASS.
6. Catalog save bytes'ını mutate etmez — ilk CI PASS.
7. M65/M75/M76/M77 authority sınırı korunur — ilk CI PASS.

## 6. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Determinism / replay / parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job logu okunmadan patch atılmaz.
- Merge öncesi PR'ın **exact final HEAD'i için kullanıcıdan açık onay** alınır.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- M65 tek persisted game-state authority'dir.
- M75 atomik application save formatıdır.
- M77 exact M75 bytes'ını file slot'a materialize eder.
- M78 yalnız read-only catalog projection'dır; save formatının yerine geçmez.
- Mevcut repo saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

## 7. Sıradaki kesin iş

M79 seçme. PR #81'i tamamla.

Sıra:
1. docs commit'i sonrası canlı PR #81 exact head SHA'yı doğrula,
2. docs dahil final exact-head `test` job: analyzer + **355/355 test** SUCCESS olmalı,
3. M78'nin 5 acceptance testi final exact-head logunda PASS olmalı,
4. final exact-head `canonical`: M0–M78 executable adımları SUCCESS olmalı,
5. exact M78 marker PASS okunmalı,
6. Post Checkout / Complete job ve artifacts=0 doğrulanmalı,
7. strict 7 dakika nedeniyle outer canonical cancelled olursa gerçek log okunmalı; M78 + cleanup önceden SUCCESS ise timeout-only kabul edilebilir; M78'ye ulaşılmadıysa aynı exact HEAD'de canonical retry yapılmalı,
8. PR mergeable durumu doğrulanmalı,
9. draft'tan ready durumuna geçirilmeli,
10. ready sonrası exact final HEAD tekrar kilitlenmeli,
11. kullanıcıdan **exact final HEAD SHA için açık merge onayı** istenmeli,
12. onay gelmeden merge edilmemeli,
13. onay sonrası squash merge + `expected_head_sha`,
14. post-merge gerçek `main` executable CI doğrulanmadan M78 CLOSED yazılmamalı.

## 8. Kullanıcı çalışma biçimi

Kullanıcı GitHub işinin gerçekten yapılmasını bekler; yalnız açıklama yeterli değildir. Kısa ara durum güncellemeleri verilebilir. Merge onayı exact HEAD'e özeldir. Kullanıcı “Onaylıyorum” demeden ilgili exact HEAD merge edilmez.
