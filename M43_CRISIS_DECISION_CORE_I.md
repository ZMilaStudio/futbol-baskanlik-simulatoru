# M43 — Crisis Decision Core I

Durum: PR-VERIFIED / NOT MERGED
Tarih: 12 Eylül 2026

## Amaç

Ekonomi/borç baskısı, taraftar güveni, medya güvenilirliği ve başkan yönetim profilini dar, deterministic ve legacy-safe bir başkanlık kriz karar çekirdeğinde birleştirmek.

## Uygulama

Yeni `lib/src/crisis/crisis_decision_core.dart` domain'i eklendi.

### Typed input
- `ClubFinanceState` cash/debt
- `FanState.overallTrust`
- `MediaState.credibility`
- `PresidentManagementProfile`
- club id + season index

### Kriz algılama
Deterministic pressure skorları içinden en yüksek olan seçilir:
- `liquiditySqueeze`
- `supporterUnrest`
- `mediaBacklash`

Varsayılan activation threshold `35`; tüm baskılar bunun altındaysa kriz üretilmez.

### Başkan karar farkı
Profil trait'leri gerçek karar farkı yaratır:
- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `managerPatience`

Örnek canonical davranış:
- prudent liquidity response: `austerityPlan`
- bold liquidity response: `bridgeSpending`
- supporter response: `ambitionReset`
- media response: `transparentBriefing`

### Etki güvenlik kuralları
- cash/fan/media etkileri bounded
- cash sıfırın altına düşmez
- debt hiçbir kriz kararında gizlice artırılmaz
- fan/media skorları 0..100 aralığında tutulur

### Save/resume
M43 stateless'tir; yeni save formatı oluşturmaz. Aynı reconstructed continuation state aynı crisis scenario/decision/result signature'ını üretir.

### Legacy uyumluluğu
Mevcut simulation akışları kriz motorunu varsayılan olarak çağırmaz. M0–M42 public davranışı değiştirilmemiştir.

## Test ve CI kanıtı

PR #46 code-bearing HEAD: `e8d0d0384d970570a21e2382c1996dcb38be994f`
Run: `34680327227`

- analyzer: `No issues found!`
- normal tests: **179 PASS**
- canonical: **M0–M43 PASS**
- M43 canonical: PASS
- debtPreserved: `true`
- saveResumeMatch: `true`
- artifacts: **0**
- test job ≈ 1m57s
- canonical job ≈ 3m15s
- her ikisi de 7 dakikalık timeout sınırının altında

## Merge kuralı

Bu belge commit'i sonrası exact docs-inclusive PR HEAD yeniden tam CI'dan geçmeden merge yapılmaz. Yeşil exact HEAD kullanıcı tarafından bu oturum için verilmiş otomatik merge yetkisi kapsamında squash merge edilebilir.
