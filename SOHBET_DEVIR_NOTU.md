# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 14 Eylül 2026

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

M76 başlanmadan önce doğrulanan canlı `main` HEAD:

`4a2d1829636392960d68ed8915f00c5c1371bc10`

Commit:
`docs: refresh project summary and handoff state`

Durum:
- **M0–M75 CLOSED / MERGED / PASS**
- **M76 ACTIVE / PRE-MERGE**
- branch: `feat/m76-interactive-decision-application-session`
- PR: **#79 — OPEN / DRAFT**
- M76 henüz `main` üzerinde değildir

Bu dosya PR branch'i içinde güncellendiği için burada yazan branch HEAD'e körü körüne güvenme; PR #79 canlı head SHA'sını yeniden oku.

## 3. Aktif milestone — M76

**M76 — Player President Interactive Decision Application Session I**

Fresh live-main gap scan sonucu:
M75 persistence bundle formatını çözmüş olsa da gerçek application/UI katmanı çalışan session sırasında M65 checkpoint + M74 transcript + M75 resume config'i ayrı ayrı sahiplenip save/load eşlemesini elle yapmak zorundaydı.

M76 çözümü:
`PlayerPresidentInteractiveDecisionApplicationSession`

Application-facing surface:
- `resume(...)`
- `restore(...)`
- `restoreEncoded(...)`
- `advance()`
- `submit(...)`
- `persistenceBundle`
- `encodePersistenceBundle()`
- `pendingDecision`
- `answeredDecisionCount`
- `completed`

Authority değişmedi:
- M65 tek persisted **game-state authority**,
- M74 accepted-answer deterministic replay metadata,
- M75 atomik application persistence bundle,
- M76 yalnız runtime/application lifecycle composition.

Filesystem, Flutter widget/state, Android save-slot backend, database veya cloud-save authority eklenmedi.

M76 ana dosyaları:
- `lib/src/player_president/player_president_interactive_decision_application_session.dart`
- `lib/player_president_interactive_decision_application_session.dart`
- `test/m76_player_president_interactive_decision_application_session_test.dart`
- `tool/run_m76_player_president_interactive_decision_application_session.dart`
- `M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_I.md`
- `.github/workflows/m0-tests.yml`

## 4. Şu ana kadar doğrulanan M76 CI kanıtı

İlk exact code HEAD:
`7711aa26287212e10e329ffa8b750653ecc7db95`

Workflow run:
`34892927092`

`test` job:
- **SUCCESS**
- analyzer: `No issues found!`
- **344/344 tests PASS**
- M76'ya ait 5 acceptance testi PASS
- Post Checkout + Complete job SUCCESS

Bu run sırasında M76 canonical workflow adımı henüz yoktu. Source/test executable doğrulaması alındıktan sonra canonical M76 step'i eklendi ve pre-merge dokümanlar güncellendi.

Final exact-head CI **henüz bu notta PASS olarak yazılmamıştır**. Yeni sohbet/mesaj bunu canlı GitHub'dan doğrulamalıdır.

Beklenen exact M76 marker:
`M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true stableSave=true applicationLifecycle=true atomicBundle=M75 parityM75=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 5. M76 acceptance

1. Aynı checkpoint/config exact aynı ilk pending request'i üretir.
2. Dört cevap sonrası save/restore exact next pending request'e döner ve encoded bytes stabildir.
3. Stale response fail-closed olur ve transcript/save mutasyona uğramaz.
4. Corrupt M75 bundle restoreEncoded sırasında reddedilir.
5. Save→restore→completion uninterrupted session ile exact checkpoint/boundary/decision-count parity verir.
6. M65/M74/M75 authority sınırı korunur.

## 6. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Determinism / replay / parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızıysa gerçek job logu okunmadan patch atılmaz.
- Merge öncesi PR'ın **exact final HEAD'i için kullanıcıdan açık onay** alınır.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- M65 tek persisted game-state authority'dir.
- Mevcut repo saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

## 7. Sıradaki kesin iş

Yeni milestone seçme. PR #79'u tamamla.

Sıra:
1. canlı PR #79 head SHA'yı doğrula,
2. final exact-head `test` job: analyzer + tüm testler SUCCESS olmalı,
3. final exact-head `canonical`: M0–M76 executable adımları SUCCESS olmalı,
4. exact M76 marker PASS okunmalı,
5. Post Checkout / Complete job ve artifacts=0 doğrulanmalı,
6. PR mergeable durumu doğrulanmalı,
7. gerekiyorsa draft'tan ready durumuna geçir,
8. kullanıcıdan **exact final HEAD SHA için açık merge onayı** iste,
9. onay gelmeden merge etme,
10. onay sonrası squash merge + `expected_head_sha`,
11. post-merge gerçek `main` executable CI doğrulanmadan M76 CLOSED yazma.

## 8. Kullanıcı çalışma biçimi

Kullanıcı GitHub işinin gerçekten yapılmasını bekler; yalnız açıklama yeterli değildir. Kısa ara durum güncellemeleri verilebilir. Merge onayı exact HEAD'e özeldir. Kullanıcı “Onaylıyorum” demeden ilgili exact HEAD merge edilmez.
