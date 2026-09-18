# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 18 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değildir.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Canonical dünya:
- seed `20260903`
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 864 başlangıç oyuncusu

Kalıcı mimari ve çalışma kararları için `PROJE_KARARLARI.md`, yeni sohbet devri için `SOHBET_DEVIR_NOTU.md` okunmalıdır.

## 2. Kaynak önceliği ve kalıcı çalışma kuralları

Çelişki halinde:

1. **Live GitHub**
2. Repo içindeki güncel proje dosyaları
3. Eski sohbetler / eski notlar

Kalıcı çalışma disiplini:
- deterministic seed / replay / save-resume parity korunur,
- PASS yalnız canlı CI kanıtıyla yazılır,
- canonical timing-only timeout için source patch atılmaz; aynı exact SHA retry edilir,
- skipped milestone SUCCESS sayılmaz,
- merge öncesi exact final PR HEAD için açık kullanıcı onayı gerekir,
- squash merge + `expected_head_sha` lock kullanılır,
- post-merge actual-main executable doğrulaması tamamlanmadan milestone CLOSED sayılmaz,
- M65 tek persisted game-state authority olarak kalır.

## 3. CANLI DURUM — buradan devam et

**M0–M89 CLOSED / MERGED / PASS.**

Aktif milestone:

# M90 — Decision Resolution Feedback I

Branch:
`feat/m90-decision-resolution-feedback`

Draft PR:
**#93 — open / Draft / unmerged**

M90 branch başlangıç `main` SHA:
`2811989bff385eeca3b28b9393fbd55306b67e20`

Son doğrulanmış **source HEAD**:
`4f539f6129751c6114b8f53b0c2c3b9c96c9c12d`

M90 durum:
- Aşama 1 — **PASS**
- Aşama 2 — **PASS**
- Aşama 3 — **IMPLEMENTED / normal suite PASS / canonical final verification INCOMPLETE**
- Aşama 4 — **BAŞLANMADI**
- Flutter/controller/UI — M90 kapsamında henüz değiştirilmedi

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority**
- M74 yalnız accepted-choice replay metadata
- resolution/consequence runtime-only
- M76 application lifecycle / exposure
- persistence/save schema değişikliği yok

M90 Aşama 3 exact source HEAD CI:

Core Simulation Tests:
- run #574 / `35360774369`
- exact source SHA: `4f539f6129751c6114b8f53b0c2c3b9c96c9c12d`
- Analyze — **SUCCESS**
- normal tests — **SUCCESS**
- **429 tests passed**
- artifacts — **0**

Canonical:
- attempt 1: M0–M76 yolu geçti; M76 PASS marker sonrasında workflow infrastructure cancellation
- aynı exact SHA üzerinde timing-only retry attempt 2 yapıldı
- attempt 2: **M0–M79 PASS**
- M79 marker:
  `M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_PASS ... saveAuthority=M65 ...`
- M79 PASS'tan hemen sonra `The operation was canceled.`
- M80–M88 bu nedenle çalışmadı / skipped
- bu, source assertion/test failure değildir; ancak M0–M88 full SUCCESS tamamlanmadığı için Aşama 3 henüz PASS ilan edilmemiştir

Çok önemli:
Bu dokümantasyon commit'i source kodunu değiştirmeden branch HEAD'ini ilerletebilir.
Bu nedenle gelecekte:
- live PR HEAD ayrıca doğrulanmalı,
- `4f539f61...` **son doğrulanmış M90 Aşama 3 source HEAD** olarak ayrıştırılmalı,
- docs-only descendant HEAD otomatik olarak yeni source acceptance sonucu sayılmamalıdır.

Son kapanan milestone M89:
**CLOSED / MERGED / PASS**.
PR #92 merge ve actual-main kanıtları aşağıdaki tarihsel M89 bölümlerinde korunmaktadır.

## 4. M89 mimari yönü

