# M40 — Stadium Capacity & Attendance Core I

Durum: **PR-VERIFIED / NOT MERGED**

Canonical seed: `20260903`

## Amaç

M38 ile gerçek `matchdayRevenue` hattına bağlanan stadium yatırımını sabit gelir çarpanından daha anlamlı bir kapasite/talep/doluluk modeline taşımak. Level `0` legacy davranışı korunur; M38'in `%7,5 × level` stadium etkisi kaldırılmaz, yeni modelde maksimum gelir tavanı olarak kullanılır.

## Uygulama

- stadium capacity level `0..5`:
  - `18.000`
  - `20.500`
  - `23.500`
  - `27.000`
  - `31.000`
  - `36.000`
- deterministic demand:
  - club strength etkisi
  - current league position etkisi
- attendance = `min(capacity, demand)`
- occupancy basis-points olarak türetilir
- ticket-yield stadium level ile artar
- attendance/yield kaynaklı raw multiplier, mevcut M38 stadium multiplier'ını aşamaz
- düşük talepte yatırımın geliri tam realize olmaz
- güçlü talepte mevcut M38 gelir tavanı realize edilir
- level `0` multiplier tam `10000 bps`
- derived capacity/attendance save'e yazılmaz; facility save version `2` değişmez
- `FacilityRuntimeCareerEngine` gerçek ekonomi çağrısında attendance-aware multiplier üretir

## Kabul testleri

M40 beş normal test ekler:

1. capacity seviyeleri monotonic ve level `0` legacy revenue korunuyor
2. demand strength + league position'a tepki veriyor
3. unused capacity revenue upside'ı sınırlıyor
4. strong demand mevcut stadium revenue ceiling'ini realize edebiliyor
5. attendance modeli gerçek ekonomiyi etkiliyor ve save/load continuation deterministik kalıyor

## İlk code-bearing PR CI kanıtı

Run: `34651546720` — **SUCCESS**

Jobs:
- test `103434615793` — **SUCCESS**, yaklaşık `2m58s`
- canonical `103434615903` — **SUCCESS**, yaklaşık `3m04s`

Kanıt:
- `dart analyze`: **No issues found!**
- normal/non-canonical test: **162 PASS**
- M0–M40 canonical zinciri: **PASS**
- M40 canonical adımı: **SUCCESS**
- artifacts: **0**
- iki job da sabit `timeout-minutes: 7` sınırının altında

## M40 canonical sonuçları

- seed: `20260903`
- target club: `t1_01`
- capacities: `18000, 20500, 23500, 27000, 31000, 36000`
- capacity monotonic: `true`
- level zero legacy: `true`
- weak demand profile:
  - attendance `11700 / 36000`
  - occupancy `3250 bps`
  - realized revenue multiplier `10750 bps`
  - level-5 legacy ceiling `13750 bps`
  - underused: `true`
- strong demand profile:
  - attendance `20500 / 20500`
  - occupancy `10000 bps`
  - realized multiplier `10750 bps`
  - level-1 legacy ceiling `10750 bps`
  - ceiling realized: `true`
- real target matchday revenue: `9.84M → 10.58M`
- real matchday revenue raised: `true`
- save/load continuation match: `true`
- canonical result: **PASS**

## M38 regresyon notu

M40 sonrası M38 canonical hâlâ **PASS**. M38'in kabul kriteri stadium upgrade'in gerçek matchday gelirini artırmasıdır; exact gelir değeri contract değildir. Attendance-aware model nedeniyle M38 canonical `t3_05` örneğinde level-1 gelir `3.49M → 3.54M` oldu (M38 milestone zamanında flat multiplier ile `3.49M → 3.75M` idi). Bu fark M40'ın amaçlanan düşük-talep davranışıdır; cash/debt/save/training/parity invariant'ları değişmedi.

## Merge kuralı

Bu doküman PR doğrulamasını kaydeder; M40 **main/PASS/CLOSED** sayılmaz. Final docs-inclusive PR HEAD CI tekrar yeşil doğrulanmalı, ardından merge için kullanıcıdan explicit onay alınmalıdır. Merge sonrası `main` CI da canlı doğrulanmadan milestone kapatılmaz.
