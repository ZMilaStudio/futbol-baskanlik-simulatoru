# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 24 Eylül 2026

Bu dosyanın amacı yeni sohbetin projeyi doğru current authority ile devralmasıdır.

# EN ÖNEMLİ KURAL

**Yeni sohbet açıldığında kullanıcı yeni geliştirme promptu vermeden HİÇBİR ŞEY YAPMA.**

Kaynak önceliği:
**Live GitHub > güncel repo docs > central technical-development compass > eski sohbet bilgisi.**

## 1. Güncel proje durumu

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

# **M0–M98 — CLOSED / MERGED / PASS**

Last closed:
**M98 — Completed Season Finance Statement I**

PR #101: **MERGED / CLOSED**

Approved exact PR HEAD:
`aea64fb232e374089c79babdf4c2c6b77c2899c0`

Executable squash merge SHA:
`29a6cab58e4da45de3cdad342b521204ebb27851`

Executable authority:
`29a6cab58e4da45de3cdad342b521204ebb27851`

Core actual-main:
- #652 / run `35931227265` / attempt 1 / SUCCESS
- 501 tests PASS
- canonical M0–M88 ALL SUCCESS
- final M88 step PASS
- artifacts 0

Flutter actual-main:
- #77 / run `35931227290` / attempt 1 / SUCCESS
- Analyze SUCCESS
- 101 tests PASS
- APK SUCCESS
- emulator SUCCESS
- `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

## 2. M98 essentials

Semantic:
> Tamamlanan sezonun authoritative finansal dökümü.

Feature: **read-only completed-season president observation**.

Authority:
`PlayerPresidentInteractiveSessionCompleted`
→ `PlayerPresidentCompletedSeasonReport.fromCompleted(...)`
→ existing M91 finance selection
→ authoritative `ClubFinanceSeason`
→ `report.finance`.

Architecture:
- **A — DIRECT EXISTING M91 FINANCE SEAM**
- direct `report.finance`
- no second completed-season traversal
- no new core finance DTO
- no new finance snapshot authority
- core production impact ZERO

Five sections:
- Açılış Durumu
- Operasyonel Gelirler
- Faaliyet ve Faiz Giderleri
- Finansman / Nakit Hareketleri
- Kapanış Durumu

Finance semantics:
- `totalRevenue = centralRevenue + sponsorRevenue + matchdayRevenue + prizeRevenue`
- transfer installment income operational revenue değildir
- emergency borrowing revenue değildir
- `profitAndLossExpenses = wageExpense + operatingExpense + interestExpense`
- principal repayment P&L expense değildir
- transfer installment expense P&L expenses içine dahil değildir
- `operatingResult = totalRevenue - profitAndLossExpenses`

Accounting-safe labels:
- Toplam operasyonel gelir
- Toplam faaliyet ve faiz gideri
- Faaliyet sonucu (faiz dahil)

Flutter:
- CTA: **Finansal Dökümü Gör**
- key: `completed-season-finance-statement-button`
- existing Finansal Özet içinde
- screen: `PresidentCompletedSeasonFinanceStatementScreen`
- AppBar: **Sezon Finansları**
- inputs: `report.finance`, `report.seasonIndex`, `report.leagueName`
- raw internal IDs hidden
- `Money.toString()` reused
- shared `financialHealthLabel(...)`

Lifecycle:
- Active Completed: M91 + M96 + M97 + M98 + Sonraki Sezona Geç
- Lost Completed: M91 + M96 + M97 + M98 + M93 Career End
- Lost Completed: Sonraki Sezona Geç absent
- M93 guard preserved

Accessibility:
- real vertical ListView PASS
- 320px PASS
- TextScale 2.0 PASS
- large Money PASS
- negative operating result PASS
- zero financing rows visible PASS
- no overflow/clipping PASS

Persistence:
- **NONE**
- **M65 sole persisted game-state authority**
- no saveVersion/codec/checksum/migration/namespace/save metadata change
- no persisted financeStatement/history/viewed/cache/sidecar/new save family

Implementation scope:
- 4 production files
- 3 test files
- 7 exact
- core production 0
- persistence 0
- workflow 0

Pre-merge CI:
- Core #651 / run `35912289990` / successful attempt 17 / exact HEAD `aea64fb232e374089c79babdf4c2c6b77c2899c0` / SUCCESS
- Flutter #76 / run `35912290042` / attempt 1 / same exact HEAD / SUCCESS
- Core attempts 1–16 timing/cancellation only; no source/workflow/timeout mutation

Actual-main:
- Core #652 / run `35931227265` / attempt 1 / exact executable SHA `29a6cab58e4da45de3cdad342b521204ebb27851` / SUCCESS
- Flutter #77 / run `35931227290` / attempt 1 / same exact executable SHA / SUCCESS

## 3. Technical compass

- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE / UNCHANGED**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **AUDIT COMPLETE / activation requires separate user approval / OUT OF M98 PRODUCT SCOPE**

## 4. Current status

# **M98 — CLOSED / MERGED / PASS**
# **M0–M98 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M99:
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
- M99 seçme
- gap scan başlatma
- branch/PR açma
- kod yazma
- CI başlatma
- technical compass activation başlatma
- yeni feature başlatma

# DUR
