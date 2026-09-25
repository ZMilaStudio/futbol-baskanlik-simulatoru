# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 25 Eylül 2026

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

# **M0–M100 — CLOSED / MERGED / PASS**

Son kapanan milestone:
# M100 — Crisis Decision Terms I

Product PR: **#103 — CLOSED / MERGED**

Approved exact PR HEAD:
`9defbfef7418253ad96c3df130a81808902e3b5f`

Executable MERGE COMMIT SHA / actual-main executable authority:
`be9af5ba5318fff137f1b0f6256f027652f872e5`

Actual-main Core proof:
- Core Simulation Tests #663 / run `36170999407` / attempt 1 — SUCCESS
- exact SHA `be9af5ba5318fff137f1b0f6256f027652f872e5`
- Analyze SUCCESS; normal tests SUCCESS; canonical M0–M88 ALL SUCCESS (84/84 physical steps)
- failed / skipped canonical steps: 0

Actual-main Flutter proof:
- M89 Flutter App #83 / run `36170999215` / attempt 1 — SUCCESS
- exact SHA `be9af5ba5318fff137f1b0f6256f027652f872e5`
- Analyze SUCCESS; Flutter tests SUCCESS; debug APK SUCCESS; Android emulator SUCCESS; job overall SUCCESS
- real execution output marker VERIFIED: `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`

CI timeout remediation: PR #104 — MERGED; canonical timeout 10 minutes, normal test timeout 7 minutes.
Persistence impact: **NONE**; M65 remains sole persisted game-state authority.

# **M100 — CLOSED / MERGED / PASS**
# **M0–M100 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M101:
**NOT STARTED**

Yeni milestone otomatik seçilmez. Kullanıcı açıkça yeni geliştirme istediğinde live `main`, güncel repo docs ve central technical-development compass kontrol edilir; fresh gap scan ve product/authority contract yeni onaya tabi tutulur.

## M100 kapanış sonucu

# M100 — Crisis Decision Terms I

### Product semantic / authority

> Kriz kararı verilmeden önce, mevcut authoritative kriz seçeneklerinin kesin mali, taraftar ve medya etkilerini oyuncuya anlaşılır biçimde göstermek.

Feature: **presentation-only enhancement of the existing authoritative crisis decision**.

- Authoritative options and order: `context.availableDecisions` (`CrisisDecision`).
- Authoritative per-option terms: `decision.effect` (`cashDelta`, `fanTrustDelta`, `mediaCredibilityDelta`).
- Nine options across three crisis families: `liquiditySqueeze`, `supporterUnrest`, `mediaBacklash`.
- Existing Turkish crisis type / action labels and existing `OutlinedButton` preserved.
- Exact key: `crisis-action-${decision.action.name}`; exact submit: `PlayerCrisisActionChoice(action: decision.action)`.
- Direct source order, every option's selectability and disabled `onSubmit == null` behavior preserved.
- Signed cash display reuses `Money.toString()`; signed int display shows positive `+`, negative `-`, zero `0`.
- These are **canonical option effects**, not predicted resulting state. No Flutter-side clamp, simulation or duplicate business calculation.
- No AI recommendation, ranking, sorting, highlighting or raw enum exposure.

### Implementation scope / acceptance

Exact product PR #103 changed files (2):
- `app/lib/decisions/renderers/crisis_decision_renderer.dart`
- `app/test/decision_renderers_test.dart`

Acceptance proof includes:
- All three crisis families / nine canonical actions and source-order parity.
- Exact localized labels and canonical cash/fan/media terms per action.
- Per-option scoped assertions where distinct decisions legitimately share an effect label.
- Exact action submit identity, all-option selectability and disabled-state behavior.
- Signed positive/negative/zero coverage, no raw enum and no recommendation.
- Responsive width 320, `TextScaler.linear(2.0)`, large effects, last terms reachable and no horizontal overflow.

Product source and test blobs unchanged through main sync and merge. Core production, controller/session, persistence and product workflow untouched by PR #103.

### CI remediation — separate scope

PR #104 — `CI — Extend canonical simulation timeout` — MERGED.
- Approved CI branch HEAD `28c2df8ebfaf0d1787ebd822deba2b3ac449a314`.
- CI remediation merge SHA `118e1be8af15f49f727eb6a1e68a61924d366823`.
- Exact CI changed file: `.github/workflows/m0-tests.yml`.
- `jobs.canonical.timeout-minutes`: **7 → 10**; `jobs.test.timeout-minutes`: **7 unchanged**.
- No canonical M0–M88 step/order, concurrency, triggers, permissions or runner changes.
- Product PR #103 was synced by MERGE COMMIT, so workflow remediation is inherited from base `main`, not a PR #103 diff file.
- Earlier cancelled M100 canonical attempts were timing-only; no source/assertion failure was observed.

### Merge / exact-head validation / actual-main proof

Approved exact PR #103 HEAD: `9defbfef7418253ad96c3df130a81808902e3b5f`.
Merge method: **MERGE COMMIT** (owner-approved, no squash/rebase).
Executable merge SHA: `be9af5ba5318fff137f1b0f6256f027652f872e5`.
Merge parent 1: `118e1be8af15f49f727eb6a1e68a61924d366823`.
Merge parent 2: `9defbfef7418253ad96c3df130a81808902e3b5f`.

Pre-merge exact-head CI:
- Core Simulation Tests #662 / run `36168981755` — SUCCESS; normal tests and canonical M0–M88 ALL SUCCESS.
- M89 Flutter App #82 / run `36168981556` — SUCCESS; Analyze / Flutter tests / APK / emulator SUCCESS.

Post-merge actual-main Core:
- #663 / run `36170999407`, attempt 1, exact executable SHA, SUCCESS.
- Analyze SUCCESS; normal tests SUCCESS; 84/84 canonical physical steps SUCCESS (M0–M88; M19–M24 combined).
- Skipped / failed canonical steps: 0.

Post-merge actual-main Flutter:
- #83 / run `36170999215`, attempt 1, exact executable SHA, SUCCESS.
- Analyze SUCCESS; Flutter tests SUCCESS; debug APK SUCCESS; emulator SUCCESS; job overall SUCCESS.
- Actual execution log contains `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app` after the launch / process-presence check, not merely in workflow script text.

### Persistence / technical compass

> **M65 remains sole persisted game-state authority.**

M100 persistence impact: **NONE**.
No saveVersion, codec, checksum, migration, save metadata or M74/M75/M77–M88/M80 authority change.
FBS-01: keep current save architecture / unchanged. FBS-02 and FBS-03: not triggered. INFRA-01: outside product scope; separate owner authorization required.

### Final closure state

# **M100 — CLOSED / MERGED / PASS**
# **M0–M100 — CLOSED / MERGED / PASS**

Aktif milestone: **YOK**.
M101: **NOT STARTED**.

## M99 kapanış sonucu

# M99 — Sponsor Offer Terms I

M99 implementation PR #102 ile MERGE COMMIT yöntemiyle birleştirildi ve actual-main executable proof tamamlandı.

### Product semantic

> Sponsor seçimi sırasında authoritative sponsor teklif şartlarını anlaşılır şekilde göstermek.

Feature classification: **presentation-only enhancement of the existing authoritative sponsor decision**.

M99 yeni sponsor domain authority oluşturmaz.

Existing authoritative source:
`context.offers`.

Critical contracts:
- authoritative source order korunur,
- sorting yoktur,
- exact `offer.id` selection korunur,
- AI recommendation/ranking/highlight yoktur.

### Visible sponsor offer terms

Her authoritative sponsor offer için:
- Sponsor adı
- Yıllık garanti
- Performans bonusu
- Maksimum yıllık gelir
- Sözleşme süresi
- Bonus hedefi

Bonus target Turkish presentation:
- `topHalf` → İlk 8
- `topSix` → İlk 6
- `topFour` → İlk 4
- `champion` → Şampiyonluk

Money presentation:
- existing `Money.toString()` reuse edilir.

