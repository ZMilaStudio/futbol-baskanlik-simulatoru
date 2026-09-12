# M48 — President Facility Investment Runtime Integration I

Status: **CLOSED / MERGED / PASS**

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
Code-bearing run: `34695693706`

Final PR HEAD: `4de5350dc22fc44429b6c61548762c5e9f3f6033`
Final PR CI: `34698168272` — **SUCCESS**

Merge SHA: `63950ab4ad728fe6b6f4f0deb42323590ce5180a`
Post-merge `main` CI: `34698950932` — **SUCCESS**

Post-merge doğrulama:
- analyzer: **No issues found**
- **203 normal/non-canonical test PASS**
- **M0–M48 canonical PASS**
- M48 canonical PASS
- artifacts: **0**
- test job yaklaşık **3:13**
- canonical job yaklaşık **5:01**
- her iki job da `timeout-minutes: 7` altında

İlk PR run `34695336114` analyzer'da test tarafında 1 gerçek hata + 3 unnecessary-import bilgisiyle kırmızıydı. Gerçek log incelendi: generated `PresidentProfile` üzerinde yanlış `.presidentId` erişimi `.id` olarak düzeltildi ve üç gereksiz import kaldırıldı. Sonraki analyzer/test/canonical run'ları yeşil oldu.

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

## Kapanış

PR #51 açık kullanıcı onayı sonrası exact HEAD kilidiyle squash merge edildi.

M48 artık `main` üzerindedir ve post-merge `main` CI yeşildir. Milestone **CLOSED / MERGED / PASS**.
