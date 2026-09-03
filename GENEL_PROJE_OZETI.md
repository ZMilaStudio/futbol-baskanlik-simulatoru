# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public / proprietary notice  
**Aktif teknik aşama:** **M7 PASS adayı — final PR/main doğrulaması sonrası kapanış; sıradaki M8 / Kiralık + Taksit**  
**Ana proje durumu:** Yan geliştirme; Kelime Avı ve Minik Dedektif gibi aktif projeleri aksatmayacak.  
**UI/APK:** Henüz başlanmadı; bilinçli olarak simülasyon çekirdeği önceliklidir.

---

# 1. Proje kimliği

Futbol Başkanlık Simülatörü, ZMila Studio için geliştirilecek tam kapsamlı Android mobil futbol kulübü **başkanlığı** simülasyonudur.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

Alternatif:

> **“Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.”**

Oyuncunun ana sorumlulukları:

- kulüp ekonomisi ve borç
- teknik direktör seçimi / görevden alma
- transfer politikası
- bütçe ve maaş yapısı
- altyapı ve tesis
- sponsorlar
- taraftar beklentileri
- medya ve açıklamalar
- başkan vaatleri
- krizler ve olaylar
- uzun vadeli kulüp sağlığı

Oyuncu diziliş, antrenman, duran top veya maç içi oyuncu değişikliği yapmaz. Bunlar teknik direktörün alanıdır.

Gerçek kulüp, futbolcu, lig logosu veya lisanslı materyal kullanılmayacaktır. Dünya tamamen özgün olacaktır.

---

# 2. Değişmez tasarım prensipleri

1. Başkan teknik direktör değildir.
2. Mobil arayüz sade olacak; derin sistemler arka planda çalışabilir.
3. Başarı yalnız kupayla ölçülmez; finansal iyileşme ve sürdürülebilirlik de başarıdır.
4. Kısa vadeli sportif başarı ile uzun vadeli kulüp sağlığı arasında gerçek gerilim olmalıdır.
5. Taraftar ekonomik ve sportif bağlamı anlamalıdır; imkânsız talepler üretmemelidir.
6. Transfer AI yaş, kalite, potansiyel, sözleşme, mevki ihtiyacı, ekonomi ve oyuncu isteğini dikkate almalıdır.
7. **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**
8. “Paran yoksa transfer yapamazsın” yerine “paran yoksa daha akıllı transfer yapmak zorundasın” yaklaşımı kullanılacaktır.
9. Geçmiş açıklamalar, vaatler ve önemli kararlar unutulmamalıdır.
10. Bazı kararların sonuçları aylar veya sezonlar sonra ortaya çıkabilmelidir.
11. Doğru karar her zaman açık olmamalıdır.
12. İlk sürüm gereksiz sistemlerle şişirilmemelidir.
13. Uzun kariyer otomatik simülasyonlarla test edilmelidir.
14. Aynı simulation version + seed + veri + karar dizisi aynı sonucu üretmelidir.
15. Ekonomi ne evrensel refah ne de evrensel çöküş üretmelidir.
16. Transfer piyasası ne donmuş ne de hiperaktif olmalıdır.
17. Teknik direktör önemlidir fakat kadro kalitesinin önüne geçemez.
18. Sözleşme süresi transfer değerinin gerçek girdisidir.
19. Serbest oyuncu bonservisli transferden ayrı piyasa davranışıdır.
20. UI/APK, simülasyon çekirdeği kanıtlanmadan öncelik değildir.

---

# 3. Uzun vadeli ürün vizyonu

## Ekonomi

Arka planda derin; mobilde anlaşılır olmalıdır. Ana başlıklar:

- nakit
- borç
- transfer bütçesi
- maaş bütçesi
- oyuncu maaşları
- sponsor
- bilet / kombine
- mağaza
- transfer geliri/gideri
- tesis
- altyapı
- stadyum

Finansal sağlık kullanıcıya örneğin `Çok Güçlü / Sağlam / Dengeli / Sıkışık / Borç Krizi` gibi sade etiketlerle gösterilebilir.

## Transfer

Uzun vadeli transfer yolları:

- doğrudan bonservis
- kiralık
- satın alma opsiyonu / zorunluluğu
- taksit
- performans bonusu
- satıştan pay
- serbest oyuncu
- sözleşmesi biten oyuncu
- takas
- oyuncu + para
- maaş paylaşımı

M4 doğrudan bonservisi; M7 sözleşme süresi, gerçek maaş ve serbest oyuncuyu kanıtladı. M8 ilk gelişmiş yapılar olarak kiralık + taksite odaklanacak.

