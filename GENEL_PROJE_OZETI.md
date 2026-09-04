# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo durumu:** Public / proprietary notice  
**Aktif teknik aşama:** **M9 PASS — sıradaki M10 / Medya Hafızası + Başkan Açıklamaları**  
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

Başkanın alanı: ekonomi/borç, teknik direktör seçimi, transfer politikası, bütçe/maaş, altyapı, tesis, sponsor, taraftar, medya, vaat, kriz ve uzun vadeli kulüp sağlığı.

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
20. Taksit banka borcu değildir; ayrı gelecek transfer yükümlülüğüdür.
21. Kiralıkta kalıcı kontrat parent club'da korunur.
22. Gelişmiş transfer yapıları seçenek olmalı, otomatik varsayılan olmamalıdır.
23. Taraftar güveni tek sayıdan ibaret değildir; alt boyut + neden hafızası taşır.
24. Taraftar beklentisi kulübün ekonomik/sportif bağlamına göre değişmelidir.
25. Taraftar güven geçmişi her sezon otomatik olarak nötre sıfırlanmamalıdır.
26. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 3. Uzun vadeli ürün vizyonu

## Ekonomi

Arka planda derin, mobilde anlaşılır. Nakit, borç, transfer/maaş bütçesi, oyuncu maaşı, sponsor, maç günü, mağaza, transfer, tesis, altyapı ve stadyum ekonomisi birbirini etkileyecek.

Finansal sağlık kullanıcıya sade etiketlerle gösterilebilir: `Çok Güçlü / Sağlam / Dengeli / Sıkışık / Borç Krizi`.

## Transfer

Hedef yollar:

- doğrudan bonservis
- kiralık
- satın alma opsiyonu/zorunluluğu
- taksit
- performans bonusu
- satıştan pay
- serbest oyuncu / sözleşmesi biten
- takas / oyuncu + para
- maaş paylaşımı

Tamamlanan transfer katmanları: M4 direct fee, M7 gerçek kontrat/free-agent, M8 kiralık+taksit.

## Teknik direktör

Özerk futbol karakteridir. Uzun vadede transfer isteği, bütçe şikâyeti, zam, başka kulüp teklifi, medya açıklaması ve yönetim çatışması yaşayabilir.

## Taraftar

M9 ile ilk bağlamsal çekirdek tamamlandı. Borçlu/zayıf kulüp pahalı yıldız yerine akıllı kiralık veya finans disiplini beklentisi üretebilir. Güven sporting / financial / transfer / identity boyutlarında saklanır ve her değişiklik neden kodu taşır. M9'da taraftar henüz seyirci/gelir/sponsor tarafını geri beslemez.

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

Katman yönü:

- `simulation_core`: saf Dart domain ve kurallar.
- `simulation_runner`: headless CLI, seed replay, batch/denge raporları.
- `persistence`: ileride versiyonlu local save/load, migration, autosave, backup.
- `application`: başkan use-case katmanı.
- `presentation`: Flutter UI; henüz kapsam dışı.

## Determinizm

