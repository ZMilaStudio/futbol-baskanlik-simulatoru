# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 03.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo görünürlüğü:** Public  
**Aktif teknik aşama:** M0 PASS — sıradaki milestone M1 / 20 Sezon Yaşam Döngüsü  
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

Oyuncu saha içi diziliş, antrenman ve maç içi değişikliklerle uğraşmaz. Başkan olarak ekonomi, teknik direktör, transfer politikası, borç, altyapı, tesis, sponsor, taraftar, medya, vaatler, krizler ve uzun vadeli kulüp sağlığını yönetir.

Gerçek kulüp, futbolcu, lig logosu veya lisanslı materyal kullanılmayacaktır.

---

# 2. Değişmez tasarım prensipleri

1. Başkan teknik direktör değildir.
2. Mobil ekranda sade bilgi gösterilir; derin hesaplamalar arka planda çalışabilir.
3. Taraftar bağlamı anlamalı, ekonomik gerçeklerden kopuk talepler üretmemelidir.
4. Transfer AI yaş, kalite, potansiyel, sözleşme, ihtiyaç ve ekonomi bağlamını dikkate almalıdır.
5. Piyasa değeri ile gerçek transfer fiyatı aynı kavram değildir.
6. Doğru karar her zaman açık olmamalıdır.
7. Kısa vadeli sportif başarı ile uzun vadeli kulüp sağlığı arasında gerilim yaratılmalıdır.
8. Geçmiş açıklamalar, vaatler ve önemli kararlar unutulmamalıdır.
9. Bazı kararların sonuçları sezonlar sonra ortaya çıkabilmelidir.
10. Uzun kariyer mutlaka otomatik simülasyonlarla test edilmelidir.
11. İlk sürüm gereksiz sistemlerle şişirilmemelidir.
12. İlk hedef UI/APK değil sağlam simülasyon çekirdeğidir.

---

# 3. Ana teknik mimari

Önerilen yapı:

## `simulation_core`
Saf Dart. Flutter ve Android bağımlılığı yoktur.

İçerik zamanla domain modelleri, deterministic RNG, oyun tarihi, maç motoru, sezon/lig motoru, ekonomi, oyuncu yaşam döngüsü, transfer ve transfer AI, teknik direktör davranışları, taraftar, medya hafızası, vaatler, altyapı, tesis, sponsor ve kriz/olay sistemlerini kapsayacaktır.

## `simulation_runner`
Headless Dart/CLI test katmanı. Tek sezon, 20 sezon, 100/500/1.000 kariyer batch, seed tekrar oynatma ve denge raporları için kullanılacaktır.

## `persistence`
Yerel, versiyonlu kayıt/yükleme; migration, otomatik kayıt ve yedek kayıt baştan düşünülür. Flutter tarafında ileride Drift/SQLite değerlendirilebilir.

## `application`
Başkan eylemlerini yöneten use-case katmanı: `StartCareer`, `AdvanceWeek`, `SubmitTransferOffer`, `HireManager`, `FireManager`, `AcceptSponsor`, `MakeMediaStatement`, `SetSeasonPromise`, `UpgradeFacility` gibi.

## `presentation`
Flutter mobil UI. İlk aşamanın önceliği değildir.

---

# 4. Kritik teknik kararlar

## Deterministik simülasyon

Aynı simulation version, veri seti, seed ve karar dizisi aynı sonucu üretmelidir.

Maçlar tek global RNG zinciri yerine maç bazlı seed kullanır:

`matchSeed = hash(careerSeed, seasonIndex, fixtureId, simulationVersion)`

Dart'ın varsayılan `hashCode` davranışına bağımlı kalmamak için kararlı FNV-1a tabanlı hash ve özel xorshift32 `SeededRng` kullanılmaktadır.

## Para

Ekonomide `double` yerine ileride integer tabanlı veya `Money` value object kullanılacaktır.

## Oyun zamanı

Telefon saatinden bağımsız `GameDate` sistemi kurulacaktır.

## Event geçmişi

Transfer, teknik direktör işe alma/kovma, vaat, medya açıklaması, borç, tesis yükseltme ve önemli sportif olaylar tutulacaktır. Bu geçmiş medya, taraftar ve uzun vadeli sonuç sistemlerinde kullanılacaktır.

---

# 5. Sistem öncelik sırası

1. Simülasyon altyapısı
2. Sezon / lig yaşam döngüsü
3. Kulüp ekonomisi
4. Futbolcu yaşam döngüsü
5. Maç simülasyonu
6. Oyuncu değerleme ve maaş beklentisi
7. Transfer pazarı
8. Kulüp transfer AI
9. Teknik direktör sistemi
10. Taraftar beklentisi ve güveni
11. Medya hafızası ve vaatler
12. Tesis / altyapı / sponsor / kriz

