# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo:** Public / proprietary notice  
**Aktif teknik aşama:** **M7 PASS — sıradaki M8 / Gelişmiş Transfer Yapıları I: Kiralık + Taksit**  
**Proje önceliği:** Yan geliştirme; Kelime Avı ve Minik Dedektif gibi aktif projeleri aksatmayacak.  
**UI/APK:** Henüz başlanmadı; simülasyon çekirdeği önceliklidir.

---

# 1. Proje kimliği

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

Alternatif:

> **“Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.”**

Başkanın alanı: ekonomi/borç, teknik direktör, transfer politikası, bütçe/maaş, altyapı, tesis, sponsor, taraftar, medya, vaat, kriz ve uzun vadeli kulüp sağlığı.

Başkanın alanı değildir: diziliş, antrenman, duran top, maç içi değişiklik ve saha içi mikro taktik.

Dünya tamamen özgün olacak; gerçek kulüp, futbolcu, lig logosu veya lisanslı materyal kullanılmayacak.

---

# 2. Değişmez ürün ilkeleri

1. Başkan teknik direktör değildir.
2. Mobil UI sade; arka plan sistemleri derin olabilir.
3. Başarı yalnız kupa değil; finansal iyileşme ve sürdürülebilirliktir.
4. Kısa vadeli sportif başarı ile uzun vadeli kulüp sağlığı arasında gerçek gerilim olmalıdır.
5. Taraftar ekonomik/sportif bağlamı anlamalı, imkânsız talep üretmemelidir.
6. Transfer AI yaş, kalite, potansiyel, mevki, sözleşme, ekonomi ve oyuncu isteğini dikkate almalıdır.
7. **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**
8. **“Paran yoksa transfer yapamazsın” değil, “paran yoksa daha akıllı transfer yapmak zorundasın.”**
9. Geçmiş açıklamalar, vaatler ve önemli kararlar hatırlanmalıdır.
10. Bazı sonuçlar aylar/sezonlar sonra ortaya çıkabilmelidir.
11. Doğru karar her zaman açık olmamalıdır.
12. V1 gereksiz sistemlerle şişirilmemelidir.
13. Uzun kariyer otomatik simülasyonlarla test edilmelidir.
14. Aynı simulation version + seed + veri + karar dizisi aynı sonucu üretmelidir.
15. Ekonomi ne evrensel refah ne evrensel çöküş üretmelidir.
16. Transfer piyasası ne donmuş ne hiperaktif olmalıdır.
17. Teknik direktör önemlidir ama kadronun önüne geçemez.
18. Sözleşme süresi transfer değerinin gerçek girdisidir.
19. Serbest oyuncu bonservisli transferden ayrı piyasa davranışıdır.
20. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 3. Uzun vadeli sistem vizyonu

## Ekonomi

Arka planda derin, mobilde anlaşılır. Nakit, borç, transfer/maaş bütçesi, oyuncu maaşı, sponsor, maç günü, mağaza, transfer, tesis, altyapı ve stadyum ekonomisi birbirini etkileyecek.

Finansal sağlık kullanıcıya sade etiketlerle gösterilebilir: `Çok Güçlü / Sağlam / Dengeli / Sıkışık / Borç Krizi`.

## Transfer

Hedef transfer yolları:

- doğrudan bonservis
- kiralık
- satın alma opsiyonu/zorunluluğu
- taksit
- performans bonusu
- satıştan pay
- serbest oyuncu / sözleşmesi biten
- takas / oyuncu + para
- maaş paylaşımı

M4 direct fee, M7 gerçek kontrat + free agent. M8 ilk gelişmiş yapılar olarak **kiralık + taksit**.

## Teknik direktör

Özerk futbol karakteri. Uzun vadede transfer isteği, bütçe şikâyeti, zam, başka kulüp teklifi, medya açıklaması ve yönetim çatışması yaşayabilir.

## Taraftar

Bağlam farkındalığı imza sistemlerden biri. Borçlu kulübün taraftarı 60M yıldız yerine kaliteli kiralık isteyebilir. Güven nedenleri ayrıca saklanmalı: derbi, borç, transfer, bilet, genç, vaat, hoca vb.

## Medya + vaat hafızası