Kararlı FNV-1a tabanlı hash + özel xorshift32 `SeededRng`. Runtime `hashCode` kullanılmaz. Maç, transfer, manager, kontrat ve bağlı sistemler career seed / simulation version / sezon / entity ID üzerinden türetilir. M9 fan lifecycle same-seed replay ile ayrıca doğrulanır.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate`.

## Para / muhasebe

Para `double` değil integer minor-unit `Money`.

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Anapara gider değildir; faiz giderdir. Negatif nakit sessizce sıfırlanmaz, `emergencyBorrowing` yaratır. Bonservis ve loan fee yeni para yaratmaz; kulüpler arasında taşınır. Transfer taksiti banka borcundan ayrı yükümlülüktür.

## Hook / katmanlama yönü

`WorldCareerEngine` sistemleri kopyalamadan genişletilir:

- `WorldCareerHooks`: manager gibi sezon/sportif lifecycle.
- `WorldRosterHooks`: kontrat/kadro/gerçek maaş.
- `WorldFinanceHooks`: taksit gibi sezon içi ek finans hareketleri.
- `WorldTransferHooks`: kiralık gibi transfer penceresi sonrası hareketler.

Varsayılanlar no-op. M9 ilk sürümde M8 advanced report'u gözlemsel kaynak olarak işler; taraftar simülasyon sonucunu henüz değiştirmez. Böylece fan context doğruluğu ekonomik geri beslemeden ayrı test edilir.

---

# 5. GitHub / CI çalışma kuralı

Repo public, açık kaynak lisansı yok; `LICENSE.md` proprietary notice içerir.

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1–M9 20 sezon headless runner'ları

APK/AAB, büyük binary ve `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M9 üretiminde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük/refactor/migration/karmaşık hata için kullanılacak.

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

## M4 — Basit Transfer Pazarı — PASS

Market value, mevki ihtiyacı, satıcı talebi/alıcı maksimumu, finans baskısı, 2M rezerv, `%35` pencere harcama sınırı, max 2 alım, kadro/pozisyon satış tabanları, nakit korunumu.

Seed `20260903`: 32 transfer, `161,68M` hacim, `5,05M` ortalama bonservis, cash `96,38M`, debt `58,61M`, final 148 oyuncu, validation `0`.

## M5 — 48 Kulüp / 3 Lig — PASS

48 kurgu kulüp; Taç/Birlik/Ufuk, 3×16, 720 maç/world season, 14.400 maç/20 sezon, 864 başlangıç oyuncusu, 3'er terfi/düşme.

Reddedilen kalibrasyonlar: 2 transfer + `3.966,16M` borç; 7 transfer + `2.268,60M` borç; ardından 158 transfer + `1.909,01M` nakit. Üçü de reddedildi.

Kabul seed `20260903`: final oyuncu `906`, lig hareketi `228`, transfer `71`, hacim `637,91M`, cash `862,25M`, debt `647,04M`, emergency `569,03M`, 35 transfer katılımcısı, 10 farklı Taç Ligi şampiyonu, validation `0`.

Açık not: Ufuk Ligi final nakit birikimi yüksek; nihai ekonomi değildir.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi — PASS

96 deterministik manager; `balanced`, `youthDeveloper`, `budgetBuilder`, `starManager`, `resultsFirst` profilleri. Kulüp-finans-kadro-lig fit modeli, `-2,5...+2,5` maç strength etkisi, board relationship, performans/board breakdown/emeklilik görev değişimleri.

Seed `20260903`: 60 farklı manager, 82 değişim, ortalama etki `+0,922`, final board relationship `72,22`, transfer `84`, cash `1.048,02M`, debt `582,36M`, emergency `473,40M`, validation `0`.

Açık: manager maaşı/kontratı, başka kulüp teklifi, zam, spesifik transfer talebi, medya etkisi yok.

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi — PASS

`PlayerContract`, gerçek yıllık maaş, yenileme/release, free-agent havuzu, youth ilk kontratı, transfer sonrası yeni kontrat ve kontrat süresinin market value etkisi.

Seed `20260903`: aktif final kontrat `874`, renewal `3.757`, release `1.143`, free-agent signing `776`, final free agent `32`, youth contract `912`, transfer contract `103`, final wage bill `491,27M`, ortalama maaş `562.091`, transfer `103`, cash `1.060,80M`, debt `554,81M`, emergency `428,76M`, validation `0`.

CI geniş guard: renewal 1.500–7.000; release 300–2.500; free signing 200–2.000; final free agent 5–100; bonservis 40–300; wage 200M–900M; cash/debt 100M–2B.

Ayrıntı: `M7_OYUNCU_SOZLESMESI_MAAS.md`.