Maximum annual revenue:
- existing domain `offer.maxAnnualRevenue` getter doğrudan kullanılır,
- Flutter-side duplicated arithmetic yoktur.

### UI / decision contracts

Korunan davranış:
- existing `OutlinedButton`
- whole offer selectable
- exact `offer.id` submit
- outer key `sponsor-offer-${offer.id}`
- existing intro copy unchanged
- sponsor-specific disabled behavior preserved
- all other offers selectable
- AI choice hidden
- raw enum hidden
- raw offer ID hidden
- raw `clubId` hidden
- no recommendation
- no ranking
- no highlight

### Test / responsive coverage

M99 acceptance coverage:
- exact offer terms
- localized bonus targets
- source-order preservation
- exact selection identity
- all-offer selectability
- sponsor-specific disabled state
- raw enum hiding
- raw ID hiding
- long sponsor name
- 320px width
- TextScale 2.0
- large Money values
- champion mapping
- no horizontal overflow / layout safety

### Source scope

Production:
- `app/lib/decisions/renderers/sponsor_decision_renderer.dart`

Tests:
- `app/test/decision_renderers_test.dart`

Total:
- 1 production
- 1 test
- 2 exact

Unchanged:
- Core production
- DecisionPanel
- GameFlowController
- application session
- persistence
- saveVersion
- workflows

### Persistence

> **M65 remains sole persisted game-state authority.**

M99 persistence impact: **NONE**.

No change to:
- M65
- M74
- M75
- M80
- M77–M88
- saveVersion
- codecs
- checksum
- migrations
- save metadata
- save namespaces

### Validation authority

Implementation environment'ta local Dart/Flutter CLI mevcut değildi.

PR #102 current authority'sine göre exact-head GitHub CI authoritative validation gate olarak kullanıldı.

Pre-merge exact-head:
- Core Simulation Tests #655 / run `36034707258`
- exact SHA `c068538687a71716ff5af1af896a2253be2f4a6d`
- SUCCESS
- M89 Flutter App #78 / run `36034707284`
- same exact SHA
- SUCCESS

### Merge + actual-main executable proof

Approved exact PR HEAD:
`c068538687a71716ff5af1af896a2253be2f4a6d`

Merge method:
**MERGE COMMIT**

Executable merge SHA:
`aaafa10cae59a3f5e39d68a415a9f27c0b6cbac5`

Actual-main Core:
- Core Simulation Tests #656 / run `36051807362`
- exact SHA `aaafa10cae59a3f5e39d68a415a9f27c0b6cbac5`
- successful attempt 2
- SUCCESS
- Analyze SUCCESS
- 501 tests PASS
- canonical M0–M88 ALL SUCCESS
- artifacts 0

Core retry history:
- attempt 1: M0–M74 SUCCESS → M75 timing-cancel → M76–M88 SKIPPED
- attempt 2: M0–M88 ALL SUCCESS
- assertion/source failure NONE
- source/workflow mutation NONE

