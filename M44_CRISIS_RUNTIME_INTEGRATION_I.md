# M44 — Crisis Runtime Integration I

Durum: **PR-VERIFIED / NOT MERGED**
Tarih: 12 Eylül 2026
Branch: `feat/m44-crisis-runtime-integration`
PR: #47

## Amaç

M43'te oluşturulan stateless kriz karar çekirdeğini gerçek başkanlık continuation state'ine bağlamak; bunu yaparken legacy `PresidentDomainCareerEngine` davranışını değiştirmemek ve mevcut save formatını büyütmemek.

## Mimari

M44 ayrı ve opt-in bir runtime katmanı ekler:

- `CrisisRuntimeIntegrationEngine`
- `CrisisRuntimeCareerEngine`
- `CrisisRuntimeClubSnapshot`
- `CrisisRuntimeBoundaryResult`
- `CrisisRuntimeCareerResult`

Public opt-in giriş noktası: `lib/crisis_runtime_integration.dart`.

Mevcut `PresidentDomainCareerEngine` değiştirilmedi.

### Season-boundary entegrasyonu

Bir sezon tamamlandıktan sonra gerçek `PresidentDomainMemoryCheckpoint` okunur.

Her kulüp için M43 `CrisisContext` şu gerçek state'lerden kurulur:
- finance: `WorldCheckpoint.nextSeasonFinanceStates`
- fan: `PresidentRuntimeCheckpoint.clubs[].fanReputation`
- media: `PresidentRuntimeCheckpoint.clubs[].mediaReputation`
- president: `PresidentRuntimeCheckpoint.clubs[].managementProfile`

M43 kararı uygulandıktan sonra:
- cash etkisi gerçek `nextSeasonFinanceStates` içine yazılır,
- fan etkisi gerçek president runtime fan state'ine yazılır,
- media etkisi gerçek president runtime media state'ine yazılır,
- debt M43 invariant'ı gereği değiştirilmez.

Bu state'ler `PresidentDomainResumeEngine` tarafından zaten bir sonraki sezonun başlangıç state'i olarak kullanıldığı için kriz sonucu gerçek continuation davranışına taşınır.

## Save/load kararı

Yeni save alanı veya version bump eklenmedi.

Nedeni: continuation-critical kriz sonucu zaten mevcut versioned checkpoint'in finance/fan/media state'lerine uygulanıyor. Existing `PresidentDomainMemorySaveCodec` bu state'leri mevcut şemayla serialize ediyor.

Acceptance kanıtı:
- kriz uygulanmış checkpoint mevcut codec ile round-trip ediyor,
- loaded checkpoint'ten resume ile direct checkpoint'ten resume aynı sonucu üretiyor,
- 2 + 2 sezon save/resume, uninterrupted 4 sezonla aynı final checkpoint ve aynı crisis boundary history üretiyor.

## Legacy güvenliği

M44 opt-in wrapper'dır. Legacy `PresidentDomainCareerEngine` kriz motorunu kendiliğinden çağırmaz.

Ayrıca testte activation threshold 101 olan neutral runtime kullanılarak 4 sezonluk checkpoint, legacy president-domain checkpoint ile encoded-byte seviyesinde aynı doğrulanmıştır.

## Başkan turnover etkisi

Runtime her sezon sonunda o anda checkpoint'te bulunan gerçek başkan `managementProfile`ını kullanır.

Canonical 4 sezon senaryosunda:
- gerçek president turnovers: **42**
- en az bir kriz senaryosunda farklı policy üreten turnover: **35**

Dolayısıyla başkan değişimi bir sonraki kriz karar felsefesini gerçek olarak değiştirebilir.

## Kriz sıklığı dengelemesi

İlk teknik olarak yeşil code-bearing run `34682061772` şu sonucu verdi:
- 4 sezon × 48 kulüp = 192 kulüp-sezonu
- kriz: **164 / 192**

Bu kadar yüksek oran sistemi 'kriz' olmaktan çıkarıp rutin olay haline getiriyordu. M43 core varsayılanı değiştirilmeden sadece M44 runtime wrapper varsayılan activation threshold'u **55** yapıldı.

Ayrıca canonical gate'e kalıcı sıklık koruması eklendi:
- kriz sayısı kulüp-sezonlarının %75'ine ulaşırsa M44 canonical FAIL olur.

Final code-bearing canonical sonuç:
- kriz: **17 / 192** (%8,9)
- türler: `liquiditySqueeze=17`
- aksiyonlar: `bridgeSpending=4`, `balancedRecovery=10`, `austerityPlan=3`

Bu değişiklik M43 `CrisisDecisionEngine` core default threshold'unu değiştirmez; yalnız M44 gerçek runtime varsayılanını daha seçici yapar.

## Test kapsamı

M44 5 normal acceptance testi ekler:
1. kriz sonucu gerçek continuation finance/fan/media state'ine yazılır,
2. neutral wrapper legacy checkpoint'i exact korur,
3. mevcut save codec kriz-adjusted state'i persist eder,
4. 2+2 save/resume = uninterrupted 4 sezon,
5. gerçek president turnover kriz policy'sini değiştirebilir.

## Failure / düzeltme geçmişi

İlk PR run: `34681997922`.

Analyzer failure:
- testte var olmayan `FictionalWorld` tipi kullanılmıştı.
- factory'nin gerçek return tipi `FictionalWorldSetup` olduğu gerçek analyzer logundan doğrulandı.
- test tipi `FictionalWorldSetup` olarak düzeltildi.

İkinci code-bearing run `34682061772` tam yeşildi ancak canonical 164/192 kriz oranını ortaya çıkardı. Bu teknik failure değil ürün denge problemi olarak ele alındı; runtime threshold 55'e yükseltildi ve frequency guard eklendi.

## Final code-bearing CI kanıtı

HEAD: `295bbd4a7967e25c16bf8b72c4f67c0317159298`
Run: `34682359483`

- test job `103523238562`: **SUCCESS**
- analyzer: `No issues found!`
- **184 normal/non-canonical test PASS**
- canonical job `103523238501`: **SUCCESS**
- **M0–M44 canonical PASS**
- artifacts: **0**
- canonical job süresi yaklaşık 4:37, 7 dakika sınırının altında

M44 canonical final:
- seasons=4
- crises=17/192
- turnovers=42
- policyChanges=35
- legacyParity=true
- finalCheckpointMatch=true
- boundaryMatch=true
- PASS

## Merge öncesi kalan kapı

Bu doküman ve `GENEL_PROJE_OZETI.md` güncellemesi branch HEAD'ini değiştireceği için docs-inclusive exact HEAD CI yeniden yeşil doğrulanmalıdır. Ardından PR #47 squash merge edilebilir.
