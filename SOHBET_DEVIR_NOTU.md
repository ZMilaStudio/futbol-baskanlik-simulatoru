# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 26 Eylül 2026

Bu dosyanın amacı yeni sohbetin projeyi doğru current authority ile devralmasıdır.

# EN ÖNEMLİ KURAL

**Yeni sohbet açıldığında kullanıcı yeni geliştirme promptu vermeden HİÇBİR ŞEY YAPMA.**

Kaynak önceliği: **Live GitHub > güncel repo docs > central technical-development compass > eski sohbet bilgisi.**

## 1. Güncel proje durumu

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

# **M101 — CLOSED / MERGED / PASS**
# **M0–M101 — CLOSED / MERGED / PASS**

Last closed: **M101 — First Career Orientation I**. PR #105 CLOSED / MERGED / Draft=false.
Approved product HEAD: `0599d0c2e2e71643e002ba56fc834afb91f97611`.
Executable product merge authority: `76c785296aa70b754d90a28c130930293a7d3e1d`.
MERGE COMMIT with explicit M101 owner approval; parent 1 `f319b9ef40a85645c467a6c97e057a420e7cc152`, parent 2 `0599d0c2e2e71643e002ba56fc834afb91f97611`. General merge governance unchanged.

Actual-main Core #668 / run `36196662322` / attempt 1 — SUCCESS; normal tests SUCCESS; canonical M0–M88 84/84 physical SUCCESS; failed/skipped 0.
Actual-main Flutter #87 / run `36196662312` / attempt 1 — SUCCESS; Analyze, Flutter tests, debug APK, Android emulator and overall job SUCCESS.
Real execution marker VERIFIED: `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`. Android `am start -W` timeout/UNKNOWN was followed by a successful PID check: this is **launch-smoke**, not an end-to-end interactive gameplay test.

This docs-only closure moves `main` but does not modify executable product authority `76c785296aa70b754d90a28c130930293a7d3e1d`.

Persistence impact: **NONE**. M65 sole persisted game-state authority; M73/M76 Pending/submit, M87/M88 save/load and replay parity unchanged.

Aktif milestone: **YOK**. M102 not selected or started.

## 2. M101 essentials

Product identity: **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**
Opening: president role and decision → result → season cycle explained; existing New Game and Load Save routes preserved.
Club selection: canonical 48 clubs in original order; initial league from `world.leagues / clubIds` exact-one membership, missing/ambiguous membership fails closed.
President Home: current Pending kind and sequence exactly once before prepared **season-start**, not live-state snapshot; no next Pending during Resolution; Completed/next-season/career-end unchanged.
Six-file PR scope: `app/lib/screens/opening_screen.dart`, `app/lib/screens/club_selection_screen.dart`, `app/lib/screens/president_home_screen.dart`, `app/test/widget_test.dart`, `app/test/prepared_season_dashboard_widget_test.dart`, `app/test/next_season_widget_test.dart`.
Acceptance: 320px/TextScale 2.0, long names, lazy scroll, no overflow, exact choice/club identity, fail-closed, save/load/rebind and next-season/lost-career regression. No new gameplay, AI advice, tutorial-progress state or persisted schema.

## 3. Technical compass / next-work rule

- FBS-01 — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED.
- FBS-02 — NOT TRIGGERED.
- FBS-03 — NOT TRIGGERED.
- INFRA-01 — separate owner approval required; no activation.

**Without a new user request, do nothing.** Do not select M102, open a gap scan, branch, PR, CI or implementation. On a new authorized request: verify live `main`, read current repo docs and central compass, examine fresh product/authority evidence, and lock a product/authority contract with explicit owner approval before implementation.

## 4. Historical M100 handoff snapshot — 25 Eylül 2026 (NOT CURRENT)

The M100 closure facts below are historical. Old last-closed and next-work notes describe the M100 checkpoint, not current M101 authority.

### 4.1 M100 kapanış anındaki durum

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

# **M100 — CLOSED / MERGED / PASS**
# **M0–M100 — CLOSED / MERGED / PASS**