Başkanın eski açıklamaları/vaatleri kaydedilmeli. Hocaya kamuoyu önünde destek verip kısa süre sonra kovmak medya güvenilirliğini düşürmelidir.

## Seçim

Daha sonraki aşama. Sportif sonuç, finans, kulüp değeri, tesis, taraftar, vaat ve medya itibarı etkili olacak. Seçim kaybı kariyeri zorunlu olarak bitirmeyebilir.

## Tesis / altyapı / sponsor / kriz

Tesis adayları: altyapı, antrenman, sağlık, scouting, stadyum, kulüp mağazası. Yatırımlar dekorasyon değil gerçek fayda üretmeli.

Kriz örnekleri: zam isteyen oyuncu, kaptan-hoca çatışması, sponsor ayrılığı, bilet protestosu, büyük teklif, genç oyuncunun süre isteği, hocanın yönetimi eleştirmesi, stadyum bakım sorunu, federasyon cezası, menajer baskısı.

---

# 4. Teknik mimari

> **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**

- `simulation_core`: saf Dart domain ve kurallar.
- `simulation_runner`: headless CLI, seed replay, batch/denge raporları.
- `persistence`: ileride versiyonlu local save/load, migration, autosave, backup.
- `application`: başkan use-case katmanı.
- `presentation`: Flutter UI; henüz kapsam dışı.

## Determinizm

Kararlı FNV-1a tabanlı hash + özel xorshift32 `SeededRng`. Runtime `hashCode` kullanılmaz. Maç, transfer, manager ve kontrat kararları career seed / simulation version / sezon / entity ID üzerinden türetilir.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate`.

## Para / muhasebe

Para `double` değil integer minor-unit `Money`.

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Anapara gider değildir; faiz giderdir. Negatif nakit sessizce sıfırlanmaz, `emergencyBorrowing` yaratır. Bonservis yeni para yaratmaz; alıcıdan satıcıya nakit taşır.

## Hook mimarisi

`WorldCareerEngine` sistemleri kopyalamadan genişletilir:

- `WorldCareerHooks`: manager gibi sezon/sportif lifecycle sistemleri.
- `WorldRosterHooks`: kontrat/kadro/gerçek maaş sistemleri.

Her ikisinin varsayılanı no-op. Manager + contract hook birlikte otomatik test edilmiştir. Eski milestone yolları böylece birebir regresyon baseline'ı olarak korunur.

---

# 5. GitHub / CI çalışma kuralı

Repo public, açık kaynak lisansı yok; `LICENSE.md` proprietary notice içerir.

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1–M7 20 sezon headless runner'ları

APK/AAB, büyük binary ve `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M7 üretiminde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük/refactor/migration/karmaşık hata için kullanılacak.

---

# 6. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS

8 kurgu kulüp, çift devre, 56 maç/sezon, Poisson maç motoru, standings/validator, 100 sezon regresyon.

100 sezon baseline: 5.600 maç; ev `%45,2857`, beraberlik `%24,5893`, deplasman `%30,1250`, gol/maç `2,5864`, invariant `0`.

## M1 — 20 Sezon Yaşam Döngüsü — PASS

`GameDate`, 20 sezon, 1.120 maç, deterministik geçiş. Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

Seed `20260903`: başlangıç 144, final 148 oyuncu, 148 emeklilik, 152 youth intake, 146 aktif akademi mezunu, yaş ortalaması `25,84`, validation `0`.

## M3 — Temel Kulüp Ekonomisi — PASS

İlk deneme REDDEDİLDİ: `1.017,03M` nakit, `0` borç, 8/8 veryStrong → evrensel refah.

Kabul baseline: cash `124,28M`, debt `104,43M`, emergency `67,44M`, 2 veryStrong / 2 solid / 2 balanced / 2 debtCrisis, validation `0`.

Integer `Money`, gelir/gider, borç/faiz ve emergency borrowing bu aşamada geldi. `WageModel`, M7'ye kadar geçici maaş köprüsüydü.

## M4 — Basit Transfer Pazarı — PASS

Market value, mevki ihtiyacı, satıcı talebi/alıcı maksimumu, finans baskısı, 2M rezerv, `%35` pencere harcama sınırı, max 2 alım, kadro/pozisyon satış tabanları, nakit korunumu.

