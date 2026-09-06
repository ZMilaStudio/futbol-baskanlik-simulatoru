# M29 — President Runtime Snapshot I

Durum: **PASS / MERGED / main green**  
Tarih: 6 Eylül 2026  
Canonical seed: `20260903`

## Amaç

M28 compact advanced runtime üzerine continuation-critical başkan state'ini eklemek.

M29 özellikle şunları snapshot eder:
- her 48 kulübün current başkan görev süresi
- current management profile
- current fan reputation skorları
- current media credibility
- deterministic election term cursor
- nested M28 compact advanced runtime

M29 bilinçli olarak ayrıntılı fan/media/promise geçmişini resumable yapmaz. Bu historical/runtime memory sonraki save milestone'una bırakılmıştır.

## Ana tipler

- `PresidentClubRuntimeState`
- `PresidentRuntimeCheckpoint`
- `PresidentRuntimeSaveCodec`

Test/runner:
- `test/m29_president_runtime_snapshot_test.dart`
- `tool/run_m29_president_runtime_snapshot.dart`

Public export:
- `lib/futbol_baskanlik_m0.dart`

CI:
- `.github/workflows/m0-tests.yml`
- `Run M29 president runtime snapshot`

## Snapshot sözleşmesi

Her world club için tam bir current state gerekir.

`PresidentClubRuntimeState`:
- `PresidentTenureState`
- `PresidentManagementProfile`
- `FanState`
- `MediaState`

Checkpoint election cursor:
- `electionInterval`
- `completedElectionTerms`
- `seasonsIntoCurrentTerm`

Validation:
- nested M28 runtime geçerli olmalı
- world `baseClubs` ile tam 1:1 club coverage olmalı
- duplicate/unknown club reddedilmeli
- management profile president ID current tenure president ile eşleşmeli
- fan/media club ID current club ile eşleşmeli
- election cursor completed seasons ile matematiksel olarak tutarlı olmalı

## Save formatı

Format:
`zmila-fbs-president-runtime`

Version:
`1`

Özellikler:
- canonical JSON
- FNV-1a checksum
- malformed/corrupt payload rejection
- unsupported future version rejection
- sentetik `v0 → v1` migration

V0 migration alanları:
- `compactRuntimeSave` → `runtimeSave`
- `termLength` → `electionInterval`
- `completedTerms` → `completedElectionTerms`
- `termOffset` → `seasonsIntoCurrentTerm`
- `presidents` → `clubs`

## Double-encoding failure ve düzeltme

İlk codec tasarımında nested M28 save, M29 payload içine JSON string olarak yazılıyordu.

Bu nedenle M28 JSON içindeki her quote tekrar escape ediliyor ve başkan state'i gerçekte küçük olmasına rağmen toplam M29 overhead büyüyordu.

Gerçek CI failure:
- run `33999050218`
- job `101394527746`
- analyzer PASS
- 117 test PASS, 1 test FAIL
- failing test: `M29 adds bounded president state overhead to M28 compact save`
- expected `<50000`
- actual overhead `222895`

Doğru çözüm:
- guard gevşetilmedi
- nested M28 save string yerine doğrudan JSON object olarak saklandı
- fix commit: `8c1de528e0d7ef6d3671e0e71064b03bc1c9802e`

Sonuç:
- M28 compact bytes: `736274`
- M29 president bytes: `754721`
- actual overhead: `18447`
- `<50000` guard PASS

## Canonical M29 sonucu

Canonical runner:
`dart run tool/run_m29_president_runtime_snapshot.dart 20260903`

Sonuç:
- completed seasons: `8`
- next season index: `8`
- president club states: `48`
- completed election terms: `2`
- term offset: `0`
- M28 compact bytes: `736274`
- M29 president bytes: `754721`
- overhead: `18447`
- round-trip: PASS

## Test kapsamı

- 48 current president state capture
- election cursor doğruluğu
- deterministic encode/decode round-trip
- management profile preservation
- checksum corruption rejection
- future save version rejection
- synthetic v0 migration
- bounded overhead `<50000 bytes`

Final PR CI:
- PR `#30`
- head `8c1de528e0d7ef6d3671e0e71064b03bc1c9802e`
- run `33999480197`
- job `101395663903`
- analyzer PASS
- normal tests: `118` PASS
- M0–M29 PASS
- artifact `0`

Squash merge:
`467689aa29e4805dcd93f9448cc7a1c21ba8e8d1`

Post-merge main CI:
- run `34027200080`
- job `101470178756`
- M0–M29 PASS
- artifact `0`

## Mimari sınır

M29, current başkan domain state'ini save'e alır fakat ayrıntılı fan/media/promise event memory'yi taşımaz.

Bu nedenle M29 için şu iddia yapılmaz:

> 8 sezon president-domain save/load + 12 sezon resume, historical fan/media/promise memory dahil kesintisiz 20 sezonla birebir eşittir.

Bu iddia ancak ilgili continuation memory save katmanı eklendiğinde yapılabilir.

## Sonraki mantıklı milestone

**M30 adayı — Fan / Media / Promise Runtime Memory Snapshot I**

Hedef:
- continuation-critical fan state memory
- media statement/contradiction memory
- promise lifecycle/runtime memory
- M29 current state ile tutarlı restore
- deterministic resume
- migration/checksum/versioning
- save growth measurement ve gerekirse history compaction policy