## M8 — Gelişmiş Transfer Yapıları I / Kiralık + Taksit — PASS

### Taksit

- `TransferInstallment` / `TransferInstallmentObligation`.
- upfront + iki gelecek sezon taksiti.
- `upfront + taksitler = toplam fee` invariantı.
- taksit banka borcundan ayrı.
- vadesinde alıcıdan satıcıya gerçek nakit akışı.
- 5M altı bonserviste taksit yok.
- upfront yaklaşık `%58–73`.
- satıcı ekonomisi taksit kabulünü etkiler.

### Kiralık

- sezonluk `LoanAgreement`.
- parent club kontratı korunur.
- borrower kadrosunda oynar, sezon sonunda otomatik döner.
- loan fee `100K–1,5M` aralığında ve finans kapasitesiyle sınırlı.
- loan club maaş payı `%45–80`.
- borrower mevki/kalite ihtiyacı olmadan otomatik kiralama yapmaz.
- parent club mevki fazlalığı ve kadro tabanı korunur.

### Reddedilen M8 denge denemeleri

1. `183` kalıcı / `146` taksit / `755` kiralık → iki yapı da varsayılan davranış.
2. `189` kalıcı / `145` taksit / `482` kiralık → kiralık düzeldi, taksit aşırı.
3. `147` kalıcı / `108` taksit / `462` kiralık → taksit hâlâ çoğunluk.
4. `156` kalıcı / `86` taksit / `491` kiralık → taksit `%55`, ürün kriterini kaçırdı.

### M8 kabul baseline — seed `20260903`

- 20 sezon / `14.400` maç
- kalıcı transfer `140`
- taksitli `68` (`%48,6`)
- taksit taahhüdü `234,79M`
- ödenmiş `232,77M`
- açık `2,02M`
- kiralık `478`
- final aktif kiralık `32`
- loan fee `113,15M`
- ortalama borrower maaş payı `%62,18`
- cash `1.017,61M`
- debt `378,97M`
- emergency `185,61M`
- validation `0`

CI geniş M8 guard'ları: kalıcı 80–260; taksit 20–120 ve kalıcıların yarısından az; kiralık 250–700; aktif loan 5–48; wage share 4500–8000 bps; installment commitment 50M–600M; outstanding <=100M; loan fees 40M–250M; cash 300M–2B; debt 100M–1,2B.

Ayrıntı: `M8_KIRALIK_TAKSIT.md`.

## M9 — Taraftar Beklentisi + Güven Çekirdeği — PASS

### Domain

- `FanState`: sporting / financial / transfer / identity.
- overall trust ağırlıkları `%35 / %30 / %25 / %10`.
- `FanSeasonContext` gerçek world/finance/transfer/loan verisinden oluşur.
- `FanExpectationEngine` bağlamsal beklenti üretir.
- `FanTrustEngine` neden kodlu güven değişimi üretir.
- `FanCareerReport` ve `FanCareerValidator` 48×20 sezonu takip eder.

### İmza davranışı

Borç krizi + sportif zayıflık durumunda `smartLoanReinforcement` üretilebilir. Aynı kriz bağlamında:

- akıllı kiralık → `used_smart_loan`, transfer trust `+4`,
- yüksek harcama + 2 taksit → `overspent_in_financial_stress`, transfer trust `-4`.

### Reddedilen M9 kalibrasyonu

İlk teknik PASS:

- avg trust `61,06`
- aralık `46–68`
- boundary `0`

Her sezon bütün güven boyutlarını 60'a doğru çeken mean reversion 20 yıllık geçmişi fazla siliyordu. **Reddedildi.**

### M9 kabul baseline — seed `20260903`

- snapshot `960`
- final fan state `48`
- avg trust `64,88`
- min `44`
- max `75`
- spread `31`
- boundary `0`
- trust reason `2.143`
- smart-loan expectation `9`
- financial-discipline expectation `58`
- validation `0`

