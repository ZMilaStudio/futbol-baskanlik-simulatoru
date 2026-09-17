# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 17 Eylül 2026

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

Kalıcı mimari ve çalışma kararları için `PROJE_KARARLARI.md` okunmalıdır.

## 2. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Deterministic seed / replay / save-resume parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek step/log okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan timeout olursa aynı exact SHA retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın exact final HEAD'i için açık kullanıcı onayı gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Closure docs executable kanıttan sonra güncellenir.
- Closure-docs CI gözlemseldir; parent merge SHA tam executable kanıta sahipse timing-only docs CI timeout yeni docs döngüsü yaratmaz.
- Aktif milestone varsa başka milestone seçilmez.

## 3. CANLI DURUM — buradan devam et

**M0–M88 CLOSED / MERGED / PASS.**

**Aktif milestone yok. M89 preselect edilmedi.**

Son kapanan milestone:
**M88 — Player President Interactive Decision Mixed File Save Slot Binding I**

PR:
**#91 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`a2cadd307296891ef2373d1acb1d2f3147956af3`

Squash merge SHA / M88 executable code SHA:
`566b04988484d6e286e6965627f3afc70e606559`

Pre-merge final workflow:
`35245742044` — run #546 — event `pull_request`

Final pre-merge gate:
- test job `105308597930` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `105308597094` — SUCCESS,
- canonical M0–M88 — SUCCESS,
- exact M88 marker — PASS,
- artifacts — 0.

Post-merge actual-main workflow:
`35260366761` — run #547 — event `push` — exact merge SHA `566b04988484d6e286e6965627f3afc70e606559`

Actual-main executable kanıt:
- test job `105334271089` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `105334271340` — top-level conclusion `cancelled`,
- checkout exact merge SHA — doğrulandı,
- M0–M88 milestone step'lerinin tamamı — SUCCESS,
- M88 step — SUCCESS,
- exact M88 marker — PASS,
- Post Checkout + Complete job step'leri — SUCCESS,
- artifacts — 0.

Canonical job'ın üst conclusion'ı strict süre zarfında `cancelled` görünmesine rağmen hedef M88 dahil bütün milestone step'leri ve marker tamamlanmış, daha sonraki milestone gate bulunmamıştır. Bu nedenle executable actual-main kanıt hedef milestone için tamamlanmıştır.

## 4. M88 neden seçildi?

M87 kapandıktan sonra fresh live-main gap scan yapıldı.

M87 mixed save-slot lifecycle'ını tek application-facing façade altında topluyordu; ancak bir slot açıldığında consumer'ın daha sonra aynı fiziksel/typed slot'a `save back` veya `delete` yapabilmesi için `source + slotId` kimliğini session'dan ayrı olarak taşıması gerekiyordu.

En küçük authority-safe boşluk, mevcut M83 typed identity ile M76/M79 application session'ını yalnız bellekte bağlayan transient bir handle oldu.

## 5. M88 çözümü