Actual-main Flutter:
- M89 Flutter App #79 / run `36051807407`
- exact SHA `aaafa10cae59a3f5e39d68a415a9f27c0b6cbac5`
- SUCCESS
- Analyze: No issues found
- 103 tests PASS
- debug APK SUCCESS
- emulator SUCCESS
- launch marker `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

### Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M99 PRODUCT SCOPE**

### Current state after M99 closure

# **M99 — CLOSED / MERGED / PASS**
# **M0–M99 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M100:
**NOT STARTED**

## M98 kapanış sonucu

# M98 — Completed Season Finance Statement I

M98 implementation PR #101 ile squash merge edildi ve actual-main executable proof tamamlandı.

### Product semantic

> Tamamlanan sezonun authoritative finansal dökümü.

Feature classification: **read-only completed-season president observation**.

M98 değildir:
- live/current-season budget
- transfer budget allocation
- sponsor decision
- ticket pricing decision
- facility decision
- wage-policy decision
- loan/credit decision
- financial forecast
- accounting ledger
- bookkeeping engine
- transaction-history engine
- persistence authority

### Authority

Exact authority chain:

`PlayerPresidentInteractiveSessionCompleted`
→ `PlayerPresidentCompletedSeasonReport.fromCompleted(...)`
→ existing M91 finance selection
→ `boundary.source.financeFor(controlledClubId)`
→ completed world season finances
→ exact controlled `ClubFinanceSeason`
→ world-finance signature parity
→ `report.finance`.

Critical contract:
- M98 directly consumes `PlayerPresidentCompletedSeasonReport.finance`.
- No second completed-season traversal.
- No new core finance DTO.
- No new finance snapshot authority.
- No copied finance authority.

### Architecture

Locked architecture:
**A — DIRECT EXISTING M91 FINANCE SEAM**

M98 core production impact: **ZERO**.

Unchanged authorities/components:
- `PlayerPresidentCompletedSeasonReport`
- `ClubFinanceSeason`
- `Money`
- `FinancialHealth` domain
- `GameFlowController`
- `PlayerPresidentInteractiveDecisionApplicationSession`
- persistence architecture

### Finance statement structure

Five sections:
1. Açılış Durumu
2. Operasyonel Gelirler
3. Faaliyet ve Faiz Giderleri
4. Finansman / Nakit Hareketleri
5. Kapanış Durumu

Visible finance facts:

Açılış:
- `openingCash`
- `openingDebt`

Operational revenue:
- `centralRevenue`
- `sponsorRevenue`
- `matchdayRevenue`
- `prizeRevenue`
- `totalRevenue`

Expenses:
- `wageExpense`
- `operatingExpense`
- `interestExpense`
- `profitAndLossExpenses`
- `operatingResult`

Cash / financing:
- `transferInstallmentIncome`
- `transferInstallmentExpense`
- `principalRepaid`
- `emergencyBorrowing`

Closing:
- `closingCash`
- `closingDebt`
- `health`

### Finance semantics

`totalRevenue` =
`centralRevenue + sponsorRevenue + matchdayRevenue + prizeRevenue`.

`transferInstallmentIncome` operational revenue değildir.
`emergencyBorrowing` revenue değildir.

`profitAndLossExpenses` =
`wageExpense + operatingExpense + interestExpense`.

`principalRepaid` P&L expense değildir.
`transferInstallmentExpense`, `profitAndLossExpenses` içine dahil değildir.

`operatingResult = totalRevenue - profitAndLossExpenses`.

Accounting-safe UI labels:
- **Toplam operasyonel gelir**
- **Toplam faaliyet ve faiz gideri**
- **Faaliyet sonucu (faiz dahil)**
- **Transfer taksit girişi**
- **Transfer taksit ödemesi**
- **Anapara geri ödemesi**
- **Acil borçlanma**

### Do-not-show

M98 UI expose etmez:
- `clubId`
- `signature`
- `expectedClosingCash`
- `expectedClosingDebt`
- save-slot IDs
- president/internal IDs

Raw internal ID gösterilmez.

### Money / health presentation

Money presentation existing `Money.toString()` kullanır.
Format: `<value>M`.
Yeni currency/locale authority yoktur.

FinancialHealth Turkish presentation tek shared app helper üzerinden gelir:
`financialHealthLabel(...)`.

Mappings:
- `veryStrong` → Çok güçlü
- `solid` → Sağlam
- `balanced` → Dengeli
- `tight` → Sıkışık
- `debtCrisis` → Borç krizi

Duplicate production mapping yoktur.

### Flutter

CTA:
**Finansal Dökümü Gör**

Key:
`completed-season-finance-statement-button`

Placement:
existing **Finansal Özet** içinde, mevcut yedi finance summary satırından sonra.
M98 üst sporting CTA grubuna katılmaz.
Existing inline Finansal Özet korunur.

Screen:
`PresidentCompletedSeasonFinanceStatementScreen`

Key:
`completed-season-finance-statement-screen`

AppBar:
**Sezon Finansları**

Header:
`Sezon <n> • <leagueName>`

Navigation owner:
`PresidentSessionStateView`

Exact presentation inputs:
- `report.finance`
- `report.seasonIndex`
- `report.leagueName`

Screen controller/session/persistence traversal yapmaz.

### Lifecycle / M93 guard

Active Completed:
- M91 report visible
- M96 Puan Durumu available
- M97 Maç Sonuçları available
- M98 Finansal Dökümü Gör available
- Sonraki Sezona Geç visible

Lost Completed:
- M91 report visible
- M96 available
- M97 available
- M98 available
- M93 Career End visible
- Sonraki Sezona Geç absent

M98 read-only navigation continuation authority oluşturmaz.
M93 guard unchanged.

Busy state:
- finance CTA visible kalır
- disabled olur

Mobile/accessibility proof:
- real vertical `ListView` PASS
- 320px PASS
- TextScale 2.0 PASS
- very large Money PASS
- negative `operatingResult` rendering PASS
- zero financing values visible PASS
- last section reachable PASS
- no overflow/clipping PASS
- horizontal scroll gerekmez

### Persistence

> **M65 remains sole persisted game-state authority.**

M98 persistence impact: **NONE**.

No changes to:
- M65
- M74
- M75
- M80
- M77–M88
- saveVersion
- codecs
- checksum
- migrations
- save metadata
- save namespaces

No persisted:
- financeStatement
- finance history payload
- financeViewed cache
- sidecar
- new save family

Existing restored Completed finance parity remains authoritative.

### Source scope

Production:
- `app/lib/reports/financial_health_label.dart`
- `app/lib/reports/president_season_report_panel.dart`
- `app/lib/screens/president_completed_season_finance_statement_screen.dart`
- `app/lib/screens/president_home_screen.dart`

Tests:
- `app/test/completed_season_finance_statement_widget_test.dart`
- `app/test/next_season_widget_test.dart`
- `app/test/president_season_report_panel_test.dart`

Total:
- 4 production
- 3 test
- 7 exact

Core production files changed: **0**
Persistence changed: **0**
Workflow changed: **0**

### CI history

Pre-merge exact-head:
- Core Simulation Tests #651 / run `35912289990`
- exact SHA `aea64fb232e374089c79babdf4c2c6b77c2899c0`
- successful attempt 17
- SUCCESS
- canonical M0–M88 ALL SUCCESS
- artifacts 0

- M89 Flutter App #76 / run `35912290042`
- exact SHA `aea64fb232e374089c79babdf4c2c6b77c2899c0`
- attempt 1
- SUCCESS
- artifacts 0

Pre-merge Core attempts 1–16:
- canonical timing/cancellation only
- no source patch
- no timeout change
- no workflow mutation
- same exact SHA

Attempt 17: **FULL SUCCESS**.

Actual-main:
- Core Simulation Tests #652 / run `35931227265` / attempt 1
- exact SHA `29a6cab58e4da45de3cdad342b521204ebb27851`
- SUCCESS
- 501 tests PASS
- canonical M0–M88 ALL SUCCESS
- artifacts 0

- M89 Flutter App #77 / run `35931227290` / attempt 1
- exact SHA `29a6cab58e4da45de3cdad342b521204ebb27851`
- SUCCESS
- 101 Flutter tests PASS
- APK SUCCESS
- emulator SUCCESS
- launch marker SUCCESS
- artifacts 0

### Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M98 PRODUCT SCOPE**

### Current state after M98 closure

# **M98 — CLOSED / MERGED / PASS**
# **M0–M98 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M99:
**NOT STARTED**

## M97 kapanış sonucu

# M97 — Completed Season Match Results I

M97 implementation PR #100 ile squash merge edildi ve actual-main executable proof tamamlandı.

### Product semantic

> Tamamlanan sezonun authoritative maç sonuçları.

Feature classification: **read-only completed-season president observation**.

M97 değildir:
- live match center
- match simulation
- tactical control
- line-up control
- replay engine
- fixture generation
- standings calculation
- result recalculation
- persistence authority

### Authority

Exact authority chain:
`PlayerPresidentInteractiveSessionCompleted`
→ existing M91 completed-season traversal
→ authoritative `WorldCareerSeason`
→ `worldSeason.leaguesBeforeSeason`
→ controlled club completed `WorldLeague`
→ `worldSeason.leagueResults`
→ same completed `LeagueTier`
→ `LeagueSeasonSnapshot.report`
→ `SeasonReport.fixtures`.

Critical invariant:
`SeasonReport.fixtures` source order M97 observation için authoritative'dir.

M97 sort/regenerate/re-rank/standings recalculation/result simulation yapmaz.

### M91 ownership

`PlayerPresidentCompletedSeasonReport.fromCompleted(...)` single completed-season deep authority traversal owner olarak kalır.
M97 ikinci independent `fromCompleted(...)` traversal eklemez.
M97 M91'in zaten seçtiği `controlledClubId`, completed `WorldLeague` ve `SeasonReport` değerlerini tüketir.

### M96 + M97 sibling fail-closed contract

M96 seam: `PlayerPresidentCompletedSeasonReport.leagueTable` → `PlayerPresidentCompletedSeasonLeagueTableSnapshot?`.
M97 exact seam: `PlayerPresidentCompletedSeasonReport.matchResults` → `PlayerPresidentCompletedSeasonMatchResultsSnapshot?`.

`leagueTable` ve `matchResults` independent nullable fail-closed sibling projection'lardır.
M97-specific integrity failure `matchResults = null` yapar ve otherwise-valid M91 report'u korur.
M96 leagueTable bağımsız kalır; bir sibling failure diğerini fabricate/mutate etmez.
Existing M91 authority failure whole report'u fail etmeye devam eder.

### Public types / immutable rows

Public types:
- `PlayerPresidentCompletedSeasonMatchResultsSnapshot`
- `PlayerPresidentCompletedSeasonMatchResult`

Snapshot fields:
- seasonIndex
- controlledClubId
- leagueTier
- matches
- derived leagueName
- runtime-only ordered signature

Row fields:
- fixtureId
- round
- opponentClubId
- isHome
- goalsFor
- goalsAgainst

Rows immutable value-copy'dir; source Fixture/MatchResult referansı tutulmaz. `matches` `List.unmodifiable` kullanır.

### Order / result contract

M97 `SeasonReport.fixtures` listesini source order'da iterates eder; yalnız controlled club fixture'ları project edilir.
Home: `goalsFor = homeGoals`, `goalsAgainst = awayGoals`.
Away: `goalsFor = awayGoals`, `goalsAgainst = homeGoals`.
Score recalculation yoktur.
Flutter yalnız presentation olarak `Galibiyet / Beraberlik / Mağlubiyet` derive eder.

Current canonical evidence:
- league size 16
- controlled completed-season matches 30
- generic production expectation `2 * (leagueSize - 1)`

`30` hard-coded production rule değildir; current canonical evidence'dir.

### Completed-season boundary

M97 membership authority `worldSeason.leaguesBeforeSeason`.
M97 result authority `SeasonReport.fixtures`.
Authority değildir: `checkpoint.nextSeasonLeagues`, `worldSeason.leaguesAfterTransition`.

Semantics distinct:
- M95 = prepared next-season fixtures
- M96 = completed-season final league table
- M97 = completed-season played-match results

### Flutter / club-name authority

CTA: **Maç Sonuçlarını Gör**
Key: `completed-season-match-results-button`
Placement: M96 `Puan Durumunu Gör` sonrasında, `Finansal Özet` öncesinde.
Screen: `PresidentCompletedSeasonMatchResultsScreen`
AppBar: **Maç Sonuçları**
Header: `Sezon <n> • <leagueName>`

Rows show:
- `<round>. Hafta`
- canonical opponent club name
- controlled-club-perspective score
- Ev / Deplasman
- Galibiyet / Beraberlik / Mağlubiyet

Canonical display names existing PresidentHomeScreen club-name resolver / `composition.world.clubs` exact-one lookup üzerinden çözülür.
Projection identity olarak opponentClubId taşır; raw IDs gösterilmez; UI-local club-name authority yoktur.

### Lifecycle / M93 guard

Active Completed:
- M91 report visible
- M96 CTA valid olduğunda visible
- M97 CTA valid olduğunda visible
- Sonraki Sezona Geç visible

Lost Completed:
- M91 report visible
- M96 CTA valid olduğunda visible
- M97 CTA valid olduğunda visible
- M93 Career End visible
- Sonraki Sezona Geç absent

M97 read-only navigation career continuation authority oluşturmaz; M93 semantics korunur.

Mobile/accessibility evidence:
- real 30-match list PASS
- real vertical scroll PASS
- 320px PASS
- TextScale 2.0 PASS
- long club names PASS
- canonical club names PASS
- raw IDs hidden
- no overflow

M97 vertical list'tir; horizontal-scroll behavior claim edilmez.

### Save / reopen / persistence

M97 authoritative Completed state'ten yeniden derive edilir.
Persisted matchResults payload: **NONE**.
Runtime signature yalnız observation/test parity içindir.
Relevant save/reopen regression coverage PASS.

> **M65 remains sole persisted game-state authority.**

M97 persistence impact: **NONE**.

No changes to M65, M74, M75, M80, M77–M88, saveVersion, codecs, checksum, migrations, save metadata.
No persisted matchResults, cache, sidecar veya UI viewed-state persistence.

### CI history

Pre-merge exact-head:
- Core Simulation Tests #647 / run `35795112657` / exact SHA `77492d34f12142bb23969b4969e397b3edd26606` / SUCCESS
- M89 Flutter App #73 / run `35795112726` / exact SHA `77492d34f12142bb23969b4969e397b3edd26606` / SUCCESS

Actual-main:
- Core Simulation Tests #648 / run `35822393141` / successful attempt 6 / exact SHA `f8082a3d4e628a57744333e5ac977b010769ed8d` / SUCCESS
- M89 Flutter App #74 / run `35822393137` / successful attempt 3 / exact SHA `f8082a3d4e628a57744333e5ac977b010769ed8d` / SUCCESS

Core attempts 1–5 timing-only canonical cancellation; no real failure/source patch/workflow mutation.
Flutter attempts 1–2 emulator/ADB infrastructure failure after Analyze/tests/APK PASS; attempt 3 full SUCCESS.

### Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M97 PRODUCT SCOPE**

### M97 kapanış anındaki tarihsel state

Bu bölüm yalnız M97 kapanış anını belgeleyen tarihsel snapshot'tır; güncel authority üstteki CANLI DURUM bölümüdür.

# **M97 — CLOSED / MERGED / PASS**
# **M0–M97 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M98:
**NOT STARTED**

## M96 kapanış sonucu

# M96 — Completed Season League Table I

M96 implementation PR #99 ile squash merge edildi ve actual-main executable proof tamamlandı.

### Product semantic

> Tamamlanan sezonun authoritative final lig puan durumu.

Feature yalnız **read-only completed-season president observation**'dır.

M96 değildir:
- live standings,
- in-season standings,
- table simulation,
- ranking calculation,
- points calculation,
- tactics,
- match-day control,
- fixture editing,
- prediction,
- persistence authority.

### Authority ve ordering

Exact authority chain:

`PlayerPresidentInteractiveSessionCompleted`
→ existing M91 completed-season traversal
→ authoritative `WorldCareerSeason`
→ `worldSeason.leaguesBeforeSeason`
→ controlled club completed league
→ `worldSeason.leagueResults`
→ same completed `LeagueTier`
→ `LeagueSeasonSnapshot.report`
→ `SeasonReport.table`

Critical invariant:

`SeasonReport.table` order authoritative'dir.

Existing `SeasonEngine` canonical sorting:
`points DESC → goalDifference DESC → goalsFor DESC → wins DESC → clubId ASC`.

M96 bu algorithm'ın sahibi değildir:
- production sort yok,
- comparator copy yok,
- table recalculation yok,
- already-sorted `SeasonReport.table` order immutable projection'a birebir taşınır.

### Public types ve immutable row contract

Public types:
- `PlayerPresidentCompletedSeasonLeagueTableSnapshot`
- `PlayerPresidentCompletedSeasonLeagueTableRow`

M91 additive seam:
- `PlayerPresidentCompletedSeasonReport.leagueTable`
- type: `PlayerPresidentCompletedSeasonLeagueTableSnapshot?`
- nullable yalnız M96-specific integrity failure içindir.

M96 row exact value copy:
- position
- clubId
- played
- wins
- draws
- losses
- goalsFor
- goalsAgainst
- goalDifference
- points

Mutable `StandingRow` referansı tutulmaz.
Snapshot rows `List.unmodifiable` ile korunur.
Position = authoritative source table index + 1.
Re-ranking yoktur.

### M91 ownership ve fail-closed contract

`PlayerPresidentCompletedSeasonReport.fromCompleted(...)`
tek completed-season deep authority traversal owner olarak kalır.

M96 ikinci bağımsız `fromCompleted(...)` traversal eklemez.
Snapshot builder yalnız M91'in zaten seçtiği:
- `controlledClubId`
- completed `WorldLeague`
- `SeasonReport`
değerlerini alır.

Existing M91 authority failures whole completed report'u fail etmeye devam eder.

Yalnız M96-specific snapshot/integrity failure:
- `leagueTable = null`
- M91 report usable kalır
- `Puan Durumunu Gör` CTA gizlenir
- synthetic/repaired table üretilmez.

Narrow `StateError` boundary korunur.

### Promotion / relegation semantic

M96 completed-season authority:
`worldSeason.leaguesBeforeSeason`.

M96 table authority olarak kullanmaz:
- `checkpoint.nextSeasonLeagues`
- `worldSeason.leaguesAfterTransition`

Real movement proof:
- M96 tier = `movement.from`
- after-transition tier = `movement.to`
- gerçek moved controlled club üzerinde PASS.

M95 next-season prepared semantics olarak kalır; M96 completed-season final-result semantics'tir.

### Current table evidence

Current canonical world evidence:
- 16 clubs per league
- 30 matches played per club

Bunlar current-world evidence'dir; production authority değildir.
Production row count completed league membership'ten derive edilir.

### Flutter ve lifecycle

M91 completed report içindeki CTA:
`Puan Durumunu Gör`

Placement:
`Sportif Sonuç → Puan Durumunu Gör → Finansal Özet`

Screen:
`PresidentCompletedSeasonLeagueTableScreen`

Title:
`Puan Durumu`

Columns:
`# / Takım / O / G / B / M / AG / YG / AV / P`

