# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 03.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public / proprietary notice  
**Aktif teknik aşama:** **M6 PASS — sıradaki milestone M7 / Oyuncu Sözleşmesi + Gerçek Maaş Sistemi**  
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

Oyuncu saha içi diziliş, antrenman, duran top ve maç içi değişiklik yapmaz. Başkan olarak ekonomi, borç, teknik direktör seçimi, transfer politikası, altyapı, tesis, sponsor, taraftar, medya, vaat, kriz ve uzun vadeli kulüp sağlığını yönetir.

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
8. Para yoksa transfer kapanmamalı; daha akıllı transfer yolları gerekli olmalıdır.
9. Geçmiş açıklamalar, vaatler ve önemli kararlar unutulmamalıdır.
10. Bazı kararların sonuçları aylar veya sezonlar sonra ortaya çıkabilmelidir.
11. Doğru karar her zaman açık olmamalıdır.
12. İlk sürüm gereksiz sistemlerle şişirilmemelidir.
13. Uzun kariyer otomatik simülasyonlarla test edilmelidir.
14. Aynı seed ve karar dizisi aynı sonucu üretmelidir.
15. Ekonomi ne evrensel refah ne de evrensel çöküş üretmelidir.
16. Transfer piyasası ne donmuş ne de hiperaktif olmalıdır.
17. Teknik direktör kadronun önüne geçemez; katkısı önemlidir ama sınırlıdır.
18. UI/APK, simülasyon çekirdeği kanıtlanmadan öncelik değildir.

---

# 3. Teknik mimari

Temel yaklaşım:

> **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**

- `simulation_core`: saf Dart domain ve oyun kuralları.
- `simulation_runner`: headless Dart/CLI, seed replay, uzun kariyer ve denge raporları.
- `persistence`: ileride versiyonlu yerel save/load, migration, autosave ve backup.
- `application`: başkan use-case katmanı.
- `presentation`: Flutter mobil UI; henüz kapsam dışı.

## Determinizm

Kararlı FNV-1a tabanlı hash + özel xorshift32 `SeededRng` kullanılır. Runtime `hashCode` davranışına güvenilmez. Maç, transfer ve manager kararları career seed / simulation version / sezon / entity ID'lerinden deterministik türetilir.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate` kullanılır.

## Para ve muhasebe

Para `double` değil integer minor-unit tabanlı `Money` ile tutulur.

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Negatif nakit sessizce sıfırlanmaz; gerektiğinde `emergencyBorrowing` olarak borca yazılır. Transfer bonservisi yeni para yaratmaz; alıcıdan satıcıya nakit taşır.

## World lifecycle hook

M6 ile `WorldCareerEngine` opsiyonel `WorldCareerHooks` kazandı. Varsayılan `NoopWorldCareerHooks` tamamen etkisizdir; M5 baseline'ı değişmez. Manager sistemi `ManagerCareerController` hook'u ile world engine'e bağlanır.

Bu hook yönü ileride taraftar, medya, vaat ve kriz sistemlerinin motoru kopyalamadan eklenmesi için tercih edildi.

---

# 4. GitHub / CI çalışma kuralı

Repo public kalacaktır ancak açık kaynak lisansı verilmemiştir; `LICENSE.md` proprietary notice içerir.

Tek hafif CI workflow'u kullanılır. CI:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1 20 sezon kariyer
- M2 20 sezon player kariyer
- M3 20 sezon economy kariyer
- M4 20 sezon transfer kariyer
- M5 20 sezon / 48 kulüp / 3 lig world kariyer
- M6 20 sezon manager-aware world kariyer

çalıştırır.

APK/AAB, büyük binary ve `actions/upload-artifact` yoktur. Artifact hedefi `0`dır.

Codex kredisi M0–M6 üretiminde kullanılmadı; mevcut GitHub araçları yeterli oldu. Codex yalnız büyük çok dosyalı değişiklik, ağır refactor, migration veya karmaşık hata için kullanılacaktır.

---

# 5. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS

- 8 kurgu kulüp
- çift devre / 56 maç
- deterministik fixture + maç seed'i
- Poisson tabanlı gol motoru
- standings + validator
- 100 sezon regresyon

100 sezon baseline: 5.600 maç, ev `%45,2857`, beraberlik `%24,5893`, deplasman `%30,1250`, gol/maç `2,5864`, invariant issue `0`.

## M1 — 20 Sezon Yaşam Döngüsü — PASS

