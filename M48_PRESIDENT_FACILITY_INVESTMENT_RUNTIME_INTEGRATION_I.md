# M48 — President Facility Investment Runtime Integration I

Status: **PR-VERIFIED / NOT MERGED**

PR: #51
Branch: `feat/m48-president-facility-investment-runtime`
Canonical seed: `20260903`

## Amaç

M39'da ayrı karar döngüsü olarak çalışan başkan facility yatırım politikasını M47 birleşik facility+sponsor+crisis continuation runtime'ına bağlamak.

M48, her tamamlanmış sezonun sonunda yalnız gerçekten bir sonraki sezon varsa yatırım boundary'si çalıştırır:
1. M47 sezonu sponsor-aware economy + facility effects + crisis ile tek kez tamamlanır.
2. Post-season/post-crisis current president profili okunur.
3. Aynı M39 sırası kullanılır: academy önce, ardından training→stadium round-robin portfolio yatırımı.
4. Gerçek next-season cash düşülür; debt değiştirilmez; mevcut reserve kuralları korunur.
5. Güncellenmiş academy/stadium/training state aynı M47 checkpoint'e yazılır.
6. Bir sonraki sezon M47 bu yeni facility seviyelerini gerçek player lifecycle ve matchday revenue üzerinde kullanır.

Final rapordan sonra gelecek sezon yoksa yatırım uygulanmaz; böylece M47 final-season semantiği korunur.

## Teknik yaklaşım

Yeni katmanlar:
- `PresidentFacilityInvestmentRuntimeEngine`
- `PresidentFacilityInvestmentRuntimeDecision`
- `PresidentFacilityInvestmentRuntimeSeasonBoundary`
- `PresidentFacilityInvestmentRuntimeCareerEngine`

M39 logic kopyalanmadı. Doğrudan mevcut:
- `PresidentAcademyInvestmentOrchestrator`
- `PresidentFacilityPortfolioInvestmentOrchestrator`

kullanıldı.

Save formatı değiştirilmedi. M47 `FacilitySponsorCrisisRuntimeCheckpoint` ve `FacilitySponsorCrisisRuntimeSaveCodec` aynen yeniden kullanılır; save-version bump yoktur.

## Acceptance coverage

5 yeni normal test:
1. Gelecek sezon olmayan tek-sezon M48, M47 checkpoint'iyle birebir parity verir.
2. M48, M39 plan/uygulama sonucunu birebir yeniden kullanır; gerçek cash düşer, debt aynı kalır.
3. Sezon-1 stadium yatırımı sezon-2 gerçek sponsor-aware matchday revenue'yu artırır.
4. Election sonrası yatırım kararı post-election current president profiline aittir; turnover doğal olarak replanning yapar.
5. Existing M47 save codec ile `2 + 2 == uninterrupted 4` sezon checkpoint ve boundary parity verir.

Normal test toplamı: **203 PASS**.

## CI / canonical kanıtı

Code-bearing HEAD: `5a6bd0e695af214cf16530138ed3ba318effad46`
Run: `34695693706`

- analyzer: **No issues found**
- test job: **SUCCESS**, yaklaşık 3:21
- canonical job: **SUCCESS**, yaklaşık 5:04
- **203 normal/non-canonical test PASS**
- **M0–M48 canonical PASS**
- artifacts: **0**
- her iki job da `timeout-minutes: 7` altında

İlk PR run `34695336114` analyzer'da test tarafında 1 gerçek hata + 3 unnecessary-import bilgisiyle kırmızıydı. Gerçek log incelendi: generated `PresidentProfile` üzerinde yanlış `.presidentId` erişimi `.id` olarak düzeltildi ve üç gereksiz import kaldırıldı. Sonraki analyzer/test run'ları yeşil oldu.

## M48 canonical sonucu

- seasons=4
- prepared investment boundaries=3
- president facility decisions=144
- upgrades academy/training/stadium=`70/45/33`
- total facility investment spend=`634,000,000`
- invested club windows=`73`
- stadium effect target=`t1_02`
- matchday revenue=`10,168,800 -> 10,922,000`
- `currentPresidentMatch=true`
- `sponsorStatePreserved=true`
- `debtPreserved=true`
- `cashSpendMatches=true`
- `investmentActive=true`
- `stadiumEffect=true`
- `finalSeasonNoInvestment=true`
- `finalSeasonM47Parity=true`
- `saveResumeMatch=true`
- `boundaryMatch=true`
- saveBytes=`922058`

## Merge kapısı

M48 henüz `main` üzerinde değildir.

Code-bearing kapılar yeşildir. Merge öncesi kalan zorunlu adımlar:
1. bu doküman + `GENEL_PROJE_OZETI.md` commitlerinden oluşan docs-inclusive exact PR HEAD CI'ını doğrula
2. analyzer + 203 tests + M0–M48 + artifact 0 kanıtını exact HEAD için al
3. PR head değişmediğini ve mergeable olduğunu doğrula
4. kullanıcıdan PR #51 için açık merge onayı al
5. yalnız onaydan sonra squash merge et
6. post-merge `main` CI yeşil olmadan M48'i CLOSED sayma
