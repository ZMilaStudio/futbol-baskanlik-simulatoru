# M63 — Player President Tenure-Gated Promise + Media Composition I

## Amaç

M61 player-president promise kontrolü ile M62 media statement stance kontrolünü ayrı president-domain simülasyonları olarak değil, **aynı authoritative president-domain sezon akışı** üzerinde çalıştırmak.

Bu milestone oyuncunun başkan olarak iki karar yüzeyini aynı kariyerde kullanabilmesi için ilk domain-level composition adımıdır.

## Canlı mimari boşluğu

M61 ve M62 ayrı ayrı doğru tenure gating sağlıyordu; fakat her biri kendi `PresidentDomainCareerEngine` akışını ve save envelope'unu kullanıyordu. Bu nedenle ikisi aynı gerçek kariyer checkpoint'i üzerinde birlikte çalışmıyordu.

M63 bu boşluğu şu şekilde kapatır:
- M56 promise generator ve M57 media statement engine aynı `PromiseMediaCareerEngine` source report'una bağlanır;
- ikisi aynı `PresidentDomainMemoryCheckpoint` üzerinde ilerler;
- ikisi aynı M58 `PlayerPresidentTenureControlState` ile yetkilendirilir;
- tek save envelope domain checkpoint + tenure-control state saklar;
- callback provider'lar runtime-only kalır.

## Korunan semantik

- Promise choice yalnız mevcut context-valid canonical `PresidentPromiseType` seçeneklerinden yapılır.
- Promise target canonical generator tarafından belirlenmeye devam eder.
- Media provider yeni statement event yaratamaz.
- Statement existence/id/club/target manager/season/topic canonical kalır; yalnız stance seçilebilir.
- Diğer 47 kulüp promise ve media yüzeylerinde exact AI parity'de kalır.
- Gerçek election turnover sonrası successor'ın ilk sezonundan itibaren iki provider da çağrılmaz.
- Reelection aynı incumbent identity'yi koruduğu için iki kontrol de devam eder.
- Persisted `lost` state sticky kalır; save/load sonrası reaktive olmaz.
- Split save/resume, runtime-only provider'lar yeniden kurulduğunda direct run ile deterministik kalır.

## Bilinçli kapsam dışı

- M59 facility/sponsor/crisis/manager stack ile tek üst-level checkpoint composition bu milestone'a dahil değildir.
- M60 transfer-strategy control bu milestone'a dahil değildir. Transfer-window davranışı `decisionSeasonIndex = seasonIndex + 1` semantiğine sahiptir ve ayrı entegrasyon gerektirir; yanlış zamanlamayla composition public simulation semantiğini değiştirebilir.

## Acceptance

1. Active incumbent aynı sezon akışında hem promise hem media seçimini uygular; iki yüzeyde de diğer 47 kulüp exact AI parity'de kalır.
2. Real turnover successor'ın ilk sezonunda her iki provider'ı da bloklar ve final president-domain state exact AI baseline ile eşleşir.
3. Reelection her iki provider'ı da sonraki dönemde aktif tutar.
4. Persisted lost tenure save/load sonrası iki provider'ı da reaktive etmez.
5. Runtime-only provider'lar yeniden kurularak split save/resume direct combined-control run ile deterministik kalır.

## İlk code-bearing CI kanıtı

- Code-bearing HEAD: `99006dfcb88f76701d8b25780db897dc57b9e9ac`
- PR #66 CI: `34764229332`
- analyzer: `No issues found!`
- normal/non-canonical: **278/278 PASS**
- beş M63 acceptance testi PASS
- mevcut M0–M62 canonical: PASS
- artifacts: 0

Final merge-ready HEAD üzerinde workflow M63 canonical runner'ı da çalıştıracaktır.
