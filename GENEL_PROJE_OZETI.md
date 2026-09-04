# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo:** Public / proprietary notice  
**Aktif teknik aşama:** **M10 PASS — sıradaki M11 / Başkan Vaatleri + Takip Çekirdeği**  
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
6. Transfer AI yaş, kalite, potansiyel, mevki, sözleşme ve ekonomi bağlamını dikkate almalıdır.
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
23. Taraftar güveni alt boyut + neden hafızası taşır.
24. Taraftar beklentisi kulübün ekonomik/sportif bağlamına göre değişmelidir.
25. Taraftar geçmişi her sezon otomatik nötre sıfırlanmamalıdır.
26. Medya başkanın geçmiş açıklamasını sonraki eylemle birlikte değerlendirmelidir.
27. Açıklama yalnız dekoratif metin değil, sonraki olayda çözülen hafıza kaydı olmalıdır.
28. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 3. Uzun vadeli ürün vizyonu

## Ekonomi

Nakit, borç, transfer/maaş bütçesi, oyuncu maaşı, sponsor, maç günü, mağaza, transfer, tesis, altyapı ve stadyum ekonomisi birbirini etkileyecek. Mobilde sade finansal sağlık etiketleri kullanılabilir: `Çok Güçlü / Sağlam / Dengeli / Sıkışık / Borç Krizi`.

## Transfer

Uzun vadeli yollar: doğrudan bonservis, kiralık, satın alma opsiyonu/zorunluluğu, taksit, performans bonusu, satıştan pay, free agent, takas, oyuncu+para ve maaş paylaşımı.

Tamamlanan katmanlar: M4 direct fee; M7 kontrat/free-agent; M8 kiralık+taksit.

## Teknik direktör

Özerk karakterdir. Uzun vadede transfer isteği, bütçe şikâyeti, zam, başka kulüp teklifi, medya açıklaması ve yönetim çatışması yaşayabilir.

## Taraftar

M9 bağlamsal çekirdeği tamamlandı. Borçlu/zayıf kulüp pahalı yıldız yerine akıllı kiralık veya finans disiplini beklentisi üretebilir. `sporting / financial / transfer / identity` güven boyutları ve neden hafızası vardır. Henüz seyirci/gelir/sponsor tarafını geri beslemez.

## Medya

M10 ilk medya hafızasını tamamladı. Teknik direktörün geleceği hakkında başkan açıklaması kaydedilir ve aynı sezon sonundaki yönetim eylemiyle consistency/contradiction olarak çözülür. Güçlü destek verip hocayı değiştirmek ciddi credibility cezası yaratır. Medya henüz ekonomi/taraftarı geri beslemez.

## Vaat / seçim

Başkan vaatleri ölçülebilir hedefler olarak saklanacak; gerçekleşti/başarısız/kısmi ilerleme durumuna çözülecek ve daha sonra taraftar/media/seçim sistemlerini etkileyecek. Seçim daha sonraki aşamadır.

## Tesis / altyapı / sponsor / kriz

Tesis adayları: altyapı, antrenman, sağlık, scouting, stadyum, kulüp mağazası. Yatırımlar dekorasyon değil gerçek fayda üretmeli. Krizler oyuncu zam talebi, hoca/yönetim çatışması, sponsor ayrılığı, bilet protestosu, büyük teklif, genç oyuncunun süre isteği, stadyum bakım problemi ve federasyon cezası gibi bağlamsal olaylardan doğabilir.

---

# 4. Teknik mimari

> **Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği**

- `simulation_core`: saf Dart domain ve kurallar.
- `simulation_runner`: headless CLI, seed replay, batch/denge raporları.
- `persistence`: ileride versiyonlu local save/load, migration, autosave, backup.
- `application`: başkan use-case katmanı.
- `presentation`: Flutter UI; henüz kapsam dışı.

## Determinizm

Kararlı FNV-1a hash + özel xorshift32 `SeededRng`. Runtime `hashCode` kullanılmaz. Maç, transfer, manager, kontrat, fan ve media kararları seed / simulation version / sezon / entity ID üzerinden deterministik türetilir.

## Oyun zamanı

Cihaz saatinden bağımsız `GameDate`.

## Para / muhasebe

Para `double` değil integer minor-unit `Money`.

`Kapanış Nakit = Açılış Nakit + Gelir - Gider - Anapara Ödemesi + Yeni Borçlanma`

`Kapanış Borç = Açılış Borç - Anapara Ödemesi + Yeni Borçlanma`

Anapara gider değildir; faiz giderdir. Negatif nakit `emergencyBorrowing` yaratır. Bonservis/loan fee yeni para yaratmaz. Transfer taksiti banka borcundan ayrı yükümlülüktür.

