# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 03.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public / proprietary notice  
**Aktif teknik aşama:** **M5 PASS — sıradaki milestone M6 / Teknik Direktör Sistemi**  
**Ana proje durumu:** Yan geliştirme. Kelime Avı ve Minik Dedektif gibi aktif projeleri aksatmayacak.  
**UI/APK durumu:** Henüz başlanmadı; bilinçli olarak simülasyon çekirdeği önceliklidir.

---

# 1. Proje kimliği

Futbol Başkanlık Simülatörü, ZMila Studio için geliştirilecek tam kapsamlı Android mobil futbol kulübü **başkanlığı** simülasyonudur.

Temel kimlik:

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
- altyapı ve tesisler
- sponsorlar
- taraftar beklentileri
- medya ve açıklamalar
- başkan vaatleri
- krizler ve olaylar
- uzun vadeli kulüp sağlığı

Oyuncu diziliş, antrenman, duran top veya maç içi değişiklik gibi teknik direktör işlerini yapmaz.

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
8. Para yoksa transfer sistemi kapanmamalı; oyuncu daha akıllı transfer yollarına yönelmelidir.
9. Geçmiş açıklamalar, vaatler ve önemli kararlar unutulmamalıdır.
10. Bazı kararların sonuçları aylar veya sezonlar sonra ortaya çıkabilmelidir.
11. Doğru karar her zaman açık olmamalıdır.
12. İlk sürüm gereksiz sistemlerle şişirilmemelidir.
13. Uzun kariyer otomatik simülasyonlarla test edilmelidir.
14. Aynı seed ve karar dizisi aynı sonucu üretmelidir.
15. Ekonomi ne evrensel refah ne de evrensel çöküş üretmelidir.
16. Transfer piyasası ne donmuş ne de hiperaktif olmalıdır.
17. UI/APK, simülasyon çekirdeği kanıtlanmadan öncelik değildir.

---

# 3. Uzun vadeli oyun sistemleri

## Teknik direktör

Teknik direktör özerk karakter olacaktır. Profiller örneğin:

- genç geliştirici
- yıldız teknik direktör
- disiplinci
- hücumcu / savunmacı
- medya dostu
- yüksek bütçe isteyen
- düşük bütçeyle çalışan
- altyapı odaklı

Teknik direktör transfer isteyebilmeli, bütçeden şikâyet edebilmeli, yönetimle ters düşebilmeli, başka teklif alabilmeli ve zam talep edebilmelidir.

## Transfer

Uzun vadeli hedef transfer türleri:

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

M4 yalnız doğrudan bonservis çekirdeğini kanıtladı.

## Taraftar

Taraftar güveni tek üst skorla gösterilebilir ama nedenleri saklanmalıdır. Etkenler:

- lig ve kupa sonuçları
- derbi
- borç azaltma / artırma
- transferler ve yıldız satışları
- bilet fiyatı
- altyapı kullanımı
- başkan vaatleri
- rakiplerin hamleleri
- teknik direktör kararı

Düşük güven protesto, seyirci/merch düşüşü, sponsor ilgisi kaybı, seçim baskısı gibi sonuçlar yaratabilir.

## Medya ve vaat hafızası

Başkan açıklamaları ve vaatleri kaydedilecek. Örneğin teknik direktöre kamuoyu önünde destek verip iki gün sonra kovmak medya güvenilirliğini düşürmelidir.

Vaat örnekleri:

- Avrupa hedefi
- borç azaltma
- altyapı yatırımı
- yıldız transfer
- stadyum genişletme
- genç oyuncu kullanımı

## Seçimler

Daha sonraki aşama. Sportif başarı, borç, kulüp değeri, tesis, taraftar güveni, tutulmuş vaatler ve medya itibarı etkili olabilir. Seçim kaybı kariyeri tamamen bitirmek zorunda değildir; başka kulüp teklifleri mümkün olabilir.

## Tesis / altyapı / sponsor / kriz

Planlanan tesisler:

- altyapı
- antrenman
- sağlık
- scouting
- stadyum
- kulüp mağazası

Her yatırımın gerçek sistem etkisi olmalıdır.

Kriz örnekleri: maaş talebi, kaptan-hoca çatışması, sponsor ayrılığı, bilet protestosu, büyük transfer teklifi, genç oyuncunun süre isteği, teknik direktörün yönetimi eleştirmesi, stadyum bakım problemi, federasyon cezası, menajer baskısı.

---

# 4. Teknik mimari

Temel yaklaşım:

> **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**

## `simulation_core`

Saf Dart domain modelleri ve oyun kuralları. Flutter/Android API bağımlılığı yoktur.

## `simulation_runner`

Headless Dart/CLI. Tek sezon, uzun kariyer, batch test, seed replay ve denge raporları.

## `persistence`

İleride versiyonlu yerel save/load. Hedefler:

- `saveVersion`
- `gameVersion`
- `simulationVersion`
- `dataVersion`
- career seed
- checksum/integrity
- migration history
- autosave
- önceki autosave yedeği
- manuel save

Flutter tarafında Drift/SQLite değerlendirilebilir.

## `application`

Başkan use-case katmanı: kariyer başlatma, zaman ilerletme, transfer teklifi, teknik direktör işe alma/kovma, sponsor, medya, vaat, tesis kararı vb.

## `presentation`

Flutter mobil UI. Henüz geliştirme kapsamına alınmadı.

---

# 5. Kritik teknik kararlar

## Deterministik RNG

Aynı `simulationVersion`, veri seti, kariyer seed'i ve karar dizisi aynı sonucu üretmelidir.

Maç seed'i maç bazında türetilir:

`matchSeed = hash(careerSeed, seasonIndex, fixtureId, simulationVersion)`

Kararlı FNV-1a tabanlı hash ve özel xorshift32 `SeededRng` kullanılır; runtime `hashCode` davranışına güvenilmez.

Transfer pazarlıkları da kariyer seed'i, sezon, alıcı ve oyuncu kimliği üzerinden deterministik türetilir.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate` kullanılır.

## Para

Parasal değerler integer minor-unit tabanlı `Money` value object ile tutulur. Yüzde hesapları basis-point integer aritmetiği kullanır.

## Muhasebe

Borç anapara ödemesi gider değildir; faiz giderdir.

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Negatif nakit sessizce sıfırlanmaz; gerektiğinde `emergencyBorrowing` olarak açık borç yaratılır.

## Transfer muhasebesi

Bonservis yeni para yaratmaz:

`Alıcı nakit = Alıcı nakit - fee`

`Satıcı nakit = Satıcı nakit + fee`

Transfer sırasında borç doğrudan değişmez. Pencere sonrası finans sonraki sezonun açılış finansıdır.

## Domain event yönü

İleride transfer, teknik direktör, vaat, medya, borç, tesis, derbi gibi önemli olaylar domain event geçmişine yazılacaktır. Tam event sourcing zorunlu değildir.

---

# 6. GitHub / CI çalışma kararı

Repo **Public** kalacaktır. Açık kaynak lisansı verilmemiştir; `LICENSE.md` proprietary notice içerir.

Tek hafif CI workflow'u kullanılır. Her milestone için ayrı workflow açılmaz.

CI şu anda:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1 20 sezon kariyer
- M2 20 sezon oyuncu kariyeri
- M3 20 sezon ekonomi kariyeri
- M4 20 sezon transfer kariyeri
- M5 20 sezon / 48 kulüp / 3 lig dünya kariyeri

çalıştırır.

CI içinde APK/AAB, büyük binary ve `actions/upload-artifact` yoktur. Artifact hedefi `0`dır.

M0–M5 üretiminde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu.

---

# 7. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS

- 8 kurgu kulüp
- çift devre
- 56 maç/sezon
- Poisson tabanlı maç motoru
- standings + validator
- 100 sezon regresyon

