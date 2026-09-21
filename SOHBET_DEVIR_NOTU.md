# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 21 Eylül 2026

Bu dosyanın amacı yeni sohbetin projeyi doğru current authority ile devralmasıdır.

# EN ÖNEMLİ KURAL

**Yeni sohbet açıldığında kullanıcı yeni geliştirme promptu vermeden HİÇBİR ŞEY YAPMA.**

Kaynak önceliği:

**Live GitHub > güncel repo docs > central technical-development compass > eski sohbet bilgisi.**

## 1. Güncel proje durumu

Repo:
`ZMilaStudio/futbol-baskanlik-simulatoru`

# **M0–M94 — CLOSED / MERGED / PASS**

Son kapanan milestone:

**M94 — Prepared Squad Overview I**

PR #97:
**MERGED / CLOSED**

Approved exact PR HEAD:
`70cf564fd0ec18e3d72b96c5a50e31beeb316db4`

Executable merge SHA:
`69821f3b488fabb8c1e7b4b4c939e2fc1ec713c5`

Approved PR tree = squash merge tree:
`e3c6232cda1f3d92ad9dea9e4c4c4973eb31f209`

Core actual-main:
- Core Simulation Tests #627
- run ID `35636482572`
- attempt 1
- **SUCCESS**
- normal test SUCCESS
- canonical M0–M88 SUCCESS
- skipped 0 / failed 0 / cancelled 0
- artifacts 0

Flutter actual-main:
- M89 Flutter App #56
- run ID `35636482563`
- attempt 1
- **SUCCESS**
- Analyze SUCCESS
- Flutter tests SUCCESS
- debug APK SUCCESS
- emulator SUCCESS
- `M89_FLUTTER_ANDROID_LAUNCH_PASS package=com.zmilastudio.futbol_baskanlik_app`
- artifacts 0

Executable authority SHA:
`69821f3b488fabb8c1e7b4b4c939e2fc1ec713c5`

## 2. M94 essentials

M94 = **Prepared Squad Overview I**.

Product semantic:
- read-only season-opening prepared playing-squad observation,
- başkan gözlemidir; technical-director gameplay değildir.

Authority:
- public projection: `PlayerPresidentPreparedSquadSnapshot`
- player value: `PlayerPresidentPreparedSquadPlayer`
- application seam: `PlayerPresidentInteractiveDecisionApplicationSession.preparedSquad`
- membership: `player.clubId == controlledClubId`

Loan semantics:
- loaned-in → **IN**
- loaned-out → **OUT**
- free agent → **OUT**
- contract ownership squad membership authority değildir.

New-game authority:
`WorldOpeningState.players`

Checkpoint authority:
`WorldCheckpoint.nextSeasonPlayers`

Prepared squad:
- derived-only,
- non-persisted,
- application session kurulurken derive edilir,
- Pending/Resolution boyunca same snapshot,
- M88 saveBack aynı snapshot semantic'ini korur,
- first new-game save/rebound aynı semantic/signature üretir,
- next season fresh snapshot üretir,
- Completed ve M93 Lost Completed durumlarında `Kadroyu Gör` CTA hidden.

Flutter:
- M92 prepared dashboard altında `Kadroyu Gör`,
- ayrı lightweight `PresidentPreparedSquadScreen`,
- normal `Navigator.push / MaterialPageRoute`,
- raw playerId gösterilmez,
- positions: Kaleci / Defans / Orta Saha / Forvet,
- ability/potential raw double kalır, UI yalnız `.round()` gösterir,
- deterministic presentation sorting: GK → DEF → MID → FWD → ability DESC → name ASC → playerId ASC.

Mobile acceptance:
- 320px PASS
- text scale 2.0 PASS
- long-name PASS
- academy badge PASS
- 28-row real scroll PASS

Persistence:
> **M65 = sole persisted game-state authority**

M94:
- M65 field eklemedi,
- M74/M75/M80 değiştirmedi,
- M77–M88 schema/routing değiştirmedi,
- saveVersion/codec/checksum/migration değiştirmedi,
- persisted squad/cache/presentation flag oluşturmadı.

Technical compass:
- FBS-01 — **AUDIT TAMAMLANDI / A — KEEP CURRENT SAVE ARCHITECTURE**
- FBS-02 — **NOT TRIGGERED**
- FBS-03 — **NOT TRIGGERED**
- INFRA-01 — **OUT OF M94 SCOPE**

## 3. Current status

# **M94 — CLOSED / MERGED / PASS**
# **M0–M94 — CLOSED / MERGED / PASS**

Aktif milestone:
**YOK**

M95:
**NOT STARTED**

Yeni milestone otomatik seçilmez.

## 4. Next work rule

Kullanıcı yeni geliştirme istediğinde:

1. live `main` doğrula
2. güncel repo docs oku
3. central technical-development compass kontrol et
4. fresh live-main gap scan yap
5. en küçük natural authority-safe gap'i belirle

Eski sohbetten M95 tahmin edilmez.

Kullanıcı yeni prompt vermeden:
- M95 seçme
- gap scan başlatma
- branch/PR açma
- kod yazma
- CI başlatma

# DUR

**Kullanıcı yeni prompt vermeden hiçbir işlem yapma.**
