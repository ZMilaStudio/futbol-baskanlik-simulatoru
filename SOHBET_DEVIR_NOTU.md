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

**M0–M82 CLOSED / MERGED / PASS.**

**Aktif milestone yoktur. M83 preselect edilmemiştir.**

Son kapanan milestone:
**M82 — Player President Interactive Decision New-Game Bootstrap File Save Slot Catalog I**

PR:
**#85 — MERGED**

Approved exact final PR HEAD:
`18b5a4e0644b6401334bd0419b5acd0d48e06f01`

Squash merge SHA:
`d52b879668a9ef538ac45b15a1e294e86b1f64ac`

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

1. Bootstrap slot deterministic summary + read-only bytes — PASS.
2. Deterministic list order + overwrite latest state — PASS.
3. Missing/invalid slot M81 contract parity — PASS.
4. Corrupt bytes + divergent world fail-closed — PASS.
5. M77 checkpoint namespace isolation — PASS.

## 5. M82 merge ve post-merge kanıtı

Approved exact final PR HEAD:
`18b5a4e0644b6401334bd0419b5acd0d48e06f01`

Squash merge SHA:
`d52b879668a9ef538ac45b15a1e294e86b1f64ac`

Post-merge gerçek `main` push workflow run:
`35011219817` — run #516 — event `push`

Exact tested `main` SHA:
`d52b879668a9ef538ac45b15a1e294e86b1f64ac`

Test job:
`104534184354`

- analyzer `No issues found!`
- **377/377 tests PASS**
- **5/5 M82 acceptance PASS**
- Post Checkout + Complete job SUCCESS

Canonical:
- strict 7 dakikalık envelope nedeniyle bazı denemeler M77/M79 civarında timing-only cancelled oldu,
- M82 çalışmayan denemeler kapanış kanıtı sayılmadı,
- source/docs patch'i atmadan exact aynı merge SHA retry edildi,
- başarılı canonical job: `104534182851`,
- **M0–M82 SUCCESS**,
- M82 step SUCCESS,
- exact M82 marker PASS,
- Post Checkout + Complete job SUCCESS.

Artifacts:
- run `35011219817` → **0**

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

**Aktif milestone yoktur. M83 preselect edilmemiştir.**

Bir sonraki geliştirme turunda:
1. canlı GitHub `main` HEAD ve açık PR'ları doğrula,
2. `GENEL_PROJE_OZETI.md` ve bu dosyayı oku,
3. fresh live-main gap scan yap,
4. gap scan sonucundaki en küçük doğal authority-safe milestone'u seç,
5. M65'i tek persisted game-state authority olarak koru.
