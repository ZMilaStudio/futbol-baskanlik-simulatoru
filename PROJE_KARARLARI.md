# Futbol Başkanlık Simülatörü — PROJE KARARLARI

Son güncelleme: 17 Eylül 2026

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
- Sonraki milestone numarası önceden doldurulmaz; mevcut iş kapandıktan sonra yeni numara ancak fresh live-main gap scan ile anlam kazanır.

## 5. CI ve kanıt kuralları

- PASS yalnız canlı CI kanıtıyla yazılır.
- Workflow iki ana paralel job içerir: `test` ve `canonical`.
- Her job için strict `timeout-minutes: 7` korunur.
- Artifact hedefi **0**.
- Analyzer/test/canonical hatası görülürse gerçek step ve mümkünse job logu okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan 7 dakika nedeniyle kesilirse bu timing-only durum olarak incelenir.
- Timing-only timeout için source kodu değiştirilmez; aynı exact SHA yeniden çalıştırılır.
- Hedef milestone step'i ve marker'ı tamamlanmışsa, daha sonra gelen top-level timeout/cancellation ayrıca step/log kanıtıyla değerlendirilir; skipped milestone başarı sayılmaz.
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

Sonraki persistence katmanları yeni oyun state authority'si yaratmaz; mevcut state'i paketler, saklar, listeler, yönlendirir, transient olarak bağlar veya replay metadata ile tamamlar.

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
- **M86** — M83 source-aware delete dispatcher.
- **M87** — M83–M86 davranışlarını tek application-facing mixed save-slot façade altında compose eden delegasyon servisi.
- **M88** — exact M83 typed slot identity ile yüklenen M76/M79 application session'ı yalnız runtime belleğinde bağlayan transient handle.

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
- M86 delete sırasında M83 source'a göre yalnız seçilen child store'u siler.
- M87 bu ayrımı gizleyip birleştirmez; yalnız mevcut typed routing servislerini tek application yüzeyinden sunar.
- M88 açılmış slotun exact `source + slotId` kimliğini transient olarak taşır; aynı-id sibling namespace'i tek identity'ye dönüştürmez.
- Sibling namespace same-id slot source-specific delete sırasında korunur.
- Namespace'ler otomatik birleştirilmez.
- Bootstrap slot otomatik olarak checkpoint slot ile değiştirilmez/silinmez.
- Otomatik migration veya replacement policy ayrı bir milestone kararı olmadan eklenmez.
- Child store'ların exact bytes, validation, overwrite, delete cleanup ve interrupted-recovery semantics'i üst dispatcher/façade/binding katmanlarında yeniden uygulanmaz; unchanged delege edilir.

## 10. Mixed save-slot routing kararı

Kalıcı application yüzeyi şu sorumlulukları taşır:

- M83 — iki fiziksel namespace'i typed source identity ile tek read-only mixed catalog görünümünde sunar.
- M84 — typed source identity'yi doğru child loader'a route eder.
- M85 — application session origin'ini doğru child writer/store'a route eder.
- M86 — typed source identity veya M83 summary'yi doğru child delete operation'a route eder.
- M87 — `list`, `inspect`, `load`, `loadSummary`, `save`, `delete`, `deleteSummary` operasyonlarını M83–M86 üzerinden tek application-facing façade olarak expose eder ve root factory ile mevcut child store zincirini compose eder.
- M88 — açılan typed slot identity ile loaded application session'ı geçici olarak birlikte tutar; `saveBack` ve `delete` işlemlerini aynı exact source/slot üzerinden M87'ye delege eder.

Bu katmanlar:
- üçüncü bir save namespace yaratmaz,
- save bytes'ı yeniden formatlamaz,
- child validation/cleanup/recovery contract'larını kopyalamaz,
- namespace merge veya implicit migration yapmaz,
- M65 dışında yeni persisted game-state authority oluşturmaz.

## 11. M86 ile kesinleşen delete-routing kararı

M86'in kalıcı yaklaşımı:

