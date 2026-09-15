# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı tarih için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. Bu dosyayı oku.
4. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Çelişkide **canlı GitHub kazanır**.
6. Aktif milestone varsa onu bitir; fresh scan ile başka milestone seçme.

## 2. Devredilen durum

**M0–M79 CLOSED / MERGED / PASS.**

**M80 ACTIVE / PRE-MERGE.**

Milestone:
**M80 — Player President Interactive Decision New-Game Bootstrap Snapshot I**

Branch:
`feat/m80-interactive-decision-new-game-bootstrap-snapshot`

PR:
**#83 — OPEN / DRAFT / PRE-MERGE**

İlk executable M80 HEAD:
`8eef05379c36003f7ba6e5b013fceddaf0260c3d`

İlk executable CI run:
`34962878632`

Bu devir/proje/milestone docs commit'i branch HEAD'ini yukarıdaki SHA'dan sonra ilerletecektir; sonraki işlem mutlaka canlı PR HEAD'i yeniden okumalıdır.

## 3. M80 neden seçildi?

Fresh live-main gap scan:
- M79 new-game'i application layer üzerinden başlatabiliyor,
- M65 checkpoint oluşmadan M75 persistence bilinçli olarak fail-closed,
- M73 pending karar sırasında partial game-state commit etmiyor,
- accepted cevaplar immutable başlangıç girdilerinden deterministik replay ediliyor.

Bu nedenle pre-checkpoint ilerlemeyi saklamak için partial world save veya ikinci state authority yerine **bootstrap girdileri + M74 transcript** yaklaşımı seçildi.

## 4. M80 çözümü

Yeni replay-only snapshot:
`PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot`

İçerik:
- immutable `SimulationConfig`
- `controlledClubId`
- `electionInterval`
- mevcut M75 `resumeConfig`
- mevcut M74 transcript
- deterministic `worldFingerprint`

Yeni application yüzeyi:
- `canPersistBootstrap`
- `newGameBootstrapSnapshot`
- `encodeNewGameBootstrapSnapshot()`
- `restoreNewGameBootstrap(...)`
- `restoreEncodedNewGameBootstrap(...)`

Restore:
- world snapshot içine serialize edilmez,
- caller aynı `clubs` + `leagues` girdilerini verir,
- fingerprint uyuşmazsa replay başlamadan fail-closed,
- transcript exact pending request'e replay edilir,
- tamamlanınca kesintisiz run ile aynı M65 checkpoint elde edilir.

Authority sınırı:
- M65 tek persisted game-state authority,
- M74 accepted-answer replay metadata,
- M75 checkpoint-backed application bundle,
- M76/M79 application lifecycle,
- M77 M75-only local file slots,
- M78 M75-backed load-game catalog,
- M80 pre-checkpoint bootstrap/replay metadata; partial game state değildir.

M80 non-scope:
- M77 slot formatını bootstrap için büyütmek,
- M78 catalog'a bootstrap slot metadata eklemek,
- database/cloud/Flutter/provider state.

## 5. İlk executable M80 CI kanıtı

Exact HEAD:
`8eef05379c36003f7ba6e5b013fceddaf0260c3d`

Workflow run:
`34962878632`

Test job:
- **SUCCESS**
- analyzer `No issues found!`
- **366/366 tests PASS**
- **6 M80 acceptance testi PASS**
- Post Checkout + Complete job SUCCESS

Canonical job:
- **SUCCESS**
- M0–M80 tüm executable adımlar SUCCESS
- M80 step SUCCESS
- Post Checkout + Complete job SUCCESS

Artifacts:
**0**

Exact marker:
`M80_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_SNAPSHOT_PASS controlled=t1_01 decisions=9 bootstrapRoundTrip=true stableCodec=true worldGuard=true m75Blocked=true parity=true saveAuthority=M65 replayMetadata=M74 checkpointBundle=M75 worldClubs=48 seed=20260903`

## 6. Acceptance

1. Empty bootstrap deterministic ilk pending request'i restore eder — PASS.
2. Accepted-answer transcript exact sonraki pending request'i restore eder — PASS.
3. Codec deterministic + checksum protected — PASS.
4. Divergent world replay öncesi fail-closed — PASS.
5. Restored completion kesintisiz run ile exact parity — PASS.
6. M75/M65 authority sınırı korunur; checkpoint-origin bootstrap yüzeyini reddeder — PASS.

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

1. PRE-MERGE docs commit'inden sonra PR #83 canlı HEAD'ini yeniden oku.
2. Yeni exact HEAD CI run'ını bul.
3. Analyzer + **366/366 tests** + 6 M80 acceptance doğrula.
4. Canonical M0–M80 + exact marker + cleanup doğrula; gerekirse aynı SHA canonical retry.
5. Artifacts=0 doğrula.
6. PR #83'ü Ready for review yap.
7. Ready sonrası HEAD değişmedi + `mergeable=true` doğrula.
8. Kullanıcıdan **bu exact final SHA için açık merge onayı** iste.

Kullanıcı onayı olmadan merge etme.
M80 kapanmadan M81 seçme.