Controlled club:
- authoritative position'ında kalır,
- yukarı taşınmaz,
- person icon + bold canonical club name,
- semantics: `Senin Kulübün: <club name>`.

Club-name authority:
`PresidentHomeScreen._clubNameForId(...)`
→ `composition.world.clubs`
→ exactly-one lookup.

Projection club name copy etmez.
Raw club IDs UI'da gösterilmez.

Active Completed:
- M91 report visible
- M96 CTA visible
- `Sonraki Sezona Geç` visible

Lost Completed:
- M91 report visible
- M96 CTA visible
- M93 Career End visible
- `Sonraki Sezona Geç` absent

M96 read-only navigation career continuation authority oluşturmaz.

Mobile/accessibility acceptance:
- real 16-row table PASS
- vertical real scroll PASS
- horizontal real scroll PASS
- 320px PASS
- TextScale 2.0 PASS
- long names PASS
- overflow yok
- raw IDs hidden
- controlled-club semantics PASS

### Save / reopen ve persistence

Acceptance:
- fresh Completed save/reopen parity PASS
- bound saveBack parity PASS
- checkpoint-origin Completed parity PASS
- Lost Completed save/reopen parity PASS

League table restored authoritative Completed result'tan yeniden derive edilir.
Persisted M96 table payload yoktur.
Runtime-only ordered signature yalnız observation/test parity içindir.

> **M65 remains sole persisted game-state authority.**

