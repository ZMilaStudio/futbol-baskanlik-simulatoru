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

Kalıcı mimari ve çalışma kararları için ayrıca `PROJE_KARARLARI.md` okunmalıdır.

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

**M0–M84 CLOSED / MERGED / PASS.**

**M85 MERGED, fakat post-merge actual-main executable doğrulaması henüz tamamlanmadığı için CLOSED değildir.**

M85:
**Player President Interactive Decision Mixed File Save Slot Writer I**

PR:
**#88 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`d216f435bf7a46c79e2c017b34310c5cc75e1d2f`

Squash merge SHA / canlı M85 kod SHA:
`7191fb734291420a077f5954fbdf4028763bc5c8`

Pre-merge final workflow:
`35102296859` — run #528 — event `pull_request` — final successful attempt `3`

Pre-merge exact final HEAD üzerinde:
- analyzer SUCCESS,
- normal tests SUCCESS,
- canonical **M0–M85 SUCCESS**,
- exact M85 marker PASS,
- artifacts **0**.

Post-merge actual-main workflow:
`35108099919` — run #529 — event `push` — exact merge SHA `7191fb734291420a077f5954fbdf4028763bc5c8`

Run #529 sonucu:
- `test` job **SUCCESS**,
- analyzer **SUCCESS**,
- normal tests **SUCCESS**,
- artifacts **0**,
- canonical **M0–M75 SUCCESS**,
- M76 strict 7 dakika sınırında `cancelled`,
- M77–M85 `skipped`.

Bu nedenle run #529 **M85 actual-main kapanış kanıtı değildir**. Görülen durum timing-only timeout sınıfındadır; sıradaki iş aynı exact merge SHA üzerinde canonical retry'dır. M85 koduna sırf timing için patch atılmayacaktır.

## 4. M85 neden seçildi?

M84 kapanışından sonra fresh live-main gap scan yapıldı.

M83 iki fiziksel save namespace'ini tek source-aware read-only katalogda gösteriyordu. M84 bu source-aware kimliği doğru mevcut loader'a yönlendiriyordu. Buna rağmen application katmanında bir session'ı doğru fiziksel save namespace'ine yazdıran tek source-aware writer yoktu.

Yeni save schema, metadata cache, migration veya üçüncü bir persistence authority yaratmak gereksiz ve riskliydi. En küçük doğal authority-safe adım, mevcut session origin bilgisini kullanıp write işlemini doğrudan M77 checkpoint store veya M81 bootstrap store'a delege eden ince bir writer oldu.

## 5. M85 çözümü

