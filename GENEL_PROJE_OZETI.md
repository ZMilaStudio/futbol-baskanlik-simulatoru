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

**M0–M85 CLOSED / MERGED / PASS.**

**Aktif milestone yok. M86 preselect edilmedi.**

Son kapanan milestone:
**M85 — Player President Interactive Decision Mixed File Save Slot Writer I**

PR:
**#88 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`d216f435bf7a46c79e2c017b34310c5cc75e1d2f`

Squash merge SHA / M85 executable code SHA:
`7191fb734291420a077f5954fbdf4028763bc5c8`

Pre-merge final workflow:
`35102296859` — run #528 — event `pull_request` — successful attempt `3`

Pre-merge exact final HEAD üzerinde:
- analyzer SUCCESS,
- normal tests SUCCESS,
- canonical **M0–M85 SUCCESS**,
- exact M85 marker PASS,
- artifacts **0**.

Post-merge actual-main workflow:
`35108099919` — run #529 — event `push` — exact merge SHA `7191fb734291420a077f5954fbdf4028763bc5c8`

Run #529 final successful retry:
- run attempt **10**,
- `test` job `104876041901` — **SUCCESS**,
- analyzer — **SUCCESS**,
- normal tests — **SUCCESS**,
- canonical job `104876039906` — **SUCCESS**,
- canonical **M0–M85 SUCCESS**,
- M85 step **SUCCESS**,
- exact M85 marker **PASS**,
- Post Checkout + Complete job **SUCCESS**,
- artifacts **0**.

Bu executable kanıtla M85 actual-main gate tamamlandı ve milestone CLOSED oldu.

Not: M85 merge SHA'dan sonra yalnız dokümantasyon amacıyla `ddf1b54a1811ae55ae6c2f9522c8cf68c48aefc8` commit'i `main`e eklenmişti. Run #529 gerçek `main` push run'ı olarak exact merge SHA'yı checkout edip doğruladığından executable kapanış kanıtı geçerlidir. Final closure docs bu kanıttan sonra güncellenmektedir.

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

1. Checkpoint ve bootstrap session'ları doğru child store'a route eder — **PASS**.
2. Routed bytes doğrudan M77/M81 write'larının ürettiği bytes ile aynıdır — **PASS**.
3. Aynı raw slot ID iki ayrı M83 identity olarak korunur — **PASS**.
4. Same-id collision varken overwrite yalnız seçilen namespace'i değiştirir — **PASS**.
5. Invalid slot ID fail-closed kalır ve file mutation oluşturmaz — **PASS**.

Exact canonical M85 marker:
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
- ilk exact-head CI'da analyzer M85 test dosyasındaki eksik runtime-checkpoint importu nedeniyle gerçek hata verdi; yalnız eksik import düzeltildi,
- sonraki canonical attempt'lerde strict 7 dakika nedeniyle timing-only timeout görüldü,
- aynı exact HEAD değişmeden retry edildi,
- attempt 3 canonical M0–M85 tam SUCCESS oldu.

PR #88 kullanıcı exact-HEAD onayından sonra `expected_head_sha=d216f435bf7a46c79e2c017b34310c5cc75e1d2f` kilidiyle squash merge edildi.

Squash merge SHA:
`7191fb734291420a077f5954fbdf4028763bc5c8`

Post-merge actual-main run:
`35108099919` — run #529 — event `push` — head SHA `7191fb734291420a077f5954fbdf4028763bc5c8`

İlk post-merge attempt ve birkaç exact-SHA retry strict 7 dakika nedeniyle tail milestone'lara ulaşamadan timing-only cancelled oldu. Loglar tek tek incelendi; fonksiyonel hata görülmedi ve source/timing patch'i yapılmadı.

Final post-merge başarılı retry:
- run attempt `10`,
- test job `104876041901` — SUCCESS,
- canonical job `104876039906` — SUCCESS,
- M0–M85 tüm canonical step'ler SUCCESS,
- M85 marker PASS,
- artifacts 0.

Böylece M85 için merge öncesi exact-HEAD gate + merge sonrası exact-main executable gate ikisi de tamamlandı.

## 8. Yakın milestone zinciri

- M85 — Mixed File Save Slot Writer — PR #88 — merge `7191fb734291420a077f5954fbdf4028763bc5c8` — **CLOSED / MERGED / PASS**.
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

**Aktif milestone yok. M86 preselect edilmedi.**

Sıradaki adımlar:
1. Final M85 closure docs commit'inin canlı `main` HEAD olduğunu doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; merge SHA `7191fb734291420a077f5954fbdf4028763bc5c8` üzerinde executable M0–M85 kanıt zaten tam olduğundan timing-only docs CI timeout yeni docs döngüsü başlatmaz.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman M86 kapsamını kilitle.

**M86 preselect edilmedi.**

M65 tek persisted game-state authority olarak korunacaktır.
