# M19 — Başkan Sabrı + Seçim Geri Besleme Döngüsü

## Amaç

M18'de `managerPatience` gerçek teknik direktör kararlarını ve dünyayı değiştiriyordu; ancak başkan/devir zaman çizelgesi M17'den sabit referans olarak geliyordu. M19 bu tek yönlü sınırı kapatır:

`başkan → managerPatience → teknik direktör kararı → world → taraftar/medya/vaat → seçim → başkan`

Başkanın karakterinin yarattığı sportif ve ekonomik sonuçlar artık aynı başkanın sonraki seçim sonucuna geri döner.

## Neden doğrudan büyük sezon-motoru refactor'u yapılmadı?

İlk seçenek bütün kariyer motorunu sezon sezon tek orkestratörde yeniden kurmaktı. Bu doğru ama maliyetli ve yüksek regresyon riskliydi. M19 için daha küçük ve test edilebilir bir çözüm seçildi: **deterministik fixed-point replay**.

Mevcut motorlar yeniden kullanılabilir hale getirildi:

- `PromiseMediaCareerEngine.simulateFromAdvancedReport(...)`
- `PresidentReputationCareerEngine.simulateFromSourceReport(...)`
- `PresidentManagerPatienceTimeline.fromReputationReport(...)`

Böylece eski M13–M18 yolları korunurken yeni world üzerinden reputasyon ve seçim tekrar hesaplanabiliyor.

## Fixed-point algoritması

1. Canonical M16 reputasyon/president timeline başlangıç kabulüdür.
2. O timeline'daki her sezonun incumbent başkanından deterministic `managerPatience` okunur.
3. Aynı seed ile manager-aware advanced world yeniden simüle edilir.
4. Bu dünyadan vaat, taraftar ve medya state'i yeniden üretilir.
5. Reputasyon ve seçimler yeniden hesaplanır; yeni president/turnover timeline oluşur.
6. Yeni timeline eski timeline ile aynıysa **converged**.
7. Değişmişse yeni timeline ile tekrar 2. adıma dönülür.
8. Daha önce görülen bir timeline tekrar oluşursa **cycle** kabul edilir ve validator başarısız olur.
9. Varsayılan maksimum iterasyon `8`; yakınsama yoksa iterasyon sayısını körlemesine yükseltmek kabul edilmez.

## Nedensellik sınırı

Fixed-point çözücü hesaplama sırasında bütün timeline'ı iteratif olarak çözer; ancak `patienceProvider(clubId, seasonIndex)` yalnız o sezonda yürürlükte olan başkanı döndürür. Gelecekteki başkanın trait'i geçmiş sezona uygulanmaz.

Bu nedenle final çözüm tarihsel olarak self-consistent'tır: final world'ü üreten başkan timeline'ı, aynı final world'den çıkan seçim timeline'ı ile aynıdır.

Bu yine de literal tek-geçişli sezon orkestratörü değildir. İleride interactive save/load, sezon ortası kullanıcı kararı veya daha fazla geri besleme katmanı fixed-point replay'i karmaşıklaştırırsa gerçek incremental orchestration ayrıca değerlendirilecektir.

## Canonical kabul — seed 20260903

M19 dört iterasyonda cycle olmadan yakınsadı:

| Tur | Timeline | Manager changes | Transfers | Reelected | Lost | Önceki tura göre seçim farkı |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | değişti | 88 | 153 | 157 | 83 | 50 |
| 2 | değişti | 84 | 173 | 160 | 80 | 35 |
| 3 | değişti | 84 | 168 | 160 | 80 | 2 |
| 4 | sabit | 84 | 168 | 160 | 80 | 0 |

Final karşılaştırma:

- iterations: `4`
- converged: `true`
- cycle: `false`
- elections: `240`
- M16 baseline reelected/lost: `161 / 79`
- M19 final reelected/lost: `160 / 80`
- baseline → final election outcome differences: `55 / 240`
- turnover membership differences: `55`
- baseline manager changes: `81`
- final manager changes: `84`
- baseline transfers: `173`
- final transfers: `168`
- unique final presidents: `128`
- world changed: `true`
- validation: `0`

Önemli yorum: `55` seçim sonucu farkı net olarak 55 ekstra başkan değişimi demek değildir. Bazı seçimler M16'ya göre kazanımdan kayba, bazıları kayıptan kazanıma döner; net final kayıp yalnız `79 → 80` olur.

İlk turdaki `88 manager / 153 transfer` M18 sonucudur. Başkan seçimleri geri beslendiğinde yeni yönetim profilleri dünyayı tekrar değiştirir ve sistem `84 manager / 168 transfer` noktasında dengeye oturur.

## Kabul guard'ları

Canonical seed için:

- convergence zorunlu,
- cycle yasak,
- iteration count `2–6`,
- son iteration timeline değişmemeli,
- son iteration election difference `0`,
- baseline M16 `161/79`, manager `81`, transfer `173`,
- ilk feedback turu M18 `88 manager / 153 transfer`,
- baseline/final election outcome difference `25–90`,
- final reelections `140–175`, losses `65–100`,
- final manager changes `75–100`,
- manager delta mutlak `≤25`,
- final transfers `130–210`,
- transfer delta mutlak `≤60`,
- unique final presidents `110–145`,
- world signature değişmeli.

Ek olarak temsilî üç seed (`19011`, `19012`, `19013`) 8 sezonluk feedback testinde cycle olmadan maksimum 8 iterasyonda yakınsamalıdır.

## M19'un kapattığı borç

M18'deki “değişen world seçimlere geri dönmüyor” teknik borcu kapanır. Final M19 çözümünde president timeline ve manager/world/reputation/election sonucu karşılıklı olarak tutarlıdır.

## Test geçmişi

İlk PR CI denemesi model davranışına ulaşmadan yalnız test string sözdizimi ve iki unused import nedeniyle analyzer'da başarısız oldu. Bu yüzeysel hatalar temizlendi. Sonraki CI'da analyzer PASS, canonical M19 feedback PASS, toplam `72` test PASS, eski M0–M18 runner zinciri PASS ve artifact `0` görüldü.

Final kalite kapısına ayrıca canonical denge guard'ları, üç temsilî seed için convergence testi, public M19 API export'ları ve bağımsız M19 headless runner eklendi.

## Sonraki yön

M20 adayı: **Başkan Mali Disiplini → Transfer Bütçe Davranışı I**.

İlk hedef yalnız `financialDiscipline` trait'ini gerçek harcama/borç toleransına bağlamak; `transferAmbition` ve `riskAppetite` trait'lerini aynı milestone'a yığmamak. Böylece başkan davranış etkileri yine tek tek izole edilip balance guard ile ölçülebilir.