Transfer AI, taraftar bağlamı ve uzun kariyer dengesi projenin en kritik kalite alanlarıdır.

---

# 6. İlk büyük veri modelleri

Planlanan modeller: `GameWorld`, `Career`, `Club`, `League`, `Competition`, `Fixture`, `Standing`, `Player`, `PlayerSeasonStats`, `Manager`, `Contract`, `TransferOffer`, `LoanAgreement`, `TransferWindow`, `Sponsor`, `Stadium`, `FacilityState`, `FanState`, `MediaStatement`, `Promise`, `Season`, `Match`, `FinanceLedgerSummary`, `DebtAgreement`, `Installment`, `YouthIntake`, `SimulationConfig`, `SimulationReport`, `DomainEvent`.

---

# 7. Sistem etkileşimleri

Temel ekonomi döngüsü:

`Ekonomi → transfer/maaş kapasitesi → kadro kalitesi → maç sonucu → sportif başarı → taraftar/medya/itibar → sponsor/bilet/ürün geliri → ekonomi`

Altyapı:

`altyapı yatırımı → genç üretimi → düşük maliyetli kadro / satış geliri → ekonomi + taraftar kimliği`

Teknik direktör:

`hoca seçimi → gelişim + performans + transfer talepleri → ekonomik/sportif baskı → taraftar/medya → tut/kov kararı`

Vaat:

`başkan vaadi → beklenti → sezon boyunca ölçüm → tutuldu/tutulmadı → taraftar + medya + seçim`

Borçla agresif transfer:

`borç → kısa vadeli kadro gücü → başarı ihtimali → gelecek taksit/maaş yükü → hareket alanı kaybı → zorunlu satış / kriz riski`

---

# 8. M0 — Deterministik Mini Lig Çekirdeği

Kapsam: 8 hayalî kulüp, 1 lig, çift devre, 14 hafta, 56 maç, takım başına 7 iç + 7 deplasman, tek `strength` puanı, deterministik fixture ve match seed, Poisson gol üretimi, puan tablosu, sezon raporu, invariant validator ve 100 sezon batch testi.

M0'da Flutter UI, APK, futbolcu kadroları, transfer, teknik direktör, ekonomi, taraftar, medya, sponsor, altyapı, tesis, kupa ve yükselme/düşme yoktur.

---

# 9. M0 maç matematiği

Baseline:

`d = clamp((homeStrength + 2) - awayStrength, -30, 30)`

`homeLambda = clamp(1.35 × exp(d / 45), 0.25, 3.50)`

`awayLambda = clamp(1.15 × exp(-d / 45), 0.25, 3.50)`

`homeGoals ~ Poisson(homeLambda)`

`awayGoals ~ Poisson(awayLambda)`

Referans güçler: `80, 76, 73, 70, 67, 64, 61, 58`.

Bağımsız 1.000 sezon matematik doğrulamasında yaklaşık ev galibiyeti `%44,47`, beraberlik `%25,02`, deplasman galibiyeti `%30,50`, gol/maç `2,579` bulunmuştur. Model M0 için kontrollü ama sürprize açık kabul edilmiştir.

---

# 10. M0 kalite kapısı

M0 kalite kapısı **PASS** olarak kapanmıştır. GitHub Actions üzerinde Dart 3.13.3 ile `dart analyze` hatasız tamamlandı, 4 otomatik test geçti ve 100 sezon / 5.600 maç batch simülasyonu invariant ihlali olmadan tamamlandı.

Gerçek CI sonucu:

- `dart analyze`: PASS — 0 issue
- `dart test`: PASS — 4/4 test
- 100 sezon batch: PASS
- 5.600 maç
- ev galibiyeti: `%45,2857`
- beraberlik: `%24,5893`
- deplasman galibiyeti: `%30,1250`
- gol/maç: `2,5864`
- şampiyonluk: Kuzey Yıldızı 49, Vadişehir 20, Demirkent 19, Mavi Liman 6, Çınarspor 4, Ufukşehir 2

İlk CI çalışmasında test fixture'ındaki `int → double` analyzer hatası yakalandı; iki testte explicit `.toDouble()` ile düzeltildi. `actions/checkout` da `v5`e yükseltildi. İkinci CI tam PASS verdi.

---

# 11. M0 kod durumu

Hazır parçalar: `SimulationConfig`, `StableHash`, `SeededRng`, `Club`, `Fixture`, `FixtureGenerator`, `StandingRow`, `MatchEngine`, `MatchResult`, `PoissonSampler`, `SeasonEngine`, `SeasonReport`, `SeasonValidator`, tek sezon CLI runner, 100 sezon batch runner, fixture testi, determinism testi ve 100 sezon kabul testi.

