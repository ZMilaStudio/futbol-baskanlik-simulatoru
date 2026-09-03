# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 03.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public  
**Aktif teknik aşama:** **M2 PASS — sıradaki milestone M3 / Temel Kulüp Ekonomisi**  
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

# 2. Değişmez tasarım ve teknik prensipleri

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
13. Aynı `simulationVersion` + veri seti + seed + karar dizisi aynı sonucu üretmelidir.
14. Dart runtime `hashCode` davranışına güvenilmeyecek; kararlı hash/RNG kullanılacaktır.
15. Ekonomide para geldiğinde `double` kullanılmayacak; integer tabanlı veya güvenli `Money` value object kullanılacaktır.

---

# 3. Teknik mimari

Temel yaklaşım: **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**.

## `simulation_core`
Saf Dart domain modelleri ve oyun kuralları. Flutter/Android API bağımlılığı yok.

## `simulation_runner`
Headless Dart/CLI. Tek sezon, uzun kariyer, batch simülasyon, seed replay ve denge raporları.

## `persistence`
İleride yerel, versiyonlu save/load; migration, otomatik kayıt ve yedek kayıt. Flutter tarafında Drift/SQLite değerlendirilebilir.

## `application`
Başkan eylemlerini yöneten use-case katmanı: kariyer başlatma, hafta ilerletme, transfer teklifi, teknik direktör işe alma/kovma, sponsor, medya, vaat ve tesis kararları.

## `presentation`
Flutter mobil UI. Henüz geliştirme kapsamına alınmadı.

---

# 4. Deterministik simülasyon altyapısı

Maç seed'i global RNG zinciri yerine maç bazında türetilir:

`matchSeed = hash(careerSeed, seasonIndex, fixtureId, simulationVersion)`

Kararlı FNV-1a tabanlı hash ve özel xorshift32 `SeededRng` kullanılmaktadır.

M1 ile cihaz saatinden bağımsız `GameDate` gerçek kodda devreye girdi.

M2 ile başlangıç oyuncu üretimi, oyuncu gelişimi, emeklilik ve youth intake de career seed + simulation version + season/player/club bağlamlarından türetilen deterministik seed'lerle çalışmaktadır.

---

# 5. M0 — Deterministik Mini Lig — PASS

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

Baseline:

`d = clamp((homeStrength + 2) - awayStrength, -30, 30)`

`homeLambda = clamp(1.35 × exp(d / 45), 0.25, 3.50)`

`awayLambda = clamp(1.15 × exp(-d / 45), 0.25, 3.50)`

Gerçek regresyon sonucu:

- 100 sezon / `5.600` maç: PASS
- ev galibiyeti: `%45,2857`
- beraberlik: `%24,5893`
- deplasman galibiyeti: `%30,1250`
- ortalama gol: `2,5864`
- şampiyonluk: Kuzey Yıldızı 49, Vadişehir 20, Demirkent 19, Mavi Liman 6, Çınarspor 4, Ufukşehir 2

M0 kaynakları PR #1 üzerinden squash merge edildi.

---

# 6. M1 — 20 Sezon Yaşam Döngüsü — PASS

Eklenen ana parçalar:

- `GameDate`
- `CareerEngine`
- `CareerReport`
- `CareerSeason`
- `CareerValidator`
- `ClubStrengthEvolution`
- 20 sezon CLI runner

Varsayılan kariyer:

- başlangıç: `2026-07-01`
- sezon index: `0...19`
- bitiş: `2046-07-01`
- sezon: `20`
- toplam maç: `1.120`

M1'de oyuncular gelene kadar geçici güç köprü modeli kullanıldı: sezonluk en fazla `±1.5`, baseline'a `%20` geri çekilme ve baseline'dan maksimum `±4.0` sapma.

PR #2 CI sonucu:

- Dart `3.13.3 stable`
- `dart analyze`: PASS / 0 issue
- `dart test`: PASS / 7 test
- M0 regresyon: PASS
- M1 20 sezon CLI: PASS
- validation issue: `0`

Seed `20260903` M1 şampiyonlukları: Vadişehir `10`, Kuzey Yıldızı `6`, Demirkent `4`.

PR #2 squash merge commit: `34b0c73608c536de18278c3cc98e795341da0989`.

---

# 7. M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