Expectation dağılımı: measured improvement `465`; strengthen squad `108`; rebuild after relegation `99`; prepare for higher tier `111`; ambitious reinforcement `62`; smart loan `9`; financial discipline `58`; none `48`.

Kabul modelinde mean reversion yalnız `>75` ve `<45` dış bantlarında yumuşak birer puan çalışır; 45–75 aralığındaki geçmiş otomatik silinmez.

CI geniş M9 guard'ları: avg 50–75; min 25–60; max 65–90; spread >=25; boundary <=2; reasons 1.500–3.000; smart-loan 5–100; financial-discipline 20–180; en az 7 expectation tipi; final `none=48`; measured improvement 250–650.

Ayrıntı: `M9_TARAFTAR_GUVEN.md`.

---

# 7. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1000 × 30 sezon

İzlenecekler: oyuncu sayısı/yaş, emeklilik/youth, cash/debt, wage/revenue, transfer ücret/hacim/yapısı, future installments, loan volume, title dağılımı, terfi yaşam oranı, büyük-küçük farkı, manager tenure, fan trust dağılımı/expectation mix; ileride medya/vaat/başkan tenure.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 8. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Minimum: aktif autosave + önceki autosave yedeği + manuel save + migration. Persistence domain modellerinin birebir kopyası olmak zorunda değildir.

Kalıcı state tasarımında M8 gelecek taksit yükümlülükleri/aktif kiralıkları ve M9 `FanState` güven boyutlarını saklamak gerekir. Tam fan snapshot geçmişinin save'e gömülmesi zorunlu değildir; önemli neden geçmişi ayrı kompakt event/history modeliyle ele alınabilir.

---

# 9. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Gerçek oyuncu maaşı var; resmi kulüp `wageBudget` sistemi henüz yok.
3. Free-agent AI basit ihtiyaç/affordability modelidir; oyuncu tercihi, itibar ve rekabetçi teklifler ileride gerekir.
4. Kontrat yenileme AI kararı; başkan use-case/UI yok.
5. Manager maaşı/kontratı henüz yok.
6. Taksit ve kiralık ilk kalibrasyondur; nihai oranlar değildir.
7. Satın alma opsiyonu/zorunluluğu, bonus, sell-on ve takas yok.
8. M9 taraftar güveni henüz seyirci, bilet, mağaza, sponsor veya protestoyu etkilemez.
9. `identityTrust` M9'da nötrdür; gerçek kimlik sinyali gelmeden yapay puan üretilmez.
10. Sponsor, medya, vaat, tesis ve kriz çekirdeğe bağlanmadı.
11. Flutter UI/APK bilinçli olarak başlamadı.

---

# 10. Sıradaki milestone — M10

## Medya Hafızası + Başkan Açıklamaları Çekirdeği

Amaç projenin diğer imza farkını kanıtlamak:

> **Medya başkanın dün söylediğini unutmayacak.**

İlk M10 kapsamı:

- `MediaStatement` domain modeli,
- konu/target/stance/season bilgisi,
- kamuya açık başkan desteği/eleştirisi gibi deterministik açıklama senaryoları,
- geçmiş açıklama ile sonraki yönetim davranışının uyum/çelişki kontrolü,
- 0–100 `mediaCredibility`,
- neden kodlu credibility değişimi,
- örneğin teknik direktöre güçlü destek verip kısa sürede kovmanın güvenilirlik cezası,
- açıklamanın hemen değil sonraki olayda çözümlenebilmesi,
- same-seed replay ve 20 sezon credibility dağılım guard'ı.

M10 ilk aşamada başkan vaat sistemi, seçim ve Flutter UI içermez. Vaatler ayrı milestone olarak ele alınacaktır.

---

# 11. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş bu dosyaya yazılır.
- Yeni karar eskiyle çelişirse yeni karar geçerlidir; önemli tarihçe korunur, gereksiz tekrar temizlenir.