Seed `20260903`: 32 transfer, `161,68M` hacim, `5,05M` ortalama bonservis, cash `96,38M`, debt `58,61M`, final 148 oyuncu, validation `0`.

## M5 — 48 Kulüp / 3 Lig — PASS

48 özgün kurgu kulüp; Taç/Birlik/Ufuk, 3×16, 30 maç/kulüp, 720 maç/world season, 14.400 maç/20 sezon, 864 başlangıç oyuncusu, 3'er terfi/düşme, 19 geçişte 228 lig hareketi.

Geçici ekonomi ölçekleri:

- Taç `%100 / %100`
- Birlik `%90 / %85`
- Ufuk `%80 / %75`

### Reddedilen M5 kalibrasyonları

1. 2 transfer / `3.966,16M` borç → alt lig borç ölüm sarmalı.
2. 7 transfer / `2.268,60M` borç / 34 debtCrisis → çöküş devam etti.
3. 158 transfer / `1.909,01M` nakit → aşırı servet.

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

Açık not: Ufuk Ligi final nakit birikimi yüksek; nihai ekonomi kabulü değildir. Maaş/bütçe/sponsor sistemleri geliştikçe yeniden kalibre edilecek.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi — PASS

96 deterministik manager; profiller `balanced`, `youthDeveloper`, `budgetBuilder`, `starManager`, `resultsFirst`.

Alanlar: yaş/emeklilik, reputation, coaching, youthDevelopment, manManagement, boardCooperation, budgetDemand.

`ManagerFitModel` kulüp finansı, lig, kadro yaşı/potansiyeli ve strength'i değerlendirir. `ManagerImpactModel` kesin `-2,5...+2,5`; yalnız maç strength'ine uygulanır. Doğrudan test kötü seçim `-2,5`, elit uyum `+2,5` üretir.

Görev değişimi: performans / board breakdown / emeklilik. Kovulan hoca başka kulüpte çalışabilir; emekli atanamaz.

### M6 baseline — seed `20260903`

- manager pool `96`
- görev yapan `60`
- değişim `82` = 51 performance + 29 board breakdown + 2 retirement
- ortalama etki `+0,922`
- AI min/max `-0,371 / +1,977`
- negatif kulüp-sezon `29 / 960`
- `+1,5` üzeri pozitif `77 / 960`
- final board relationship `72,22`
- transfer `84`, hacim `777,02M`
- cash `1.048,02M`, debt `582,36M`, emergency `473,40M`
- validation `0`

M5 no-op baseline aynı CI'da birebir korunur.

M6 açık: manager maaşı/kontratı, başka kulüp teklifi, zam, spesifik transfer talebi, medya, taraftar etkisi ve youthDevelopment'ın bireysel gelişime doğrudan etkisi henüz yok.

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi — PASS

### Domain ve lifecycle

`PlayerContract`: player ID, club ID, başlangıç/bitiş sezonu, yıllık `Money` maaş.

- 864 başlangıç oyuncusuna deterministik kontrat.
- Her youth intake için ilk profesyonel kontrat.
- Biten kontratta yenileme veya release.
- Release oyuncu `Player.freeAgentClubId = '__free_agent__'` durumuna geçer; `clubId` nullable yapılmadı.
- Free agent kontratsız ve maaşsızdır; normal bonservis havuzuna girmez; ayrı imza adımında mevki ihtiyacı + yaş/kalite + affordability ile kulüp bulabilir.
- Bonservis transferinden sonra oyuncuya alıcı kulüpte yeni 3–5 yıllık kontrat yazılır.

### Gerçek maaş

M7 aktifken ekonomi gerçek kontrat maaşlarını toplar. Contract hook yoksa eski `WageModel` yolu aynen korunur; M0–M6 baseline değişmez.

### Kontrat süresi ve market value

Opsiyonel ilk katsayılar:

- 0 yıl `%25`
- 1 yıl `%70`
- 2 yıl `%90`
- 3 yıl `%103`
- 4 yıl `%110`
- 5+ yıl `%115`

Kontrat süresi verilmezse eski M4–M6 value davranışı aynıdır.

### M7 kabul baseline — seed `20260903`