M2 ile gerçek oyuncu nüfusu simülasyon çekirdeğine girdi. M1 `CareerEngine` regresyon amacıyla korunmaktadır; oyuncu tabanlı uzun kariyer ayrı `PlayerCareerEngine` üzerinden çalışmaktadır.

## Başlangıç oyuncu havuzu

8 kulüp × 18 oyuncu = **144 oyuncu**.

Kulüp başına başlangıç dağılımı:

- 2 kaleci
- 6 defans
- 6 orta saha
- 4 forvet

Oyuncu temel alanları:

- `id`
- hayalî isim
- kulüp
- pozisyon
- yaş
- `ability`
- `potential`
- deterministik emeklilik yaşı
- academy graduate bilgisi

Başlangıç yaşları `17–33`, emeklilik yaşı `34–38` aralığındadır.

## Oyuncu gelişimi

- 16–20: potansiyel boşluğuna bağlı güçlü gelişim
- 21–23: orta gelişim
- 24–26: plato / küçük gelişim
- 27–29: hafif düşüş riski
- 30+: kademeli düşüş
- 34+: daha belirgin düşüş

`ability`, oyuncunun `potential` değerini geçemez.

## Youth intake

Her sezon geçişinde her kulüp 1 genç üretir. 20 sezonluk kariyerde 19 offseason vardır:

`19 × 8 = 152 youth intake`

Genç yaşı `16–18` aralığındadır. Kadroda belirgin pozisyon eksiği varsa o mevki önceliklenir; aksi halde ağırlıklı deterministik seçim yapılır. Nadir yüksek potansiyelli genç üretimi mümkündür.

İlk denge taslağında genç seviyesini yalnız mevcut kulüp gücüne bağlamanın uzun vadede bütün ligi aşağı doğru sürükleme riski tespit edildi. Commit öncesi model değiştirildi: youth kalite tabanı kulübün **başlangıç referans gücüne** bağlandı. Böylece 20 yılda yapay lig güç çöküşü engellendi.

## Kadrodan takım gücü

M2 oyuncu kariyerinde M1'in geçici `ClubStrengthEvolution` modeli kullanılmaz. Takım gücü oyuncu kadrosundan türetilir.

Referans ilk 11:

- 1 kaleci
- 4 defans
- 3 orta saha
- 3 forvet

Pozisyon eksiğinde en iyi kalan oyuncular kullanılır ve küçük pozisyon dengesizliği cezası uygulanır.

## M2 validator

Her sezon şunları denetler:

- oyuncu ID benzersizliği
- aktif yaş ve emeklilik yaşı sınırları
- ability/potential sınırları
- kulüp başına minimum 11 aktif oyuncu
- emeklilik sonrası oyuncunun havuzdan çıkması
- youth ID çakışmaması
- offseason oyuncu sayısı korunum denklemi
- final sezon sonrası hayalet offseason uygulanmaması
- M0 sezon invariant'larının korunması

## M2 gerçek GitHub Actions sonucu

PR #3: `M2: add deterministic player lifecycle`

- Dart SDK: `3.13.3 stable`
- `dart analyze`: **PASS — No issues found**
- `dart test`: **PASS — 10/10 test**
- M0 100 sezon regresyonu: **PASS**
- M1 20 sezon kariyer regresyonu: **PASS**
- M2 20 sezon oyuncu kariyeri: **PASS**
- validation issue: **0**
- artifact: **0**

Seed `20260903` M2 20 sezon sonucu:

- sezon: `20`
- maç: `1.120`
- başlangıç oyuncu: `144`
- final aktif oyuncu: `148`
- emeklilik: `148`
- youth intake: `152`
- final aktif academy graduate: `146`
- final ortalama yaş: `25,84`
- şampiyonluklar: Vadişehir `9`, Demirkent `6`, Kuzey Yıldızı `5`

20. sezon final takım güçleri:

- Kuzey Yıldızı SK: `79.59`
- Vadişehir FK: `74.68`
- Demirkent 1912: `73.10`
- Mavi Liman: `68.94`
- Çınarspor: `66.77`
- Ufukşehir FK: `63.10`
- Gölova SK: `60.44`
- Hisar Birliği: `58.04`

Sonuç: Oyuncu havuzu 20 sezonda tükenmiyor, yaş dağılımı sürdürülebilir kalıyor ve lig güç seviyesi topluca çökmüyor.

PR #3 squash merge commit: `4b57adf40df8a04e8996f3b0910ee028a622501c`.

