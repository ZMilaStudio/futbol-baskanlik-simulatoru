# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 03.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public  
**Aktif teknik aşama:** **M3 PASS — sıradaki milestone M4 / Basit Transfer Pazarı**  
**Ana proje durumu:** Yan geliştirme. Kelime Avı ve Minik Dedektif gibi aktif projeleri aksatmayacak.

---

# 1. Proje kimliği

Futbol Başkanlık Simülatörü, ZMila Studio için geliştirilecek tam kapsamlı Android mobil futbol kulübü başkanlığı simülasyonudur.

Temel kimlik:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

Alternatif slogan:

> **“Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.”**

Oyuncu saha içi diziliş, antrenman ve maç içi değişikliklerle uğraşmaz. Başkan olarak ekonomi, teknik direktör seçimi, transfer politikası, borç, altyapı, tesis, sponsor, taraftar, medya, vaatler, krizler ve uzun vadeli kulüp sağlığını yönetir.

Gerçek kulüp, futbolcu, lig logosu veya lisanslı materyal kullanılmayacaktır.

---

# 2. Değişmez tasarım prensipleri

1. Başkan teknik direktör değildir.
2. Mobil arayüz sade olacak; derin hesaplamalar arka planda çalışabilir.
3. Taraftar ekonomik ve sportif bağlamı anlamalıdır.
4. Transfer AI yaş, kalite, potansiyel, sözleşme, ihtiyaç ve ekonomik durumu dikkate almalıdır.
5. Piyasa değeri ile gerçek transfer fiyatı aynı değildir.
6. Doğru karar her zaman açık olmamalıdır.
7. Kısa vadeli sportif başarı ile uzun vadeli kulüp sağlığı arasında gerilim yaratılmalıdır.
8. Geçmiş açıklamalar, vaatler ve önemli kararlar unutulmamalıdır.
9. Bazı kararların sonuçları sezonlar sonra ortaya çıkabilmelidir.
10. Uzun kariyer otomatik simülasyonlarla test edilmelidir.
11. İlk sürüm gereksiz sistemlerle şişirilmemelidir.
12. İlk hedef UI/APK değil sağlam simülasyon çekirdeğidir.
13. Para yoksa sistem transferi tamamen kapatmak yerine daha akıllı finansal/transfer seçenekleri üretmelidir.
14. Uzun kariyerde evrensel refah veya evrensel çöküş kabul edilmez; denge otomatik kalite kapılarıyla izlenir.

---

# 3. Teknik mimari

Temel yaklaşım: **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**.

## `simulation_core`

Saf Dart. Domain modelleri ve oyun kuralları burada bulunur. Flutter/Android API'lerine bağımlı değildir.

## `simulation_runner`

Headless Dart/CLI. Tek sezon, uzun kariyer, batch simülasyon, seed tekrar oynatma ve denge raporları için kullanılır.

## `persistence`

İleride yerel, versiyonlu save/load; migration, otomatik kayıt ve yedek kayıt. Flutter tarafında Drift/SQLite değerlendirilebilir.

## `application`

Başkan eylemlerini yönetecek use-case katmanı: kariyer başlatma, hafta ilerletme, transfer teklifi, teknik direktör işe alma/kovma, sponsor, medya, vaat ve tesis kararları.

## `presentation`

Flutter mobil UI. Henüz geliştirme kapsamına alınmadı.

---

# 4. Kritik teknik kararlar

## Deterministik simülasyon

Aynı `simulationVersion`, veri seti, kariyer seed'i ve karar dizisi aynı sonucu üretmelidir.

Maç seed'i global RNG zinciri yerine maç bazında türetilir:

`matchSeed = hash(careerSeed, seasonIndex, fixtureId, simulationVersion)`

