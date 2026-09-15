# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 15 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo hâlâ saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

Canonical dünya:
- seed `20260903`
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 864 başlangıç oyuncusu

## 2. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Deterministic seed / replay / save-resume parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job logu okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan timeout olursa aynı exact HEAD retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- Aktif milestone varsa fresh scan ile başka milestone seçilmez.

## 3. CANLI DURUM — buradan devam et

**M0–M80 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**M81 ACTIVE / PRE-MERGE.**

M81 adı:
**Player President Interactive Decision New-Game Bootstrap File Save Slot Store I**

Branch:
`feat/m81-new-game-bootstrap-file-save-slot-store`

PR:
**#84 — OPEN / DRAFT / PRE-MERGE**

M81 ilk executable HEAD:
`b59bf5c23ce7a1b73683068a9aebcf32d395edb8`

İlk executable PR run:
`34974945110`

Bu PRE-MERGE doküman commit'i branch HEAD'ini yukarıdaki SHA'dan sonra ilerletecektir. Merge adımına geçmeden önce canlı PR HEAD yeniden okunmalı ve **o exact final SHA** için CI yeniden doğrulanmalıdır.

## 4. M81 neden seçildi?

Fresh live-main gap scan sonucu:
- M80 pre-checkpoint new-game ilerlemesini versioned/checksummed replay-only bootstrap + M74 transcript olarak encode edebiliyor,
- M77 file save-slot store yalnız M75 checkpoint bundle saklıyor,
- bu nedenle M80 bootstrap bytes için dayanıklı yerel disk persistence yüzeyi eksikti.

En küçük authority-safe çözüm M77'yi dual-format hale getirmek yerine ayrı bir bootstrap file adapter eklemektir.

## 5. M81 çözümü

Yeni adapter:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore`

Özellikler:
- exact M80 bootstrap envelope bytes saklar,
- ayrı `.fbs.bootstrap.json` namespace kullanır,
- M77 `.fbs.json` checkpoint slotlarını değiştirmez,
- atomic temp → target replacement ve committed backup recovery uygular,
- M77 ile aynı slot-ID path traversal sınırını kullanır,
- load sırasında M80 checksum/format validation ve world fingerprint guard aynen çalışır,
- checkpoint-backed application session bootstrap slotuna yazılmadan önce fail-closed olur; disk mutation oluşmaz,
- `listSlotIds`, `contains`, `delete` yalnız bootstrap namespace'ini görür.

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik application bundle.
- M77 M75-only checkpoint file-slot store.
- M78 M75-backed read-only checkpoint catalog.
- M80 pre-checkpoint replay-only bootstrap snapshot.
- M81 yalnız exact M80 bytes file adapter; ikinci game-state authority değildir.

M81 non-scope:
- M77 formatını dual-format envelope'a çevirmek,
- M78 catalog'a bootstrap metadata eklemek,
- checkpoint + bootstrap slotlarını tek load-game catalog altında birleştirmek,
- timestamp/nondeterministic metadata,
- database/cloud/Flutter/provider state.

Ana M81 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart`
- `lib/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart`
- `test/m81_player_president_interactive_decision_new_game_bootstrap_file_save_slot_store_test.dart`
- `tool/run_m81_player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart`
- `.github/workflows/m0-tests.yml`
- `M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_I.md`

## 6. M81 acceptance — ilk executable kanıt

1. Fresh store exact pending request + stable M80 bytes restore eder — PASS.
2. Aynı slot overwrite yalnız latest M80 bootstrap'ı bırakır — PASS.
3. Invalid slot ID ve checkpoint-backed session write fail-closed; disk mutation yok — PASS.
4. Interrupted replacement committed backup'tan recover edilir — PASS.
5. Corrupted bytes ve divergent supplied world fail-closed olur — PASS.
6. Bootstrap list/delete/contains M77 checkpoint namespace'inden izole kalır — PASS.

## 7. İlk executable M81 CI kanıtı

Exact executable HEAD:
`b59bf5c23ce7a1b73683068a9aebcf32d395edb8`

PR workflow run:
`34974945110`

Test job:
- analyzer: `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- Post Checkout + Complete job SUCCESS
- job SUCCESS

Canonical:
- **M0–M81 tüm executable adımlar SUCCESS**
- M81 step SUCCESS
- exact M81 marker PASS
- Post Checkout + Complete job SUCCESS
- job SUCCESS

Artifacts:
- **0**

Exact M81 marker:
`M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true stableSave=true interruptedRecovery=true invalidBlocked=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 worldClubs=48 seed=20260903`

## 8. Yakın milestone zinciri

- M81 — Bootstrap File Save Slot Store — PR #84 — ACTIVE / PRE-MERGE — 372 tests.
- M80 — New-Game Bootstrap Snapshot — PR #83 — merge `44dbc898de57307050f4f26525886af32c999b51` — 366 tests.
- M79 — Application New-Game Session — PR #82 — merge `1f75d9e7e363d17e429af77a7aa28c21a04e06ae` — 360 tests.
- M78 — File Save Slot Catalog — PR #81 — merge `cb9334341e42a8dacf629f4aa25f123b8a6f7160` — 355 tests.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0` — 350 tests.
- M76 ve öncesi — CLOSED / MERGED / PASS.

## 9. Sistem mimarisi — kısa harita

- M0–M18: temel sezon/kariyer/world/başkanlık sistemleri.
- M19–M24: başkan trait feedback.
- M25–M32: save/load ve runtime snapshots.
- M33–M48: facility/academy/stadium/sponsor/crisis runtime.
- M49–M65: player-president kontrolleri + tenure gate; M65 persisted state authority.
- M66–M71: tüm player-president domain composition.
- M72: tek application decision gateway.
- M73: pending request → response → continue interactive runtime.
- M74: accepted-answer transcript replay metadata.
- M75: M65 + M74 + resume config atomik checkpoint persistence bundle.
- M76: checkpoint-backed application-session lifecycle.
- M77: exact M75 bytes local checkpoint file-slot store.
- M78: authoritative M75-backed checkpoint load-game catalog.
- M79: application-owned deterministic season-0 new-game session.
- M80: pre-checkpoint bootstrap + M74 transcript replay snapshot.
- M81: exact M80 bootstrap bytes için ayrı atomic local file-slot store.

## 10. Sıradaki kesin iş

1. Bu PRE-MERGE docs commit'inden sonra PR #84 canlı final HEAD'ini yeniden oku.
2. Yeni exact HEAD için analyzer + **372 tests** + 6 M81 acceptance doğrula.
3. Canonical M0–M81 + exact M81 marker + cleanup doğrula; timing timeout olursa aynı exact SHA canonical job'u retry et.
4. Artifacts=0 doğrula.
5. PR #84'ü Ready for review yap.
6. Ready sonrası HEAD'in değişmediğini ve `mergeable=true` olduğunu yeniden doğrula.
7. Kullanıcıdan **bu exact final SHA için açık merge onayı** iste.

Onay olmadan merge etme.
M81 kapanmadan M82 seçme.
