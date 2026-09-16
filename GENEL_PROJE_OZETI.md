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

**M0–M84 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yok. M85 preselect edilmedi.**

M84:
**Player President Interactive Decision Mixed File Save Slot Loader I — CLOSED / MERGED / PASS**

PR:
**#87 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`e5e6e1aa1dd35fd1dc64cba8cc8768c26bfedfe8`

Squash merge SHA:
`232efbbb60d52340f056504b8a25f34cbc3d52c7`

Post-merge executable workflow run:
`35095632712` — run #525 — event `push`

Post-merge exact merge SHA üzerinde:
- analyzer `No issues found!`,
- **387/387 tests PASS**,
- **5/5 M84 acceptance PASS**,
- canonical **M0–M84 SUCCESS**,
- exact M84 marker PASS,
- Post Checkout + Complete job SUCCESS,
- artifacts **0**.

## 4. M84 neden seçildi?

M83 kapanışından sonra fresh live-main gap scan yapıldı.

M83, M78 checkpoint catalogu ile M82 bootstrap catalogunu tek deterministic read-only projection altında birleştiriyor ve her entry'nin source-aware kimliğini (`checkpoint` / `newGameBootstrap`) koruyordu. Ancak uygulamanın bu M83 seçimini alıp doğru mevcut store'a yönlendireceği source-aware load katmanı yoktu.

Yeni save router/store/schema yazmak authority sınırını gereksiz yere büyütecekti. Bu yüzden en küçük doğal authority-safe adım, M83 identity'sini tüketip checkpoint load'u M77'ye, bootstrap load'u M81'e unchanged delege eden ince bir dispatcher oldu.

## 5. M84 çözümü

Yeni loader:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader`

Kullandığı mevcut source enum:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSource`

Ana API:
- `load(source, slotId)`
- `loadSummary(summary)`

Davranış:
- M83 source-aware seçimini doğrudan tüketir,
- `checkpoint` source'u M77 checkpoint store `load(slotId)` yoluna delege eder,
- `newGameBootstrap` source'u M81 bootstrap store `load(...)` yoluna delege eder,
- bootstrap tarafında mevcut clubs/leagues world guard aynen M81/M80 tarafından uygulanır,
- mevcut `PlayerPresidentInteractiveDecisionApplicationSession?` tipini döndürür,
- missing slot child contract'a göre `null` kalır,
- invalid slot ID validation child store contract'ında kalır,
- corrupt checkpoint M77/M75 üzerinden fail-closed kalır,
- divergent bootstrap world M81/M80 üzerinden fail-closed kalır,
- aynı raw slot ID iki namespace'te olsa bile source routing nedeniyle collision collapse olmaz,
- load işlemi save byte'larını değiştirmez ve yeni file üretmez,
- yeni save formatı, migration, metadata cache/sidecar veya yeni persisted authority yaratmaz.

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 checkpoint file-slot store.
- M78 checkpoint read-only catalog.
- M80 replay-only pre-checkpoint bootstrap snapshot.
- M81 bootstrap file-slot store.
- M82 bootstrap read-only catalog.
- M83 mixed read-only catalog/projection.
- M84 yalnız source-aware load dispatcher; M77/M81 child authority'lerini değiştirmez.

## 6. M84 acceptance

1. Checkpoint ve bootstrap load'ları doğru child store'a route eder — **PASS**.
2. M83 same-id summary'lerini namespace collapse olmadan yükler — **PASS**.
3. Missing ve invalid slot davranışında child contract'larını korur — **PASS**.
4. Corrupt checkpoint decoding'i M77/M75 üzerinden fail-closed delege eder — **PASS**.
5. Bootstrap world guard'ı M81/M80 üzerinden delege eder ve yeni save file oluşturmaz — **PASS**.

## 7. M84 final kanıt zinciri

Final PRE-MERGE kullanıcı-onaylı PR HEAD:
`e5e6e1aa1dd35fd1dc64cba8cc8768c26bfedfe8`

Final PRE-MERGE workflow run:
`35083729658` — run #524 — event `pull_request`

Başarılı PRE-MERGE test job:
`104781832188`

Başarılı PRE-MERGE canonical job:
`104781829177`

PRE-MERGE gate:
- analyzer `No issues found!`,
- **387/387 tests PASS**,
- **5/5 M84 acceptance PASS**,
- canonical **M0–M84 SUCCESS**,
- exact M84 marker PASS,
- artifacts **0**.

Timing notu:
- run #524 canonical'ın önceki attempt'leri strict 7 dakika nedeniyle tail milestone'lara ulaşamadan timing-only cancelled oldu,
- gerçek step/loglar incelendi; fonksiyonel M84 hata kanıtı yoktu,
- source değiştirilmeden aynı final PR HEAD üzerinde retry edildi,
- attempt 4 M0–M84'ü tam SUCCESS tamamladı.

User exact HEAD onayından sonra PR #87 `expected_head_sha` kilidiyle squash merge edildi.

Squash merge SHA:
`232efbbb60d52340f056504b8a25f34cbc3d52c7`

Post-merge push run:
`35095632712` — run #525 — event `push`

Başarılı post-merge test job:
`104792143644`

Başarılı post-merge canonical job:
`104792143314`

Post-merge evidence:
- `main` checkout exact merge SHA `232efbbb60d52340f056504b8a25f34cbc3d52c7`,
- analyzer `No issues found!`,
- **387/387 tests PASS**,
- **5/5 M84 acceptance PASS**,
- **M0–M84 tüm executable adımlar SUCCESS**,
- M84 step SUCCESS,
- exact M84 marker PASS,
- Post Checkout + Complete job SUCCESS,
- artifacts **0**.

Exact post-merge marker:
`M84_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_LOADER_PASS controlled=t1_01 checkpointLoaded=true bootstrapLoaded=true collisionRouted=true missingNull=true bytesPreserved=true worldGuard=true namespacesSeparate=true saveAuthority=M65 catalog=M83 checkpointStore=M77 bootstrapStore=M81 worldClubs=48 seed=20260903`

## 8. Yakın milestone zinciri

- M84 — Mixed File Save Slot Loader — PR #87 — merge `232efbbb60d52340f056504b8a25f34cbc3d52c7` — 387 tests — **CLOSED / MERGED / PASS**.
- M83 — Mixed File Save Slot Catalog — PR #86 — merge `a71d9d83ae0f043f7e2d2e7f90e98840439bd53f` — 382 tests — CLOSED / MERGED / PASS.
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
- M84: M83 source-aware identity'yi M77 checkpoint veya M81 bootstrap loader'a yönlendiren read-only/source-aware load dispatcher; yeni persisted authority yok.

## 10. Sıradaki kesin iş

**Aktif milestone yok. M85 preselect edilmedi.**

Sıradaki adımlar:
1. Bu closure docs commit'inin canlı `main` HEAD olduğunu doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; sonucu yazmak için ikinci docs commit oluşturma.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman M85 kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