## Teknik direktör

Teknik direktör özerk futbol karakteridir. Uzun vadede transfer talebi, bütçe şikâyeti, zam isteği, medya açıklaması, başka kulüpten teklif ve yönetimle çatışma yaşayabilir.

## Taraftar

Taraftar bağlamı anlamalıdır. Borç krizindeki kulüp için imkânsız yıldız transferi yerine kaliteli kiralık isteyebilmelidir.

Güven nedenleri saklanacak: derbi, borç azaltma, yıldız satışı, bilet fiyatı, genç kullanımı, vaat, teknik direktör kararı vb.

## Medya ve vaat hafızası

Başkanın açıklamaları ve vaatleri kaydedilecek. Örneğin hocaya kamuoyu önünde destek verip iki gün sonra kovmak medya güvenilirliğini düşürmelidir.

## Seçimler

Daha sonraki aşama. Sportif başarı, borç, kulüp değeri, tesis, taraftar güveni, vaatler ve medya itibarı etkili olacaktır. Seçim kaybı kariyeri zorunlu olarak bitirmeyebilir; başka kulüp başkanlığı teklifleri mümkün olabilir.

## Tesis / altyapı / sponsor / kriz

Planlanan tesisler: altyapı, antrenman, sağlık, scouting, stadyum, kulüp mağazası. Her yatırım gerçek sistem etkisi üretmelidir.

Kriz örnekleri: maaş talebi, kaptan-hoca çatışması, sponsor ayrılığı, bilet protestosu, büyük transfer teklifi, genç oyuncunun süre isteği, teknik direktörün yönetimi eleştirmesi, stadyum bakım problemi, federasyon cezası, menajer baskısı.

---

# 4. Teknik mimari

Temel yaklaşım:

> **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**

- `simulation_core`: saf Dart domain ve oyun kuralları.
- `simulation_runner`: headless Dart/CLI, seed replay, uzun kariyer ve denge raporları.
- `persistence`: ileride versiyonlu yerel save/load, migration, autosave ve backup.
- `application`: başkan use-case katmanı.
- `presentation`: Flutter mobil UI; henüz kapsam dışı.

## Deterministik RNG

Kararlı FNV-1a tabanlı hash + özel xorshift32 `SeededRng` kullanılır. Runtime `hashCode` davranışına güvenilmez.

