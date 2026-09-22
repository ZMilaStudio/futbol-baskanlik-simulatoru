# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 23 Eylül 2026

Bu dosyanın amacı yeni sohbetin projeyi doğru current authority ile devralmasıdır.

# EN ÖNEMLİ KURAL

**Yeni sohbet açıldığında kullanıcı yeni geliştirme promptu vermeden HİÇBİR ŞEY YAPMA.**

Kaynak önceliği:

**Live GitHub > güncel repo docs > central technical-development compass > eski sohbet bilgisi.**

## 1. Güncel proje durumu

Repo:
`ZMilaStudio/futbol-baskanlik-simulatoru`

# **M0–M96 — CLOSED / MERGED / PASS**

Son kapanan milestone:
**M96 — Completed Season League Table I**

PR #99:
**MERGED / CLOSED**

Approved exact PR HEAD:
`d5d90ba9c0ce7389ff66a213d979b8315cadd4ef`

Executable squash merge SHA:
`ae1d1a4d66076b276cc375e1cec5ea1f24039872`

Core actual-main:
- Core Simulation Tests #641
- run ID `35755010035`
- attempt 1
- **SUCCESS**
- normal test SUCCESS
- 495 tests PASS
- canonical M0–M88 ALL SUCCESS
- 84 physical Run-M steps; M19–M24 combined
- failed 0 / cancelled 0 / skipped 0
- artifacts 0

Flutter actual-main:
- M89 Flutter App #68
- run ID `35755010083`
- successful attempt 2
- **SUCCESS**
- Analyze SUCCESS
- 94 tests PASS
- debug APK SUCCESS
- emulator SUCCESS
- `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

Flutter attempt 1 aynı exact merge SHA üzerinde Analyze + 94 tests + APK PASS sonrası emulator/ADB infrastructure-only `Broken pipe (32)` / exit `224` ile düştü. Source failure, source patch veya workflow mutation yoktu. Attempt 2 aynı SHA üzerinde full SUCCESS oldu.

Executable authority SHA:
`ae1d1a4d66076b276cc375e1cec5ea1f24039872`

## 2. M96 essentials

M96 = **Completed Season League Table I**.

Semantic:

> Tamamlanan sezonun authoritative final lig puan durumu.

Feature read-only completed-season president observation'dır.

Authority:
`PlayerPresidentInteractiveSessionCompleted`
→ existing M91 completed-season traversal
→ authoritative `WorldCareerSeason`
→ `worldSeason.leaguesBeforeSeason`
→ controlled club completed league
→ `worldSeason.leagueResults`
→ same completed `LeagueTier`
→ `LeagueSeasonSnapshot.report`
→ `SeasonReport.table`.

Critical invariant:
`SeasonReport.table` order authoritative'dir.

M96:
- sort yapmaz,
- ranking comparator kopyalamaz,
- standings/table recalculation yapmaz,
- points authority oluşturmaz.

Public types:
- `PlayerPresidentCompletedSeasonLeagueTableSnapshot`
- `PlayerPresidentCompletedSeasonLeagueTableRow`

M91 additive seam:
- `PlayerPresidentCompletedSeasonReport.leagueTable`
- `PlayerPresidentCompletedSeasonLeagueTableSnapshot?`

`PlayerPresidentCompletedSeasonReport.fromCompleted(...)`
tek completed-season deep traversal owner olarak kalır.
M96 ikinci bağımsız `fromCompleted(...)` traversal eklemez.

Rows immutable value-copy'dir:
- mutable `StandingRow` referansı tutulmaz,
- `List.unmodifiable`,
- position = source table index + 1,
- no re-ranking.

M96-specific integrity failure:
- `leagueTable = null`
- M91 report usable kalır
- Puan Durumu CTA hidden
- synthetic/repaired table yok.

## 3. Promotion/relegation boundary

M96 completed-season membership/tier authority:
`worldSeason.leaguesBeforeSeason`.

Table authority değildir:
- `checkpoint.nextSeasonLeagues`
- `worldSeason.leaguesAfterTransition`

Real movement test:
- M96 tier = `movement.from`
- next/after-transition tier = `movement.to`
- PASS.

Bu sınır M95'ten bilinçli olarak farklıdır:
- M95 = next-season prepared semantics
- M96 = completed-season final-result semantics.

## 4. Flutter / lifecycle

M91 report CTA:
**Puan Durumunu Gör**

Placement:
`Sportif Sonuç → Puan Durumunu Gör → Finansal Özet`

Screen:
`PresidentCompletedSeasonLeagueTableScreen`

Title:
**Puan Durumu**

Columns:
`# / Takım / O / G / B / M / AG / YG / AV / P`

Own club:
- authoritative position'ında kalır,
- reorder edilmez,
- person icon + bold canonical club name,
- semantics `Senin Kulübün: <club name>`.

Club display authority:
`PresidentHomeScreen._clubNameForId(...)`
→ `composition.world.clubs`
→ exactly-one lookup.

Raw club IDs görünmez.

Active Completed:
- M91 visible
- M96 CTA visible
- Sonraki Sezona Geç visible

Lost Completed:
- M91 visible
- M96 CTA visible
- M93 Career End visible
- Sonraki Sezona Geç absent

M96 read-only navigation career continuation authority oluşturmaz.

Acceptance:
- real 16-row table PASS
- vertical real scroll PASS
- horizontal real scroll PASS
- 320px PASS
- TextScale 2.0 PASS
- long names PASS
- raw IDs hidden
- controlled-club semantics PASS

## 5. Persistence / authority

> **M65 = sole persisted game-state authority**

M96 league table:
- derived-only
- runtime-only
- non-persisted

Persistence impact:
**NONE**

Unchanged:
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

Save/reopen proof:
- fresh Completed parity PASS
- bound saveBack parity PASS
- checkpoint-origin Completed parity PASS
- Lost Completed parity PASS

Runtime-only ordered signature yalnız observation/test parity içindir.

## 6. Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M96 PRODUCT SCOPE**

## 7. Current status

# **M96 — CLOSED / MERGED / PASS**
# **M0–M96 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M97:
**NOT STARTED**

## 8. Next work rule

Kullanıcı yeni geliştirme istediğinde:
1. live `main` doğrula
2. current repo docs oku
3. central technical-development compass kontrol et
4. fresh live-main gap scan yap
5. yeni milestone adayını değerlendir
6. product/authority contract'ını implementation öncesi kilitle

M97'yi bu devir notundan uydurma.

Kullanıcı yeni prompt vermeden:
- M97 seçme
- gap scan başlatma
- branch/PR açma
- kod yazma
- CI başlatma
- technical compass activation başlatma
- yeni feature başlatma

# DUR

**Kullanıcı yeni prompt vermeden hiçbir işlem yapma.**