## Katmanlama / hook yönü

`WorldCareerEngine` kopyalanmadan no-op varsayılanlı hook'larla genişletilir:

- `WorldCareerHooks`: manager gibi sezon/sportif lifecycle.
- `WorldRosterHooks`: kontrat/kadro/gerçek maaş.
- `WorldFinanceHooks`: taksit gibi sezon içi ek finans hareketleri.
- `WorldTransferHooks`: kiralık gibi transfer penceresi sonrası hareketler.

M9 ve M10 ilk sürümlerde alt sistem raporlarını gözlemsel kaynak olarak kullanır; fan/media çekirdeği henüz dünya sonucunu geri beslemez. Önce bağlam ve hafıza doğruluğu bağımsız kanıtlanır.

---

# 5. GitHub / CI çalışma kuralı

Repo public, açık kaynak lisansı yok; `LICENSE.md` proprietary notice içerir.

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1–M10 20 sezon headless runner'ları

APK/AAB, büyük binary ve `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M10 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük refactor/migration/karmaşık hata için kullanılacak.

---

# 6. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS

8 kulüp, 56 maç/sezon, Poisson motoru. 100 sezon: 5.600 maç; ev `%45,2857`, beraberlik `%24,5893`, deplasman `%30,1250`, gol/maç `2,5864`, invariant `0`.

## M1 — 20 Sezon Yaşam Döngüsü — PASS

`GameDate`, 20 sezon, 1.120 maç. Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi — PASS

Başlangıç 144, final 148; 148 emeklilik, 152 youth intake, yaş ortalaması `25,84`, validation `0`.

## M3 — Temel Kulüp Ekonomisi — PASS

Reddedilen ilk deneme: `1.017,03M` nakit, `0` borç, 8/8 veryStrong. Kabul: cash `124,28M`, debt `104,43M`, emergency `67,44M`, dengeli sağlık dağılımı, validation `0`.

## M4 — Basit Transfer Pazarı — PASS

Seed `20260903`: 32 transfer, `161,68M` hacim, `5,05M` ortalama fee, cash `96,38M`, debt `58,61M`, validation `0`.

## M5 — 48 Kulüp / 3 Lig — PASS

48 kulüp, 3×16 lig, 720 maç/world season, 14.400 maç/20 sezon, 864 başlangıç oyuncusu, 3'er terfi/düşme. Reddedilen denemeler: 2 transfer + `3.966,16M` borç; 7 transfer + `2.268,60M` borç; 158 transfer + `1.909,01M` nakit.

Kabul seed `20260903`: final oyuncu `906`, lig hareketi `228`, transfer `71`, hacim `637,91M`, cash `862,25M`, debt `647,04M`, emergency `569,03M`, 35 transfer katılımcısı, 10 farklı Taç Ligi şampiyonu, validation `0`.

Açık: Ufuk Ligi final nakit birikimi yüksek.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi — PASS

96 manager, 5 profil, fit modeli, `-2,5...+2,5` strength etkisi, board relationship ve görev değişimi.

Seed `20260903`: 60 farklı manager, 82 değişim, ortalama etki `+0,922`, relationship `72,22`, cash `1.048,02M`, debt `582,36M`, validation `0`.

Açık: manager maaşı/kontratı, başka kulüp teklifi, zam ve spesifik transfer talebi yok.

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş — PASS

`PlayerContract`, gerçek maaş, renewal/release, free-agent, youth kontratı, transfer kontratı, kontrat süresi market-value etkisi.

Seed `20260903`: final kontrat `874`, renewal `3.757`, release `1.143`, free signing `776`, final free agent `32`, wage bill `491,27M`, transfer `103`, cash `1.060,80M`, debt `554,81M`, validation `0`.

Ayrıntı: `M7_OYUNCU_SOZLESMESI_MAAS.md`.

## M8 — Kiralık + Taksit — PASS

Sezonluk loan, parent kontrat, loan fee, `%45–80` maaş paylaşımı, sezon sonu dönüş, upfront + iki sezon taksit, banka borcundan ayrı installment obligation.

Reddedilen denemeler: `146/183`, `145/189`, `108/147`, `86/156` taksit oranları; gelişmiş yapılar varsayılan davranışa dönüştüğü için reddedildi.

Kabul seed `20260903`: kalıcı `140`, taksitli `68`, taksit taahhüdü `234,79M`, ödenmiş `232,77M`, açık `2,02M`, kiralık `478`, aktif loan `32`, loan fee `113,15M`, borrower wage share `%62,18`, cash `1.017,61M`, debt `378,97M`, validation `0`.

Ayrıntı: `M8_KIRALIK_TAKSIT.md`.

## M9 — Taraftar Beklentisi + Güven — PASS

`FanState`: sporting/financial/transfer/identity. Bağlamsal beklenti ve neden hafızası. Aynı borç krizinde akıllı kiralık `+4`, aşırı harcama+taksit `-4` transfer trust etkisi.

Reddedilen ilk model: avg `61,06`, aralık `46–68`; yıllık 60'a dönüş geçmişi fazla siliyordu.

Kabul seed `20260903`: snapshot `960`, avg trust `64,88`, aralık `44–75`, spread `31`, boundary `0`, reason `2.143`, smart-loan `9`, financial-discipline `58`, validation `0`.

Ayrıntı: `M9_TARAFTAR_GUVEN.md`.

## M10 — Medya Hafızası + Başkan Açıklamaları — PASS

`MediaStatement`, `MediaState`, `MediaCredibilityChange`, deterministic statement engine, consistency/contradiction çözümlemesi, 20 sezon media report/validator.

İmza davranışı: credibility `60` iken strong support verip manager değiştirmek `-10`; pressure açıklaması sonrası değişim `+3`; güçlü desteği tutmak `+2`.

Reddedilen ilk model: statement `847/960`, contradiction `42`, consistent `624`, avg credibility `79,31`, aralık `31–91`. Açıklama neredeyse her kulüp/sezon otomatik olduğu için reddedildi.

Kabul seed `20260903`: statement `556`, contradiction `22`, strong-support contradiction `9`, consistent `385`, stance dağılımı strong `230` / measured `155` / pressure `121` / no-comment `50`, avg credibility `75,52`, aralık `49–87`, boundary `0`, manager change `82`, validation `0`.

CI guard: statement `300–700`, contradiction `10–80`, strong-broken `3–50`, consistent `200–550`, dört stance tipi, avg credibility `55–82`, min `25–60`, max `75–92`, boundary `<=2`.

Ayrıntı: `M10_MEDYA_HAFIZASI.md`.

---

# 7. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu sayısı/yaş, emeklilik/youth, cash/debt, wage/revenue, transfer yapısı, installments, loans, şampiyonluk, terfi, manager tenure, fan trust/expectation mix, media credibility/contradiction; ileride promise/election/başkan tenure.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 8. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Minimum: autosave + önceki autosave yedeği + manuel save + migration.

Kalıcı state: M8 installment/active loans, M9 `FanState`, M10 `MediaState` ve çözülmemiş önemli açıklamalar. Tam sezon snapshot geçmişlerinin save'e gömülmesi zorunlu değildir; kompakt history/event modeli kullanılabilir.

---

# 9. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Resmî kulüp `wageBudget` sistemi henüz yok.
3. Free-agent AI basit ihtiyaç/affordability modelidir; oyuncu tercihi/itibar/rekabet gerekir.
4. Manager maaşı/kontratı, başka kulüp teklifi ve spesifik transfer talebi yok.
5. Taksit/kiralık ilk kalibrasyondur; satın alma opsiyonu, bonus, sell-on ve takas yok.
6. M9 taraftar güveni henüz seyirci/bilet/mağaza/sponsor/protestoyu etkilemez.
7. `identityTrust` M9'da nötrdür.
8. M10 medya yalnız `managerFuture` konusunu ve aynı sezon çözümlemesini kapsar; serbest metin, çok yıllı medya hikâyesi ve ekonomik/fan geri besleme yok.
9. Sponsor, vaat, tesis ve kriz henüz çekirdeğe bağlanmadı.
10. Flutter UI/APK bilinçli olarak başlamadı.

---

# 10. Sıradaki milestone — M11

## Başkan Vaatleri + Takip Çekirdeği

Amaç:

> **Başkan verdiği sözü sezon sonunda unutamayacak.**

İlk M11 kapsamı:

- `Promise` / `PromiseType` domain modeli,
- ölçülebilir sezon hedefleri,
- örneğin borcu azaltma, lig hedefi, genç oyuncu kullanımı, transfer harcama disiplini gibi deterministic promise türleri,
- başlangıç baseline + hedef + deadline,
- sezon boyunca progress,
- `fulfilled / failed / partial` çözümlemesi,
- neden/sonuç kaydı,
- aynı seed replay,
- 20 sezon promise completion dağılımı,
- ilk aşamada fan/media puanını değiştirmeden gözlemsel doğrulama.

M11 seçim, Flutter UI ve serbest metin vaat içermez. Vaatlerin taraftar/media geri beslemesi sonraki katmanda bağlanacaktır.

---

# 11. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş bu dosyaya yazılır.
- Yeni karar eskiyle çelişirse yeni karar geçerlidir; önemli tarihçe korunur, gereksiz tekrar temizlenir.