100 sezon baseline:

- 5.600 maç
- ev `%45,2857`
- beraberlik `%24,5893`
- deplasman `%30,1250`
- gol/maç `2,5864`
- invariant issue `0`

## M1 — 20 Sezon Yaşam Döngüsü — PASS

- `GameDate`
- `CareerEngine`
- 20 sezon
- 1.120 maç
- deterministik sezon geçişi

Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

Başlangıç `144` oyuncu.

Seed `20260903` / 20 sezon:

- final oyuncu `148`
- emeklilik `148`
- youth intake `152`
- aktif akademi mezunu `146`
- final yaş ortalaması `25,84`
- validation issue `0`

## M3 — Temel Kulüp Ekonomisi — PASS

İlk koşu REDDEDİLDİ: `1.017,03M` nakit, `0` borç, 8/8 veryStrong.

Kabul edilen seed `20260903`:

- final cash `124,28M`
- final debt `104,43M`
- emergency borrowing `67,44M`
- 2 veryStrong / 2 solid / 2 balanced / 2 debtCrisis
- validation `0`

PR #4 squash merge edildi.

## M4 — Basit Transfer Pazarı — PASS

Ana kurallar:

- piyasa değeri ≠ gerçek fiyat
- mevki ihtiyacı
- satıcı talebi / alıcı maksimumu
- finans baskısında satıcı esnekliği
- min 2M rezerv
- pencere başına nakdin en fazla %35'i harcama
- kulüp başına en fazla 2 alım
- kadro / pozisyon satış tabanları
- transfer nakdi korunumu

Kabul edilen seed `20260903` / 20 sezon:

- transfer `32`
- hacim `161,68M`
- ortalama bonservis `5,05M`
- final cash `96,38M`
- final debt `58,61M`
- final oyuncu `148`
- validation `0`

PR #5 squash merge edildi. Artifact `0`.

---

# 8. M5 — 48 Kulüp / 3 Lig — PASS

M5, projenin başlangıçta belirlenen ilk büyük teknik ölçek hedefidir.

## Dünya

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- Taç Ligi / Birlik Ligi / Ufuk Ligi
- 30 maç/kulüp
- 240 maç/lig
- 720 maç/sezon
- 20 sezonda 14.400 maç
- 864 başlangıç oyuncusu

## Terfi / düşme

Her sezon arası:

- Taç son 3 → Birlik
- Birlik ilk 3 → Taç
- Birlik son 3 → Ufuk
- Ufuk ilk 3 → Birlik

12 hareket/sezon geçişi; 19 geçişte toplam `228`.

## World engine

Eklenen ana parçalar:

- `LeagueTier`
- `WorldLeague`
- `FictionalWorldFactory`
- `WorldCareerEngine`
- `WorldCareerSeason`
- `WorldCareerReport`
- `WorldCareerValidator`
- M5 CLI runner
- M5 scale/balance sanity guard

Mevcut M0–M4 motorları yeniden yazılmadı; `WorldCareerEngine` üst katman olarak onları birleştirir.

## Lig ekonomisi

`BasicEconomyEngine` geriye dönük uyumlu iki opsiyonel ölçek kazandı:

- gelir/başlangıç finansı: `economicScaleBps`
- maaş/işletme maliyeti: `costScaleBps`

Varsayılan `%100/%100` kaldığı için M0–M4 baseline'ları değişmedi.

M5 geçici ölçekleri:

- Taç: gelir `%100`, maliyet `%100`
- Birlik: gelir `%90`, maliyet `%85`
- Ufuk: gelir `%80`, maliyet `%75`

## Reddedilen M5 denemeleri

### Deneme 1 — RED

- transfer `2`
- hacim `17,00M`
- cash `105,05M`
- debt `3.966,16M`

Alt ligler borç ölüm sarmalına girdi, pazar dondu.

### Deneme 2 — RED

- transfer `7`
- hacim `58,48M`
- cash `237,18M`
- debt `2.268,60M`
- emergency `2.688,27M`
- debtCrisis `34/48`