Kararlı FNV-1a tabanlı hash ve özel xorshift32 `SeededRng` kullanılmaktadır. Dart runtime `hashCode` davranışına güvenilmez.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate` gerçek kodda devrededir.

## Para

M3 ile parasal değerler `double` yerine integer minor-unit tabanlı `Money` value object ile tutulmaya başlandı. Yüzde hesapları basis-point integer aritmetik kullanır.

## Muhasebe

Borç anapara ödemesi gider değildir. Faiz giderdir.

Nakit denklemi:

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

Borç denklemi:

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Negatif nakit görünmez biçimde sıfırlanmaz; gerekiyorsa `emergencyBorrowing` olarak açıkça borca yazılır.

## Event geçmişi

İleride transfer, teknik direktör, vaat, medya, borç, tesis ve önemli sportif olaylar domain event olarak tutulacaktır.

---

# 5. GitHub / CI çalışma kararı

Repo **Public** kalacaktır. Önceki Private planı geçersizdir.

Ana gerekçe GitHub Actions kullanım/kota avantajıdır.

Repo public olsa da proje açık kaynak değildir; `LICENSE.md` içinde proprietary notice vardır.

Tek hafif CI workflow'u kullanılır. Yeni milestone için ayrı workflow açılmaz.

CI şu anda:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon regresyonu
- M1 20 sezon kariyeri
- M2 20 sezon oyuncu kariyeri
- M3 20 sezon ekonomi kariyeri

çalıştırır.

CI içinde:

- APK yok
- AAB yok
- büyük binary yok
- `actions/upload-artifact` yok
- artifact sayısı hedefi `0`

Codex kredisi şu ana kadarki M0–M3 üretiminde kullanılmadı; GitHub araçları yeterli oldu.

---

# 6. M0 — Deterministik Mini Lig — PASS

Kapsam:

- 8 hayalî kulüp
- tek lig
- çift devre / 14 hafta / 56 maç
- takım başına 7 iç + 7 deplasman
- tek `strength` puanı
- deterministik fixture + maç seed'i
- Poisson gol üretimi
- puan tablosu
- `SeasonReport` + `SeasonValidator`
- 100 sezon batch testi

Maç baseline:

`d = clamp((homeStrength + 2) - awayStrength, -30, 30)`

`homeLambda = clamp(1.35 × exp(d / 45), 0.25, 3.50)`

`awayLambda = clamp(1.15 × exp(-d / 45), 0.25, 3.50)`

Gerçek regresyon sonucu:

- 100 sezon
- 5.600 maç
- ev galibiyeti `%45,2857`
- beraberlik `%24,5893`
- deplasman galibiyeti `%30,1250`
- gol/maç `2,5864`
- invariant issue `0`

M0 kalite kapısı kapandı.

---

# 7. M1 — 20 Sezon Yaşam Döngüsü — PASS

Eklenen ana parçalar:

- `GameDate`
- `CareerEngine`
- `CareerReport`
- `CareerSeason`
- `CareerValidator`
- geçici `ClubStrengthEvolution`

Varsayılan kariyer:

- başlangıç `2026-07-01`
- sezon index `0...19`
- bitiş `2046-07-01`
- 20 sezon
- toplam `1.120` maç

Seed `20260903` örnek M1 şampiyonlukları:

- Vadişehir `10`
- Kuzey Yıldızı `6`
- Demirkent `4`

M1'deki sezonlar arası strength modeli geçici köprü modelidir; M2 ile kadrodan takım gücü türetme devreye girdi.

M1 kalite kapısı kapandı.

---

# 8. M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

Eklenen ana parçalar:

- `Player`
- pozisyon sistemi
- deterministik başlangıç oyuncu havuzu
- yaşlanma
- gelişim / düşüş
- 34–38 yaş arası emeklilik
- genç üretimi
- ilk 11 kalitesinden takım strength hesaplama
- player career report / validator

Başlangıç:

- 8 kulüp
- kulüp başına 18 oyuncu
- toplam `144` oyuncu

Seed `20260903` / 20 sezon gerçek sonuç:

- final aktif oyuncu `148`
- toplam emeklilik `148`
- toplam youth intake `152`
- aktif akademi mezunu `146`
- final yaş ortalaması `25,84`
- validation issue `0`

Final kadrodan türetilmiş takım güçleri:

- Kuzey Yıldızı `79,59`
- Vadişehir `74,68`
- Demirkent `73,10`
- Mavi Liman `68,94`
- Çınarspor `66,77`
- Ufukşehir `63,10`
- Gölova `60,44`
- Hisar Birliği `58,04`

M2 kalite kapısı kapandı.

---

# 9. M3 — Temel Kulüp Ekonomisi — PASS

M3 ile M2 oyuncu/kadro kariyerinin üzerine gerçek finans yaşam döngüsü eklendi.

Ana parçalar:

- integer minor-unit tabanlı `Money`
- `ClubFinanceState`
- sezonluk finans raporu
- `BasicEconomyEngine`
- `EconomyCareerEngine`
- `EconomyCareerReport`
- `EconomyCareerValidator`
- `FinancialHealth`
- geçici `WageModel`
- M3 CLI runner
- 20 sezon ekonomi sanity guard testi

## M3 gelirleri

- merkezi gelir
- sponsor geliri
- maç günü geliri
- lig sırasına bağlı başarı geliri

Sponsor ve maç günü gelirleri mevcut takım gücüyle ölçeklenir.

## M3 giderleri

- oyuncu kalitesinden türetilen geçici maaş yükü
- işletme gideri
- borç faizi

Gerçek oyuncu sözleşmesi/maaşı henüz bulunmadığı için `WageModel` geçici köprüdür.

## Borç davranışı

- açılış nakit/borç değerleri seed ve kulüp profiline göre deterministik oluşturulur,
- yıllık faiz giderdir,
- yıllık normal anapara geri ödemesi açılış borcunun `%5`idir,
- nakit minimum seviyenin altına düşerse fark `emergencyBorrowing` olarak yeni borca eklenir.

## İlk M3 denemesi — REDDEDİLDİ

İlk gerçek 20 sezon CI koşusu teknik olarak PASS olmasına rağmen ekonomik olarak kabul edilmedi:

- final toplam nakit `1.017,03M`
- final toplam borç `0,00M`
- acil finansman `0,00M`
- 8/8 kulüp `veryStrong`

Neden: ekonomi 20 yılda evrensel refah ve otomatik borç sıfırlaması üretiyordu.

Uygulanan düzeltmeler:

- yapısal işletme giderleri yükseltildi,
- fazla nakdi otomatik ek borç kapatmaya dönüştüren davranış kaldırıldı,
- finansal sağlık eşikleri sıkılaştırıldı.

## Kabul edilen M3 baseline

Seed `20260903` / 20 sezon:

- sezon `20`
- maç `1.120`
- final toplam nakit `124,28M`
- final toplam borç `104,43M`
- toplam acil finansman `67,44M`
- validation issue `0`

Final finansal sağlık:

- `veryStrong`: 2
- `solid`: 2
- `balanced`: 2
- `debtCrisis`: 2

Kulüp bazında final:

- Kuzey Yıldızı: cash `2,91M`, debt `16,70M`, `balanced`
- Vadişehir: cash `51,02M`, debt `8,07M`, `solid`
- Demirkent: cash `7,35M`, debt `7,13M`, `balanced`
- Mavi Liman: cash `2,00M`, debt `39,60M`, `debtCrisis`
- Çınarspor: cash `15,36M`, debt `5,75M`, `solid`
- Ufukşehir: cash `2,00M`, debt `19,28M`, `debtCrisis`
- Gölova: cash `21,05M`, debt `3,96M`, `veryStrong`
- Hisar Birliği: cash `22,59M`, debt `3,94M`, `veryStrong`

Bu değerler nihai oyun ekonomisi değildir. M3 için amaç, karar sistemi ve transfer pazarı eklenmeden önce **çeşitli ve sürdürülebilir bir baseline** oluşturmaktır.

## Kalıcı M3 sanity guard'ları

20 sezon baseline için geniş alarm aralıkları CI içine eklendi:

- final toplam nakit `20M–500M`
- final toplam borç `>0` ve `<400M`
- toplam acil finansman `<250M`
- final sağlık dağılımında en az 2 sınıf
- `debtCrisis` en fazla 4 kulüp
- `veryStrong` en fazla 4 kulüp

Bu eşikler nihai denge hedefi değil, ekonomik patlamayı/çöküşü otomatik yakalayan regresyon bariyerleridir.

M3 PR #4 squash merge ile `main`e alındı. Merge commit: `6cacf8b8389c18ba8ab4a82e7933c36557887a5c`.

M3 kalite kapısı:

- `dart analyze`: PASS
- otomatik test: `15/15 PASS`
- M0 regresyon: PASS
- M1 regresyon: PASS
- M2 regresyon: PASS
- M3 20 sezon: PASS
- sanity guard: PASS
- artifact: `0`

M3 kalite kapısı kapandı.

---

# 10. Roadmap

## M0 — Deterministik Mini Lig
**PASS**

## M1 — 20 Sezon Yaşam Döngüsü
**PASS**

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi
**PASS**

## M3 — Temel Kulüp Ekonomisi
**PASS**

## M4 — Basit Transfer Pazarı
**Sıradaki milestone.**

İlk kontrollü kapsam:

- oyuncu piyasa değeri baseline modeli
- kulüp pozisyon ihtiyacı
- satıcı için kabul edilebilir fiyat
- alıcı için maksimum fiyat
- doğrudan bonservis teklifi
- bütçe/nakit kontrolü
- oyuncunun bir kulüpten diğerine taşınması
- transfer gelir/giderinin kulüp finansına yazılması
- transfer sonrası kadro strength yeniden hesaplama
- sezonlar arasında transfer penceresi
- aynı seed ile aynı transfer pazarı
- 20 sezon transfer hacmi / fiyat dağılımı / bütçe ihlali raporu

M4'ün ilk sürümünde henüz kiralık, taksit, bonus, satıştan pay ve takas zorunlu değildir. Önce doğrudan bonservis sistemi mantıklı çalışmalıdır.

## M5 — 48 Kulüp / 3 Lig

Yaklaşık 48 özgün kulüp, 3 lig, yükselme/düşme, oyuncu yaşam döngüsü, ekonomi, temel transfer ve 20 sezon otomatik kariyer.

Bu nokta ilk büyük teknik başarı hedefidir.

---

# 11. Uzun kariyer kalite hedefleri

İleride:

- 20 sezon geliştirici testi
- 100 kariyer × 20 sezon temel denge
- 500 kariyer × 30 sezon regresyon
- 1.000 kariyer × 30 sezon stres testi

Ölçülecek metrikler:

- aktif oyuncu sayısı
- oyuncu yaş dağılımı
- genç üretimi
- emeklilik
- kulüp nakdi
- kulüp borcu
- acil finansman
- maaş / gelir oranı
- transfer ücretleri
- transfer sayısı
- transfer yaşı ve pozisyon dağılımı
- şampiyonluk dağılımı
- büyük/küçük kulüp farkı
- ileride taraftar güveni
- teknik direktör görev süresi
- başkan görev süresi

Her başarısız kariyer seed ile tekrar üretilebilmelidir.

---

# 12. İlk aşamada yapılmayacaklar

- 3D maç
- online multiplayer
- gerçek kulüp/futbolcu
- lisanslı logo
- ayrıntılı saha içi taktik
- Football Manager seviyesinde attribute sistemi
- onlarca ülke / tam dünya futbol piramidi
- erken monetizasyon optimizasyonu
- görsel polish
- APK üretme baskısı

---

# 13. Codex çalışma kuralı

Codex kredisi gereksiz kullanılmayacaktır.

Codex; büyük çok dosyalı implementasyon, büyük refactor, simülasyon/test altyapısı, karmaşık hata düzeltmesi ve migration gibi yüksek kaldıraçlı işlerde kullanılabilir.

Basit analiz, tasarım kararı, formül konuşması ve küçük belge değişikliklerinde kullanılmaz.

M0, M1, M2 ve M3 doğrudan GitHub araçlarıyla yürütüldü; Codex kredisi kullanılmadı.

---

# 14. Güncel durum

**Tamamlanan:**

- ✅ M0 — lig / maç çekirdeği
- ✅ M1 — 20 sezon kariyer yaşam döngüsü
- ✅ M2 — oyuncu yaşam döngüsü
- ✅ M3 — temel ekonomi

**Güncel teknik kanıt:**

Saf Dart çekirdeği 8 kulüp ve yaşayan oyuncu havuzuyla 20 sezon / 1.120 maçı deterministik biçimde çalıştırabiliyor; oyuncular yaşlanıyor/emekli oluyor, gençler sisteme giriyor, takım strength kadrodan türetiliyor, kulüpler sezonluk gelir/gider/borç döngüsünü yaşıyor ve muhasebe denklemleri ile uzun dönem ekonomi sanity guard'ları CI üzerinde doğrulanıyor.

**Sıradaki iş:**

## M4 — Basit Transfer Pazarı

M4 de Flutter UI/APK kapsamına girmeyecek. İlk hedef, kulüplerin finansal durumları ve kadro ihtiyaçlarıyla uyumlu biçimde oyuncu alıp satabildiğini 20 sezon otomatik simülasyonda kanıtlamaktır.
