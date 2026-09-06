# M36 — President Youth Orientation → Academy Investment Orchestration I

Durum: **CLOSED / PASS**

Tarih: 6 Eylül 2026

## Amaç

Başkanın `PresidentManagementProfile.youthOrientation` trait'ini gerçek, persistent academy facility yatırım kararına bağlamak; yatırımın mevcut cash/affordability kurallarına uymasını, `financialDiscipline` tarafından nakit rezervi korunmasını ve save/load/resume sonrası deterministic continuity'nin bozulmamasını sağlamak.

## Uygulanan davranış

Yeni `PresidentAcademyInvestmentOrchestrator`:

- `youthOrientation` değerinden academy hedef seviyesi üretir.
- Düşük youth orientation daha tutucu; yüksek youth orientation daha agresif yatırım üretir.
- Aynı yatırım penceresinde uygulanabilecek upgrade sayısını profile göre sınırlar.
- `financialDiscipline` yükseldikçe korunacak cash reserve artar.
- Gerçek harcama mevcut `FacilityInvestmentOrchestrator` üzerinden yapılır.
- Yetersiz nakitte gizli borç yaratılmaz.
- Eski/default simulation semantiği, orchestration açıkça çağrılmadıkça değişmez.

## Acceptance testleri

M36 için 4 test eklendi:

1. Youth orientation → academy ambition monotonik eşleşmesi.
2. Aynı kulüp ve aynı finans durumunda yüksek-youth başkanın düşük-youth başkandan daha agresif yatırım yapması.
3. Daha yüksek `financialDiscipline` profilinin en az aynı miktarda nakit tutması.
4. Profile-driven yatırım sonrası save/load/resume'un direct continuation ile deterministic eşitliği.

## Canonical sonuç

Seed: `20260903`

- Investment checkpoint: season `8`
- Investment club: `t3_05`
- Youth orientation: `90`
- Financial discipline: `60`
- Target academy level: `5`
- Window upgrade cap: `2`
- Cash reserve: `1500 bps` (`%15`)
- Applied upgrades: `2`
- Academy level: `0 → 2`
- Investment spend: `9.00M`
- Completed seasons after resume: `20`
- Youth history match: `true`
- Final checkpoint match: `true`
- President-driven academy investment: **PASS**

## GitHub / CI kanıtı

PR: `#37`

Final PR HEAD:
`67a1996202a4fca6c6b9fc3998c18f0ac5daa1ba`

PR CI:
- run `34057110415`
- job `101550909615`
- analyzer PASS
- `144` normal/non-canonical test PASS
- M0–M36 runner zinciri PASS
- artifacts `0`

Squash merge commit:
`545a0c10345cbf12826c2bf615c5a5a20d2e99db`

Merge sonrası main CI:
- run `34057573190`
- job `101552160184`
- analyzer PASS
- `144` normal/non-canonical test PASS
- M0–M36 runner zinciri PASS
- artifacts `0`

## Kapanan açık

M35 sonunda ertelenen ana açık kapandı:

> `youthOrientation` artık yalnız transfer adayı tercihinde ve soyut academy target policy'de kalmıyor; gerçek persistent academy yatırım kararını da sürüyor.

## Sonraki mantıklı yön

M37 için doğal aday: academy yatırım kararını tek manuel yatırım checkpoint'inden çıkarıp başkan görev süresi boyunca sezonluk/periodik facility decision loop'a bağlamak; başkan değişiminde yeni profile göre yatırım yönünü değiştirmek ve multi-president save/resume continuity'sini kanıtlamak.