M96 persistence impact:
**NONE**

Değişmeyen contracts:
- M65
- M74
- M75
- M80
- M77–M88
- saveVersion
- codecs
- checksum
- migrations
- save metadata

M96 league table:
**derived-only / runtime-only / non-persisted**.

### Validation highlights

- exact `SeasonReport.table` order parity PASS
- exact per-row value parity PASS
- no production sorting PASS
- mutable `StandingRow` isolation PASS
- defensive immutable copy PASS
- M91 finalPosition parity PASS
- M91 standing parity PASS
- M91 champion parity PASS
- real promotion/relegation boundary PASS
- malformed M96-only fail-closed PASS
- M91 preserved under M96-only integrity failure PASS
- active Completed UI PASS
- Lost Completed / M93 regression PASS
- active save/reopen PASS
- checkpoint-origin save/reopen PASS
- lost save/reopen PASS
- 320px / TextScale 2.0 / long names / real 2-axis scroll PASS

### CI history

Pre-merge exact-head:
- Core Simulation Tests #640 / run `35688979348` / successful attempt 2 / SUCCESS
- M89 Flutter App #67 / run `35688979321` / attempt 1 / SUCCESS

Actual-main:
- Core Simulation Tests #641 / run `35755010035` / attempt 1 / SUCCESS
- M89 Flutter App #68 / run `35755010083` / successful attempt 2 / SUCCESS

Flutter actual-main attempt 1:
Analyze + 94 tests + APK PASS sonrası emulator/ADB infrastructure-only `Broken pipe (32)` / exit `224` failure. Source/workflow mutation yapılmadı. Attempt 2 aynı exact merge SHA üzerinde full SUCCESS oldu.

Executable authority:
`ae1d1a4d66076b276cc375e1cec5ea1f24039872`

### Technical compass

M96 kapanışında:
- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M96 PRODUCT SCOPE**

### M96 kapanış anındaki tarihsel state

Bu bölüm yalnız M96 kapanış anını belgeleyen tarihsel snapshot'tır; güncel authority üstteki CANLI DURUM bölümüdür.

# **M96 — CLOSED / MERGED / PASS**
# **M0–M96 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M97:
**NOT STARTED**

## M94 kapanış sonucu

# M94 — Prepared Squad Overview I

M94 aşamaları:
- Aşama 1 — **PASS**
- Aşama 2 — **PASS**
- Aşama 3 — **PASS**
- Aşama 4 Final Acceptance — **PASS**
- Aşama 5 Merge + actual-main proof — **PASS**
- Final classification — **A — READY / NO BLOCKER**

### Product semantic

Prepared Squad semantic:

> Bu application session'ın başladığı, oynanmak üzere olan sezonun hazırlanmış aktif playing squad'ı.

Feature yalnız **read-only president observation**'dır.

Bu milestone:
- tactics değildir,
- formation değildir,
- first XI değildir,
- substitutions değildir,
- training değildir,
- player instruction değildir,
- live-match management değildir,
- contract/transfer execution değildir.

Ürün kimliği korunur:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

### Authority

Public projection:
- `PlayerPresidentPreparedSquadSnapshot`
- `PlayerPresidentPreparedSquadPlayer`

Public application seam:
- `PlayerPresidentInteractiveDecisionApplicationSession.preparedSquad`

Playing-squad membership authority:
`player.clubId == controlledClubId`

Bu contract-owned roster değildir.

Loan semantics:
- loaned-in → included
- loaned-out → excluded
- free agent → excluded

`PlayerContract` ownership squad membership authority değildir.

### New game

New-game prepared authority:

`WorldOpeningStateInitializer`
→ `WorldOpeningState.players`

Aynı materialized opening state:
- M92 Prepared Season Dashboard
- M94 Prepared Squad

için kullanılır.

Duplicate `PlayerPoolGenerator` formula yoktur.

### Checkpoint

Checkpoint prepared authority:

`PlayerPresidentTicketPricingRuntimeCheckpoint`
→ nested M65 runtime
→ `WorldCheckpoint`
→ `nextSeasonPlayers`

Filtering:
`player.clubId == controlledClubId`

M94 simulation, replay veya mutation çalıştırmaz.

### Lifecycle

Prepared squad:
- application session kurulurken derive edilir,
- aynı session boyunca immutable observation'dır,
- Pending → same snapshot,
- Resolution → same snapshot,
- M88 saveBack → same snapshot,
- first new-game save/rebound → same semantic/signature,
- next season → fresh prepared snapshot,
- Completed → squad CTA hidden,
- Lost Completed → squad CTA hidden.

M91 Completed report primary kalır.
M93 lost career-end panel primary kalır.

### Flutter

Placement:

M92 `Sezona Hazırlık / Kulüp Özeti` altında:
`Kadroyu Gör`
→ `PresidentPreparedSquadScreen`

Navigation:
- normal `Navigator.push`
- `MaterialPageRoute`
- normal Back
- yeni bottom-nav/global navigation authority yok.

Gösterilen alanlar:
- name
- position
- age
- ability
- potential
- academy marker

Raw `playerId` UI'da gösterilmez.

Position labels:
- Kaleci- Defans
- Orta Saha
- Forvet

Ability/potential raw double authority korunur; UI yalnız `.round()` ile presentation integer gösterir.

Presentation-only sorting:
GK → DEF → MID → FWD → ability DESC → name ASC → playerId ASC.

### Mobile / accessibility

Acceptance evidence:
- 320px width — PASS
- `TextScaler.linear(2.0)` — PASS
- long-name — PASS
- academy badge — PASS
- 28-row real scroll — PASS
- final row reachable
- overflow/exception yok

### Persistence

> **M65 sole persisted game-state authority olarak kalır.**

M94:
- yeni M65 field eklemedi,
- saveVersion değiştirmedi,
- codec değiştirmedi,
- checksum değiştirmedi,
- migration eklemedi,
- M74 değiştirmedi,
- M75 değiştirmedi,
- M80 değiştirmedi,
- M77–M88 schema/routing değiştirmedi,
- persisted squad snapshot oluşturmadı,
- roster cache oluşturmadı,
- UI presentation flag persist etmedi.

Prepared squad:
**derived-only / non-persisted**.

### Technical compass

M94 kapanışında:
- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **OUT OF M94 SCOPE**

### Merge + executable proof

Approved exact PR HEAD:
`70cf564fd0ec18e3d72b96c5a50e31beeb316db4`

Squash merge:
`69821f3b488fabb8c1e7b4b4c939e2fc1ec713c5`

Approved PR tree ve squash merge tree:
`e3c6232cda1f3d92ad9dea9e4c4c4973eb31f209`

Actual-main Core:
- Core Simulation Tests #627
- run ID `35636482572`
- attempt 1
- SUCCESS
- normal test SUCCESS
- canonical SUCCESS
- M0–M88 SUCCESS
- 84/84 canonical Run M steps SUCCESS
- skipped 0 / failed 0 / cancelled 0
- artifacts 0

Actual-main Flutter:
- M89 Flutter App #56
- run ID `35636482563`
- attempt 1
- SUCCESS
- Analyze SUCCESS
- Flutter tests SUCCESS
- debug APK SUCCESS
- emulator SUCCESS
- launch marker PASS
- artifacts 0

Executable authority SHA:
`69821f3b488fabb8c1e7b4b4c939e2fc1ec713c5`

M94 kapanış anındaki tarihsel state:

Bu bölüm yalnız M94 kapanış anını belgeleyen tarihsel snapshot'tır; güncel authority üstteki CANLI DURUM bölümüdür.

# **M94 — CLOSED / MERGED / PASS**
# **M0–M94 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M95:
**NOT STARTED**

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

## 18. M90 kapanış sonucu

M90 — Decision Resolution Feedback I tamamlandı.

### Aşama 1 — Backward-Compatible Runtime Resolution Contract
**PASS.**
M73 additive `submitWithResolution(...)` contract'ı eklendi; legacy `submit(...)` nextStep semantics'i korundu.