M89 ile yeni backend façade/helper zinciri üretmek yerine ilk gerçek oynanabilir Flutter katmanı kuruldu.

Korunan dependency yönü:

`Flutter widgets`
→ transient presentation/controller
→ mevcut application session
→ M87 mixed save-slot façade / M88 binding
→ deterministic Dart core
→ **M65 persisted game-state authority**

Kesin sınırlar:
- root package saf Dart core olarak kalır,
- Flutter uygulaması repo içinde ayrı `app/` package'tır,
- root `pubspec.yaml` Flutter package'a dönüştürülmedi,
- simulation logic Flutter'a taşınmadı,
- persistence codec/routing semantics Flutter'da yeniden uygulanmadı,
- provider/controller authoritative persisted game-state sahibi değildir,
- M65 tek persisted game-state authority olarak kalır,
- M87 application-facing mixed save-slot entry point,
- M88 exact typed slot/session binding olarak kullanılır.

## 5. M89 Aşama 1 — Flutter shell + dependency boundary

PASS.

Kurulan temel:
- ayrı `app/` Flutter application package,
- Android application scaffold,
- `app/pubspec.yaml` üzerinden root Dart package'a local path dependency,
- root package Flutter dependency kazanmadı,
- bağımsız `M89 Flutter App` CI workflow'u,
- Android debug APK build,
- gerçek Android emulator launch smoke.

Public core API Flutter tarafından consumer olarak kullanılmaktadır.

## 6. M89 Aşama 2 — Composition Root + Açılış + Kulüp Seçimi

PASS.

`AppComposition` wiring-only kalır:
- `FictionalWorldFactory.build()` ile canonical world,
- application-private save directory,
- mevcut M87 `PlayerPresidentInteractiveDecisionMixedFileSaveSlotService`.

Açılış:
- `Yeni Oyun`
- `Kayıt Yükle`

Yeni oyun:
- canonical 48 kulüp doğrudan core world'den listelenir,
- UI-local duplicated club data yok,
- authoritative `Club` identity Başkanlık Merkezi akışına taşınır.

## 7. M89 Aşama 3 — Interactive New-Game Session + GameFlowController

PASS.

`GameFlowController` yalnız transient lifecycle/presentation coordinator'dır.

Resmi application lifecycle:
- `PlayerPresidentInteractiveDecisionApplicationSession.start(...)`
- `advance()`
- gerçek `PlayerPresidentInteractiveDecisionPending`
- gerçek `PlayerPresidentInteractiveSessionCompleted`

Fake Pending/Completed veya duplicated persisted gameplay model oluşturulmaz.

## 8. M89 Aşama 4 — Nine Decision Renderers + Submit Loop

PASS.

Dokuz decision kind'ın tamamı oynanabilir:
1. facility
2. sponsor
3. crisis
4. manager review
5. manager replacement
6. promise
7. media
8. transfer strategy
9. ticket pricing

Renderer yapısı presentation-only'dir.

Seçenekler authoritative request/context'ten gelir; mevcut domain choice tipleri kullanılır.

Submit yolu:
`session.submit(request: current.request, choice: choice)`

Kanıtlanan davranışlar:
- Pending → Pending,
- Pending → Completed,
- invalid/stale response fake progression üretmez,
- double-submit koruması yalnız transient UI safety'dir.

## 9. M89 Aşama 5 — Save / Load + M87 / M88

PASS.

Kayıt Yükle ekranı:
- M87 `list()` kullanır,
- typed source + slotId identity korunur,
- M88 `openSummary(...)` ile exact typed slot açılır,
- `saveBack()` exact source + slotId'ye yazar,
- delete exact typed source'u siler,
- same raw slot ID sibling namespace ayrı kalır.

Fresh new-game save:
- M87 `save(...)` ile bootstrap namespace'e route edilir.

Loaded save:
- M88 binding üzerinden devam eder.