### Deneme 3 — RED / karşı uç

- transfer `158`
- hacim `1.556,01M`
- cash `1.909,01M`
- debt `318,16M`
- emergency `113,71M`
- veryStrong `22/48`

Borç çözüldü fakat dünya aşırı servet üretti.

## Kabul edilen M5 baseline — seed `20260903`

- sezon `20`
- maç `14.400`
- başlangıç oyuncu `864`
- final oyuncu `906`
- lig hareketi `228`
- transfer `71`
- transfer hacmi `637,91M`
- ortalama bonservis `8,98M`
- final cash `862,25M`
- final debt `647,04M`
- emergency borrowing `569,03M`
- transfer katılımcısı `35` farklı kulüp
- farklı Taç Ligi şampiyonu `10`
- validation issue `0`

Final health:

- veryStrong `16`
- solid `14`
- balanced `8`
- debtCrisis `10`

Final ortalama lig güçleri:

- Taç `72,01`
- Birlik `65,54`
- Ufuk `59,21`

Sportif katmanlar doğru sırada ayrışıyor.

Final lig finans toplamları:

- Taç: cash `241,93M`, debt `364,86M`
- Birlik: cash `213,52M`, debt `230,12M`
- Ufuk: cash `406,79M`, debt `52,06M`

**Açık denge notu:** Ufuk Ligi final nakdinin üst liglerden yüksek olması nihai ekonomi kabulü değildir. Kulüpler ligler arasında hareket ediyor ve mevcut `WageModel` gerçek sözleşme/maaşa dayanmıyor. Gerçek sözleşme/maaş sistemi eklendiğinde lig bazlı maliyet/nakit birikimi yeniden kalibre edilecektir.

M5 sanity guard:

- final oyuncu `600–1.150`
- transfer `60–600`
- hacim `200M–4B`
- final cash `150M–1,5B`
- final debt `>0` ve `<1,5B`
- emergency `<1,5B`
- en az 2 health sınıfı
- debtCrisis en fazla 20
- en az 4 farklı üst lig şampiyonu
- en az 20 farklı transfer katılımcısı

Transfer alt sınırı ilk başta kalibrasyonsuz `80` seçilmişti. 71 transfer + 35 katılımcı + 637,91M hacmin donmuş pazar olmadığı görüldüğü için geniş regresyon bariyeri `60` olarak kalibre edildi.

M5 PR kalite kapısı:

- `dart analyze`: PASS
- test `23/23 PASS`
- M0–M5 runner PASS
- M5 validation `0`
- artifact `0`

Ayrıntılı teknik belge: `M5_48_KULUP_3_LIG.md`.

---

# 9. Roadmap

- ✅ M0 — Deterministik Mini Lig
- ✅ M1 — 20 Sezon Yaşam Döngüsü
- ✅ M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi
- ✅ M3 — Temel Kulüp Ekonomisi
- ✅ M4 — Basit Transfer Pazarı
- ✅ M5 — 48 Kulüp / 3 Lig
- ⏭️ **M6 — Teknik Direktör Sistemi**

M6 önerilen kapsam:

- teknik direktör modeli ve profil etiketleri
- kalite / genç geliştirme / insan yönetimi / disiplin / medya / bütçe talebi
- kulüp–teknik direktör uyum skoru
- işe alma
- görevden alma
- sözleşme özeti
- yönetim ilişkisi
- transfer/bütçe beklentisi
- takım gücü ve oyuncu gelişimine etkisi
- 20 sezon teknik direktör görev süresi / değişim sanity guard'ı

M6'da oyuncu teknik direktörün taktiğini yönetmeyecek. Amaç başkanın **doğru hocayı seçmesi ve yönetmesi** olacak.

M6 sonrasında aday sıra:

