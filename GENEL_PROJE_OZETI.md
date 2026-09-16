# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 16 Eylül 2026

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

**M0–M83 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yok. M84 preselect edilmedi.**

M83:
**Player President Interactive Decision Mixed File Save Slot Catalog I — CLOSED / MERGED / PASS**

PR:
**#86 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`1e69bfa0afab205fce80aec5282d158cf13bac34`

Squash merge SHA:
`a71d9d83ae0f043f7e2d2e7f90e98840439bd53f`

Post-merge executable workflow run:
`35075992189` — run #521 — event `push`

Post-merge exact merge SHA üzerinde:
- analyzer `No issues found!`,
- **382/382 tests PASS**,
- **5/5 M83 acceptance PASS**,
- canonical **M0–M83 SUCCESS**,
- exact M83 marker PASS,
- cleanup SUCCESS,
- artifacts **0**.

## 4. M83 neden seçildi?

M82 kapanışından sonra fresh live-main gap scan yapıldı.

M78 checkpoint-backed slotlar için güvenli/deterministic load-game catalog sağlıyor; M82 ise M81 bootstrap slotları için aynı işi pre-checkpoint yaşam evresinde yapıyordu. Ancak uygulamanın tek bir read-only “yüklenebilir oyunlar” listesi için bu iki güvenli catalogu birleştiren typed projection yoktu.

Save router, migration veya dual-format store yazmak daha geniş ve mutating kapsam gerektirirdi. Bu yüzden en küçük authority-safe adım, yalnız mevcut M78 + M82 summary yüzeylerini composition ile birleştirmek oldu.

## 5. M83 çözümü

Yeni catalog:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog`

Yeni source enum:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSource`

Yeni ortak summary:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSummary`

Davranış:
- checkpoint M78 ve bootstrap M82 cataloglarını child authority olarak kullanır,
- physical save namespace'lerini birleştirmez,
- entry source'u açıkça `checkpoint` veya `newGameBootstrap` olarak taşır,
- aynı raw `slotId` iki namespace'te varsa iki ayrı `source:slotId` identity korunur,
- deterministic sıra slot ID, sonra source rank kullanır,
- source-specific exact summary objesini korur,
- checksum/decode/replay/world guard'larını child cataloglara delege eder,
- hiçbir save byte'ını mutate etmez,
- metadata sidecar/timestamp/schema üretmez.

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 checkpoint file-slot store.
- M78 checkpoint read-only catalog.
- M80 replay-only pre-checkpoint bootstrap snapshot.
- M81 bootstrap file-slot store.
- M82 bootstrap read-only catalog.
- M83 yalnız M78 + M82 read-only projection composition katmanıdır.

## 6. M83 acceptance

1. Child cataloglar boşken mixed catalog empty sonuç verir — **PASS**.
2. Checkpoint + bootstrap summary'lerini deterministic order ile birleştirir — **PASS**.
3. Aynı raw slot ID collision'ında iki typed identity de korunur — **PASS**.
4. Corrupt checkpoint child catalog üzerinden fail-closed kalır — **PASS**.
5. Divergent bootstrap world fail-closed kalır ve mixed catalog yeni write/file üretmez — **PASS**.

## 7. M83 final kanıt zinciri

Final PRE-MERGE exact SHA:
`1e69bfa0afab205fce80aec5282d158cf13bac34`

Final PRE-MERGE workflow run:
`35074707295` — run #520

PRE-MERGE gate:
- analyzer `No issues found!`,
- **382/382 tests PASS**,
- **5/5 M83 acceptance PASS**,
- canonical **M0–M83 SUCCESS**,
- exact marker PASS,
- artifacts **0**.

User approval sonrası PR #86 `expected_head_sha` kilidiyle squash merge edildi.

Squash merge SHA:
`a71d9d83ae0f043f7e2d2e7f90e98840439bd53f`

Post-merge push run:
`35075992189` — run #521

Başarılı post-merge test job:
`104746735582`

Başarılı post-merge canonical job:
`104746734713`

Post-merge evidence:
- analyzer `No issues found!`,
- **382/382 tests PASS**,
- **5/5 M83 acceptance PASS**,
- **M0–M83 tüm executable adımlar SUCCESS**,
- M83 step SUCCESS,
- exact M83 marker PASS,
- Post Checkout + Complete job SUCCESS,
- artifacts **0**.

Exact post-merge marker:
`M83_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 summaries=3 collisionPreserved=true deterministicOrder=true readOnly=true metadataExact=true worldGuard=true namespacesSeparate=true saveAuthority=M65 checkpointCatalog=M78 bootstrapCatalog=M82 worldClubs=48 seed=20260903`

Timing notu:
- post-merge canonical'ın önceki attempt'leri strict 7 dakika nedeniyle hedef M83 çalışmadan timing-only cancelled oldu,
- bu attempt'ler PASS sayılmadı,
- source/docs değiştirilmeden aynı exact merge SHA üzerinde retry edildi,
- başarılı attempt M83'e kadar tam yürüdü.

## 8. Yakın milestone zinciri

- M83 — Mixed File Save Slot Catalog — PR #86 — merge `a71d9d83ae0f043f7e2d2e7f90e98840439bd53f` — 382 tests — **CLOSED / MERGED / PASS**.
- M82 — Bootstrap File Save Slot Catalog — PR #85 — merge `d52b879668a9ef538ac45b15a1e294e86b1f64ac` — 377 tests — CLOSED / MERGED / PASS.
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
- M49–M65: player-president kontrolleri + tenure gate; **M65 persisted state authority**.
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
- M83: M78 checkpoint + M82 bootstrap catalogları üzerinde typed deterministic mixed read-only projection.

## 10. Sıradaki kesin iş

**Aktif milestone yok. M84 preselect edilmedi.**

Sıradaki adımlar:
1. Closure docs commit sonrası canlı `main` HEAD'ini doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; ikinci docs commit yaratma.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman yeni milestone numarasını/kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