---

# 8. GitHub / CI kararı

Repo **Public** kalacaktır. Önceki Private planı geçersizdir. Ana gerekçe GitHub Actions kullanım/kota avantajıdır.

Repo açık kaynak değildir; `LICENSE.md` proprietary notice içerir.

Tek mevcut Core Simulation workflow'u şu sırayı çalıştırır:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon regresyonu
- M1 20 sezon kariyer doğrulaması
- M2 20 sezon oyuncu kariyeri

CI içinde APK, AAB, büyük binary veya `actions/upload-artifact` yoktur. M2 PR koşusunda artifact listesi boş (`0`) olarak doğrulanmıştır.

---

# 9. Roadmap

## M0 — Deterministik Mini Lig
**PASS**

## M1 — 20 Sezon Yaşam Döngüsü
**PASS**

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi
**PASS**

M2'de maaş ve sözleşme özellikle eklenmedi; bunlar ekonomi/transfer bağlamı olmadan anlamsız yarım sistem oluşturacağı için sonraki aşamalara bırakıldı.

## M3 — Temel Kulüp Ekonomisi
**Sıradaki milestone.**

İlk kapsam:

- güvenli para modeli (`Money` veya integer minor unit)
- kulüp başlangıç nakdi
- sezonluk temel gelir
- oyuncu maaş gideri için ekonomi bağlantısına hazırlık
- işletme gideri
- temel borç/taksit yükü
- sezon finans özeti
- negatif nakit / sürdürülebilirlik invariant'ları
- 20 sezon finans kariyeri

Transfer pazarı M3'e alınmayacak.

## M4 — Basit Transfer Pazarı
Doğrudan bonservis, sözleşmesi biten oyuncu, pozisyon ihtiyacı, değerleme ve bütçe kontrolü.

## M5 — 48 Kulüp / 3 Lig
Yaklaşık 48 özgün kulüp, 3 lig, yükselme/düşme, oyuncu yaşam döngüsü, ekonomi, temel transfer ve 20 sezon otomatik kariyer. İlk büyük teknik başarı hedefidir.

---

# 10. Uzun kariyer kalite hedefleri

İleride:

- 20 sezon geliştirici testi
- 100 kariyer × 20 sezon temel denge
- 500 kariyer × 30 sezon regresyon
- 1.000 kariyer × 30 sezon stres testi

Ölçülecek metrikler zamanla:

- aktif oyuncu sayısı ve yaş dağılımı
- genç üretimi / emeklilik
- takım güç dağılımı
- kulüp nakdi / borcu
- maaş / gelir oranı
- transfer ücretleri
- şampiyonluk dağılımı
- büyük/küçük kulüp farkı
- taraftar güveni
- teknik direktör ve başkan görev süresi

Her başarısız kariyer seed ile tekrar üretilebilmelidir.

---

# 11. İlk aşamada yapılmayacaklar

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

# 12. Codex çalışma kuralı

Codex kredisi gereksiz kullanılmayacaktır. Büyük çok dosyalı implementasyon, büyük refactor, simülasyon/test altyapısı, karmaşık hata düzeltmesi ve migration gibi yüksek kaldıraçlı işlerde kullanılabilir.

Basit analiz, tasarım kararı, formül konuşması ve küçük belge değişikliklerinde kullanılmaz.

**M0, M1 ve M2 doğrudan GitHub araçlarıyla tamamlandı; Codex kredisi kullanılmadı.**

---

# 13. Güncel durum

Tamamlanan teknik milestone'lar:

- ✅ M0 — Deterministik Mini Lig
- ✅ M1 — 20 Sezon Yaşam Döngüsü
- ✅ M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi

Saf Dart çekirdeği artık aynı seed ile deterministik biçimde 20 sezon / 1.120 maç çalıştırabiliyor; oyuncular yaşlanıyor, gelişiyor, emekli oluyor, genç oyuncular sisteme giriyor ve takım gücü gerçek kadrodan türetiliyor.

**Sıradaki milestone: M3 — Temel Kulüp Ekonomisi.**

M3 de UI/APK ve transfer pazarı kapsamına girmeyecek. İlk amaç ekonomik sistemin 20 sezon boyunca matematiksel olarak ayakta kalabildiğini ve borç/nakit invariant'larının otomatik testlerle doğrulanabildiğini kanıtlamaktır.
