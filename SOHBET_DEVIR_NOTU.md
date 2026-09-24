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