- `GameDate`
- `CareerEngine`
- 20 sezon / 1.120 maç
- deterministik sezon geçişi

Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

Başlangıç 144 oyuncu. Seed `20260903` / 20 sezon: final 148 oyuncu, 148 emeklilik, 152 youth intake, 146 aktif akademi mezunu, yaş ortalaması `25,84`, validation `0`.

## M3 — Temel Kulüp Ekonomisi — PASS

İlk koşu ekonomik olarak REDDEDİLDİ: `1.017,03M` nakit, `0` borç, 8/8 `veryStrong`.

Kabul baseline: cash `124,28M`, debt `104,43M`, emergency `67,44M`, sağlık dağılımı 2 `veryStrong` / 2 `solid` / 2 `balanced` / 2 `debtCrisis`, validation `0`.

M3 ile integer `Money`, gelir/gider, borç/faiz ve acil finansman devreye girdi. `WageModel` hâlâ geçici köprüdür.

## M4 — Basit Transfer Pazarı — PASS

- market value modeli
- mevki ihtiyacı
- satıcı talebi / alıcı maksimumu
- finans baskısında satıcı esnekliği
- minimum 2M rezerv
- pencere harcama limiti `%35`
- kulüp başına en fazla 2 alım
- kadro/pozisyon satış tabanları
- doğrudan bonservis nakit korunumu

Seed `20260903`: 32 transfer, `161,68M` hacim, `5,05M` ortalama ücret, cash `96,38M`, debt `58,61M`, final 148 oyuncu, validation `0`.

Kiralık, taksit, bonus, takas, satıştan pay ve gerçek kontrat henüz yoktur.

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

- 20 sezon / 14.400 maç
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

Açık denge notu: Ufuk Ligi final nakit birikimi üst liglerden yüksektir. Bu nihai ekonomi kabulü değildir; gerçek maaş/sözleşme sistemi geldiğinde yeniden kalibre edilecektir.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi — PASS

M6 başkanlık kimliğini ilk kez yaşayan manager sistemiyle güçlendirdi.

### Domain

96 deterministik manager; profiller:

- `balanced`
- `youthDeveloper`
- `budgetBuilder`
- `starManager`
- `resultsFirst`

Alanlar: yaş/emeklilik, reputation, coaching, youthDevelopment, manManagement, boardCooperation, budgetDemand.

### Uyum ve sportif etki

`ManagerFitModel` manager profilini kulüp finansı, lig seviyesi, kadro yaşı/potansiyeli ve takım gücüyle eşleştirir.

`ManagerImpactModel` coaching + man management + fit + board relationship + genç oyuncu oranı/youthDevelopment etkisini toplar ve kesin `-2,5...+2,5` aralığına sınırlar.

Manager bonusu yalnız maç strength'ine uygulanır. Oyuncu lifecycle ve transfer market ham kadro gücünü kullanır.

### Görev yaşam döngüsü

Her sezonda beklenen sıra ham kadro gücünden hesaplanır; gerçek lig sırasıyla karşılaştırılır. Yönetim ilişkisi güncellenir.

Görev değişimi nedenleri:

- performans
- yönetim ilişkisi kopması
- emeklilik

Kovulan manager başka kulüpte yeniden çalışabilir. Emekli manager yeniden atanamaz. Aynı sezonda her kulüpte ve her manager için tek aktif görev vardır.

### M6 kabul baseline — seed `20260903`

- 20 sezon / 14.400 maç
- manager pool `96`
- görev yapan farklı manager `60`
- toplam değişim `82`
- performance `51`
- board breakdown `29`
- retirement `2`
- ortalama strength etkisi `+0,922`
- AI atamalarında min/max `-0,371 / +1,977`
- negatif manager etkili kulüp-sezon `29 / 960`
- `+1,5` üzeri güçlü pozitif kulüp-sezon `77 / 960`
- final ortalama board relationship `72,22`
- transfer `84`
- transfer hacmi `777,02M`
- final cash `1.048,02M`
- final debt `582,36M`
- emergency `473,40M`
- manager validation `0`

Doğrudan impact testi başkanın çok kötü tercihi için `-2,5`, çok güçlü uyum için `+2,5` üretildiğini garanti eder. AI çoğunlukla uygun manager seçtiği için gerçek kariyerde negatif örnekler daha sınırlıdır.

M5 no-op yolu aynı CI'da eski `71 transfer / 862,25M cash / 647,04M debt` baseline'ını birebir korudu.

### M6 açık sınırlar

Henüz yok:

- manager maaşı / sözleşmesi
- başka kulüpten manager teklifi
- zam talebi
- spesifik transfer talebi
- medya açıklaması
- taraftar tepkisi
- manager youthDevelopment'ın bireysel player development hızına doğrudan etkisi

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

---

# 6. Sıradaki teknik yol

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi

Öncelik budur. Nedenleri:

- M3 `WageModel` geçicidir.
- M5 alt lig ekonomi kalibrasyonu gerçek maaşlar olmadan nihai değildir.
- Transfer fiyatının sözleşme bitişine gerçek tepki vermesi gerekir.
- Serbest oyuncu ve sözleşme yenileme gelişmiş transfer pazarının temelidir.

M7 ilk kapsam:

- `PlayerContract`
- başlangıç sözleşme üretimi
- gerçek oyuncu maaşı
- contract end season/date
- sözleşme bitişi
- temel yenileme kararı
- serbest oyuncu durumu
- maaş yükünün ekonomiye doğrudan bağlanması
- market value'da contract length etkisi
- 20 sezon contract/population/economy validator

M7'de henüz kiralık/taksit/bonus/takas yapılmayacak.

## Sonraki sıra

M8: gelişmiş transfer yapıları — kiralık, taksit, bonus, satıştan pay, opsiyon/obligation.  
M9: context-aware taraftar güveni ve beklenti sistemi.  
M10: medya hafızası + başkan açıklamaları.  
M11: başkan vaatleri.  
M12: tesis / altyapı yatırımları / sponsor / kriz-event katmanları.  
Daha sonra seçim sistemi ve başkan kariyeri genişletilecek.

Bu sıralama gerektiğinde yeni test verilerine göre değişebilir.

---

# 7. Uzun kariyer kalite hedefleri

Mevcut her milestone en az 20 sezon deterministic headless kariyerle doğrulanır.

İleride kalite seviyeleri:

- 20 sezon geliştirici testi
- 100 kariyer × 20 sezon temel denge
- 500 kariyer × 30 sezon regresyon
- 1.000 kariyer × 30 sezon stres

Ölçümler:

- aktif oyuncu ve yaş dağılımı
- emeklilik / youth intake
- nakit / borç / emergency financing
- maaş/gelir oranı
- transfer sayısı, hacmi, yaş/mevki dağılımı
- contract length vs fiyat
- lig hareketleri ve şampiyon çeşitliliği
- manager görev süresi/değişimi
- ileride fan trust, promise success ve president tenure

Her hata seed ile tekrar üretilebilir olmalıdır.

---

# 8. Save / persistence yönü

Save sistemi sonradan rastgele eklenmeyecek. Hedef metadata:

- `saveVersion`
- `gameVersion`
- `simulationVersion`
- `dataVersion`
- `careerSeed`
- `currentGameDate`
- integrity/checksum
- migration history

Minimum: aktif autosave + önceki autosave backup + manuel save + migration desteği.

---

# 9. İlk sürümde özellikle yapılmayacaklar

- 3D maç
- online multiplayer
- gerçek kulüp/futbolcu/logo
- saha içi taktik mikro yönetimi
- FM seviyesinde onlarca attribute
- 20 ülkelik dünya piramidi
- erken görsel polish
- UI uğruna simülasyon testlerini erteleme
- pay-to-win ekonomi

---

# 10. Monetizasyon yönü

Daha sonra yeniden değerlendirilecek. Pay-to-win olmayacak. Adaylar: tek seferlik premium, reklam kaldırma, opsiyonel ödüllü reklam veya kozmetik kulüp temaları. Oyun ekonomisi IAP baskısı için bozulmayacaktır.

---

# 11. Güncel durum

**Tamamlanan çekirdek:**

- ✅ M0 lig/maç
- ✅ M1 uzun sezon yaşam döngüsü
- ✅ M2 oyuncu yaşam döngüsü
- ✅ M3 ekonomi
- ✅ M4 basit transfer
- ✅ M5 48 kulüp / 3 lig / terfi-düşme
- ✅ M6 teknik direktör sistemi

Saf Dart çekirdeği şu anda 48 kulüp, 3 lig, yaşayan oyuncu havuzu, ekonomi, transfer pazarı, terfi/düşme ve yaşayan teknik direktör havuzunu **20 sezon / 14.400 maç** boyunca deterministik çalıştırabiliyor.

**Sıradaki iş:** M7 oyuncu sözleşmeleri ve gerçek maaş sistemi. Flutter UI/APK hâlâ kapsam dışıdır.