App recreation testleri:
- controlled club parity,
- answered decision count parity,
- Pending kind/key/contextSignature parity,
- submit → saveBack → reopen parity.

Flutter save bytes, JSON codec veya namespace routing authority taşımaz.

## 10. M89 Aşama 6 — Completed → Checkpoint Handoff + Next Season

PASS.

Completed authoritative result içindeki checkpoint doğrudan resmi resume contract'ına verilir:

`PlayerPresidentInteractiveDecisionApplicationSession.resume(...)`

Handoff sonrası:
- session origin = checkpoint,
- first boundary gerçek Pending veya Completed,
- mevcut 9-renderer gameplay loop yeniden kullanılır,
- ilk checkpoint-origin save yine M87 üzerinden route edilir,
- M88 exact checkpoint slot binding çalışır,
- app recreation checkpoint restore parity çalışır.

Eski bootstrap save:
- otomatik silinmez,
- migrate edilmez,
- checkpoint identity'ye dönüştürülmez.

Bootstrap + checkpoint typed saves aynı storage root'ta ayrı identity olarak birlikte yaşayabilir.

## 11. Persisted-state authority haritası

En kritik mimari karar:

> **M65 tek persisted game-state authority olarak kalır.**

İlgili zincir:
- M65 — persisted game-state authority
- M74 — accepted-answer replay metadata
- M75 — checkpoint persistence bundle
- M76 — application-session lifecycle
- M77/M78 — checkpoint file-slot store/catalog
- M79/M80/M81/M82 — new-game session/bootstrap/store/catalog
- M83 — mixed typed catalog
- M84 — source-aware loader
- M85 — source-aware writer
- M86 — source-aware deleter
- M87 — application-facing mixed save-slot service
- M88 — transient exact typed slot/session binding
- M89 Flutter — consumer/presentation/application coordination; yeni persisted authority değildir

Flutter tarafında:
- save bytes yok,
- custom persistence schema yok,
- metadata sidecar yok,
- checkpoint clone authority yok,
- duplicate finance/fan/club/season gameplay authority yok,
- namespace map authority yok.

## 12. M89 final acceptance audit ve cleanup

M89 final acceptance audit'i source HEAD
`d1f815896a32ec6c01e31dfd88260812bc8b2e15`
üzerinde yapıldı.

Audit sonucu:
**B) NOT READY — FIXABLE NON-AUTHORITY GAPS**

Architecture/authority blocker bulunmadı.

Bulunan gerçek teknik gap:
- root `analysis_options.yaml` içindeki `app/**` exclusion nedeniyle Flutter `flutter analyze` gate'i app kaynaklarını anlamlı şekilde analiz etmiyordu,
- audit sırasında log `No issues found! (ran in 0.0s)` gösteriyordu.

Bu gap sonrasında canlı branch'te düzeltildi:

1. `0b1cb0e40449d7c5f578cb8e76a7cbe6c5c226d7`
   — `ci(m89): isolate Flutter analyzer config`
   — `app/analysis_options.yaml` eklendi ve app-local analyzer exclusion sıfırlandı.

2. `0d400c5573dc876fcb54d78281809db2ceb3c7b9`
   — `chore(m89): fix Flutter analyzer warnings`
   — analyzer'ın gerçek app source'u analiz etmesi sonrası çıkan iki test warning'i temizlendi.

Latest exact-head Flutter analyze kanıtı:
- `Analyzing app...`
- `No issues found! (ran in 8.6s)`

Bu, önceki 0.0s false-positive analyzer gate probleminin giderildiğini gösterir.

## 13. M89 final pre-merge kanıtı

Kullanıcı tarafından onaylanan final PR HEAD:
`f03db45e69b3993d9688e3fbbf47624ec066c734`

Final PR exact-head Flutter kanıtı:
- run #15 / workflow `35334739016` — SUCCESS,
- gerçek Flutter analyze — SUCCESS,
- 37 tests — PASS,
- Android debug APK — SUCCESS,
- emulator launch — SUCCESS,
- artifacts — 0.

