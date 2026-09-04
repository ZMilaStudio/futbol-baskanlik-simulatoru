# M17 — Başkan Profili + Yönetim Felsefesi Çekirdeği

## Amaç

M15–M16 ile başkan kimliği, görev süresi, seçim devri ve kişisel itibar artık gerçek state olarak bulunuyor. M17'nin amacı başkan değişiminin yalnız isim ve itibar değil, ileride kulübün kararlarını etkileyebilecek **tutarlı yönetim felsefesi** de değiştirebilmesini sağlamaktır.

Bu milestone gözlemseldir. Yönetim profili henüz ekonomi, transfer veya teknik direktör AI kararını değiştirmez. Böylece M16 seçim/turnover baseline'ı sabit kalırken profil modelinin kendi kalitesi ölçülebilir.

## Beş yönetim boyutu

Her `PresidentManagementProfile` 20–90 bandında beş trait taşır:

1. `financialDiscipline` — borç ve mali risk karşısındaki disiplin,
2. `riskAppetite` — kısa vadeli başarı uğruna risk alma isteği,
3. `transferAmbition` — transfer harcaması / yıldız hamlesi iştahı,
4. `youthOrientation` — genç ve altyapı yönelimi,
5. `managerPatience` — teknik direktöre zaman tanıma eğilimi.

Profil `careerSeed + simulationVersion + presidentId` üzerinden deterministiktir.

## Arketipler

Trait'ler bağımsız rastgele sayılar değildir. Önce altı tutarlı arketipten biri seçilir, sonra merkez değerlerine küçük seed'li jitter uygulanır:

- `balanced`
- `prudentBuilder`
- `ambitiousSpender`
- `youthArchitect`
- `patientPlanner`
- `interventionist`

Örneğin `prudentBuilder` yüksek mali disiplin / düşük risk / görece yüksek sabır; `ambitiousSpender` düşük mali disiplin / yüksek risk / yüksek transfer hırsı; `youthArchitect` yüksek altyapı yönelimi üretir.

## M16 ile ilişki

M17, `PresidentReputationCareerEngine` raporunu kaynak kabul eder. M16 dünyasını veya seçimlerini değiştirmez.

- başlangıç 48 incumbent başkan profillenir,
- her gerçek turnover'daki incoming başkan profillenir,
- aynı president ID her zaman aynı management profile alır,
- outgoing/incoming profiller turnover bazında karşılaştırılır.

## Turnover değişim ölçümü

Beş trait'in mutlak farklarının ortalaması `averageTraitDistance` olarak tutulur.

- tek trait farkı `>=15` ise materially changed sayılır,
- ortalama trait mesafesi `>=12` ise turnover `meaningfulChange` sayılır,
- arketip değişimi ayrıca sayılır.

Bu metrikler M18 ve sonraki AI bağlantılarında “başkan değişti ama kulüp aynı davranıyor” problemini test etmeyi sağlar.

## Kabul baseline — seed 20260903

M16 kaynak zinciri:

- elections `240`
- reelected `161`
- lost / turnovers `79 / 79`
- unique presidents `127`

M17:

- management profiles `127`
- youthArchitect `23`
- interventionist `25`
- prudentBuilder `24`
- patientPlanner `15`
- balanced `18`
- ambitiousSpender `22`
- financial discipline avg `60,48`, range `28–90`
- risk appetite avg `54,98`, range `20–90`
- transfer ambition avg `56,54`, range `29–90`
- youth orientation avg `59,90`, range `30–90`
- manager patience avg `57,94`, range `20–90`
- average turnover profile distance `22,47`
- archetype-changing turnovers `67 / 79`
- meaningful management changes `57 / 79`
- validation `0`

## Kabul yorumu

İlk model doğrudan kabul edildi.

Altı arketipin tamamı kullanılıyor ve hiçbir arketip popülasyona hakim değil. Trait ortalamaları merkezde kalırken bütün eksenlerde geniş aralık bulunuyor. Turnover'ların çoğunda arketip değişiyor ve yaklaşık dörtte üçünde yönetim profili anlamlı ölçüde farklılaşıyor.

Bu aşamada etkileri dünyaya bağlamamak bilinçli karardır. Önce karakter modeli kanıtlandı; davranış geri beslemesi sonraki milestone'larda tek sistem halinde eklenecek.

## CI guard'ları

Seed `20260903` için:

- profiles `127`
- 6/6 arketip aktif
- her arketip `10–30`
- archetype-changing turnovers `55–75`
- meaningful turnovers `45–65`
- avg turnover distance `18–27`
- trait ortalamaları geniş orta bantlarda,
- her trait minimumu yaklaşık `20–35`, maksimumu `85–90`,
- M16 election `161/79` ve turnover `79` aynen korunur,
- validator issues `0`.

## Kapsam dışı

M17'de yapılmaz:

- transfer AI'a gerçek profil etkisi,
- ekonomi/borç kararına gerçek profil etkisi,
- manager dismissal threshold değişikliği,
- sponsor/tesis etkisi,
- kullanıcı başkan profili seçimi,
- Flutter/UI.

## Sonraki milestone

**M18 — Başkan Sabri → Teknik Direktör Karar Eşiği I.**

İlk gerçek davranış bağlantısı yalnız `managerPatience` ile sınırlı tutulacak. Amaç sabırlı başkanların teknik direktörü daha uzun değerlendirmesi, müdahaleci/düşük sabırlı başkanların daha erken değişime gitmesi; bunu yaparken M6 manager marketini aşırı hareketli veya donmuş hale getirmemektir.