- 20 sezon / `14.400` maç
- başlangıç kontratı `864`
- final aktif kontrat `874`
- renewal `3.757`
- release `1.143`
- free-agent signing `776`
- final free agent `32`
- youth contract `912`
- transfer sonrası kontrat `103`
- final yıllık toplam maaş `491,27M`
- ortalama final yıllık maaş `562.091`
- bonservis transferi `103`
- transfer hacmi `868,67M`
- final cash `1.060,80M`
- final debt `554,81M`
- emergency `428,76M`
- validation `0`

### Geniş regresyon guard'ları

Nihai denge değil, sistemin donmasını/patlamasını önleyen sınırlar:

- renewal `1.500–7.000`
- release `300–2.500`
- free-agent signing `200–2.000`
- final free agent `5–100`
- bonservis transferi `40–300`
- final yıllık maaş `200M–900M`
- final cash `100M–2B`
- final debt `100M–2B`

M7 kalite kapısı: `dart analyze` PASS, **31/31 test PASS**, M0–M7 runner PASS, same-seed replay PASS, different-seed divergence PASS, manager+contract coexistence PASS, artifact `0`.

M5 seed baseline M7 CI'da yine birebir `71 transfer / 637,91M / 862,25M cash / 647,04M debt / 569,03M emergency / validation 0` kaldı. M6 baseline da değişmedi.

M7 kapsam dışı: signing bonus, performans bonusu, release clause, oyuncu temsilcisi, etkileşimli maaş pazarlığı, loan, installment, satın alma opsiyonu/zorunluluğu, sell-on, takas, maaş paylaşımı, Flutter UI/APK.

Ayrıntı: `M7_OYUNCU_SOZLESMESI_MAAS.md`.

---

# 7. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1000 × 30 sezon

İzlenecekler: oyuncu sayısı/yaş, emeklilik/youth, cash/debt, wage/revenue, transfer ücret/hacim, renewal/release/free-agent, title dağılımı, terfi yaşam oranı, büyük-küçük farkı, manager tenure; ileride taraftar/vaat/başkan tenure.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 8. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Minimum: aktif autosave + önceki autosave yedeği + manuel save + migration. Persistence domain modellerinin birebir kopyası olmak zorunda değildir.

---

# 9. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Gerçek oyuncu maaşı var; resmi kulüp `wageBudget` sistemi henüz yok.
3. Free-agent AI şu an basit ihtiyac/affordability modelidir; oyuncu tercihi, itibar ve rekabetçi teklifler ileride gerekir.
4. Kontrat yenileme şu an AI kararı; başkan use-case/UI yok.
5. Manager maaşı/kontratı oyuncu kontratından ayrı ve henüz yok.
6. Transfer hâlâ direct-fee ağırlıklı; M8 loan + installment.
7. Kontrat market-value katsayıları ilk kalibrasyondur, nihai değildir.
8. Sponsor, taraftar, medya, vaat, tesis ve kriz çekirdeğe bağlanmadı.
9. Flutter UI/APK bilinçli olarak başlamadı.

---

# 10. Sıradaki milestone — M8

## Gelişmiş Transfer Yapıları I: Kiralık + Taksit

Amaç ana transfer felsefesini gerçekleştirmeye başlamak:

> **Paran yoksa daha akıllı transfer yapmak zorundasın.**

### Kiralık

- sezonluk `LoanAgreement`
- parent club kimliği
- loan club kadrosunda oynama
- basit loan fee
- basit wage sharing
- sezon sonunda güvenli dönüş

### Taksitli bonservis

- upfront ödeme
- future installment obligations
- toplam bedel
- alıcı için gelecek sezon nakit yükü
- satıcı için gelecek tahsilat
- ekonomi raporunda açık yükümlülük

M8'e şimdilik alınmayacak: satın alma opsiyonu/zorunluluğu, performans bonusu, sell-on, takas, oyuncu+para. Önce loan + installment 20 sezon ve uzun kariyer testlerinde kanıtlanacak.

---

# 11. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş bu dosyaya yazılır.
- Yeni karar eskiyle çelişirse yeni karar geçerlidir; önemli tarihçe korunur, gereksiz tekrar temizlenir.
