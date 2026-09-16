# Futbol Başkanlık Simülatörü — PROJE KARARLARI

Son güncelleme: 16 Eylül 2026

Bu dosyanın amacı geçici sohbet durumunu değil, **uzun ömürlü proje kararlarını** tek yerde tutmaktır. Güncel milestone/CI durumu için `GENEL_PROJE_OZETI.md`, sohbet devri için `SOHBET_DEVIR_NOTU.md`, gerçek kaynak durumu için canlı GitHub esas alınır.

## 1. Kaynak önceliği

Çelişki halinde sıra değişmez:

1. **Canlı GitHub**
2. Repo içindeki güncel proje dosyaları
3. Eski sohbetler / eski notlar

Bir karar bu dosyada yazıyor olsa bile canlı kod ve açıkça daha yeni kullanıcı kararı tarafından geçersiz kılınabilir.

## 2. Ürün kimliği

- Oyun bir **futbol kulübü başkanlık simülatörüdür**.
- Oyuncu teknik direktör rolünde değildir.
- Ana ürün cümlesi: **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**
- Başkanlık rolü; tesis, sponsor, kriz, teknik direktör, transfer stratejisi, vaat, medya, bilet fiyatı ve benzeri kulüp yönetimi kararlarını kapsar.
- Teknik/taktik maç yönetimi ürünün ana oyuncu rolü değildir.

## 3. Teknik temel

- Simulation core deterministic kalacaktır.
- Canonical career seed: `20260903`.
- Canonical dünya: **48 kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 864 başlangıç oyuncusu**.
- Seed/replay/save-resume parity yeni geliştirmelerde korunacaktır.
- Şu anki repo saf Dart core'dur; Flutter/UI katmanı henüz kurulmamıştır.
- UI katmanı geldiğinde core authority UI/provider state'e taşınmayacaktır.

## 4. Milestone çalışma modeli

- Aynı anda yalnız **tek aktif milestone** bulunur.
- Aktif milestone kapanmadan sonraki milestone seçilmez.
- Yeni milestone, eski sohbet varsayımından değil **fresh live-main gap scan** ile seçilir.
- Seçilen iş mümkün olan **en küçük doğal authority-safe boşluk** olmalıdır.
- Scope ve non-scope açıkça kilitlenir.
- Gereksiz schema, migration, cache, sidecar, duplicate authority veya namespace birleştirme eklenmez.
- Sonraki milestone numarası önceden doldurulmaz; örneğin mevcut iş M85 ise M86 ancak M85 kapandıktan sonraki live-main gap scan ile belirlenir.

## 5. CI ve kanıt kuralları

- PASS yalnız canlı CI kanıtıyla yazılır.
- Workflow iki ana paralel job içerir: `test` ve `canonical`.
- Her job için strict `timeout-minutes: 7` korunur.
- Artifact hedefi **0**.
- Analyzer/test/canonical hatası görülürse gerçek step ve mümkünse job logu okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan 7 dakika nedeniyle kesilirse bu **timing-only** durum olarak incelenir.
- Timing-only timeout için source kodu değiştirilmez; aynı exact SHA yeniden çalıştırılır.
- Bir önceki SHA'nın başarılı sonucu yeni HEAD için kanıt sayılmaz.
- Pre-merge kanıt ile post-merge actual-main kanıtı birbirinden ayrıdır.

## 6. PR ve merge yönetişimi

- Merge öncesinde kullanıcının **exact final PR HEAD SHA** için açık onayı gerekir.
- Kullanıcı onayı alındıktan sonra PR head yeniden doğrulanır.
- Merge yöntemi **squash**.
- Merge sırasında `expected_head_sha` lock kullanılır.
- PR head onaydan sonra değişmişse eski onaya dayanarak merge yapılmaz.
- Milestone, merge olmuş olsa bile gerçek `main` executable doğrulaması tamamlanmadan **CLOSED** sayılmaz.

## 7. Dokümantasyon yönetişimi

- `GENEL_PROJE_OZETI.md`: projenin güncel teknik/milestone özeti.
- `SOHBET_DEVIR_NOTU.md`: yeni sohbete geçişte kaldığımız kesin yer ve sıradaki adım.
- `PROJE_KARARLARI.md`: bu dosya; yalnız uzun ömürlü ürün, mimari ve çalışma kararları.
- Closure docs ancak actual-main executable kanıt tamamlandıktan sonra kapanış diliyle güncellenir.
- Kapanış dosyaları mümkün olduğunda **tek atomik commit** ile güncellenir.
- Closure-docs push CI gözlemseldir; parent merge SHA zaten tam executable kanıta sahipse timing-only docs CI timeout yeni docs→CI→docs döngüsü başlatmaz.