M0 kaynakları PR #1 üzerinden squash merge ile `main` branch'ine alınmıştır. Merge commit: `19858745d3f999dee7f4ddb3e107c2a964698535`.

---

# 12. GitHub / CI kararı

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Görünürlük: **Public**.

Önceki Private planı geçersizdir. Public kararının ana gerekçesi GitHub Actions kota avantajıdır.

CI ilk aşamada yalnız `dart pub get`, `dart analyze`, `dart test` ve `dart run tool/run_m0_batch.dart 100` çalıştıracaktır.

M0 CI içinde APK, AAB, büyük binary veya `actions/upload-artifact` yoktur.

Repo public olsa da proje açık kaynak olarak lisanslanmayacaktır. Proprietary notice kullanılacaktır.

---

# 13. 20 sezon çekirdeğine aşamalı plan

## M0 — Deterministik Mini Lig
8 kulüp / 1 lig / 1 sezon. **PASS.**

## M1 — 20 Sezon Yaşam Döngüsü
`GameDate`, sezon index, yeni sezon oluşturma, 20 sezon batch ve season-to-season determinism.

## M2 — Oyuncu Havuzu
Yaş, pozisyon, mevcut seviye, potansiyel, maaş, sözleşme, yaşlanma, gelişim/düşüş, emeklilik ve youth intake.

## M3 — Temel Ekonomi
Nakit, gelir, maaş, işletme gideri, temel borç yükü ve sezon finans raporu.

## M4 — Basit Transfer Pazarı
Doğrudan bonservis, sözleşmesi biten oyuncu, pozisyon ihtiyacı, değerleme ve bütçe kontrolü.

## M5 — 48 Kulüp / 3 Lig
Yaklaşık 48 özgün kulüp, 3 lig, yükselme/düşme, oyuncu yaşam döngüsü, ekonomi, temel transfer pazarı ve 20 sezon otomatik kariyer. Bu nokta ilk büyük teknik başarı kabul edilir.

---

# 14. Uzun kariyer kalite hedefleri

İleride batch testler: 20 sezon geliştirici testi, 100 kariyer × 20 sezon temel denge, 500 kariyer × 30 sezon regresyon ve 1.000 kariyer × 30 sezon büyük sürüm stres testi.

Ölçülecek metrikler kulüp nakdi/borcu, maaş/gelir oranı, transfer ücretleri, oyuncu yaş dağılımı, genç üretimi, şampiyonluk dağılımı, büyük/küçük kulüp farkı ve ileride taraftar güveni, teknik direktör ve başkan görev süresidir.

Her başarısız kariyer seed ile tekrar üretilebilmelidir.

---

# 15. İlk aşamada yapılmayacaklar

3D maç, online multiplayer, gerçek kulüp/futbolcu, lisanslı logo, ayrıntılı saha içi taktik, Football Manager seviyesinde attribute sistemi, onlarca ülke, tam dünya piramidi, erken monetizasyon optimizasyonu, görsel polish ve APK üretme baskısı.

---

# 16. Codex çalışma kuralı

Codex kredisi gereksiz kullanılmayacaktır. Büyük çok dosyalı implementasyon, refactor, simülasyon runner/test harness, karmaşık hata düzeltmesi ve migration için uygundur. Basit analiz, tasarım kararı, formül konuşması ve küçük belge değişikliklerinde kullanılmaz.

---

# 17. Güncel durum ve sıradaki iş

**Tamamlanan:**

- proje kimliği ve ana mimari,
- sistem öncelikleri ve veri modeli taslağı,
- sistem etkileşimleri,
- M0 simülasyon sözleşmesi,
- deterministik RNG/hash altyapısı,
- fikstür + maç + puan tablosu + sezon validator,
- fixture/determinism/100 sezon testleri,
- hafif GitHub Actions CI,
- PR #1 merge,
- gerçek Dart CI doğrulaması,
- M0 kalite kapısının kapanması.

**M0 sonucu: PASS.**

GitHub Actions gerçek sonucu:

- Dart SDK: `3.13.3 stable`
- analyze: PASS / 0 issue
- test: PASS / 4 test
- 100 sezon: PASS
- toplam maç: `5.600`
- ev: `%45,29`
- beraberlik: `%24,59`
- deplasman: `%30,13`
- ortalama gol: `2,586`

**Sıradaki milestone:**

## M1 — 20 Sezon Yaşam Döngüsü

İlk kapsam:

- `GameDate`,
- sezon index ilerlemesi,
- yeni sezon oluşturma,
- sezonlar arası reset kuralları,
- geçici/sade takım gücü değişimi,
- 20 sezon arka arkaya simülasyon,
- season-to-season determinism,
- 20 sezon raporu ve validator.

M1 de UI/APK kapsamına girmeyecek ve mevcut aktif projeleri aksatmayacak kadar küçük tutulacaktır.