Final PR exact-head Core kanıtı:
- run #563 / workflow `35334738958`,
- normal Analyze + tests — SUCCESS,
- canonical timing-only retry kuralıyla aynı exact SHA üzerinde attempt 3 — SUCCESS,
- M0–M88 tamamı — SUCCESS,
- skipped milestone yok,
- artifacts — 0.

## 14. PR #92 merge

PR #92 kullanıcının exact final HEAD
`f03db45e69b3993d9688e3fbbf47624ec066c734`
için verdiği açık onaydan sonra Ready yapıldı.

Merge öncesi HEAD tekrar doğrulandı ve değişmedi.

Squash merge:
- `expected_head_sha=f03db45e69b3993d9688e3fbbf47624ec066c734`
- merge SHA: `299c8f6ba898c490ff9a072c0381418e4aa1a499`
- PR #92 — MERGED.

## 15. Post-merge actual-main executable kanıtı

Actual executable `main` SHA:
`299c8f6ba898c490ff9a072c0381418e4aa1a499`

### Flutter actual-main

Workflow:
`35337399941` — **M89 Flutter App run #16 — event push — SUCCESS**

Job:
`105575323525` — SUCCESS

Kanıt:
- `Analyzing app...`
- `No issues found! (ran in 6.8s)`
- **37 tests PASS**
- Android debug APK — SUCCESS
- Android emulator launch — SUCCESS
- marker:
  `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts — 0.

### Core actual-main

Workflow:
`35337399947` — **Core Simulation Tests run #564 — event push — SUCCESS**

Normal job:
`105575323848` — SUCCESS
- Analyze — SUCCESS
- normal tests — SUCCESS

Canonical job:
`105575324082` — SUCCESS
- M0–M88 milestone step'lerinin tamamı — SUCCESS
- M88 exact marker — PASS
- skipped milestone yok
- artifacts — 0.

M88 marker:
`M88_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_BINDING_PASS ... saveAuthority=M65 ...`

## 16. M89 kapanış sonucu

M89 final acceptance blocker'ı olan Flutter analyzer boundary problemi giderildi.

Actual-main executable doğrulaması da tamamlandığı için:

# **M89 — CLOSED / MERGED / PASS**

Authority sonucu değişmedi:
- **M65 tek persisted game-state authority**,
- Flutter consumer/presentation layer,
- `AppComposition` wiring-only,
- `GameFlowController` transient lifecycle/presentation coordinator,
- M87/M88 mevcut persistence/application contract'larını korur,
- automatic bootstrap → checkpoint migration/delete yok,
- duplicate gameplay/persistence authority yok.

## 17. Bilinen non-blocker hardening notları

Bunlar M89 blocker değildir ve kullanıcı istemeden yeni scope'a çevrilmemelidir:
- `app/pubspec.lock` repoda yok,
- Flutter workflow job adı hâlâ `flutter-stage-1`,
- `actions/setup-java@v4` deprecation warning verebilir,
- Flutter workflow path filter root public API-only değişikliklerinde otomatik tetiklenmeyebilir,
- emulator gate launch-smoke düzeyinde; tüm gameplay'i gerçek cihaz üzerinde tıklayan ayrı `integration_test` yok.

`PROJE_KARARLARI.md` içindeki M89 öncesi “Flutter/UI henüz kurulmamıştır” gibi tarihsel ifadeler current live state değildir. Current state için Live GitHub ve bu güncel özet üstündür. Bu closure kapsamında `PROJE_KARARLARI.md` değiştirilmedi.

## 18. M90 Aşama 1–3 teknik durumu ve sıradaki davranış

### Aşama 1 — Backward-Compatible Runtime Resolution Contract

**PASS.**

M73'e additive:
`submitWithResolution(...) -> PlayerPresidentInteractiveDecisionSubmissionResult`
eklendi.

Legacy:
`submit(...) -> PlayerPresidentInteractiveSessionStep`
observable semantics'i korunur.

Resolution runtime-only'dir:
- M65 değildir,
- transcript değildir,
- save state değildir,
- codec/schema değildir.

### Aşama 2 — Nine-Kind Authoritative Consequence Capture

**PASS.**

Dokuz decision kind'ın tamamı için authoritative immediate consequence runtime capture çalışır:
1. facility investment
2. sponsor
3. crisis
4. manager review
5. manager replacement
6. promise
7. media statement
8. transfer strategy
9. ticket pricing

Capture:
- domain'in zaten ürettiği authoritative result'tan gelir,
- current submit sequence/request'e exact bound'dur,
- geçmiş replay consequence current resolution olarak sızmaz,
- future prediction veya Flutter-side business logic üretmez.

Aşama 2 final source HEAD:
`cae6b18ea6417fef5c4b71ef0bdd38b55f04c70f`

Aşama 2 exact-head run #571 / `35358399187`:
- Analyze SUCCESS
- 417 tests PASS
- canonical M0–M88 SUCCESS
- artifacts 0

### Aşama 3 — M74 / M76 Additive Resolution Integration

**IMPLEMENTED; final canonical acceptance henüz kapanmadı.**

Ana implementation commit:
`61c06f1f1babf629903aae2b0376de4b0834a73f`
— `feat(m90): expose additive resolution through app session`

Test import cleanup:
`a5def29b43fdad0fad531616beb2555ecc52cf81`

9-kind application fixture correction:
`4f539f6129751c6114b8f53b0c2c3b9c96c9c12d`

M74:
- additive `submitWithResolution(...)` expose eder,
- underlying M73 result'ını reconstruction yapmadan geçirir,
- transcript entry yalnız authoritative submit SUCCESS sonrasında bir kez eklenir,
- stale/invalid submit transcript'i mutate etmez,
- legacy `submit()` additive result `.nextStep` üzerinden compatible kalır,
- transcript format/saveVersion/entry schema unchanged,
- historical resolution persistence veya restore queue yok.

M76:
- additive `submitWithResolution(...)` M74'e delege eder,
- newGame ve checkpoint origin desteklenir,
- 9/9 consequence application boundary'ye pass-through edilir,
- resolution serialize edilmez,
- save/bootstrap sonrası restore next authoritative Pending/Completed boundary'ye gelir,
- stale/invalid submit persistence/bootstrap bytes'ını mutate etmez.

M75 ve M80 encoded schema unchanged.
M65 authority unchanged.
Flutter/controller/UI untouched.

### Son doğrulama

Exact source HEAD:
`4f539f6129751c6114b8f53b0c2c3b9c96c9c12d`

Run #574 / `35360774369`:
- Analyze SUCCESS
- normal tests SUCCESS
- **429 tests PASS**
- artifacts 0
- canonical attempt 2 M0–M79 PASS
- M79 PASS sonrasında infrastructure cancellation
- M80–M88 skipped

Bu nedenle resmi durum:
**M90 Aşama 3 = IMPLEMENTED / NORMAL PASS / CANONICAL FINAL VERIFICATION INCOMPLETE**

### Yeni sohbet için kesin kilit

Kullanıcı yeni prompt vermeden:
- live GitHub doğrulaması başlatma,
- CI retry başlatma,
- source patch yapma,
- commit oluşturma,
- PR metadata değiştirme,
- Aşama 3'ü PASS ilan etme,
- Aşama 4'e başlama,
- Flutter/controller/UI değiştirme,
- PR Ready yapma,
- merge yapma,
- docs closure yapma,
- yeni milestone seçme.

**Yeni sohbet açıldığında hiçbir otomatik işlem yapma. DUR ve kullanıcının açık promptunu bekle.**

