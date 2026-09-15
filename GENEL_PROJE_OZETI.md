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
- CI kırmızı/cancelled ise gerçek job step/logu okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan timeout olursa aynı exact SHA retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Closure docs executable kanıttan sonra tek atomik commit ile güncellenir.
- Closure-docs CI gözlemseldir; parent merge SHA tam executable kanıta sahipse timing-only timeout yeni docs döngüsü yaratmaz.
- Aktif milestone varsa başka milestone seçilmez.

## 3. CANLI DURUM — buradan devam et

**M0–M81 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**M82 ACTIVE / PRE-MERGE.**

M82:
**Player President Interactive Decision New-Game Bootstrap File Save Slot Catalog I**

PR:
**#85 — OPEN / DRAFT / PRE-MERGE**

Branch:
`feat/m82-new-game-bootstrap-file-save-slot-catalog`

M82 executable parent code HEAD:
`9ae3a13afd017022baca6e76cda56e6e14b56de1`

Base `main`:
`e1d90a20702a9bcfcc46aae3e9d779121cfa297e`

Bu PRE-MERGE doküman commit'i branch HEAD'ini yukarıdaki executable parent SHA'dan ilerletecektir. **Merge onayı yalnız docs-included final candidate SHA için istenecektir.**

## 4. M82 neden seçildi?

Fresh live-main gap scan'de M81'in pre-checkpoint M80 bootstrap bytes'ını güvenli file slotlarında sakladığı ve slot ID'lerini listelediği; ancak M78'in checkpoint/M75 tarafında sunduğu gibi bootstrap slotları için güvenli, deterministik ve read-only bir load-game özeti bulunmadığı görüldü.

Checkpoint + bootstrap slotlarını tek catalog altında birleştirmek daha geniş kapsamlı olacaktı. En küçük authority-safe adım, yalnız M81 bootstrap namespace'i üzerinde read-only catalog/projection eklemekti.

## 5. M82 çözümü

Yeni catalog:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog`

Davranış:
- M81 slotunu exact load ederek M80 checksum/format/world-fingerprint doğrulamasını çalıştırır,
- M74 transcript replay/application session sonucundan load-game summary üretir,
- metadata sidecar yazmaz,
- inspect/list sırasında slot bytes'ını değiştirmez,
- deterministic slot-id sırası kullanır,
- overwrite sonrası latest bootstrap state'ini projekte eder,
- corrupt bytes ve divergent supplied world durumunda fail-closed olur,
- M77 `.fbs.json` checkpoint namespace'ini görmez veya değiştirmez.

Summary yüzeyi en az şu alanları taşır:
- slot ID,
- controlled club ID/name,
- career seed,
- answered decision count,
- pending decision kind,
- resume season count,
- election interval.

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik application bundle.
- M77 M75-only checkpoint file-slot store.
- M78 M75-backed checkpoint catalog.
- M80 pre-checkpoint replay-only bootstrap snapshot.
- M81 exact M80 bootstrap bytes file adapter.
- M82 yalnız read-only bootstrap catalog/projection; ikinci game-state authority değildir.

M82 non-scope:
- metadata sidecar,
- M77 + M81 birleşik mixed load-game catalog,
- M77'yi dual-format store'a çevirmek,
- timestamp/nondeterministic metadata,
- database/cloud/Flutter/provider state,
- yeni persisted game-state authority.

## 6. M82 acceptance

Executable parent SHA `9ae3a13afd017022baca6e76cda56e6e14b56de1` üzerinde:

1. Bootstrap slot deterministic load-game metadata üretir ve bytes değişmez — **PASS**.
2. List deterministic slot-id order kullanır ve overwrite sonrası latest state'i yansıtır — **PASS**.
3. Missing/invalid slot davranışı M81 contract'ını korur — **PASS**.
4. Corrupt bytes + divergent supplied world fail-closed olur — **PASS**.
5. Catalog M77 checkpoint namespace'inden izole kalır — **PASS**.

## 7. M82 executable PRE-MERGE kanıtı

PR workflow run:
`34990552222`

Executable parent exact branch HEAD:
`9ae3a13afd017022baca6e76cda56e6e14b56de1`

Test evidence:
- analyzer `No issues found!`
- **377/377 tests PASS**
- **5/5 M82 acceptance PASS**
- test cleanup SUCCESS

Canonical evidence:
- strict 7 dakikalık envelope nedeniyle önceki denemeler M77/M79/M78 civarında timing-only cancelled oldu; M82 çalışmadığı için PASS sayılmadı,
- aynı exact SHA üzerinde kod patch'i olmadan retry edildi,
- başarılı canonical job: `104504219474`,
- **M0–M82 tüm executable adımlar SUCCESS**,
- M82 step SUCCESS,
- Post Checkout + Complete job SUCCESS,
- exact M82 marker PASS.

Artifacts:
- **0**

Exact marker:
`M82_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 summaries=2 primaryAnswers=4 deterministicOrder=true readOnly=true metadataExact=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 store=M81 worldClubs=48 seed=20260903`

## 8. Yakın milestone zinciri

- M82 — Bootstrap File Save Slot Catalog — PR #85 — **ACTIVE / PRE-MERGE**.
- M81 — Bootstrap File Save Slot Store — PR #84 — merge `76566493c7f5999487b53db4794088a75bbe6a7b` — 372 tests.
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
- M82: M81 bootstrap slots için deterministic read-only load-game catalog.

## 10. Sıradaki kesin iş

M82 henüz CLOSED değildir.

1. Bu PRE-MERGE docs commit'inin oluşturduğu **final docs-included PR HEAD** için CI yeniden doğrulanır.
2. Analyzer, 377/377 tests, 5/5 M82 acceptance, canonical M0–M82, exact marker ve artifacts 0 tekrar kilitlenir.
3. PR #85 Ready yapılır ve exact final HEAD + mergeability yeniden okunur.
4. Kullanıcıdan **exact final SHA** için açık squash-merge onayı istenir.
5. Onay gelmeden merge yapılmaz.

**M83 seçilmez; önce M82 tam kapanır.**
