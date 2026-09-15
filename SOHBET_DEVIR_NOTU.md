# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı tarih için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. Bu dosyayı oku.
4. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Çelişkide **canlı GitHub kazanır**.
6. Aktif milestone varsa onu bitir; başka milestone seçme.

## 2. Devredilen durum

**M0–M80 CLOSED / MERGED / PASS.**

**M81 ACTIVE / PRE-MERGE.**

Milestone:
**M81 — Player President Interactive Decision New-Game Bootstrap File Save Slot Store I**

Branch:
`feat/m81-new-game-bootstrap-file-save-slot-store`

PR:
**#84 — OPEN / DRAFT / PRE-MERGE**

İlk executable HEAD:
`b59bf5c23ce7a1b73683068a9aebcf32d395edb8`

İlk executable CI run:
`34974945110`

Bu PRE-MERGE docs commit'i branch HEAD'ini yukarıdaki SHA'dan sonra ilerletecektir. Sonraki işlem mutlaka canlı PR HEAD'i yeniden okumalı ve o exact SHA'yı yeniden doğrulamalıdır.

## 3. M81 neden seçildi?

Fresh live-main gap scan:
- M80 pre-checkpoint new-game ilerlemesini replay-only bootstrap + M74 transcript olarak encode ediyor,
- M77 yalnız M75 checkpoint bundle için disk slotu sağlıyor,
- dolayısıyla M80 bootstrap bytes'ı için durable local file-slot persistence eksikti.

M81, M77'yi dual-format hale getirmeden ayrı bootstrap namespace ile bu açığı kapatır.

## 4. M81 çözümü

Yeni adapter:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore`

Davranış:
- exact M80 bytes saklar,
- `.fbs.bootstrap.json` namespace kullanır,
- temp/backup ile atomic replacement ve interrupted recovery sağlar,
- invalid slot ID'leri fail-closed reddeder,
- checkpoint-backed session'ı disk mutation öncesi reddeder,
- load sırasında M80 checksum + world fingerprint guard'ı çalıştırır,
- list/contains/delete M77 `.fbs.json` checkpoint slotlarından izoledir.

Authority değişmedi:
- **M65 tek persisted game-state authority**,
- M74 replay metadata,
- M75 checkpoint-backed bundle,
- M77 M75-only checkpoint file store,
- M78 checkpoint catalog,
- M80 replay-only bootstrap snapshot,
- M81 yalnız M80 bytes file adapter.

Non-scope:
- M77 formatını dual-format yapmak,
- M78'e bootstrap metadata eklemek,
- birleşik load-game catalog,
- timestamp/nondeterministic metadata,
- database/cloud/Flutter/provider state.

## 5. İlk executable M81 CI kanıtı

Exact HEAD:
`b59bf5c23ce7a1b73683068a9aebcf32d395edb8`

Workflow run:
`34974945110`

Test job:
- **SUCCESS**
- analyzer `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- Post Checkout + Complete job SUCCESS

Canonical job:
- **SUCCESS**
- M0–M81 tüm executable adımlar SUCCESS
- M81 step SUCCESS
- exact M81 marker PASS
- Post Checkout + Complete job SUCCESS

Artifacts:
**0**

Exact marker:
`M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true stableSave=true interruptedRecovery=true invalidBlocked=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 worldClubs=48 seed=20260903`

## 6. Acceptance

1. Fresh store exact pending request + stable M80 bytes restore eder — PASS.
2. Overwrite yalnız latest M80 bootstrap'ı bırakır — PASS.
3. Invalid IDs + checkpoint-backed session write fail-closed ve disk mutation yok — PASS.
4. Interrupted replacement committed backup'tan recover edilir — PASS.
5. Corrupt bytes + divergent supplied world fail-closed — PASS.
6. Bootstrap slot operations M77 checkpoint namespace'inden izoledir — PASS.

## 7. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki job: `test` + `canonical`.
- Her job strict 7 dakika.
- Artifacts 0.
- Timeout'ta gerçek step/log okunur.
- Hedef milestone çalışmadan timeout olan canonical run merge kanıtı değildir; aynı exact HEAD retry edilir.
- Sırf timeout için kod patch'i atılmaz.
- Merge öncesi final exact HEAD kullanıcıya açıkça onaylatılır.
- Merge squash + `expected_head_sha` lock.
- Post-merge gerçek `main` CI bitmeden CLOSED yazılmaz.
- Docs→CI→docs döngüsü yapılmaz.

## 8. Sıradaki kesin iş

1. PRE-MERGE docs commit'inden sonra PR #84 canlı final HEAD'ini yeniden oku.
2. Yeni exact HEAD CI run'ını bul.
3. Analyzer + **372/372 tests** + 6 M81 acceptance doğrula.
4. Canonical M0–M81 + exact marker + cleanup doğrula; gerekirse aynı SHA canonical retry.
5. Artifacts=0 doğrula.
6. PR #84'ü Ready for review yap.
7. Ready sonrası HEAD değişmedi + `mergeable=true` doğrula.
8. Kullanıcıdan **bu exact final SHA için açık merge onayı** iste.

Kullanıcı onayı olmadan merge etme.
M81 kapanmadan M82 seçme.
