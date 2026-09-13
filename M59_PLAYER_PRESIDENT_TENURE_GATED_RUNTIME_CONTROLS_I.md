# M59 — Player President Tenure-Gated Runtime Controls I

## Amaç

M58 ile oluşturulan persisted player-president tenure ownership gate'ini M49–M52'nin gerçek runtime karar zincirine bağlamak.

M49–M52 daha önce controlled club kimliğine göre oyuncu provider'larını çalıştırıyordu. Gerçek seçimde incumbent başkan değişse bile yalnız kulüp-id kontrolü oyuncu yetkisinin teorik olarak devam etmesine izin verebilirdi. M59 bu boşluğu gerçek `presidentId` ownership kontrolüyle kapatır.

## Kapsam

M59 yalnız nested M49–M52 karar stack'ini kapsar:
- facility investment — M49
- sponsor selection — M50
- crisis action — M51
- manager retain/replace + replacement selection — M52

M55 transfer-strategy, M56 promise ve M57 media-statement yüzeyleri ayrı runtime yollarında bulunduğu için bu milestone'a dahil edilmez; bunların tenure gating'i sonraki milestone kapsamına bırakılır.

## Tasarım

Yeni üst runtime katmanı `PlayerPresidentTenureGatedRuntimeCareerEngine`, mevcut M52 stack'ini değiştirmeden compose eder.

Persisted checkpoint:
- mevcut `PlayerPresidentManagerControlCheckpoint`
- M58 `PlayerPresidentTenureControlState`

Provider callback'leri save'e yazılmaz; runtime-only kalır.

Her sezon M52 bir sezonluk segment olarak çalıştırılır. Segment başında tenure state active ise facility/sponsor/crisis/manager provider'ları ortak bir runtime decision session üzerinden guard edilir. Decision context'teki gerçek `presidentId`, capture edilmiş player-president id ile eşleşiyorsa dış provider çağrılır.

Gerçek seçim turnover'ında successor `presidentId` aynı sezonun karar context'inde görüldüğü anda ortak session bloke olur. Böylece turnover boundary içinde kalan bütün oyuncu kararları da dış provider'a gitmez ve ilgili sistemin kanonik AI kararına düşer:
- facility: mevcut president academy/portfolio policy hedefleri
- sponsor: `context.aiChoice`
- crisis: `context.aiDecision.action`
- manager review/replacement: mevcut AI review + `context.aiChoice`

Sezon sonunda M58 gate gerçek persisted president runtime ile refresh edilir. State `lost` olduğunda sonraki sezonlarda provider wrapper bile kurulmaz; orijinal no-provider M52 AI path'i kullanılır. Loss sticky kalır.

## Save / Resume

`PlayerPresidentTenureGatedRuntimeSaveCodec` M52 save'i ve M58 tenure-control save'ini deterministic checksum'lı bir M59 envelope içinde taşır.

Format: `zmila-fbs-player-president-tenure-gated-runtime`
Save version: `1`

Mevcut M49–M52 codec formatları değiştirilmediği için eski public save semantiğine migration borcu eklenmez.

## Acceptance

1. Active incumbent iken M49–M52 dış player provider'ları gerçek karar context'leriyle çağrılır — PASS.
2. Gerçek election turnover boundary içinde successor görülür görülmez dış provider çağrıları durur — PASS.
3. Reelection aynı president identity'yi koruduğunda player control aktif kalır — PASS.
4. Lost checkpoint resume edildiğinde poison provider'lar hiç çağrılmaz ve sonuç exact no-provider AI path ile aynıdır — PASS.
5. Save round-trip ve 2+2 resume, uninterrupted 4-season checkpoint ile deterministic parity korur — PASS.

## Canlı code-bearing CI kanıtı

- Branch: `feat/m59-player-president-tenure-gated-runtime-controls`
- PR: #62
- Verified code-bearing HEAD: `1c48a94e87f88367f81f5838a711acc94637758d`
- Workflow run: `34751744123` — SUCCESS
- Analyzer: `No issues found!`
- Normal/non-canonical tests: **258/258 PASS**
- M59 acceptance: **5/5 PASS**
- Canonical chain: **M0–M59 PASS**
- Marker: `M59_PLAYER_PRESIDENT_TENURE_GATED_RUNTIME_CONTROLS_PASS turnoverClub=t1_01 reelectedClub=t1_03 activeDelegation=true turnoverStopsControl=true reelectionKeepsControl=true exactAiAfterLoss=true deterministic=true worldClubs=48`
- Artifacts: **0**

## Dosyalar

- `lib/src/election/player_president_tenure_gated_runtime_controls.dart`
- `lib/player_president_tenure_gated_runtime_controls.dart`
- `test/m59_player_president_tenure_gated_runtime_controls_test.dart`
- `tool/run_m59_player_president_tenure_gated_runtime_controls.dart`
- `.github/workflows/m0-tests.yml`
- `M59_PLAYER_PRESIDENT_TENURE_GATED_RUNTIME_CONTROLS_I.md`
- `GENEL_PROJE_OZETI.md`

## Durum

Code-bearing implementation PASS. Dokümantasyon refresh'i final PR HEAD'ini değiştireceğinden merge-ready ilanından önce final exact-head üzerinde test + canonical + marker + artifact=0 tekrar doğrulanmalıdır.