Yeni katman:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding`

Temel davranış:
- mevcut slot `source + slotId` ile veya M83 typed summary ile açılır,
- exact typed identity ile yüklenen application session yalnız runtime belleğinde birlikte tutulur,
- `saveBack()` aynı raw slot ID ve aynı typed source'a M87/M85 üzerinden delege eder,
- `delete()` yalnız bağlı typed source'u M87/M86 üzerinden siler,
- same-id checkpoint/bootstrap sibling namespace ayrı kalır,
- stale veya missing slot açılışı `null` döner,
- invalid slot validation mevcut M87/child-store contract'larında fail-closed kalır,
- binding metadata diske yazılmaz,
- yeni save schema, sidecar/cache, migration, rename/copy/bulk-delete veya namespace merge eklenmez.

Authority sınırı:
- **M65 tek persisted game-state authority.**
- M74 replay metadata.
- M75 checkpoint bundle.
- M77 checkpoint store.
- M78 checkpoint catalog.
- M80 bootstrap snapshot.
- M81 bootstrap store.
- M82 bootstrap catalog.
- M83 mixed typed read-only catalog.
- M84 source-aware loader.
- M85 source-aware writer.
- M86 source-aware deleter.
- M87 unified application-facing mixed save-slot façade.
- M88 transient typed slot/session binding; persisted authority oluşturmaz.

## 6. M88 acceptance

1. Checkpoint ve bootstrap summary'leri exact typed identity ile açılır — PASS.
2. Same raw slot ID iki namespace'te ayrı binding olarak korunur — PASS.
3. `saveBack()` exact bağlı namespace'e yazar ve sibling namespace'i değiştirmez — PASS.
4. `delete()` yalnız bağlı source'u siler — PASS.
5. Silinmiş/stale summary yeniden açıldığında `null` döner — PASS.
6. Missing slot `null` döner — PASS.
7. Invalid slot fail-closed kalır ve disk mutation oluşturmaz — PASS.
8. Binding transient kalır; yeni persisted metadata/authority yaratmaz — PASS.
9. M65 tek persisted game-state authority olarak kalır — PASS.

Exact canonical M88 marker:
`M88_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_BINDING_PASS controlled=t1_01 checkpointBound=true bootstrapBound=true collisionDistinct=true saveBackExact=true deleteIsolation=true staleNull=true missingNull=true invalidBlocked=true transientBinding=true saveAuthority=M65 service=M87 catalog=M83 loader=M84 writer=M85 deleter=M86 checkpointStore=M77 bootstrapStore=M81 worldClubs=48 seed=20260903`

## 7. M88 kanıt zinciri

Final PRE-MERGE kullanıcı-onaylı PR HEAD:
`a2cadd307296891ef2373d1acb1d2f3147956af3`

Final PRE-MERGE workflow:
`35245742044` — run #546

Başarılı PRE-MERGE işler:
- test job `105308597930` — SUCCESS,
- canonical job `105308597094` — SUCCESS,
- exact final HEAD üzerinde M0–M88 SUCCESS,
- M88 marker PASS,
- artifacts 0.

PR #91 kullanıcı exact-HEAD onayından sonra squash merge edildi.

Squash merge SHA:
`566b04988484d6e286e6965627f3afc70e606559`

Post-merge actual-main run:
`35260366761` — run #547 — event `push`

Actual-main executable kanıt:
- test job `105334271089` — SUCCESS,
- canonical job `105334271340`,
- exact merge SHA checkout — doğrulandı,
- M0–M88 milestone step'leri — SUCCESS,
- M88 exact marker — PASS,
- Post Checkout + Complete job step'leri — SUCCESS,
- artifacts — 0.

Canonical job'ın üst conclusion'ı `cancelled` kaldı; ancak cancellation hedef milestone tamamlandıktan sonra görülüyor ve M0–M88'in tamamı step-level SUCCESS. M88'den sonra başka milestone gate olmadığı için bu, mevcut timing-only kanıt kuralına göre actual-main executable closure için yeterlidir.

## 8. Yakın milestone zinciri

- M88 — Mixed File Save Slot Binding — PR #91 — merge `566b04988484d6e286e6965627f3afc70e606559` — **CLOSED / MERGED / PASS**.
- M87 — Mixed File Save Slot Service — PR #90 — merge `290de87297af115301b1e9d6d3ff0c0b5980087c` — CLOSED / MERGED / PASS.
- M86 — Mixed File Save Slot Deleter — PR #89 — merge `70f096a38e76894b909b334833409c4507a8fe4f` — CLOSED / MERGED / PASS.
- M85 — Mixed File Save Slot Writer — PR #88 — merge `7191fb734291420a077f5954fbdf4028763bc5c8` — CLOSED / MERGED / PASS.
- M84 — Mixed File Save Slot Loader — PR #87 — merge `232efbbb60d52340f056504b8a25f34cbc3d52c7` — CLOSED / MERGED / PASS.
- M83 — Mixed File Save Slot Catalog — PR #86 — merge `a71d9d83ae0f043f7e2d2e7f90e98840439bd53f` — CLOSED / MERGED / PASS.
- M82 ve öncesi — CLOSED / MERGED / PASS.

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
- M76: application-session lifecycle.
- M77/M78: checkpoint file-slot store + catalog.
- M79/M80/M81/M82: new-game bootstrap session/snapshot/store/catalog.
- M83: mixed typed read-only catalog.
- M84: source-aware loader.
- M85: source-aware writer.
- M86: source-aware deleter.
- M87: M83–M86 üstünde unified application-facing mixed save-slot service façade.
- M88: exact typed slot identity ile loaded application session'ı transient olarak bağlayan save-back/delete handle'ı.

## 10. Sıradaki kesin iş

**Aktif milestone yok. M89 preselect edilmedi.**

Sıradaki adımlar:
1. Bu M88 closure-docs commit'inin canlı `main` durumunu doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; parent M88 merge SHA üzerinde executable kanıt tamamlandığı için timing-only docs CI timeout yeni docs döngüsü başlatmaz.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman M89 kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
