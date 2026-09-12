# M49 — Player President Facility Decision Override I

Status: **PR-VERIFIED / NOT MERGED**

PR: #52  
Branch: `feat/m49-player-president-facility-control`  
Canonical seed: `20260903`

## Amaç

Oyunun temel ürün vaadi olan **“oyuncu kulüp başkanıdır”** yaklaşımına ilk explicit human/player decision yolunu eklemek.

M48'e kadar facility yatırım kararlarının tamamı generated başkan profili tarafından otomatik veriliyordu. M49 ile bir `controlledClubId` seçilir ve yalnız bu kulübün gelecek-sezon facility yatırım kararı player provider tarafından override edilebilir.

Diğer 47 kulüp mevcut M48/M39 AI yatırım davranışını birebir sürdürür.

## Player facility kararı

`PlayerFacilityInvestmentChoice` bir yatırım penceresinde üç tesis için ayrı istek taşır:
- academy: 0..2 upgrade
- training ground: 0..2 upgrade
- stadium: 0..2 upgrade

Player isteği doğrudan para yaratmaz veya reserve kuralını aşmaz:
1. academy önce işlenir
2. training → stadium round-robin sırası korunur
3. M39 başkan profilinden gelen academy/portfolio cash-reserve bps guard'ları korunur
4. upgrade yalnız mevcut real cash ile karşılanabiliyorsa uygulanır
5. debt değişmez; hidden borrowing yoktur

`PlayerFacilityInvestmentContext`, UI/application katmanının karar verirken görebileceği deterministic bağlamı taşır:
- season / club / current president
- management profile
- cash / debt
- mevcut facility seviyeleri
- AI'nın önerdiği target seviyeler
- mevcut reserve bps değerleri

## Save / resume

Yeni wrapper checkpoint:
- `PlayerPresidentFacilityControlCheckpoint`
- mevcut `FacilitySponsorCrisisRuntimeCheckpoint`
- `controlledClubId`

Yeni codec:
- `PlayerPresidentFacilityControlSaveCodec`
- format: `zmila-fbs-player-president-facility-control`
- save version: 1

Player provider/callback serialize edilmez; bu uygulama/input katmanıdır. Ancak aynı deterministic provider ile save/load resume exact parity zorunludur.

## Legacy / AI güvenliği

- provider yoksa M49 runtime state'i M48 ile birebir parity verir
- controlled club dışındaki tüm kulüpler exact M39/M48 AI orchestrator yolunu kullanır
- M48 source değiştirilmedi; player control ayrı composition katmanıdır
- M0–M48 davranışı geriye dönük korunur

## Acceptance coverage

5 yeni normal test:
1. provider yokken M49 = M48 exact runtime checkpoint parity
2. player `hold` yalnız controlled club'ı override eder; diğer 47 karar M48 ile aynıdır
3. player stadium yatırımı bir sonraki gerçek sponsor-aware matchday revenue'yu artırır
4. save round-trip `controlledClubId` bilgisini deterministic olarak korur
5. aynı provider ile `2 + 2 save/resume == uninterrupted 4` checkpoint ve boundary parity verir

Normal test toplamı: **208 PASS**.

## İlk CI failure ve düzeltme

İlk PR run: `34700738952`.

Analyzer iki gerçek compile hatası verdi:
- `player_president_facility_control.dart:364`
- `player_president_facility_control.dart:408`
- yanlış tip adı: `PresidentRuntimeClubState`

Canlı `president_runtime_checkpoint.dart` doğrulandı; gerçek sınıf `PresidentClubRuntimeState` idi. Branch'te davranış/state değiştirmeyen internal compatibility typedef eklenerek iki annotation mevcut gerçek tipe bağlandı. Sonraki analyzer temiz geçti.

## Code-bearing CI kanıtı

Code-bearing HEAD: `4290b428f09b5475bd3131f351075db0151b0ac9`  
Run: `34701135589`

- analyzer: **No issues found**
- test job: **SUCCESS**, yaklaşık 2:27
- canonical job: **SUCCESS**, yaklaşık 5:09
- **208 normal/non-canonical test PASS**
- **M0–M49 canonical PASS**
- artifacts: **0**
- her iki job da `timeout-minutes: 7` altında

## M49 canonical sonucu

- controlledClub=`t1_02`
- `aiParityCount=47`
- `playerWindows=3`
- controlled-player total spend=`12,000,000`
- hold spend=`0`
- canonical stadium upgrades=`1`
- real matchday revenue=`10,168,800 -> 10,931,460`
- `neutralM48Parity=true`
- `debtPreserved=true`
- `cashSpendMatches=true`
- `controlledClubPersisted=true`
- `finalCheckpointMatch=true`
- `boundaryMatch=true`
- saveBytes=`1329011`

## Merge kapısı

M49 henüz `main` üzerinde değildir.

Kalan zorunlu adımlar:
1. bu doküman + `GENEL_PROJE_OZETI.md` içeren docs-inclusive exact PR HEAD CI'ını doğrula
2. exact HEAD için analyzer + 208 tests + M0–M49 + artifact 0 kanıtını al
3. PR #52 head SHA değişmediğini ve mergeable olduğunu doğrula
4. kullanıcıdan PR #52 için açık merge onayı al
5. yalnız onaydan sonra squash merge et
6. post-merge `main` CI yeşil olmadan M49'u CLOSED sayma