### Aşama 2 — Nine-Kind Authoritative Consequence Capture
**PASS.**
Dokuz decision kind'ın tamamında consequence, ilgili domain'in zaten applied authoritative sonucundan capture edilir. Current submit request/sequence'e exact bound'dur; geçmiş replay consequence current result'a sızmaz.

### Aşama 3 — M74 / M76 Additive Resolution Integration
**PASS.**
M74 additive pass-through + accepted-choice transcript davranışı korunur. M76 newGame/checkpoint application boundary'de additive resolution expose eder. M74 formatı, M75 ve M80 encoded schema değişmedi.

### Aşama 4 — Flutter Transient Decision Resolution Feedback Flow
**PASS.**
`GameFlowController` yalnız transient:
- current resolution,
- queued authoritative nextStep
taşır.

Successful submit:
- M76 `submitWithResolution(...)`
- resolution görünür
- next Pending/Completed queue'da tutulur
- `Devam Et` yalnız queued authoritative step'i reveal eder
- yeniden submit/advance/replay/simulation yapmaz
`DecisionResolutionPanel` dokuz public consequence subtype'ını presentation-only render eder.
Flutter gameplay sonucu/formülü yeniden hesaplamaz.

Save davranışı:
- resolution görünürken save mümkündür
- existing M88 `saveBack()` transient feedback'i bozmaz
- fresh M87 save sonrası yeni M88-bound session authoritative olarak adopt edilir
- queued boundary yeni bound session'ın restored current boundary'sine rebase edilir
- resolution persisted değildir
- recreation/load historical resolution restore etmez

### Aşama 5 — Final Acceptance / Regression Audit
**PASS — A) READY / NO BLOCKER.**

Audit sonucunda:
- authority blocker yok
- persistence blocker yok
- legacy compatibility blocker yok
- single-execution blocker yok
- request-binding blocker yok
- nine-kind domain blocker yok
- Flutter business-logic duplication yok
- M87/M88 regression yok
- analyzer boundary regression yok

### Merge

Kullanıcının açık onay verdiği exact PR HEAD:
`e262b69000b65d3fe114557d3ac5016ce48ad174`

PR #93 Ready yapıldı, HEAD tekrar doğrulandı ve değişmedi.

Squash merge:
- `expected_head_sha=e262b69000b65d3fe114557d3ac5016ce48ad174`
- merge SHA: `c81b8f1619820ce8a2fad0a7ebd1e3394ba0ce3b`
- PR #93 — MERGED

### Post-merge actual-main proof

Executable merge SHA:
`c81b8f1619820ce8a2fad0a7ebd1e3394ba0ce3b`

Flutter:
- M89 Flutter App run #18 / `35389490910` — SUCCESS
- real analyze: `No issues found! (ran in 8.4s)`
- 44 tests PASS
- Android debug APK SUCCESS
- Android emulator launch SUCCESS
- artifacts 0

Core:
- Core Simulation Tests run #577 / `35389490940` — SUCCESS
- Analyze SUCCESS
- 429 tests PASS
- canonical M0–M88 SUCCESS
- skipped milestone yok
- M88 marker PASS
- artifacts 0

Final authority sonucu:
> **M65 tek persisted game-state authority olarak kalır.**

M90 resolution/consequence:
- runtime-only,
- M74 transcript değildir,
- M65 değildir,
- save schema değildir,
- save slot metadata değildir,
- reload edilen presentation state değildir.

# **M90 — CLOSED / MERGED / PASS**

### Sonraki davranış

Yeni milestone otomatik seçilmez.

Yeni sohbet veya yeni görevde kullanıcı açık prompt vermeden:
- live GitHub sorgusu başlatma,
- gap scan başlatma,
- branch/PR açma,
- kod yazma,
- CI başlatma,
- yeni milestone numarası belirleme.

Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrula,
2. güncel repo dosyalarını oku,
3. fresh live-main gap scan yap,
4. en küçük doğal authority-safe gap'i öner/uygula.

**Kullanıcı promptu gelmeden DUR.**

## 19. M91 kapanış sonucu

# M91 — President Season Report I

M91, PR #94 ile merge edildi ve actual-main executable proof tamamlandı.

### Final lifecycle

`Final Decision`
→ `Decision Resolution`
→ `Devam Et`
→ authoritative `Completed`
→ `PlayerPresidentCompletedSeasonReport`
→ `PresidentSeasonReportPanel`
→ `Sonraki Sezona Geç`

### Kalıcı application/authority contract

- `PlayerPresidentCompletedSeasonReport` public read-only application projection'dır.
- Projection yalnız exactly-one-season authoritative `Completed` root'tan üretilir.
- Sporting result authoritative completed-season league result'tan gelir.
- Finance authoritative completed-season finance seam'inden gelir; next-season finance state report yerine kullanılmaz.
- Manager, completed-season historical manager'dır; post-season replacement manager geçmiş sezon sonucu olarak gösterilmez.
- Promise sonucu canonical authoritative promise resolution'dır; promise yoksa nullable kalır.
- Flutter nested M71→M65→M48→M47 runtime graph traversal yapmaz.
- `GameFlowController` report için yeni state authority kazanmaz.
- Season Report persisted değildir.
- Authoritative `Completed` restore edilirse report yeniden türetilir.
- `seasonReportShown` yoktur.
- Persisted report snapshot/cache/sidecar yoktur.
- Invalid report authority UI'da fail-closed olur; next-season continuation sunulmaz.
- **M65 sole persisted game-state authority olarak kalır.**
- M74/M75/M80/M77–M88 persistence/application contracts unchanged.
- FBS-01 / FBS-02 / FBS-03 tetiklenmedi.

### Merge ve executable proof

Approved exact PR HEAD:
`fed669993a82744f3f7892b9266c357fd7eb5cb5`

Squash merge executable SHA:
`35bc2c3da9d90f887f1bcfcc2d750a38a413ebd0`