Last closed: **M100 — Crisis Decision Terms I**.
PR #103: **CLOSED / MERGED**.
Approved exact PR HEAD: `9defbfef7418253ad96c3df130a81808902e3b5f`.
Executable merge SHA: `be9af5ba5318fff137f1b0f6256f027652f872e5`.
Executable authority = product merge SHA; this doc-closure commit does not change executable product content.

Actual-main Core: **Core Simulation Tests #663**, run `36170999407`, attempt 1, exact executable SHA, SUCCESS.
- Analyze SUCCESS; normal tests SUCCESS; canonical M0–M88 ALL SUCCESS (84/84 physical steps).

Actual-main Flutter: **M89 Flutter App #83**, run `36170999215`, attempt 1, exact executable SHA, SUCCESS.
- Analyze SUCCESS; Flutter tests SUCCESS; debug APK SUCCESS; Android emulator SUCCESS; job overall SUCCESS.
- Real execution marker VERIFIED: `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`.

CI timeout remediation: PR #104 — MERGED, merge SHA `118e1be8af15f49f727eb6a1e68a61924d366823`.
- `test.timeout-minutes: 7`; `canonical.timeout-minutes: 10`.

Aktif milestone: **YOK**.
M101 o tarihte henüz açılmamıştı; güncel M101 CLOSED durumu yukarıdadır.

### 4.2 M100 essentials

Semantic: show the existing authoritative crisis option's exact cash, fan-trust and media-credibility effects before the player makes the crisis decision.
Feature: **presentation-only**; no new crisis authority.

Authority and contracts:
- Source: `context.availableDecisions` in original order; effect source: `decision.effect`.
- Three crisis families / nine actions.
- `cashDelta`, `fanTrustDelta`, `mediaCredibilityDelta` shown as signed effects.
- `Money.toString()` reused; positive values prefixed `+`, zero `0`.
- Exact outer key `crisis-action-${decision.action.name}` and `PlayerCrisisActionChoice(action: decision.action)` preserved.
- Canonical option effect, not post-decision forecast; no Flutter-side clamp/simulation.
- Turkish labels; all options selectable; submit-null disables options.
- No sorting, recommendation/ranking/highlight, raw enum or new business authority.

Acceptance: nine options in source order, exact localized labels and effect text, per-option assertions for repeated labels, exact submit identity, positive/negative/zero, disabled state, 320px, TextScale 2.0, large effects and last terms reachable.

Product PR #103 exact two files:
- `app/lib/decisions/renderers/crisis_decision_renderer.dart`
- `app/test/decision_renderers_test.dart`

Pre-merge exact-head Core #662 (`36168981755`) and Flutter #82 (`36168981556`) SUCCESS.
Post-merge actual-main Core #663 (`36170999407`) and Flutter #83 (`36170999215`) SUCCESS.

Persistence impact: **NONE**. **M65 sole persisted game-state authority**.
Core/controller/session/saveVersion/codecs/checksum/migrations unchanged.

### 4.3 M100 technical compass / historical next-work rule

- FBS-01 — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED.
- FBS-02 — NOT TRIGGERED.
- FBS-03 — NOT TRIGGERED.
- INFRA-01 — OUT OF M100 PRODUCT SCOPE; separate owner approval required.

Yeni milestone otomatik seçilmez. Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrula
2. current repo docs oku
3. central technical-development compass kontrol et
4. fresh live-main gap scan yap
5. milestone adayını değerlendir
6. implementation öncesi product/authority contract'ını kilitle

Bu M100 tarihsel devir kuralıdır; güncel sonraki çalışma kuralı yukarıda.

## 5. Historical M99 handoff snapshot — 24 Eylül 2026 (NOT CURRENT)

Aşağıdaki M99 devri tarihsel kayıt olarak korunmuştur. Buradaki `M100 NOT STARTED` ifadesi yalnız M99 kapanış anına aittir; güncel durum üstteki M100 kapanışıdır.

# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 24 Eylül 2026

Bu dosyanın amacı yeni sohbetin projeyi doğru current authority ile devralmasıdır.

# EN ÖNEMLİ KURAL

