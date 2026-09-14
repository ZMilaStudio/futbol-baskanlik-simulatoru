# M75 — Player President Interactive Decision Persistence Bundle I

Durum: **PRE-MERGE / MERGE-READY ADAYI**

Tarih: 14 Eylül 2026

## 1. Neden gerekliydi?

M73, gerçek application/UI katmanı için deterministic `pause → pending request → response → continue` session sınırını kurdu. M74 ise kabul edilmiş cevap transcript'ini versioned/checksummed bir sidecar olarak persist etti.

Ancak M74 sidecar tek başına restore için yeterli değildi. Application katmanı hâlâ şu üç parçayı doğru biçimde kendisi eşlemek zorundaydı:

1. authoritative M65 game-state save/checkpoint,
2. M74 accepted-answer transcript sidecar,
3. M73 resume sırasında gereken küçük deterministic runtime parametreleri.

Bu parçalar ayrı ayrı save slot'a yazılırsa yanlış checkpoint + transcript eşleşmesi veya eksik resume parametresi gerçek UI/application lifecycle'ında restore hatasına yol açabilirdi.

## 2. Çözüm

M75 yeni bir game-state authority yaratmadan bu üç parçayı tek application-save unit altında atomik olarak eşler.

Eklenen ana tipler:

- `PlayerPresidentInteractiveDecisionResumeConfig`
- `PlayerPresidentInteractiveDecisionPersistenceBundle`
- `PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec`

Bundle içeriği:

- `PlayerPresidentTicketPricingRuntimeCheckpoint` — authoritative M65 game state,
- `PlayerPresidentInteractiveDecisionTranscriptSnapshot` — M74 replay metadata,
- M73 resume için `seasonCount`, `hasFutureSeasonAfterReport`, `crisisActivationThreshold`, `candidateLimit`.

Codec davranışı:

- outer format versioned/checksummed canonical JSON'dur;
- nested M65 game-state save mevcut `PlayerPresidentTicketPricingRuntimeSaveCodec` ile encode/decode edilir;
- nested M74 transcript mevcut `PlayerPresidentInteractiveDecisionTranscriptSaveCodec` ile encode/decode edilir;
- böylece outer checksum yanında her nested save kendi version/checksum doğrulamasını da korur;
- malformed JSON, yanlış envelope, unsupported version, checksum mismatch ve invalid payload fail-closed olur.

Restore davranışı:

- bundle M65 checkpoint'ten `PlayerPresidentInteractiveDecisionSession.resume(...)` kurar;
- M74 transcript `PlayerPresidentInteractiveDecisionTranscriptSession.restore(...)` üzerinden deterministic replay edilir;
- stale/divergent transcript, M74'ün exact request-key eşleşmesi sayesinde restore sırasında reddedilir;
- pending request save içine yazılmaz; M73 tarafından deterministic yeniden türetilir.

## 3. Authority sınırı

M75 **yeni persisted game-state şeması değildir**.

Persistence authority değişmez:

- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted game-state authority olmaya devam eder.
- M74 transcript yalnız accepted-answer replay metadata'sıdır.
- M75 yalnız bu iki mevcut formatı ve minimal deterministic resume config'i tek outer envelope içinde eşler.
- Flutter/UI, filesystem, Android save-slot backend, cloud save veya database katmanı eklenmez.

## 4. Acceptance

1. Canonical bundle encode/decode round-trip exact nested M65 save ve M74 transcript'i korur — **PASS**.
2. Partial in-progress bundle restore exact pending request'i yeniden üretir ve completion sonunda uninterrupted M74 ile exact checkpoint/boundary parity verir — **PASS**.
3. Outer checksum yeniden hesaplanmış olsa bile başka M65 checkpoint ile eşleştirilmiş stale transcript restore sırasında fail-closed olur — **PASS**.
4. Outer envelope corruption nested restore başlamadan checksum mismatch ile reddedilir — **PASS**.
5. Outer checksum geçerli olsa bile bozuk nested M65 save kendi nested validation/checksum yolunda reddedilir — **PASS**.
6. M65 persisted game-state authority korunur; M75 yalnız application persistence envelope'dur — **PASS**.

## 5. Dosyalar

- `lib/src/player_president/player_president_interactive_decision_persistence_bundle.dart`
- `lib/player_president_interactive_decision_persistence_bundle.dart`
- `test/m75_player_president_interactive_decision_persistence_bundle_test.dart`
- `tool/run_m75_player_president_interactive_decision_persistence_bundle.dart`
- `M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

## 6. Canonical marker

`M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true canonicalRoundTrip=true atomicBundle=true nestedChecksums=true parityM74=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 7. Pre-doc canlı CI kanıtı

Exact code HEAD:
`c052b40e775dd65d9d7f36ccdfe71b89249452ce`

Workflow run:
`34886961074`

`test` job:
- **SUCCESS**
- Dart analyzer: `No issues found!`
- **339/339 tests PASS**
- M75'e ait 5 acceptance testi PASS
- cleanup + Complete job SUCCESS

`canonical` attempt 1:
- M0–M75 adımlarının tamamı SUCCESS
- exact M72, M73, M74 ve M75 marker'ları PASS
- Post Checkout SUCCESS
- Complete job SUCCESS
- strict `timeout-minutes: 7` envelope sonunda job conclusion `cancelled`
- assertion/runtime failure yok

Aynı exact HEAD'te izin verilen tek canonical retry:
- M0–M75 adımlarının tamamı tekrar SUCCESS
- exact M75 marker PASS
- Post Checkout SUCCESS
- Complete job SUCCESS
- strict 7 dakika envelope sonunda job conclusion yine `cancelled`
- üçüncü retry açılmadı

Artifacts: **0**

Bu evidence substantive executable correctness'i gösterir; merge-ready docs commit'i sonrası yeni exact HEAD için final PR CI ayrıca doğrulanacaktır.

## 8. Merge kuralı

Bu milestone merge edilmeden önce:

1. merge-ready docs commit'i sonrası exact final PR HEAD doğrulanmalı,
2. o exact HEAD'in final CI kanıtı okunmalı,
3. PR mergeable olmalı,
4. kullanıcıdan o exact HEAD için açık merge onayı alınmalı,
5. squash merge `expected_head_sha` kilidiyle yapılmalı,
6. post-merge gerçek `main` executable CI doğrulanmadan M75 CLOSED sayılmamalıdır.