1. gelişmiş oyuncu sözleşmesi ve maaş sistemi
2. gelişmiş transfer yapıları: kiralık/taksit/bonus/satıştan pay
3. taraftar beklenti ve güven sistemi
4. medya hafızası + başkan vaatleri
5. tesis / altyapı yatırımları
6. sponsor ve kriz/event sistemi
7. başkan değerlendirmesi / seçimler

Bu sıra ileride test sonuçlarına göre değişebilir.

---

# 10. Uzun kariyer kalite hedefleri

Kademeli hedef:

- 20 sezon geliştirici testi
- 100 kariyer × 20 sezon temel denge
- 500 kariyer × 30 sezon regresyon
- 1.000 kariyer × 30 sezon major-release stres testi

Ölçülecek metrikler:

- aktif oyuncu ve yaş dağılımı
- genç üretimi / emeklilik
- kulüp nakdi / borcu / emergency borrowing
- maaş / gelir oranı
- transfer sayısı / hacmi / yaş / mevki
- ligler arası transfer dağılımı
- terfi/düşme dağılımı
- şampiyonluk çeşitliliği
- büyük/küçük kulüp farkı
- ileride taraftar güveni
- teknik direktör görev süresi
- vaat başarı oranı
- başkan görev süresi

Her başarısız kariyer seed ile tekrar üretilebilmelidir.

---

# 11. İlk aşamada yapılmayacaklar

- 3D maç
- online multiplayer
- gerçek kulüp/futbolcu/logo
- ayrıntılı saha içi taktik
- Football Manager seviyesinde attribute sistemi
- tam dünya futbol piramidi / onlarca ülke
- erken monetizasyon optimizasyonu
- görsel polish baskısı
- simülasyon kanıtlanmadan APK üretme baskısı

---

# 12. Monetizasyon yönü

Daha sonra yeniden değerlendirilecek. Pay-to-win olmayacak.

Adaylar:

- tek seferlik premium
- reklam kaldırma
- isteğe bağlı ödüllü reklam
- kozmetik kulüp temaları

Oyun ekonomisi IAP baskısı için yapay biçimde bozulmayacaktır.

---

# 13. Codex çalışma kuralı

Codex kredisi gereksiz kullanılmayacaktır.

Codex özellikle:

- büyük çok dosyalı implementasyon
- büyük refactor
- otomatik test altyapısı
- karmaşık bug fix
- migration

konularında kullanılabilir.

Basit analiz, formül, küçük belge veya küçük kod değişikliklerinde kullanılmaz.

M0–M5 doğrudan GitHub araçlarıyla yürütüldü; Codex kredisi kullanılmadı.

---

# 14. Proje yönetim kuralı

Bu sohbet projenin ana çalışma sohbetidir.

`GENEL_PROJE_OZETI.md` önemli çalışmalardan sonra güncellenecek:

- yeni kararlar
- tamamlanan işler
- test sonuçları
- reddedilen denemeler
- açık sorunlar
- teknik mimari
- simülasyon sonuçları
- sıradaki işler

Yeni açık karar eski çelişkili kararı geçersiz kılar. GitHub kullanılıyorsa **canlı GitHub durumu eski sohbet notlarından üstündür**.

---

# 15. Güncel durum

**Tamamlanan:** M0, M1, M2, M3, M4 ve M5.

**İlk büyük teknik hedef başarıyla kanıtlandı:**

> 48 kurgu kulüp + 3 lig + 864 başlangıç oyuncusu + yaşayan oyuncu havuzu + ekonomi + transfer + terfi/düşme, 20 sezon / 14.400 maç boyunca deterministik ve validation issue `0` ile çalışabiliyor.

Bu henüz oynanabilir ürün ve nihai ekonomi değildir. Özellikle gerçek oyuncu sözleşmesi/maaşı, teknik direktör, taraftar, medya ve başkan karar sistemleri eklenmeden denge final sayılmaz.

**Sıradaki iş:**

## M6 — Teknik Direktör Sistemi

M6 da önce headless simülasyon olarak geliştirilecek. Flutter UI/APK hâlâ zorunlu değildir.
