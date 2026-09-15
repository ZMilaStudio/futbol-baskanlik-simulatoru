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
- CI tam iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job logu okunmadan patch atılmaz.
- Canonical M79'e ulaşmadan timeout olursa aynı exact HEAD retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- Aktif milestone yoksa fresh live-main gap scan yapılmadan sonraki kapsam seçilmez.

## 3. Devir dosyaları

- Kalıcı proje özeti: `GENEL_PROJE_OZETI.md`
- Hızlı devir: `SOHBET_DEVIR_NOTU.md`

Yeni sohbet başlangıcı:
1. canlı `main` HEAD,
2. bu dosya,
3. `SOHBET_DEVIR_NOTU.md`,
4. açık PR/branch/workflow/job/artifact durumu,
5. aktif milestone varsa onu tamamla; yoksa fresh gap scan.

## 4. CANLI DURUM — buradan devam et

**M0–M78 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**M79 ACTIVE / PRE-MERGE.**

M79 adı:
**Player President Interactive Decision Application New-Game Session I**

Branch:
`feat/m79-interactive-decision-application-new-game-session`

PR:
**#82 — OPEN / DRAFT / PRE-MERGE**

M79 executable code/workflow HEAD:
`2cc2fa74b40ac8321e7e75b567715517b14f3aa7`

Bu dosyanın eklendiği PRE-MERGE docs commit'i branch HEAD'ini yukarıdaki SHA'dan sonra ilerletecektir. Sonraki işlem mutlaka canlı PR HEAD'i yeniden okumalıdır.

## 5. Aktif milestone — M79

### M79 — Player President Interactive Decision Application New-Game Session I

Fresh scan sonucu doğrulanan açık:
- M73 sezon 0'dan deterministic interactive new-game session başlatabiliyordu,
- M76 application-session owner yalnız M65 checkpoint-backed `resume/restore` sunuyordu,
- uygulama/UI yeni oyunu application layer üzerinden başlatamıyor ve M73'e doğrudan inmek zorunda kalıyordu.

M79 çözümü:
- `PlayerPresidentInteractiveDecisionApplicationSession.start(...)`
- origin: `newGame` / `checkpoint`
- `isNewGame`
- `canPersist`
- `checkpointOrNull`
- `newGameElectionInterval`

Pre-checkpoint persistence bu milestone'da özellikle **eklenmedi**:
- `canPersist == false`,
- `checkpointOrNull == null`,
- M75 persistence isteği fail-closed,
- tamamlanan new-game sonucu mevcut M65 checkpoint-backed M76 lifecycle'a handoff olur.

Authority değişmedi:
- M65 tek persisted game-state authority,
- M74 replay transcript metadata,
- M75 atomik application save formatı,
- M76/M79 application lifecycle,
- M77 exact M75 bytes file-slot storage,
- M78 read-only load-game catalog.

M79 yeni save codec, ikinci authority, M75/M77 format değişikliği, metadata sidecar, database, cloud sync veya Flutter/provider state eklemez.

Ana dosyalar:
- `lib/src/application/player_president_interactive_decision_application_session.dart`
- `test/m79_player_president_interactive_decision_application_new_game_session_test.dart`
- `tool/run_m79_player_president_interactive_decision_application_new_game_session.dart`
- `.github/workflows/m0-tests.yml`
- `M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_I.md`

## 6. M79 acceptance

1. Application start M73 new-game ilk request'ini deterministic sahiplenir — PASS.
2. Application new-game completion raw M73 ile exact parity verir — PASS.
3. Pre-checkpoint M75 persistence fail-closed — PASS.
4. Completed new-game checkpoint mevcut M76 lifecycle'a handoff olur — PASS.
5. New-game input validation korunur — PASS.
6. M65/M75/M77 authority sınırı korunur — PASS.

## 7. İlk executable M79 CI kanıtı

PR run:
- `34931609477`
- event `pull_request`
- code/workflow HEAD `2cc2fa74b40ac8321e7e75b567715517b14f3aa7`

Test:
- analyzer `No issues found!`
- **360/360 tests PASS**
- 5 M79 acceptance testi PASS
- test job SUCCESS

Canonical:
- ilk dört attempt strict 7 dakika nedeniyle M79'e ulaşmadan M70–M72 civarında kesildi ve merge kanıtı sayılmadı,
- attempt 5 job `104291384887` **SUCCESS**,
- canonical **M0–M79 tüm executable adımları SUCCESS**,
- exact M79 marker PASS,
- Post Checkout + Complete job SUCCESS.

Artifacts:
- **0**

Exact M79 marker:
`M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_PASS controlled=t1_01 decisions=9 startOwned=true deterministic=true persistenceBlocked=true parityM73=true checkpointHandoff=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 8. Yakın milestone zinciri

- M79 — Application New-Game Session — PR #82 — ACTIVE / PRE-MERGE — 360 tests.
- M78 — File Save Slot Catalog — PR #81 — merge `cb9334341e42a8dacf629f4aa25f123b8a6f7160` — 355 tests.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0` — 350 tests.
- M76 — Interactive Decision Application Session — PR #79 — merge `3fdc084a988050b179892ebdc5818c9d032720a0` — 344 tests.
- M75 — Persistence Bundle — PR #78 — merge `c88d65f6c06769fa2298d92bc791f76a0ebf5bed` — 339 tests.
- M74 — Transcript Snapshot — PR #77 — merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c` — 334 tests.
- M73 — Interactive Decision Session — PR #76 — merge `a82caf70f832c20e2da2929bcaddd26aad85b618` — 329 tests.
- M72 — Unified Decision Gateway — PR #75 — merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c` — 324 tests.
- M71 ve öncesi — CLOSED / MERGED / PASS.

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
- M75: M65 + M74 + resume config atomik persistence bundle.
- M76: checkpoint-backed application-session lifecycle.
- M77: exact M75 bytes local file save-slot store.
- M78: authoritative save-slot load-game catalog projection.
- M79: application-owned deterministic season-0 new-game session; pre-checkpoint persistence bilinçli olarak kapalı.

## 10. Sıradaki kesin iş

M79 docs commit'inden sonra:
1. PR #82 live final HEAD'i yeniden oku ve kilitle,
2. **o exact HEAD** için analyzer + 360 tests + canonical M0–M79 + exact marker + cleanup + artifacts=0 doğrula,
3. M79'e ulaşmayan canonical timeout'larında aynı SHA retry et,
4. PR'ı Ready for review yap,
5. ready sonrası HEAD/mergeable durumunu yeniden doğrula,
6. kullanıcıdan **exact final SHA için açık merge onayı** iste.

Onay olmadan merge etme.
M79 kapanmadan M80 seçme.
