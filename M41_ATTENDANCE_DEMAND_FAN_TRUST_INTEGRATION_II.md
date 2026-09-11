# M41 — Attendance Demand & Fan Trust Integration II

## Amaç

M40'ta kurulan stadium capacity + demand + attendance modelini mevcut taraftar güveni domain'ine bağlamak. Başkanın ve kulübün yarattığı gerçek `FanState.overallTrust`, maç günü talebi ve dolayısıyla matchday gelir potansiyelini etkiler.

## Davranış

- `StadiumInvestmentPolicy.neutralFanTrust = 60`.
- Fan trust talep çarpanı `7000 + fanTrust * 50` basis-point'tir.
- trust `0` → `7000 bps`, trust `60` → `10000 bps`, trust `100` → `12000 bps`.
- Neutral trust `60`, M40 demand/attendance/revenue semantiğini birebir korur.
- Düşük trust aynı sportif bağlamda talebi düşürür; yüksek trust yükseltir.
- `FacilityRuntimeCareerEngine`, opsiyonel typed `Map<String, FanState>` alır.
- Fan state verilmezse neutral trust kullanılır; bütün legacy caller'lar M40 davranışında kalır.
- Fan map key'i `FanState.clubId` ile eşleşmek zorundadır.
- Facility save formatı `v2` değişmez; fan trust facility checkpoint'e kopyalanmaz.
- Aynı typed fan state save/load sonrası yeniden verildiğinde continuation deterministik kalır.

## Kabul testleri

M41 beş yeni normal test ekler:

1. Explicit neutral trust ile parametresiz M40 demand/attendance/revenue birebir aynıdır.
2. Fan trust multiplier bounded/monotonic ve invalid trust güvenli reddedilir.
3. Aynı sportif bağlamda low < neutral < high demand sıralaması korunur.
4. Gerçek `FanState` düşük/yüksek değerleri gerçek facility runtime matchday gelirini değiştirir.
5. Neutral runtime parity ve fan-aware save/load continuation deterministiktir.

## Canonical kanıt

Canonical seed: `20260903`

M41 runner çıktısı:

- target club: `t1_01`
- demand: low `15360`, neutral `19200`, high `22080`
- demand multipliers: `8000`, `10000`, `11500 bps`
- neutral M40 parity: `true`
- trust demand ordered: `true`
- real matchday revenue low → high: `10.29M → 12.06M`
- real fan revenue effect: `true`
- save/load continuation match: `true`
- final result: `PASS`

## CI kanıtı — code-bearing PR HEAD

PR: `#44`
Branch: `feat/m41-fan-trust-attendance-integration`
Code-bearing HEAD: `215e5a0eed817037badfd5fc5086b8e4ff933756`
Run: `34654802377` — **SUCCESS**

- test job `103444747764` — SUCCESS
- analyzer: `No issues found!`
- **167 normal/non-canonical tests PASS**
- canonical job `103444747982` — SUCCESS
- **M0–M41 canonical PASS**
- artifacts: **0**
- test ≈ `3m01s`
- canonical ≈ `4m29s`
- iki job da sabit `timeout-minutes: 7` sınırının altında

## Durum

M41 code-bearing PR doğrulandı. Merge edilmemiştir; final docs-inclusive HEAD CI ve kullanıcı explicit merge onayı gerekir.
