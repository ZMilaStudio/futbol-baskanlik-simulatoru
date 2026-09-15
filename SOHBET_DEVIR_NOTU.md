# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı tarih için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. Bu dosyayı oku.
4. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Çelişkide **canlı GitHub kazanır**.
6. Aktif milestone varsa onu bitir; yoksa fresh gap scan yap.

## 2. Devredilen durum

**M0–M80 CLOSED / MERGED / PASS.**

**Aktif milestone yok.**

**M81 henüz seçilmedi.**

Son kapanan milestone:
**M80 — Player President Interactive Decision New-Game Bootstrap Snapshot I**

PR:
**#83 — MERGED**

Final approved PR HEAD:
`99b94db11354be7650edbc362716896bcc66b74e`

Squash merge SHA:
`44dbc898de57307050f4f26525886af32c999b51`

Post-merge gerçek `main` workflow run:
`34971253889`

Bu kapanış doküman commit'i `main` HEAD'ini merge SHA'dan sonra ilerletecektir. Yeni sohbet mutlaka canlı `main` HEAD'i yeniden okumalıdır.

## 3. M80 neyi kapattı?

M79 application-owned sezon-0 new-game başlatabiliyordu; ancak M65 checkpoint oluşmadan M75 persistence bilinçli olarak fail-closed idi. M73 pending decision anında partial game-state commit etmediği için pre-checkpoint ilerleme immutable başlangıç girdileri + accepted-answer transcript ile deterministik replay edilebiliyordu.

M80 ile replay-only bootstrap snapshot eklendi:
- `PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot`
- versioned/checksummed codec
- immutable `SimulationConfig`
- `controlledClubId`
- `electionInterval`
- M75 `resumeConfig`
- M74 transcript
- deterministic `worldFingerprint`
- `newGameBootstrapSnapshot`
- `encodeNewGameBootstrapSnapshot()`
- `restoreNewGameBootstrap(...)`
- `restoreEncodedNewGameBootstrap(...)`
- `canPersistBootstrap`

Restore semantiği:
- world snapshot içine serialize edilmez,
- caller aynı `clubs` + `leagues` girdilerini sağlar,
- world fingerprint farklıysa replay başlamadan fail-closed,
- aynı girdiler aynı pending request'e ve tamamlanınca aynı M65 checkpoint'e ulaşır.

Authority değişmedi:
- **M65 tek persisted game-state authority**,
- M74 accepted-answer replay metadata,
- M75 checkpoint-backed application bundle,
- M76/M79 application lifecycle,
- M77 M75-only file-slot store,
- M78 M75-backed load-game catalog,
- M80 yalnız pre-checkpoint bootstrap/replay metadata; partial game-state değildir.

M80 kapsamında M77 slot formatı ve M78 catalog bootstrap desteği özellikle eklenmedi.

## 4. M80 final CI / merge kanıtı

### Pre-merge exact HEAD

Final approved PR HEAD:
`99b94db11354be7650edbc362716896bcc66b74e`

Final PR run:
`34963832381`

Kanıt:
- analyzer `No issues found!`
- **366/366 tests PASS**
- **6 M80 acceptance testi PASS**
- canonical **M0–M80 SUCCESS**
- exact M80 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

### Post-merge gerçek main

Merge SHA:
`44dbc898de57307050f4f26525886af32c999b51`

Push workflow run:
`34971253889`

Kanıt:
- event `push`, head `main`, exact merge SHA
- test job **SUCCESS**
- analyzer `No issues found!`
- **366/366 tests PASS**
- 6 M80 acceptance testi PASS
- canonical job **SUCCESS**
- M0–M80 tüm canonical executable adımlar SUCCESS
- M80 step SUCCESS
- Post Checkout + Complete job SUCCESS
- artifacts **0**

Exact marker:
`M80_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_SNAPSHOT_PASS controlled=t1_01 decisions=9 bootstrapRoundTrip=true stableCodec=true worldGuard=true m75Blocked=true parity=true saveAuthority=M65 replayMetadata=M74 checkpointBundle=M75 worldClubs=48 seed=20260903`

## 5. Acceptance

1. Empty bootstrap deterministic ilk pending request'i restore eder — PASS.
2. Accepted-answer transcript exact sonraki pending request'i restore eder — PASS.
3. Codec deterministic + checksum protected — PASS.
4. Divergent world replay öncesi fail-closed — PASS.
5. Restored completion kesintisiz run ile exact parity — PASS.
6. M75/M65 authority sınırı korunur; checkpoint-origin bootstrap yüzeyini reddeder — PASS.

## 6. Kalıcı çalışma kuralları

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

## 7. Sıradaki kesin iş

1. Canlı `main` HEAD'i yeniden doğrula.
2. Açık PR/branch/workflow/artifact durumunu yeniden doğrula.
3. Fresh live-main gap scan yap.
4. M81'i ancak bu scan sonucunda seç.
5. Seçilen kapsamı branch + acceptance + canonical ile uygula.
6. Merge öncesi exact final HEAD için yeniden açık kullanıcı onayı iste.

M81'i geçmiş sohbet tahmininden seçme.
