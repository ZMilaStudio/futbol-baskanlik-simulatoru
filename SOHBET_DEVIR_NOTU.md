# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 22 Eylül 2026

Bu dosyanın amacı yeni sohbetin projeyi doğru current authority ile devralmasıdır.

# EN ÖNEMLİ KURAL

**Yeni sohbet açıldığında kullanıcı yeni geliştirme promptu vermeden HİÇBİR ŞEY YAPMA.**

Kaynak önceliği:

**Live GitHub > güncel repo docs > central technical-development compass > eski sohbet bilgisi.**

## 1. Güncel proje durumu

Repo:
`ZMilaStudio/futbol-baskanlik-simulatoru`

# **M0–M95 — CLOSED / MERGED / PASS**

Son kapanan milestone:
**M95 — Prepared Season Fixtures I**

PR #98:
**MERGED / CLOSED**

Approved exact PR HEAD:
`a50a5b13f9580f5f51ee1b88a8134036dc406e06`

Executable squash merge SHA:
`1faa49169746f78e6c2dc4b9da5a9fddaba04884`

Core actual-main:
- Core Simulation Tests #633
- run ID `35652917756`
- successful attempt 6
- **SUCCESS**
- normal `test` SUCCESS
- canonical M0–M88 ALL SUCCESS
- 84 physical Run-M steps because M19–M24 is one combined canonical step
- failed 0 / cancelled 0 / skipped 0
- artifacts 0

Attempts 1–5 yalnız timing-only canonical cancellation yaşadı; gerçek assertion/exception/deterministic contract failure yoktu ve source patch yapılmadı. Attempt 6 aynı exact executable SHA üzerinde full canonical SUCCESS oldu.

Flutter actual-main:
- M89 Flutter App #61
- run ID `35652917456`
- attempt 1
- **SUCCESS**
- Analyze SUCCESS
- 91 tests PASS
- debug APK SUCCESS
- emulator SUCCESS
- `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

Executable authority SHA:
`1faa49169746f78e6c2dc4b9da5a9fddaba04884`

## 2. M95 essentials

M95 = **Prepared Season Fixtures I**.

Semantic:

> Bu application session’ın başladığı, oynanmak üzere olan sezonun hazırlanmış lig fikstürü.

Feature read-only president observation'dır.

Public types:
- `PlayerPresidentPreparedSeasonFixturesSnapshot`
- `PlayerPresidentPreparedSeasonFixture`

Application seam:
- `PlayerPresidentInteractiveDecisionApplicationSession.preparedSeasonFixtures`

Canonical pairing authority:
`FixtureGenerator.generateDoubleRoundRobin(...)`

Critical invariant:
`league.clubIds` order aynen korunur.

Exact authority flow:
`league.clubIds → canonical clubs by ID → ordered club list → existing FixtureGenerator → controlled club subset`

M95 yeni scheduling algorithm sahibi değildir.

New-game source:
existing materialized `WorldOpeningState` → controlled club prepared league → ordered `league.clubIds` → existing `FixtureGenerator`.

M92 / M94 / M95 aynı prepared-opening semantic ailesindedir.

Checkpoint source:
nested M65 `WorldCheckpoint.nextSeasonLeagues`.

Season:
`checkpoint.nextSeasonIndex`.

Promotion/relegation sonrası next-season membership kullanılır; previous completed league kullanılmaz.

Current canonical 16-team league:
- 30 controlled fixtures
- 15 home
- 15 away
- rounds 1..30

Production formula generic:
`2 * (league size - 1)`.

Flutter:
- M92 prepared context altında sibling `Kadroyu Gör` + `Fikstürü Gör`
- screen: `PresidentPreparedSeasonFixturesScreen`
- Pending visible
- Resolution visible
- Completed hidden
- M93 Lost Completed hidden
- real 30-row scroll PASS
- 320px PASS
- TextScale 2.0 PASS
- long names PASS
- raw fixture/opponent IDs görünmez

## 3. Persistence / authority

> **M65 = sole persisted game-state authority**

M95 prepared fixtures:
- derived-only
- runtime-only
- non-persisted

M95 şu persistence authority/contracts alanlarını değiştirmedi:
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

Validation highlights:
- exact SeasonEngine tuple parity PASS
- league.clubIds order-sensitivity PASS
- M80 bootstrap/transcript independence PASS
- M65 codec observation parity PASS
- M75 restore parity PASS
- real player-president checkpoint promotion/relegation PASS
- Pending/Resolution same snapshot PASS
- first-save rebound semantic parity PASS
- M88 saveBack PASS
- next-season fresh snapshot PASS
- M91/M92/M93/M94 regressions PASS

## 4. Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **OUT OF M95 SCOPE**

## 5. Current status

# **M95 — CLOSED / MERGED / PASS**
# **M0–M95 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M96:
**NOT STARTED**

## 6. Next work rule

Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrula
2. current repo docs oku
3. central technical-development compass kontrol et
4. fresh live-main gap scan yap
5. sonra yeni milestone adayını değerlendir

Eski sohbetten M96 uydurma.

Kullanıcı yeni prompt vermeden:
- M96 seçme
- gap scan başlatma
- branch/PR açma
- kod yazma
- CI başlatma
- yeni feature başlatma

# DUR

**Kullanıcı yeni prompt vermeden hiçbir işlem yapma.**
