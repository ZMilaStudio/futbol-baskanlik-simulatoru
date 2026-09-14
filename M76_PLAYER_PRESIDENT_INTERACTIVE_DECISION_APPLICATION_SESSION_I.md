# M76 — Player President Interactive Decision Application Session I

Durum: **PRE-MERGE / FINAL CI BEKLİYOR**

Tarih: 14 Eylül 2026

## 1. Fresh live-main gap scan

M75, checkpoint-backed interaktif başkanlık oturumunun persistence formatını güvenli biçimde çözdü: M65 authoritative game-state save + M74 accepted-answer transcript + minimal M73 resume config tek atomik bundle içinde eşleniyor.

Ancak gerçek application/UI katmanı bir oturumu sürerken hâlâ şu parçaları kendisi ayrı ayrı yönetmek zorundaydı:

1. M65 başlangıç checkpoint'i,
2. çalışan M74 transcript session,
3. M75 resume config,
4. save anında bunlardan M75 bundle üretme,
5. load anında M75 bundle'dan session restore etme.

Bu, persistence formatı doğru olsa bile application lifecycle için gereksiz eşleme sorumluluğu bırakıyordu.

## 2. Çözüm

M76 yeni bir domain veya persistence authority yaratmadan tek application-facing lifecycle owner ekler:

`PlayerPresidentInteractiveDecisionApplicationSession`

Sağlanan application surface:

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

Bu controller checkpoint-backed M73 session'ını M74 transcript wrapper ile birlikte sahiplenir ve save/load için M75 bundle codec'ini kullanır.

## 3. Authority sınırı

M76 **yeni game-state veya save authority değildir**.

Authority zinciri değişmez:

- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted game-state authority'dir.
- M74 accepted-answer transcript yalnız deterministic replay metadata'sıdır.
- M75 atomik application persistence bundle formatıdır.
- M76 yalnız runtime/application lifecycle composition katmanıdır.
- Pending request ayrıca persist edilmez; M73 tarafından deterministic yeniden türetilir.
- Filesystem, Android save-slot backend, database, cloud save veya Flutter widget/state authority eklenmez.

## 4. Acceptance

1. Aynı M65 checkpoint + config iki bağımsız application session'da exact aynı ilk pending request'i üretir.
2. Dört cevap sonrası `encodePersistenceBundle()` ile alınan save, `restoreEncoded()` sonrasında exact aynı next pending request'e döner ve encode bytes değişmez.
3. Stale response reddedilir ve accepted transcript/persisted bundle mutasyona uğramaz.
4. Corrupt M75 bundle `restoreEncoded()` sırasında fail-closed olur.
5. Save → restore → completion sonucu uninterrupted application session ile exact checkpoint + boundary + decision-count parity verir.
6. M65/M74/M75 authority sınırı korunur; M76 yalnız application lifecycle owner'dır.

## 5. Dosyalar

- `lib/src/player_president/player_president_interactive_decision_application_session.dart`
- `lib/player_president_interactive_decision_application_session.dart`
- `test/m76_player_president_interactive_decision_application_session_test.dart`
- `tool/run_m76_player_president_interactive_decision_application_session.dart`
- `M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_I.md`
- `.github/workflows/m0-tests.yml`

## 6. Canonical marker

`M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true stableSave=true applicationLifecycle=true atomicBundle=M75 parityM75=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 7. İlk executable CI kanıtı

Exact code HEAD:
`7711aa26287212e10e329ffa8b750653ecc7db95`

PR:
`#79 — M76: interactive decision application session`

Workflow run:
`34892927092`

`test` job:
- **SUCCESS**
- Dart analyzer: `No issues found!`
- **344/344 tests PASS**
- M76'ya ait 5 acceptance testi ayrı ayrı PASS
- Post Checkout + Complete job SUCCESS

Bu ilk run sırasında workflow henüz M76 canonical adımını içermiyordu; amaç executable source + acceptance testlerinin compile/test kanıtını almaktı.

M76 canonical workflow adımı bu kanıttan sonra eklendi. Merge-ready final HEAD için yeni exact-head CI ayrıca doğrulanacaktır.

## 8. Merge kuralı

M76 merge edilmeden önce:

1. final docs/workflow commit'leri sonrası exact PR HEAD doğrulanmalı,
2. o exact HEAD'in `test` job'ı analyzer + tüm testleri PASS etmeli,
3. canonical job M0–M76 executable adımlarını SUCCESS tamamlamalı ve exact M76 marker PASS görülmeli,
4. artifacts 0 doğrulanmalı,
5. PR mergeable olmalı,
6. kullanıcıdan o exact HEAD için açık merge onayı alınmalı,
7. squash merge `expected_head_sha` kilidiyle yapılmalı,
8. post-merge gerçek `main` executable CI doğrulanmadan M76 CLOSED sayılmamalıdır.
