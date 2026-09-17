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

**M0–M87 CLOSED / MERGED / PASS.**

**Aktif milestone yok. M88 preselect edilmedi.**

Son kapanan milestone:
**M87 — Player President Interactive Decision Mixed File Save Slot Service I**

PR:
**#90 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`064e19d3397f3e03c086fbab272ea628cf8905bf`

Squash merge SHA / M87 executable code SHA:
`290de87297af115301b1e9d6d3ff0c0b5980087c`

Pre-merge final workflow:
`35162467750` — run #537 — event `pull_request`

Final pre-merge gate:
- test job `105183751608` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `105183750488` — SUCCESS,
- canonical M0–M87 — SUCCESS,
- exact M87 marker — PASS,
- artifacts — 0.

Post-merge actual-main workflow:
`35217065854` — run #538 — event `push` — exact merge SHA `290de87297af115301b1e9d6d3ff0c0b5980087c`

Final post-merge executable kanıt:
- run attempt `10`,
- test job `105265777969` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `105265775729` — SUCCESS,
- checkout exact merge SHA — doğrulandı,
- M0–M87 tüm milestone step'leri — SUCCESS,
- M87 step — SUCCESS,
- exact M87 marker — PASS,
- Post Checkout + Complete job — SUCCESS,
- artifacts — 0,
- run-level conclusion — SUCCESS.

Böylece M87 actual-main executable gate tam başarıyla kapanmıştır.

## 4. M87 neden seçildi?

M86 kapandıktan sonra fresh live-main gap scan yapıldı.

M83 typed mixed catalog, M84 source-aware loader, M85 source-aware writer ve M86 source-aware deleter ayrı application servisleri olarak mevcuttu. Ancak application/UI katmanının bunları tek tek kurması ve hangi operasyon için hangi servisi çağıracağını bilmesi gerekiyordu.

En küçük authority-safe boşluk, mevcut M83–M86 davranışlarını değiştirmeden tek application-facing save-slot façade altında toplamak oldu.

## 5. M87 çözümü

Yeni servis:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotService`

Temel davranış:
- `list` / `inspect` → M83 mixed typed catalog davranışını kullanır,
- `load` / `loadSummary` → M84 source-aware loader'a delege eder,
- `save` → M85 application-session-origin-aware writer'a delege eder,
- `delete` / `deleteSummary` → M86 source-aware deleter'a delege eder,
- root factory mevcut checkpoint/bootstrap child store zincirini tek application-facing composition root üzerinden kurar,
- same-id checkpoint/bootstrap typed identities ayrı kalır,
- child exact-bytes / validation / cleanup / recovery contract'ları yeniden uygulanmaz,
- yeni save schema, migration, metadata cache/sidecar, namespace merge veya persisted authority oluşturulmaz.

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
- M87 unified application-facing façade; alt servisleri route/delegate eder, authority devralmaz.

## 6. M87 acceptance

1. Tek façade üzerinden list + inspect çalışır — PASS.
2. Save + load doğru typed namespace/store zincirine delege edilir — PASS.
3. Summary tabanlı load/delete routing exact source identity'yi korur — PASS.
4. Same raw slot ID iki namespace'te ayrı typed identity olarak korunur — PASS.
5. Source-specific delete sibling namespace'i korur — PASS.
6. Root factory gerçek M77/M81 child store zincirini kurar — PASS.
7. Invalid slot davranışı child contract'lara delege edilerek fail-closed kalır — PASS.
8. M65 tek persisted game-state authority olarak kalır — PASS.

Exact canonical M87 marker:
`M87_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_SERVICE_PASS controlled=t1_01 unifiedFacade=true listInspect=true saveLoad=true summaryRouting=true collisionPreserved=true deleteIsolation=true rootFactory=true invalidBlocked=true saveAuthority=M65 catalog=M83 loader=M84 writer=M85 deleter=M86 checkpointStore=M77 bootstrapStore=M81 worldClubs=48 seed=20260903`

## 7. M87 kanıt zinciri

Final PRE-MERGE kullanıcı-onaylı PR HEAD:
`064e19d3397f3e03c086fbab272ea628cf8905bf`

Final PRE-MERGE workflow:
`35162467750` — run #537

Başarılı PRE-MERGE işler:
- test job `105183751608` — SUCCESS,
- canonical job `105183750488` — SUCCESS,
- exact final HEAD üzerinde M0–M87 SUCCESS,
- M87 marker PASS,
- artifacts 0.

PR #90 kullanıcı exact-HEAD onayından sonra squash merge edildi.

Squash merge SHA:
`290de87297af115301b1e9d6d3ff0c0b5980087c`

Post-merge actual-main run:
`35217065854` — run #538 — event `push`

İlk post-merge canonical attempt'lerde strict 7 dakika nedeniyle farklı tail noktalarında timing-only cancellation görüldü. Her attempt'in step/logları incelendi; fonksiyonel hata görülmedi ve sırf timeout için kod/workflow patch'i yapılmadı. Aynı exact merge SHA üzerinde retry edildi.

Final attempt `10`:
- test job `105265777969` — SUCCESS,
- canonical job `105265775729` — SUCCESS,
- exact merge SHA checkout — doğrulandı,
- M0–M87 milestone step'leri — SUCCESS,
- M87 exact marker — PASS,
- Post Checkout + Complete job — SUCCESS,
- artifacts — 0,
- workflow run conclusion — SUCCESS.

Böylece M87 için merge öncesi exact-HEAD gate + merge sonrası exact-main executable gate tamamlandı.

## 8. Yakın milestone zinciri

- M87 — Mixed File Save Slot Service — PR #90 — merge `290de87297af115301b1e9d6d3ff0c0b5980087c` — **CLOSED / MERGED / PASS**.
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

## 10. Sıradaki kesin iş

**Aktif milestone yok. M88 preselect edilmedi.**

Sıradaki adımlar:
1. M87 closure docs commit'lerinin canlı `main` durumunu doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; parent M87 merge SHA üzerinde executable kanıt tamamlandığı için timing-only docs CI timeout yeni docs döngüsü başlatmaz.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman M88 kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