**Yeni sohbet açıldığında kullanıcı yeni geliştirme promptu vermeden HİÇBİR ŞEY YAPMA.**

Kaynak önceliği:
**Live GitHub > güncel repo docs > central technical-development compass > eski sohbet bilgisi.**

## 1. Güncel proje durumu

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

# **M0–M99 — CLOSED / MERGED / PASS**

Last closed:
**M99 — Sponsor Offer Terms I**

PR #102: **MERGED / CLOSED**

Approved exact PR HEAD:
`c068538687a71716ff5af1af896a2253be2f4a6d`

Executable merge SHA:
`aaafa10cae59a3f5e39d68a415a9f27c0b6cbac5`

Executable authority:
`aaafa10cae59a3f5e39d68a415a9f27c0b6cbac5`

Core actual-main:
- #656 / run `36051807362` / successful attempt 2 / SUCCESS
- Analyze SUCCESS
- 501 tests PASS
- canonical M0–M88 ALL SUCCESS
- attempt 1 timing-only cancellation at M75; no source/assertion failure
- attempt 2 full SUCCESS
- artifacts 0

Flutter actual-main:
- #79 / run `36051807407` / SUCCESS
- Analyze SUCCESS
- 103 tests PASS
- APK SUCCESS
- emulator SUCCESS
- `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

## 2. M99 essentials

Semantic:
> Sponsor seçimi sırasında authoritative sponsor teklif şartlarını anlaşılır şekilde göstermek.

Feature:
**presentation-only enhancement of the existing authoritative sponsor decision**.

Authority:
- source: `context.offers`
- source order preserved
- no sorting
- exact `offer.id` submit preserved
- no new sponsor domain authority

Visible terms:
- Sponsor adı
- Yıllık garanti
- Performans bonusu
- Maksimum yıllık gelir
- Sözleşme süresi
- Bonus hedefi

Target localization:
- `topHalf` → İlk 8
- `topSix` → İlk 6
- `topFour` → İlk 4
- `champion` → Şampiyonluk

Presentation contracts:
- existing `OutlinedButton`
- whole offer selectable
- key `sponsor-offer-${offer.id}`
- `Money.toString()` reused
- `offer.maxAnnualRevenue` direct existing getter
- no duplicated Flutter arithmetic
- AI choice hidden
- raw enum / offer ID / clubId hidden
- no recommendation/ranking/highlight

Acceptance:
- source-order proof PASS
- exact selection identity PASS
- all-offer selectability PASS
- disabled sponsor behavior PASS
- long sponsor name PASS
- 320px PASS
- TextScale 2.0 PASS
- large Money PASS
- champion mapping PASS
- no horizontal overflow PASS

Implementation scope:
- `app/lib/decisions/renderers/sponsor_decision_renderer.dart`
- `app/test/decision_renderers_test.dart`
- 2 exact files
- core production 0
- controller/session 0
- persistence 0
- workflow 0
- saveVersion 0

Persistence:
- **NONE**
- **M65 sole persisted game-state authority**

Pre-merge CI:
- Core #655 / run `36034707258` / exact HEAD `c068538687a71716ff5af1af896a2253be2f4a6d` / SUCCESS
- Flutter #78 / run `36034707284` / same exact HEAD / SUCCESS

Actual-main:
- Core #656 / run `36051807362` / successful attempt 2 / exact executable SHA `aaafa10cae59a3f5e39d68a415a9f27c0b6cbac5` / SUCCESS
- Flutter #79 / run `36051807407` / same exact executable SHA / SUCCESS

## 3. Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M99 PRODUCT SCOPE**

## 4. Current status

# **M99 — CLOSED / MERGED / PASS**
# **M0–M99 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M100:
**NOT STARTED**

## 5. Next work rule

Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrula
2. current repo docs oku
3. central technical-development compass kontrol et
4. fresh live-main gap scan yap
5. milestone adayını değerlendir
6. product/authority contract'ını implementation öncesi kilitle

Kullanıcı yeni geliştirme istemeden:
- M100 seçme
- gap scan başlatma
- branch/PR açma
- kod yazma
- CI başlatma
- technical compass activation başlatma
- yeni feature başlatma

# DUR

