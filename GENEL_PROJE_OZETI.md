# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 03.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public  
**Aktif teknik aşama:** **M1 PASS — sıradaki milestone M2 / Oyuncu Havuzu + Yaşlanma + Genç Üretimi**  
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
Başkan eylemlerini yöneten use-case katmanı: kariyer başlatma, hafta ilerletme, transfer teklifi, teknik direktör işe alma/kovma, sponsor, medya, vaat ve tesis kararları.

## `presentation`
Flutter mobil UI. Henüz geliştirme kapsamına alınmadı.

---

# 4. Kritik teknik kararlar

## Deterministik simülasyon

Aynı `simulationVersion`, veri seti, kariyer seed'i ve karar dizisi aynı sonucu üretmelidir.

Maç seed'i global RNG zinciri yerine maç bazında türetilir:

`matchSeed = hash(careerSeed, seasonIndex, fixtureId, simulationVersion)`

Kararlı FNV-1a tabanlı hash ve özel xorshift32 `SeededRng` kullanılmaktadır. Dart'ın runtime `hashCode` davranışına güvenilmez.

## Oyun zamanı

M1 ile cihaz saatinden bağımsız `GameDate` gerçek kodda devreye girdi.

## Para

Ekonomi geldiğinde para `double` olarak tutulmayacak; integer tabanlı veya güvenli `Money` value object kullanılacak.

## Event geçmişi

İleride transfer, teknik direktör, vaat, medya, borç, tesis ve önemli sportif olaylar domain event olarak tutulacaktır.

---

# 5. Sistem öncelik sırası

1. Simülasyon altyapısı
2. Sezon / lig yaşam döngüsü
3. Futbolcu yaşam döngüsü
4. Kulüp ekonomisi
5. Maç simülasyonu
6. Oyuncu değerleme ve maaş beklentisi
7. Transfer pazarı
8. Kulüp transfer AI
9. Teknik direktör sistemi
10. Taraftar beklentisi ve güveni
11. Medya hafızası ve vaatler
12. Tesis / altyapı / sponsor / kriz

Transfer AI, taraftar bağlamı ve uzun kariyer dengesi projenin kritik kalite alanlarıdır.

---

# 6. Sistem etkileşimleri

`Ekonomi → transfer/maaş kapasitesi → kadro kalitesi → maç sonucu → sportif başarı → taraftar/medya/itibar → sponsor/bilet/ürün geliri → ekonomi`

`Altyapı yatırımı → genç üretimi → düşük maliyetli kadro / satış geliri → ekonomi + taraftar kimliği`

`Teknik direktör seçimi → gelişim + performans + transfer talepleri → ekonomik/sportif baskı → taraftar/medya → tut/kov kararı`

`Başkan vaadi → beklenti → sezon boyunca ölçüm → tutuldu/tutulmadı → taraftar + medya + seçim`

`Borçla agresif transfer → kısa vadeli güç → başarı ihtimali → gelecek taksit/maaş yükü → hareket alanı kaybı → zorunlu satış / kriz riski`

---

# 7. M0 — Deterministik Mini Lig Çekirdeği — PASS

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

Baseline maç modeli:

`d = clamp((homeStrength + 2) - awayStrength, -30, 30)`

`homeLambda = clamp(1.35 × exp(d / 45), 0.25, 3.50)`

`awayLambda = clamp(1.15 × exp(-d / 45), 0.25, 3.50)`

Gerçek GitHub CI regresyon sonucu (M1 PR içinde yeniden doğrulandı):

- 100 sezon: PASS
- toplam maç: `5.600`
- ev galibiyeti: `%45,2857`
- beraberlik: `%24,5893`
- deplasman galibiyeti: `%30,1250`
- ortalama gol: `2,5864`
- şampiyonluk: Kuzey Yıldızı 49, Vadişehir 20, Demirkent 19, Mavi Liman 6, Çınarspor 4, Ufukşehir 2

M0 kaynakları PR #1 üzerinden squash merge edildi. M0 kalite kapısı kapanmıştır.

---

# 8. M1 — 20 Sezon Yaşam Döngüsü — PASS

M1 ile tek sezon motoru gerçek kariyer omurgasına dönüştürüldü.

Eklenen parçalar:

- `GameDate`
- `CareerEngine`
- `CareerReport`
- `CareerSeason`
- `CareerValidator`
- `ClubStrengthEvolution`
- 20 sezon CLI runner
- M1 otomatik testleri
- CI içinde M0 regresyonu + M1 kariyer koşusu

Varsayılan kariyer:

- başlangıç: `2026-07-01`
- sezon index: `0...19`
- bitiş penceresi: `2046-07-01`
- 20 sezon
- toplam `1.120` maç

## Geçici sezonlar arası takım gücü modeli

M2'de oyuncu kadroları gelene kadar kulüp gücü geçici bir köprü modeliyle evrilir:

- sezonluk random hareket en fazla `±1.5`
- baseline'a geri çekilme oranı `%20`
- baseline'dan maksimum sapma `±4.0`
- her kulüp/sezon için deterministik seed
- aynı kariyer seed'i aynı güç evrimini üretir