- `checkpoint` source → M77 checkpoint store `delete`,
- `newGameBootstrap` source → M81 bootstrap store `delete`,
- `deleteSummary` M83 typed summary'nin `source + slotId` kimliğini aynen kullanır,
- same-id sibling namespace otomatik silinmez,
- missing source `false` döndürür ve sibling mutation oluşturmaz,
- `.tmp` / `.bak` dahil child-store cleanup davranışı üst katmanda yeniden uygulanmaz,
- invalid slot validation seçilen child store contract'ında kalır.

M86'in bilinçli non-scope'u:
- automatic bootstrap → checkpoint replacement/deletion,
- namespace merge/migration,
- bulk delete / delete-all policy,
- yeni save schema, metadata cache/sidecar veya persisted authority,
- Flutter/provider/UI state.

Bu maddeler gelecekte ancak fresh live-main gap scan sonunda ayrı bir ihtiyaç olarak doğrulanırsa ele alınır.

## 12. M87 ile kesinleşen unified façade kararı

M87'in kalıcı yaklaşımı:

- Application/UI consumer mixed save-slot işlemleri için öncelikle M87 unified façade'ını kullanabilir.
- M87 business/save authority sahibi değildir; M83 catalog, M84 loader, M85 writer ve M86 deleter contract'larını compose eder.
- `list` / `inspect` mixed typed identity'yi korur.
- `loadSummary` / `deleteSummary` summary'nin source identity'sini değiştirmeden delege eder.
- `save` session origin üzerinden mevcut M85 routing'ini kullanır.
- Root factory M77 checkpoint ve M81 bootstrap store zincirini mevcut namespace ayrımıyla kurar.
- Façade seviyesinde metadata cache, sidecar, automatic migration, replacement, namespace merge veya yeni persistence formatı eklenmez.

Bu kararın amacı UI/application consumer'ı alt dispatcher wiring ayrıntısından ayırmak; fakat authority ve child-store semantics'ini değiştirmemektir.

## 13. M88 ile kesinleşen transient binding kararı

M88'in kalıcı yaklaşımı:

- Bir mixed save slot açıldığında exact M83 `source + slotId` kimliği ile loaded application session aynı transient object üzerinde tutulabilir.
- Binding metadata yalnız runtime belleğindedir; diske veya save bytes'a yazılmaz.
- `saveBack()` session origin'in hâlâ bound source ile eşleşmesini doğrular ve M87/M85 üzerinden aynı raw slot ID'ye yazar.
- `delete()` yalnız bound typed source'u M87/M86 üzerinden siler.
- Same raw ID'nin diğer namespace'teki sibling slot'u korunur.
- Stale summary veya missing slot açılışı `null` döner.
- Invalid slot validation mevcut service/child-store contract'larına delege edilir ve disk mutation oluşturmadan fail-closed kalır.

M88'in bilinçli non-scope'u:
- persisted binding metadata / sidecar / cache,
- rename / copy / bulk delete,
- automatic bootstrap → checkpoint replacement veya migration,
- namespace merge,
- yeni save schema veya game-state authority,
- Flutter/provider/UI state authority.

## 14. UI için ön karar

Flutter/UI henüz kurulmadığı için ekran mimarisi şu an persistence/core authority'yi değiştirecek şekilde tasarlanmayacaktır.

UI geldiğinde temel ilke:
- UI mevcut application/core servislerini tüketir; mixed save-slot lifecycle için M87 façade doğal application entry point'tir,
- açılmış bir slotla çalışılan ekran akışında M88 transient binding exact typed identity'yi taşımak için kullanılabilir,
- provider/view-model yeni authoritative game state sahibi olmaz,
- binding identity kalıcı UI metadata authority'sine dönüştürülmez,
- save/load/list/write/delete davranışlarının asıl contract'ı core/application katmanında kalır,
- deterministic test edilebilirlik korunur.

## 15. Karar ekleme ve değiştirme kuralı

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