## 8. Persisted state authority kararı

En kritik mimari karar:

> **M65 tek persisted game-state authority olarak kalır.**

Sonraki persistence katmanları yeni oyun state authority'si yaratmaz; mevcut state'i paketler, saklar, listeler, yönlendirir veya replay metadata ile tamamlar.

Yetki zinciri:
- **M65** — persisted game-state authority.
- **M74** — accepted-answer replay metadata / transcript.
- **M75** — M65 + M74 + resume config içeren checkpoint-backed atomik persistence bundle.
- **M76** — checkpoint-backed application-session lifecycle.
- **M77** — exact M75 bytes için checkpoint file-slot store.
- **M78** — checkpoint read-only catalog.
- **M79** — deterministic application new-game session.
- **M80** — pre-checkpoint replay-only bootstrap snapshot.
- **M81** — exact M80 bootstrap bytes için ayrı bootstrap file-slot store.
- **M82** — bootstrap read-only catalog.
- **M83** — checkpoint + bootstrap için typed mixed read-only projection.
- **M84** — source-aware load dispatcher.
- **M85** — application-session-origin-aware write dispatcher.

Hiçbiri M65'in persisted game-state authority rolünü devralmaz.

## 9. Save namespace kararı

İki fiziksel save namespace'i bilinçli olarak ayrıdır:

- checkpoint namespace — M77
- new-game bootstrap namespace — M81

Kalıcı kurallar:
- Aynı raw `slotId` iki namespace'te aynı anda bulunabilir.
- Bu durum collision değildir; iki ayrı typed identity olarak korunur.
- M83 source identity bu ayrımı görünür kılar.
- M84 load sırasında source'a göre doğru child store'u seçer.
- M85 write sırasında session origin'e göre doğru child store'u seçer.
- Namespace'ler otomatik birleştirilmez.
- Bootstrap slot otomatik olarak checkpoint slot ile değiştirilmez/silinmez.
- Otomatik migration veya replacement policy ayrı bir milestone kararı olmadan eklenmez.
- Child store'ların exact bytes, validation, overwrite ve interrupted-recovery semantics'i üst dispatcher katmanlarında yeniden uygulanmaz; unchanged delege edilir.

## 10. M85 ile kesinleşen write-routing kararı

M85'in kalıcı yaklaşımı:

- checkpoint-backed `PlayerPresidentInteractiveDecisionApplicationSession` → M77 checkpoint store,
- pre-checkpoint/new-game `PlayerPresidentInteractiveDecisionApplicationSession` → M81 bootstrap store,
- writer typed M83 source döndürür,
- same-id iki namespace ayrı kalır,
- routed child-store bytes yeniden formatlanmaz,
- invalid slot validation seçilen child store contract'ında kalır,
- yeni save schema, metadata cache/sidecar, migration veya üçüncü store yaratılmaz.

M85'in bilinçli non-scope'u:
- delete routing,
- automatic bootstrap → checkpoint replacement/deletion,
- namespace merge/migration,
- yeni save bytes/schema,
- Flutter/provider/UI state.

Bu maddeler gelecekte ancak fresh live-main gap scan sonunda ayrı bir ihtiyaç olarak doğrulanırsa ele alınır.

## 11. UI için ön karar

Flutter/UI henüz kurulmadığı için ekran mimarisi şu an persistence/core authority'yi değiştirecek şekilde tasarlanmayacaktır.

UI geldiğinde temel ilke:
- UI mevcut application/core servislerini tüketir,
- provider/view-model yeni authoritative game state sahibi olmaz,
- save/load/list/write davranışlarının asıl contract'ı core/application katmanında kalır,
- deterministic test edilebilirlik korunur.

## 12. Karar ekleme ve değiştirme kuralı

Bu dosyaya yalnız şu tip kararlar eklenir:
- ürün kimliğini uzun süre etkileyen kararlar,
- mimari authority sınırları,
- persistence/save namespace kuralları,
- CI/merge/dokümantasyon yönetişimi,
- açıkça kesinleşmiş uzun ömürlü scope/non-scope ilkeleri.

Şunlar bu dosyaya yazılmaz:
- anlık workflow ilerlemesi,
- geçici job ID'leri,
- o anda çalışan CI step'i,
- kısa ömürlü sohbet devri,
- henüz onaylanmamış fikirler.

Bir karar değişirse eski karar sessizce bırakılmaz; ilgili bölüm yeni kararla güncellenir ve gerekiyorsa neden değiştiği kısa notla belirtilir.