Bu **nihai takım gelişim sistemi değildir**. M2 ile takım gücü oyuncu kadrosundan türetilecek ve bu geçici model kaldırılabilecek/değiştirilebilecektir.

## M1 gerçek GitHub Actions sonucu

PR #2: `M1: add deterministic 20-season career lifecycle`

PR CI:

- Dart SDK: `3.13.3 stable`
- `dart analyze`: **PASS — No issues found**
- `dart test`: **PASS — 7/7 test**
- M0 100 sezon regresyonu: **PASS**
- M1 20 sezon kariyer CLI: **PASS**
- validation issue: **0**

Seed `20260903` M1 örnek kariyeri:

- pencere: `2026-07-01 → 2046-07-01`
- sezon: `20`
- maç: `1.120`
- şampiyonluklar: Vadişehir `10`, Kuzey Yıldızı `6`, Demirkent `4`

20. sezon sonu geçici güçler:

- Kuzey Yıldızı SK: `80.55`
- Vadişehir FK: `77.10`
- Demirkent 1912: `74.00`
- Mavi Liman: `69.28`
- Çınarspor: `65.66`
- Ufukşehir FK: `65.54`
- Gölova SK: `61.57`
- Hisar Birliği: `57.12`

M1 testleri ayrıca:

- aynı seed'in aynı 20 sezonluk şampiyon dizisini ve final güçlerini üretmesini,
- farklı seed'lerin farklı kariyer üretmesini,
- özel başlangıç `seasonIndex` ve `GameDate` değerlerinin doğru ilerlemesini,
- tüm sezonlarda M0 invariant'larının korunmasını

doğrulamaktadır.

PR #2 squash merge ile `main` branch'ine alındı. Merge commit: `34b0c73608c536de18278c3cc98e795341da0989`.

---

# 9. GitHub / CI kararı

Repo **Public** kalacaktır. Önceki Private planı geçersizdir.

Ana gerekçe GitHub Actions kullanım/kota avantajıdır.

Repo public olsa da proje açık kaynak değildir; `LICENSE.md` içinde proprietary notice vardır.

CI prensibi:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon regresyonu
- M1 20 sezon kariyer doğrulaması

CI içinde:

- APK yok
- AAB yok
- büyük binary yok
- `actions/upload-artifact` yok

Bu yaklaşım artifact storage tüketimini baştan önler.

---

# 10. 20 sezon çekirdeğine roadmap

## M0 — Deterministik Mini Lig
**PASS.**

## M1 — 20 Sezon Yaşam Döngüsü
**PASS.**

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi
Sıradaki milestone.

İlk hedef alanlar:

- `Player` temel modeli
- yaş / doğum tarihi
- mevki
- current ability
- potential
- maaş
- sözleşme süresi
- kulüp kadroları
- sezon sonunda yaş ilerlemesi
- gelişim / düşüş eğrisi
- emeklilik
- youth intake
- kadrodan takım gücü türetme
- 20 sezon sonunda oyuncu havuzunun tükenmemesi
- mantıklı yaş dağılımı

## M3 — Temel Ekonomi
Nakit, gelirler, maaşlar, işletme giderleri, temel borç ve finans raporu.

## M4 — Basit Transfer Pazarı
Doğrudan bonservis, sözleşmesi biten oyuncu, pozisyon ihtiyacı, değerleme ve bütçe kontrolü.

## M5 — 48 Kulüp / 3 Lig
Yaklaşık 48 özgün kulüp, 3 lig, yükselme/düşme, oyuncu yaşam döngüsü, ekonomi, temel transfer ve 20 sezon otomatik kariyer. İlk büyük teknik başarı hedefidir.

---

# 11. Uzun kariyer kalite hedefleri

İleride:

- 20 sezon geliştirici testi
- 100 kariyer × 20 sezon temel denge
- 500 kariyer × 30 sezon regresyon
- 1.000 kariyer × 30 sezon stres testi

Ölçülecek metrikler zamanla:

- aktif oyuncu sayısı ve yaş dağılımı
- genç üretimi
- emeklilik
- kulüp nakdi / borcu
- maaş / gelir oranı
- transfer ücretleri
- şampiyonluk dağılımı
- büyük/küçük kulüp farkı
- taraftar güveni
- teknik direktör ve başkan görev süresi

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

M0 ve M1 çalışmaları doğrudan GitHub araçlarıyla yürütüldü; Codex kredisi kullanılmadı.

---

# 14. Güncel durum ve sıradaki iş

**Tamamlanan teknik milestone'lar:**

- ✅ M0 — Deterministik Mini Lig
- ✅ M1 — 20 Sezon Yaşam Döngüsü

**Güncel kanıt:** Saf Dart çekirdeği aynı kariyer seed'iyle deterministik biçimde 20 sezon / 1.120 maç çalıştırabiliyor ve tüm mevcut invariant testlerini geçiyor.

**Sıradaki milestone:**

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi

M2 de UI/APK kapsamına girmeyecek. İlk amaç, 20 sezon sonunda oyuncu nüfusunun, yaş dağılımının ve takım güçlerinin mantıklı kalabildiğini otomatik olarak kanıtlamaktır.
