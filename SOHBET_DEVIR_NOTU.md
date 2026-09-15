# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı tarih için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. Bu dosyayı oku.
4. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Çelişkide **canlı GitHub kazanır**.
6. Aktif milestone varsa onu bitir; fresh scan ile yeni milestone seçme.

## 2. Devredilen durum

**M0–M78 CLOSED / MERGED / PASS.**

**M79 ACTIVE / PRE-MERGE.**

Milestone:
**M79 — Player President Interactive Decision Application New-Game Session I**

Branch:
`feat/m79-interactive-decision-application-new-game-session`

PR:
**#82 — OPEN / DRAFT / PRE-MERGE**

Executable code/workflow HEAD:
`2cc2fa74b40ac8321e7e75b567715517b14f3aa7`

Bu devir/proje/milestone docs commit'i branch HEAD'ini yukarıdaki SHA'dan sonra ilerletecektir; yeni sohbet mutlaka canlı PR HEAD'i yeniden okumalıdır.

## 3. M79 neden seçildi?

Fresh live-main gap scan:
- M73 deterministic sezon-0/new-game interactive session başlatabiliyor,
- M76 application lifecycle yalnız checkpoint-backed `resume/restore` sağlıyordu,
- UI/application yeni oyunu M76 üzerinden sahiplenemiyor, M73'e doğrudan inmek zorunda kalıyordu.

M79 bu application ownership boşluğunu kapatır.

Pre-checkpoint save'i bu milestone çözmez; çünkü M75 M65 checkpoint authority'sine dayanır. Save formatını büyütmeden önce application start yüzeyini tamamlamak daha küçük ve güvenli adımdır.

## 4. M79 çözümü

`PlayerPresidentInteractiveDecisionApplicationSession.start(...)`

eklendi.

Session origin:
- `newGame`
- `checkpoint`

Yeni yüzey:
- `isNewGame`
- `canPersist`
- `checkpointOrNull`
- `newGameElectionInterval`

Pre-checkpoint davranış:
- persistence desteklenmez,
- `canPersist=false`,
- M65 checkpoint yoktur,
- M75 encode isteği fail-closed olur.

New-game tamamlanınca çıkan gerçek checkpoint mevcut M76 checkpoint-backed lifecycle'a aktarılabilir.

Authority:
- M65 tek persisted game-state authority,
- M74 replay transcript metadata,
- M75 application save formatı,
- M76/M79 application lifecycle,
- M77 local file slot store,
- M78 read-only catalog.

## 5. M79 executable CI kanıtı

Workflow run:
`34931609477`

Test job:
- **SUCCESS**
- analyzer `No issues found!`
- **360/360 tests PASS**
- 5 M79 acceptance testi PASS
- cleanup SUCCESS

Canonical timing:
- attempt 1: strict timeout, M79 çalışmadı,
- attempt 2: strict timeout, M79 çalışmadı,
- attempt 3: strict timeout, M79 çalışmadı,
- attempt 4: strict timeout, M79 çalışmadı,
- attempt 5: **SUCCESS**.

Attempt 5 canonical job:
`104291384887`

Kanıt:
- M0–M79 tüm executable adımlar SUCCESS,
- M79 step SUCCESS,
- Post Checkout SUCCESS,
- Complete job SUCCESS.

Exact marker:
`M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_PASS controlled=t1_01 decisions=9 startOwned=true deterministic=true persistenceBlocked=true parityM73=true checkpointHandoff=true saveAuthority=M65 worldClubs=48 seed=20260903`

Artifacts:
**0**

## 6. Acceptance

1. Application start M73 sezon-0 deterministic first request'ini sahiplenir — PASS.
2. New-game application completion raw M73 ile exact parity — PASS.
3. Pre-checkpoint M75 persistence fail-closed — PASS.
4. Tamamlanan new-game checkpoint mevcut M76 lifecycle'a handoff — PASS.
5. New-game validation korunur — PASS.
6. M65/M75/M77 authority sınırı korunur — PASS.

## 7. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki job: `test` + `canonical`.
- Her job strict 7 dakika.
- Artifacts 0.
- Timeout'ta gerçek step/log okunur.
- M79 çalışmadan timeout olan canonical run merge kanıtı değildir; aynı exact HEAD retry edilir.
- Sırf timeout için kod patch'i atılmaz.
- Merge öncesi final exact HEAD kullanıcıya açıkça onaylatılır.
- Merge squash + `expected_head_sha` lock.
- Post-merge gerçek `main` CI bitmeden CLOSED yazılmaz.
- Docs→CI→docs döngüsü yapılmaz.

## 8. Sıradaki kesin iş

PRE-MERGE docs commit'inden sonra:
1. PR #82'nin canlı HEAD'ini yeniden oku; bu yeni **final candidate SHA** olacak.
2. Final exact HEAD CI run'ını bul.
3. Analyzer + **360/360 tests** doğrula.
4. Canonical'ın M79 marker + Post Checkout + Complete job'a ulaştığını doğrula; gerekirse aynı SHA canonical retry.
5. Artifacts=0 doğrula.
6. PR #82'yi Ready for review yap.
7. Ready sonrası PR HEAD'in değişmediğini ve `mergeable=true` olduğunu yeniden doğrula.
8. Kullanıcıdan **bu exact final SHA için açık merge onayı** iste.

Kullanıcı onayı olmadan merge etme.
M79 kapanmadan M80 seçme.