Yeni writer:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter`

Temel davranış:
- checkpoint-backed application session → mevcut **M77 checkpoint store**,
- pre-checkpoint new-game application session → mevcut **M81 bootstrap store**,
- yazılan slot için M83'ün typed source kimliğini döndürür,
- aynı raw slot ID'nin checkpoint ve bootstrap namespace'lerinde ayrı kalmasını korur,
- child store'ların byte üretimi, overwrite/recovery davranışı ve slot validation contract'larını değiştirmez,
- M84 loader ile round-trip uyumludur,
- yeni save formatı/schema, migration, metadata sidecar/cache veya yeni persisted-state authority oluşturmaz.

Authority sınırı:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik persistence bundle.
- M77 checkpoint file-slot store.
- M78 checkpoint read-only catalog.
- M80 replay-only pre-checkpoint bootstrap snapshot.
- M81 bootstrap file-slot store.
- M82 bootstrap read-only catalog.
- M83 mixed typed read-only catalog/projection.
- M84 source-aware load dispatcher.
- M85 source-aware write dispatcher; child store authority'lerini değiştirmez.

## 6. M85 acceptance

1. Checkpoint ve bootstrap session'ları doğru child store'a route eder — **PASS pre-merge**.
2. Routed bytes doğrudan M77/M81 write'larının ürettiği bytes ile aynıdır — **PASS pre-merge**.
3. Aynı raw slot ID iki ayrı M83 identity olarak korunur — **PASS pre-merge**.
4. Same-id collision varken overwrite yalnız seçilen namespace'i değiştirir — **PASS pre-merge**.
5. Invalid slot ID fail-closed kalır ve file mutation oluşturmaz — **PASS pre-merge**.

Canonical M85 marker:
`M85_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_WRITER_PASS controlled=t1_01 checkpointRouted=true bootstrapRouted=true collisionPreserved=true loadRoundTrip=true namespaceIsolation=true bytesDelegated=true invalidBlocked=true saveAuthority=M65 catalog=M83 loader=M84 checkpointStore=M77 bootstrapStore=M81 worldClubs=48 seed=20260903`

## 7. M85 kanıt zinciri

Final PRE-MERGE kullanıcı-onaylı PR HEAD:
`d216f435bf7a46c79e2c017b34310c5cc75e1d2f`

Final PRE-MERGE workflow:
`35102296859` — run #528 — event `pull_request`

Başarılı PRE-MERGE test job:
`104828464555`

Başarılı PRE-MERGE canonical job:
`104828461515`

Pre-merge timing notu:
- ilk exact-head CI'da analyzer M85 test dosyasındaki eksik runtime-checkpoint importu nedeniyle gerçek hata verdi; sadece eksik import düzeltildi,
- sonraki canonical attempt'lerde strict 7 dakika nedeniyle timing-only timeout görüldü,
- aynı exact HEAD değişmeden retry edildi,
- final attempt 3 canonical M0–M85 tam SUCCESS oldu.

PR #88 kullanıcı exact-HEAD onayından sonra `expected_head_sha=d216f435bf7a46c79e2c017b34310c5cc75e1d2f` kilidiyle squash merge edildi.

Squash merge SHA:
`7191fb734291420a077f5954fbdf4028763bc5c8`

İlk post-merge run:
`35108099919` — run #529 — event `push`

Post-merge test job:
`104834439486` — **SUCCESS**

Post-merge canonical job:
`104834439090` — **CANCELLED / timing-only**

Run #529 canonical M0–M75 SUCCESS tamamladı; M76 timeout sırasında cancelled olduğu için M77–M85 çalışmadı. Bu sebeple milestone henüz CLOSED değildir.

## 8. Yakın milestone zinciri

- M85 — Mixed File Save Slot Writer — PR #88 — merge `7191fb734291420a077f5954fbdf4028763bc5c8` — **MERGED / post-merge verification pending**.
- M84 — Mixed File Save Slot Loader — PR #87 — merge `232efbbb60d52340f056504b8a25f34cbc3d52c7` — **CLOSED / MERGED / PASS**.
- M83 — Mixed File Save Slot Catalog — PR #86 — merge `a71d9d83ae0f043f7e2d2e7f90e98840439bd53f` — CLOSED / MERGED / PASS.
- M82 — Bootstrap File Save Slot Catalog — PR #85 — merge `d52b879668a9ef538ac45b15a1e294e86b1f64ac` — CLOSED / MERGED / PASS.
- M81 — Bootstrap File Save Slot Store — PR #84 — merge `76566493c7f5999487b53db4794088a75bbe6a7b`.
- M80 — New-Game Bootstrap Snapshot — PR #83 — merge `44dbc898de57307050f4f26525886af32c999b51`.
- M79 — Application New-Game Session — PR #82 — merge `1f75d9e7e363d17e429af77a7aa28c21a04e06ae`.
- M78 — File Save Slot Catalog — PR #81 — merge `cb9334341e42a8dacf629f4aa25f123b8a6f7160`.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0`.
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
- M84: M83 source-aware identity'yi M77 checkpoint veya M81 bootstrap loader'a yönlendiren load dispatcher.
- M85: application session origin'ini M77 checkpoint veya M81 bootstrap store'a yönlendiren write dispatcher.

## 10. Sıradaki kesin iş

**Aktif milestone M85'tir; yeni milestone seçilmez.**

Sıradaki adımlar:
1. Run #529 canonical cancellation'ı timing-only olarak ele al ve **aynı exact merge SHA `7191fb734291420a077f5954fbdf4028763bc5c8`** üzerinde canonical retry et.
2. Retry'da M85 marker dahil canonical M0–M85 tam SUCCESS kanıtını al.
3. `test` SUCCESS + canonical M0–M85 SUCCESS + artifacts 0 actual-main kanıtı tamamlanınca M85'i CLOSED yaz.
4. Closure docs'u tek atomik commit ile güncelle; closure-docs CI yalnız gözlemsel olsun.
5. Ancak M85 tamamen kapandıktan sonra fresh live-main gap scan ile sonraki milestone değerlendirilsin.

**M86 preselect edilmedi.**

M65 tek persisted game-state authority olarak korunacaktır.
