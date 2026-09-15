# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı tarih için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. Bu dosyayı oku.
4. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Çelişkide **canlı GitHub kazanır**.
6. Aktif milestone varsa onu bitir; yoksa fresh live-main gap scan yap.

## 2. Devredilen durum

**M0–M81 CLOSED / MERGED / PASS.**

**M82 ACTIVE / PRE-MERGE.**

M82:
**Player President Interactive Decision New-Game Bootstrap File Save Slot Catalog I**

PR:
**#85 — OPEN / DRAFT / PRE-MERGE**

Branch:
`feat/m82-new-game-bootstrap-file-save-slot-catalog`

Executable parent code HEAD:
`9ae3a13afd017022baca6e76cda56e6e14b56de1`

Base `main`:
`e1d90a20702a9bcfcc46aae3e9d779121cfa297e`

Bu PRE-MERGE docs commit'i branch HEAD'ini ilerletir. Merge onayı yalnız docs-included final candidate exact SHA için alınmalıdır.

## 3. M82 çözümü

Yeni catalog:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog`

Davranış:
- M81 bootstrap slotunu exact load eder,
- M80 checksum/format/world fingerprint guard'ını aynen kullanır,
- M74 replay/application session sonucundan deterministic read-only summary üretir,
- metadata sidecar yazmaz,
- slot bytes'ını değiştirmez,
- list deterministic slot-id order kullanır,
- overwrite sonrası latest bootstrap state'ini gösterir,
- corrupt bytes ve divergent world fail-closed olur,
- M77 `.fbs.json` checkpoint namespace'inden izole kalır.

Summary alanları en az:
- slotId,
- controlledClubId / controlledClubName,
- careerSeed,
- answeredDecisionCount,
- pendingDecisionKind,
- resumeSeasonCount,
- electionInterval.

Authority değişmedi:
- **M65 tek persisted game-state authority**,
- M74 replay metadata,
- M75 checkpoint-backed bundle,
- M77 M75-only checkpoint file store,
- M78 checkpoint catalog,
- M80 replay-only bootstrap snapshot,
- M81 exact M80 bytes file store,
- M82 yalnız read-only bootstrap catalog/projection.

## 4. M82 acceptance

Executable parent exact SHA `9ae3a13afd017022baca6e76cda56e6e14b56de1` üzerinde:

1. Bootstrap slot deterministic summary + read-only bytes — PASS.
2. Deterministic list order + overwrite latest state — PASS.
3. Missing/invalid slot M81 contract parity — PASS.
4. Corrupt bytes + divergent world fail-closed — PASS.
5. M77 checkpoint namespace isolation — PASS.

## 5. M82 executable PRE-MERGE kanıtı

PR workflow run:
`34990552222`

- analyzer `No issues found!`
- **377/377 tests PASS**
- **5/5 M82 acceptance PASS**
- test cleanup SUCCESS
- canonical timing-only timeout denemelerinde target M82 çalışmadığı için PASS sayılmadı
- aynı exact SHA üzerinde kod patch'i olmadan retry edildi
- başarılı canonical job: `104504219474`
- **M0–M82 SUCCESS**
- M82 step SUCCESS
- exact M82 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

Exact marker:
`M82_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 summaries=2 primaryAnswers=4 deterministicOrder=true readOnly=true metadataExact=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 store=M81 worldClubs=48 seed=20260903`

## 6. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki job: `test` + `canonical`.
- Her job strict 7 dakika.
- Artifacts hedefi 0.
- Timeout'ta gerçek step/log okunur.
- Hedef milestone çalışmadan timeout olan canonical run kapanış kanıtı değildir; aynı exact SHA retry edilir.
- Sırf timeout için kod patch'i atılmaz.
- Merge öncesi final exact HEAD kullanıcıya açıkça onaylatılır.
- Merge squash + `expected_head_sha` lock.
- Post-merge gerçek `main` CI bitmeden CLOSED yazılmaz.
- Closure docs tek atomik commit; docs→CI→docs döngüsü yapılmaz.

## 7. Sıradaki kesin iş

1. PRE-MERGE docs commit'inden sonra oluşan docs-included final PR HEAD'i canlı oku.
2. O exact SHA için analyzer + 377/377 + 5/5 M82 + canonical M0–M82 + marker + artifacts 0 doğrula; timing-only canonical timeout olursa exact aynı SHA retry et.
3. PR #85'i Ready yap.
4. Ready sonrası head/base/open/draft/mergeable state'i yeniden doğrula.
5. Kullanıcıdan **exact final SHA** için açık squash-merge onayı iste.
6. Onay gelmeden merge yapma.

**M82 kapanmadan M83 seçme.**