Maç, transfer, manager ve kontrat kararları career seed / simulation version / sezon / entity ID üzerinden deterministik türetilir.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate` kullanılır.

## Para

Para `double` değil integer minor-unit tabanlı `Money` value object ile tutulur.

Borç anapara ödemesi gider değildir; faiz giderdir.

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Negatif nakit sessizce sıfırlanmaz; gerektiğinde `emergencyBorrowing` açık borç yaratır.

Bonservis yeni para yaratmaz; alıcıdan satıcıya nakit taşır.

## Hook mimarisi

`WorldCareerEngine` iki ayrı genişleme noktası taşır:

### `WorldCareerHooks`

M6 ile eklendi. Teknik direktör gibi sezon/sportif lifecycle sistemleri için kullanılır. Varsayılan `NoopWorldCareerHooks` tamamen etkisizdir.

### `WorldRosterHooks`

M7 ile eklendi. Kontrat/kadro/gerçek maaş sistemleri için kullanılır:

- sezonluk gerçek maaş toplamı
- offseason kadro hazırlığı
- transfer öncesi kontrat süresi
- transfer sonrası kontrat güncellemesi

Varsayılan `NoopWorldRosterHooks` tamamen etkisizdir.

Manager ve contract hook'ları aynı world motorunda birlikte çalışabilir; otomatik testle doğrulanmıştır.

Bu ayrım ileride sistemleri birbirine gömmeden genişletmek için korunacaktır.

---

# 5. GitHub / CI çalışma kuralı

Repo public kalacaktır ancak açık kaynak lisansı verilmemiştir; `LICENSE.md` proprietary notice içerir.

Tek hafif CI workflow'u kullanılır. Şu anda:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1 20 sezon kariyer
- M2 20 sezon player kariyer
- M3 20 sezon economy kariyer
- M4 20 sezon transfer kariyer
- M5 20 sezon / 48 kulüp / 3 lig world kariyer
- M6 20 sezon manager-aware kariyer
- M7 20 sezon contract-aware kariyer

çalıştırılır.

APK/AAB, büyük binary ve `actions/upload-artifact` yoktur. Artifact hedefi `0`dır.

Codex kredisi M0–M7 üretiminde kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük çok-dosyalı değişiklik, ağır refactor, migration veya karmaşık hata için kullanılacaktır.

---

# 6. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS

- 8 kurgu kulüp
- çift devre / 56 maç
- deterministik fixture + maç seed'i
- Poisson tabanlı gol motoru
- standings + validator
- 100 sezon regresyon

100 sezon baseline:

- 5.600 maç
- ev galibiyeti `%45,2857`
- beraberlik `%24,5893`
- deplasman `%30,1250`
- gol/maç `2,5864`
- invariant issue `0`

## M1 — 20 Sezon Yaşam Döngüsü — PASS

- `GameDate`
- `CareerEngine`
- 20 sezon / 1.120 maç
- deterministik sezon geçişi

Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

Başlangıç 144 oyuncu.

Seed `20260903` / 20 sezon:

- final oyuncu `148`
- emeklilik `148`
- youth intake `152`
- aktif akademi mezunu `146`
- yaş ortalaması `25,84`
- validation `0`

## M3 — Temel Kulüp Ekonomisi — PASS

İlk ekonomi denemesi REDDEDİLDİ:

- final nakit `1.017,03M`
- borç `0`
- 8/8 `veryStrong`

Evrensel refah ürettiği için kabul edilmedi.

Kabul edilen seed `20260903` baseline:

- cash `124,28M`
- debt `104,43M`
- emergency `67,44M`
- 2 veryStrong / 2 solid / 2 balanced / 2 debtCrisis
- validation `0`

M3 ile integer `Money`, gelir/gider, borç/faiz ve emergency borrowing geldi. M7'ye kadar `WageModel` geçici maaş köprüsüydü.

## M4 — Basit Transfer Pazarı — PASS

Ana kurallar:

- market value modeli
- mevki ihtiyacı
- satıcı talebi / alıcı maksimumu
- finans baskısında satıcı esnekliği
- minimum 2M rezerv
- pencere başına nakdin en fazla `%35`i
- kulüp başına en fazla 2 alım
- kadro / pozisyon satış tabanları
- bonservis nakit korunumu

Seed `20260903`:

- transfer `32`
- hacim `161,68M`
- ortalama bonservis `5,05M`
- final cash `96,38M`
- final debt `58,61M`
- final oyuncu `148`
- validation `0`

## M5 — 48 Kulüp / 3 Lig — PASS

İlk büyük ölçek hedefi.

- 48 özgün kurgu kulüp
- Taç / Birlik / Ufuk ligleri
- 3 × 16 kulüp
- 30 maç/kulüp
- 720 maç/world season
- 20 sezonda 14.400 maç
- 864 başlangıç oyuncusu
- her lig sınırında 3 terfi / 3 düşme
- 19 geçişte 228 lig hareketi
- ortak 48 kulüplük transfer pazarı

Geçici ekonomi ölçekleri:

- Taç: gelir `%100`, maliyet `%100`
- Birlik: `%90 / %85`
- Ufuk: `%80 / %75`

### Reddedilen M5 kalibrasyonları

1. 2 transfer / `3.966,16M` borç → alt lig borç ölüm sarmalı.
2. 7 transfer / `2.268,60M` borç / 34 debtCrisis → hâlâ çöküş.
3. 158 transfer / `1.909,01M` nakit → karşı uçta aşırı servet.

### Kabul M5 baseline — seed `20260903`

- final oyuncu `906`
- lig hareketi `228`
- transfer `71`
- hacim `637,91M`
- ortalama bonservis `8,98M`
- final cash `862,25M`
- final debt `647,04M`
- emergency `569,03M`
- 35 transfer katılımcısı
- 10 farklı Taç Ligi şampiyonu
- validation `0`

Açık denge notu: Ufuk Ligi final nakit birikimi üst liglerden yüksektir. Nihai ekonomi kabulü değildir; gerçek sözleşme/maaş, sponsor ve bütçe sistemleri geldikçe tekrar kalibre edilecektir.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi — PASS

### Domain

96 deterministik manager. Profiller:

- `balanced`
- `youthDeveloper`
- `budgetBuilder`
- `starManager`
- `resultsFirst`

Alanlar: yaş/emeklilik, reputation, coaching, youthDevelopment, manManagement, boardCooperation, budgetDemand.

### Uyum ve sportif etki

`ManagerFitModel` manager profilini kulüp finansı, lig seviyesi, kadro yaşı/potansiyeli ve takım gücüyle eşleştirir.

`ManagerImpactModel` kesin `-2,5...+2,5` aralığına sınırlandırılmıştır. Manager bonusu yalnız maç strength'ine uygulanır; oyuncu lifecycle ve transfer market ham kadro gücünü kullanır.

Doğrudan test kötü başkanlık tercihi için `-2,5`, elit uyum için `+2,5` üretildiğini garanti eder.

### Görev yaşam döngüsü

Görev değişimi nedenleri:

- performans
- yönetim ilişkisi kopması
- emeklilik

Kovulan manager başka kulüpte çalışabilir; emekli manager atanamaz.

### M6 kabul baseline — seed `20260903`

- manager pool `96`
- görev yapan farklı manager `60`
- toplam değişim `82`
- performance `51`
- board breakdown `29`
- retirement `2`
- ortalama strength etkisi `+0,922`
- AI atamalarında min/max `-0,371 / +1,977`
- negatif etkili kulüp-sezon `29 / 960`
- `+1,5` üzeri güçlü pozitif kulüp-sezon `77 / 960`
- final ortalama board relationship `72,22`
- transfer `84`
- hacim `777,02M`
- final cash `1.048,02M`
- final debt `582,36M`
- emergency `473,40M`
- validation `0`

M5 no-op yolu aynı CI'da eski baseline'ı birebir korur.

### M6 açık sınırlar

Henüz yok:

- manager maaşı / sözleşmesi
- başka kulüpten teklif
- zam talebi
- spesifik transfer talebi
- medya davranışı
- taraftar tepkisi
- youthDevelopment'ın bireysel oyuncu gelişim hızına doğrudan etkisi

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi — PASS adayı

M7, geçici maaş tahminini gerçek oyuncu kontratlarına dönüştürdü.

### PlayerContract

Alanlar:

- player ID
- club ID
- başlangıç sezonu
- bitiş sezonu
- yıllık maaş (`Money`)

### Başlangıç ve yeni oyuncu kontratları

- kariyer başında 864 oyuncunun tamamına deterministik kontrat
- genç oyunculara youth intake sonrası ilk profesyonel kontrat
- transfer edilen oyuncuya alıcı kulüpte yeni kontrat

### Kontrat bitişi

Biten kontrat:

- yenilenebilir
- veya oyuncu serbest kalabilir

Kararda yaş, ability, potential, deterministik varyasyon ve kadro güvenliği kullanılır.

### Serbest oyuncu

`Player.freeAgentClubId = '__free_agent__'` kullanılır. `clubId` nullable yapılmadı.

Serbest oyuncu:

- kontratsızdır
- maaş giderine dahil değildir
- normal bonservis satış havuzuna girmez
- ayrı free-agent imza adımında kulüp bulabilir

Free-agent imzası mevki ihtiyacı, yaş/kalite ve maaş karşılanabilirliği dikkate alır.

### Gerçek maaş

M7 aktifken `BasicEconomyEngine` oyuncu kontratlarının gerçek yıllık toplamını kullanır.

Gerçek maaş map'i verilmezse eski `WageModel` davranışı korunur; bu nedenle M0–M6 baseline'ları değişmez.

### Kontrat süresi → piyasa değeri

`MarketValueModel` opsiyonel `contractYearsRemaining` kullanır.

İlk katsayılar:

- 0 yıl: `%25`
- 1 yıl: `%70`
- 2 yıl: `%90`
- 3 yıl: `%103`
- 4 yıl: `%110`
- 5+ yıl: `%115`

Parametre verilmezse eski market value davranışı korunur.

### M7 kabul baseline — seed `20260903`

20 sezon / 48 kulüp / 3 lig:

- maç `14.400`
- başlangıç kontratı `864`
- final aktif kontrat `874`
- yenileme `3.757`
- release `1.143`
- free-agent signing `776`
- final free agent `32`
- youth contract `912`
- transfer sonrası kontrat `103`
- final toplam yıllık maaş `491,27M`
- ortalama final yıllık maaş `562.091`
- bonservis transferi `103`
- transfer hacmi `868,67M`
- final cash `1.060,80M`
- final debt `554,81M`
- emergency borrowing `428,76M`
- validation `0`

Bu sayılar nihai oyun dengesi değildir; geniş regresyon bantlarıyla korunur.

### M7 geniş regresyon guard'ları

- renewal `1.500–7.000`
- release `300–2.500`
- free-agent signing `200–2.000`
- final free agent `5–100`
- bonservis transferi `40–300`
- final yıllık maaş `200M–900M`
- final cash `100M–2B`
- final debt `100M–2B`

Manager + contract hook'ları aynı world engine üzerinde birlikte test edilir.

M7 öncesi M5 ve M6 baselinelarının aynı CI'da birebir korunması geriye dönük uyumluluk şartıdır.

### M7 bilinçli kapsam dışı

- imza parası
- performans bonusu
- release clause
- oyuncu menajeri/temsilcisi
- etkileşimli maaş pazarlığı
- kiralık
- taksitli bonservis
- satın alma opsiyonu/zorunluluğu
- satıştan pay
- takas
- maaş paylaşımı
- Flutter UI/APK

Ayrıntı: `M7_OYUNCU_SOZLESMESI_MAAS.md`.

---

# 7. Uzun kariyer kalite hedefi

Projenin en kritik kalite gereksinimlerinden biri 10–30 sezon sonra dünyanın bozulmamasıdır.

Uzun vadeli test seviyeleri:

- geliştirici testi: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 kariyer × 30 sezon
- büyük sürüm stres: 1000 kariyer × 30 sezon

İzlenecek metrikler:

- oyuncu sayısı / yaş dağılımı
- emeklilik / youth üretimi
- kulüp nakit ve borç dağılımı
- wage/revenue
- transfer hacmi ve ücretleri
- kontrat yenileme / release / free-agent hacmi
- şampiyon dağılımı
- terfi edenlerin yaşam oranı
- büyük/küçük kulüp farkı
- manager görev süresi
- ileride taraftar güveni / vaat / başkan görev süresi

Her başarısız uzun kariyer seed ile yeniden üretilebilir olmalıdır.

---

# 8. Save/load yönü

UI başlamadan önce save modeli versiyonlu tasarlanacaktır.

Aday metadata:

- `saveVersion`
- `gameVersion`
- `simulationVersion`
- `dataVersion`
- `careerSeed`
- current `GameDate`
- checksum/integrity
- migration history

Minimum hedef:

- aktif autosave
- önceki autosave yedeği
- manuel save
- migration

Persistence formatı domain nesnelerinin birebir kopyası olmak zorunda değildir.

---

# 9. Açık denge / teknik notlar

1. Ufuk Ligi'nin M5 final nakit birikimi hâlâ takip edilmelidir.
2. M7 gerçek maaşı ekledi ancak kulüp bazlı resmi `wageBudget` henüz yoktur.
3. Serbest oyuncu imzası şu an basit affordability + kadro ihtiyacı modelidir; oyuncu tercihi/itibar/diğer teklifler ileride gerekir.
4. Kontrat yenileme şu an AI kararıdır; başkan use-case/UI henüz yoktur.
5. Manager maaşı/sözleşmesi oyuncu kontrat sisteminden ayrı kalmıştır.
6. Transfer pazarı henüz direct-fee ağırlıklıdır; M8 ile kiralık + taksit eklenecek.
7. `MarketValueModel` sözleşme etkisi ilk kalibrasyondur, nihai ekonomi değildir.
8. Sponsor, taraftar, medya, vaat, tesis ve kriz sistemleri henüz çekirdeğe bağlanmadı.
9. Flutter UI/APK bilinçli olarak başlamadı.

---

# 10. Sıradaki milestone

## M8 — Gelişmiş Transfer Yapıları I: Kiralık + Taksit

Amaç:

> **“Paran yoksa transfer yapamazsın” değil, “paran yoksa daha akıllı transfer yapmak zorundasın.”**

M8 ilk aşamada yalnız iki yapı ekleyecek:

### Kiralık

- sezonluk loan agreement
- oyuncunun parent club kimliği korunmalı
- loan club kadrosunda oynamalı
- basit loan fee
- basit wage sharing
- sezon sonunda güvenli dönüş

### Taksitli bonservis

- upfront ödeme
- future installment obligations
- toplam transfer bedeli
- alıcı için gelecek sezon nakit yükü
- satıcı için gelecek tahsilat
- ekonomi raporunda açık yükümlülük

M8'de henüz zorunlu olarak eklenmeyecek:

- satın alma opsiyonu
- zorunlu satın alma
- performans bonusu
- satıştan pay
- takas
- oyuncu + para

Önce loan + installment ekonomisinin 20 sezon ve uzun kariyer testlerinde sağlam olduğu kanıtlanacak.

---

# 11. Çalışma disiplini

- Büyük kod değişiklikleri branch + PR + CI ile yapılır.
- Kullanıcı mikro test operatörü yapılmaz.
- Aynı sorular tekrar tekrar sorulmaz; mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredi kullanımı minimum tutulur.
- `main` ve canlı GitHub durumu eski sohbet notlarından üstündür.
- Önemli karar, test sonucu, reddedilen deneme, açık sorun ve sıradaki iş `GENEL_PROJE_OZETI.md`ye yazılır.
- Yeni karar eski kararla çelişirse yeni karar geçerlidir; önemli tarihçe korunur.