Flutter actual-main:
- M89 Flutter App run #33 / `35447739837`
- final attempt 2 — SUCCESS
- real analyze: `No issues found! (ran in 7.7s)`
- 53 tests PASS
- Android debug APK SUCCESS
- Android emulator launch SUCCESS
- marker: `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

Core actual-main:
- Core Simulation Tests run #596 / `35447739836`
- final attempt 4 — SUCCESS
- Analyze SUCCESS
- 438 tests PASS
- canonical M0–M88 tamamı SUCCESS
- skipped milestone 0
- M88 marker PASS
- artifacts 0

İlk üç canonical attempt source/assertion failure olmadan timing-only cancellation yaşadı; exact executable SHA üzerinde retry kuralı uygulandı ve attempt 4 tam SUCCESS oldu. Flutter attempt 1'de emulator package service `Broken pipe (32)` infrastructure failure'ı yaşandı; aynı exact SHA üzerinde attempt 2 tam SUCCESS oldu.

M91 post-merge actual-main executable acceptance — **PASS**.

# **M91 — CLOSED / MERGED / PASS**
# **M0–M91 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

Yeni milestone otomatik seçilmez. Kullanıcı yeni geliştirme promptu verdiğinde live `main` üzerinden fresh gap scan yapılır; o zamana kadar M92 seçilmez, branch/PR açılmaz ve yeni feature başlatılmaz.



## 20. M92 kapanış sonucu

# M92 — Prepared Season Dashboard I

M92, PR #95 ile squash merge edildi ve actual-main executable proof tamamlandı.

### Merge kimliği

Approved exact PR HEAD:
`f16ee1142ab8f70ea12ef4d0e7e389083d5a142a`

Executable squash merge SHA:
`7f46f05ba0aacf9615ebe85ac7c5ba8d8ef02c51`

M92:
- Aşama 1 — PASS
- Aşama 2 — PASS
- Aşama 3 — PASS
- Aşama 4 — PASS
- Aşama 5 Final Acceptance — PASS
- Merge — COMPLETED
- Post-merge actual-main executable proof — PASS

Final classification:
**A — READY / NO BLOCKER**

### Prepared-season semantic

M92 yüzeyi:
**Sezona Hazırlık / Kulüp Özeti**

Amaç:
“Bu sezona hangi hazırlanmış authoritative kulüp durumuyla girdim?”

Prepared dashboard:
- live/current değildir,
- decision sonrası mutate olmaz,
- season-opening/prepared snapshot'tır,
- aynı application session boyunca immutable observation olarak kalır.

### Public application contract

Public read-only type:
`PlayerPresidentPreparedSeasonDashboardSnapshot`

Public application seam:
`PlayerPresidentInteractiveDecisionApplicationSession.preparedSeasonDashboard`

Snapshot:
- non-authoritative,- non-persisted,
- non-serialized,
- gameplay decision authority değildir,
- application/UI observation'dır.

Prepared content:
- controlled club,
- prepared season index,
- prepared league/tier,
- opening/prepared cash,
- opening/prepared debt,
- fan overall trust,
- president tenure,
- player-president control state,
- assigned manager,
- board relationship,
- academy/stadium/training-ground levels,
- nullable active sponsor.

### Canonical opening initialization

Finance:
- `WorldOpeningStateInitializer`
- existing `WorldCareerEngine`
- canonical `BasicEconomyEngine.initialStates(...)`

aynı opening authority zincirini kullanır. Dashboard-specific finance formula yoktur.

Manager:
- `ManagerOpeningStateInitializer` canonical opening manager initialization'ını shared hale getirir,
- `ManagerCareerController` ve M92 new-game prepared snapshot aynı initializer'ı kullanır,
- duplicate manager-selection algorithm yoktur.

### Tenure / lost-control semantic

Player control lost olduktan sonra:
- original player-president yeniden incumbent olamaz,
- ancak gelecekteki her incumbent'ın ilk `successorPresidentId` ile aynı olması gerekmez.

İlk successor metadata'sı tüm gelecekteki president identity'leri için authority değildir.

Bu düzeltme election authority'yi, persisted loss metadata'sını veya M65 authority'yi değiştirmez.

### Flutter contract ve lifecycle

Presentation widget:
`PresidentPreparedSeasonDashboardPanel`

`GameFlowController` yalnız `session.preparedSeasonDashboard` snapshot'ını read-only forward eder.

Flutter'da:
- duplicate dashboard state yok,
- dashboard cache yok,
- recomputation yok,
- checkpoint traversal yok,
- finance calculation yok,
- manager/sponsor selection yok,
- facility initialization yok.

Lifecycle:
- Pending → Prepared Dashboard + `DecisionPanel`
- Decision Resolution → Prepared Dashboard + `DecisionResolutionPanel`
- Completed → prepared dashboard yok; yalnız `PresidentSeasonReportPanel`
- Next season → completed checkpoint → yeni application session → yeni prepared snapshot

Old snapshot carry-over/cache edilmez.

Responsive Flutter testleri:
- 320px viewport,
- textScale 1.5,
- uzun manager adı,
- uzun sponsor adı

ile horizontal overflow/exception olmadığını doğrular.

### M91 / M92 ayrımı

M91:
`President Season Report` = completed-season authoritative result.

M92:
`Prepared Season Dashboard` = season-opening prepared observation.

Finance semantiği:
- M91 = completed-season finance,
- M92 = opening/prepared finance state.

### Persistence / authority sonucu

> **M65 sole persisted game-state authority olarak kalır.**

M92:
- yeni persisted authority oluşturmadı,
- save field eklemedi,
- save schema/version değiştirmedi,
- codec/checksum değiştirmedi,
- sidecar/cache oluşturmadı.

M74 unchanged.
M75 unchanged.
M80 unchanged.
M77–M88 unchanged.

Prepared dashboard:
- M65'e yazılmaz,
- M75 bundle'a yazılmaz,
- M80 bootstrap payload'a yazılmaz,
- M74 transcript metadata değildir,
- M87/M88 save identity authority değildir.

Save/reload parity:
- fresh new-game same inputs → same prepared snapshot,
- M80 save/reload → same prepared semantics,
- same M65 checkpoint → same prepared snapshot,
- M75 encode/restore → same semantics,
- M87 first save / M88 rebound → same prepared snapshot,
- M88 saveBack → snapshot mutation yok,
- next-season new session → new prepared snapshot.

Technical compass:
- FBS-01 — NOT TRIGGERED
- FBS-02 — NOT TRIGGERED
- FBS-03 — NOT TRIGGERED

### Actual-main executable proof

Executable SHA:
`7f46f05ba0aacf9615ebe85ac7c5ba8d8ef02c51`

Flutter:
- M89 Flutter App run #37 / `35513781177`
- SUCCESS
- Analyze SUCCESS / No issues found
- 61 tests PASS
- Android debug APK SUCCESS
- Android emulator/smoke SUCCESS
- artifacts 0

Core:
- Core Simulation Tests run #604 / `35513781186`
- final successful attempt 12
- SUCCESS
- Analyze SUCCESS
- 447 tests PASS
- canonical M0–M88 SUCCESS
- 84 canonical milestone steps SUCCESS
- skipped 0
- failed 0
- cancelled 0
- artifacts 0

Timing-only attempts:
- 8 → M70 civarı cancellation
- 9 → M73 cancellation
- 10 → M69 cancellation
- 11 → M70 cancellation
- 12 → COMPLETE SUCCESS

Source/assertion failure görülmedi; final PASS yalnız attempt 12'nin tek full-success sonucu ile verildi.

# **M92 — CLOSED / MERGED / PASS**
# **M0–M92 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

Yeni milestone otomatik seçilmez. Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrula,
2. güncel repo docs oku,
3. central technical-development compass triggerlarını kontrol et,
4. fresh live-main gap scan yap,
5. en küçük doğal authority-safe gap'i belirle.

Eski sohbetten M93 tahmin edilmez.

## M93 kapanış sonucu

# M93 — Career End / Presidency Loss I

M93:
- Aşama 1 — PASS
- Aşama 2 — PASS
- Aşama 3 — PASS
- Aşama 4 Final Acceptance — PASS
- Merge — COMPLETED
- Post-merge actual-main executable proof — PASS

Final classification:

**A — READY / NO BLOCKER**

### M93 authority semantic

Career-end source of truth:

`PlayerPresidentTenureControlState`

Completed boundary authority:

`completed.result.checkpoint.tenureControl`

Career ended iff:

`tenureControl.status == lost`

Authority değildir:
- M92 prepared dashboard
- `successorPresidentId` heuristic
- Flutter local flag
- manager/sponsor/election inference

### Application contract

Public read-only seam:

`PlayerPresidentInteractiveDecisionApplicationSession.completedTenureControl`

Semantik:

`_session.completed?.result.checkpoint.tenureControl`
Pending/non-completed → `null`

Completed → authoritative final tenure-control state.

`continuePlayerCareerToNextSeason()`:
- only Completed
- active → authoritative completed checkpoint üzerinden yeni application session
- lost → fail-closed
- generic resume/load LOST checkpoint için çalışmaya devam eder

### Core lost-presidency behavior

Lost presidency core simulation'ı durdurmaz.

Generic LOST checkpoint resume:
- player providers tenure gate ile kapanabilir
- player Pending oluşmayabilir
- AI simulation devam edebilir
- direct Completed üretilebilir

M93 yalnız player-controlled next-season continuation'ı kapatır.

### Flutter contract

Presentation widget:
`PresidentCareerEndPanel`

Completed active:
M91 President Season Report + `Sonraki Sezona Geç`

Completed lost:
M91 President Season Report + `PresidentCareerEndPanel`

Lost durumda next-season CTA yoktur.

Career End:
- **Başkanlık Görevin Sona Erdi**
- **Kulüp yönetimindeki görevin bu sezon sonunda sona erdi.**

`lostAtCompletedSeason` doğrudan completed-season ordinal'dır.

`4 → "4. sezon sonunda."`

İkinci +1 conversion yoktur.

Successor adı M93-I'de gösterilmez; raw successor ID UI'a sızdırılmaz.

Ana Menü:
`Navigator.popUntil(... route.isFirst)`

### Save / load contract

- Lost Completed save edilebilir.
- Save button kariyer sonu nedeniyle kapatılmaz.
- Reopen aynı authoritative lost tenure state'i yeniden üretir.
- M75 deterministic restore korunur.
- M87/M88 save/load/binding contract değişmez.
- persisted `careerEnded`, `gameOver`, `gameOverShown`, `lossScreenShown` yoktur.

### M92 regression semantic

M92 opening snapshot'ta `playerControlActive == true` iken aynı season final Completed boundary'de `tenureControl.status == lost` olabilir.

Bu contradiction değildir.

- M92 = season-opening immutable prepared observation
- M93 = completed-boundary career-end authority

### Persistence / authority result

> **M65 sole persisted game-state authority olarak kalır.**

M93:
- yeni M65 field eklemedi
- saveVersion değiştirmedi
- codec/checksum değiştirmedi
- M74 formatını değiştirmedi
- M75 bundle formatını değiştirmedi
- M80 formatını değiştirmedi
- M77–M88 routing/schema değiştirmedi
- cache/sidecar/save family eklemedi

FBS:
- FBS-01 — **NOT TRIGGERED**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**

### Merge ve executable proof

Approved exact PR HEAD:
`9cf2e7db524da01686a9070a212d36c27e26980d`

Executable squash merge SHA:
`56c8367445e76c648dae4215548681bbfbe31c2c`

Core actual-main:
- Core Simulation Tests #618
- run ID `35569882609`
- attempt 1
- SUCCESS
- Analyze SUCCESS
- 452 tests PASS
- canonical M0–M88 ALL SUCCESS
- 84 canonical Run M steps SUCCESS
- skipped 0
- failed 0
- cancelled 0
- artifacts 0

Flutter actual-main:
- M89 Flutter App #50
- run ID `35569882525`
- SUCCESS
- Analyze SUCCESS / No issues found
- 67 tests PASS
- Android debug APK SUCCESS
- Android emulator launch SUCCESS
- marker: `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`

M93 post-merge actual-main executable acceptance — **PASS**

# **M93 — CLOSED / MERGED / PASS**
# **M0–M93 — CLOSED / MERGED / PASS**

Aktif milestone:

**YOK**

Yeni milestone otomatik seçilmez.

Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrulanır
2. güncel repo docs okunur
3. central technical-development compass kontrol edilir
4. fresh live-main gap scan yapılır
5. en küçük natural authority-safe gap belirlenir

Eski sohbetten M94 tahmin edilmez.

Kullanıcı yeni prompt vermeden:
- M94 seçme
- gap scan başlatma
- branch/PR açma
- kod yazma
- CI başlatma

## M95 kapanış sonucu

# M95 — Prepared Season Fixtures I

M95 implementation PR #98 ile squash merge edildi ve actual-main executable proof tamamlandı.

### Product semantic

Prepared Season Fixtures semantic:

> Bu application session’ın başladığı, oynanmak üzere olan sezonun hazırlanmış lig fikstürü.

M95 yalnız **read-only president observation**'dır.

Public types:
- `PlayerPresidentPreparedSeasonFixturesSnapshot`
- `PlayerPresidentPreparedSeasonFixture`

Public application seam:
- `PlayerPresidentInteractiveDecisionApplicationSession.preparedSeasonFixtures`

M95 live score, standings, tarih/saat authority, tactics, match-day control, prediction veya fixture editing/rescheduling değildir.

### Fixture authority

Canonical fixture pairing authority:

`FixtureGenerator.generateDoubleRoundRobin(...)`

Critical ordering invariant:

`league.clubIds`
→ canonical clubs by ID
→ ordered club list
→ existing `FixtureGenerator`
→ controlled-club fixture subset

`league.clubIds` sırası aynen korunur. M95 yeni bir scheduling algorithm sahibi değildir.

### New-game source

New-game M95 source:

existing materialized `WorldOpeningState`
→ controlled club’ın prepared league’i
→ ordered `league.clubIds`
→ existing `FixtureGenerator`

M92 Prepared Season Dashboard, M94 Prepared Squad ve M95 Prepared Season Fixtures aynı prepared-opening semantic ailesindedir.

### Checkpoint source

Checkpoint M95 source:

nested M65 `WorldCheckpoint.nextSeasonLeagues`

Season:
`checkpoint.nextSeasonIndex`

Promotion/relegation sonrası next-season membership kullanılır. Previous completed league authority olarak kullanılmaz.

### Fixture contract

Current canonical 16-team league:
- 30 controlled-club fixture
- 15 home
- 15 away
- rounds 1..30

Production authority generic kalır:

`controlled fixtures = 2 * (league size - 1)`

Hard-coded 30 scheduling authority yoktur.

UI:
- `Fikstür`
- `Fikstürü Gör`
- `N. Hafta`
- `Ev`
- `Deplasman`

UI'da live score, standings, dates, match times, tactics, match-day control, prediction veya fixture editing yoktur.

### Flutter

M92 prepared context altında sibling actions:
- `Kadroyu Gör`
- `Fikstürü Gör`

Fixture screen:
`PresidentPreparedSeasonFixturesScreen`

Prepared visibility:
- Pending → visible
- Resolution → visible
- Completed → hidden
- M93 Lost Completed → hidden

Mobile/accessibility proof:
- real 30-row scroll PASS
- 320px PASS
- `TextScaler.linear(2.0)` PASS
- long names PASS
- raw fixture/opponent IDs visible değil

### Persistence / authority

> **M65 = sole persisted game-state authority**

M95 persistence impact:
**NONE**

Değişmeyen authority/contracts:
- M65 schema
- M74
- M75
- M80
- M77–M88
- saveVersion
- codecs
- checksum
- migration
- save metadata

Prepared fixtures:
**derived-only / runtime-only / non-persisted**.

### Validation highlights

M95 acceptance proof:
- exact `SeasonEngine` tuple parity PASS
- `league.clubIds` order-sensitivity proof PASS
- M80 bootstrap/transcript independence PASS
- M65 codec observation parity PASS
- M75 restore parity PASS
- same real player-president checkpoint promotion/relegation proof PASS
- Pending/Resolution same snapshot PASS
- first-save rebound semantic parity PASS
- M88 saveBack PASS
- next-season fresh snapshot PASS
- M91/M92/M93/M94 regressions PASS

### Merge + actual-main executable proof

Approved exact PR HEAD:
`a50a5b13f9580f5f51ee1b88a8134036dc406e06`

Executable squash merge SHA:
`1faa49169746f78e6c2dc4b9da5a9fddaba04884`

Core actual-main:
- Core Simulation Tests #633
- run ID `35652917756`
- successful attempt 6
- SUCCESS
- normal `test` SUCCESS
- canonical M0–M88 ALL SUCCESS
- 84 physical Run-M steps because M19–M24 is one combined canonical step
- failed Run-M 0
- cancelled Run-M 0
- skipped Run-M 0
- artifacts 0

Canonical timing history:
- attempts 1–5 yalnız timing-only cancellation yaşadı
- gerçek assertion/exception/deterministic contract failure yoktu
- source patch yapılmadı
- attempt 6 aynı exact executable SHA üzerinde full canonical SUCCESS oldu

Flutter actual-main:
- M89 Flutter App #61
- run ID `35652917456`
- attempt 1
- SUCCESS
- Analyze SUCCESS
- 91 tests PASS
- debug APK SUCCESS
- emulator SUCCESS
- marker: `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

Executable authority:
`1faa49169746f78e6c2dc4b9da5a9fddaba04884`

### Technical compass

M95 kapanışında:
- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **OUT OF M95 SCOPE**

### M95 kapanış anındaki tarihsel state

M95 closure sırasında M96 henüz başlamamıştı. Güncel authority bu belgenin üstteki
**CANLI DURUM** bölümündeki M96 closure state'idir.
