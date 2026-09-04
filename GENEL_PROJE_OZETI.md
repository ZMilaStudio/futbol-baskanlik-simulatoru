# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru`  
**Repo durumu:** Public / proprietary notice  
**Aktif teknik aşama:** **M12 PASS — sıradaki M13 / Vaat Sonuçlarının Medya Güvenilirliğine Etkisi**  
**Proje önceliği:** Yan geliştirme; Kelime Avı ve Minik Dedektif gibi aktif projeleri aksatmayacak.  
**UI/APK:** Bilinçli olarak başlanmadı; simülasyon çekirdeği öncelikli.

---

# 1. Proje kimliği

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri: **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**  
Alternatif: **“Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.”**

Başkanın alanı: ekonomi/borç, teknik direktör seçimi, transfer politikası, bütçe/maaş, altyapı, tesis, sponsor, taraftar, medya, vaat, kriz ve uzun vadeli kulüp sağlığı.

Başkanın alanı değildir: diziliş, antrenman, duran top, maç içi değişiklik ve saha içi mikro taktik.

Dünya tamamen özgün olacak; gerçek kulüp/futbolcu/lig logosu ve lisanslı materyal kullanılmayacak.

---

# 2. Değişmez ürün ve teknik ilkeler

1. Başkan teknik direktör değildir.
2. Mobil UI sade; arka plan sistemleri derin olabilir.
3. Başarı yalnız kupa değildir; finansal sağlık ve sürdürülebilirlik de başarıdır.
4. Kısa vadeli sportif başarı ile uzun vadeli kulüp sağlığı arasında gerçek gerilim olmalıdır.
5. Taraftar ekonomik/sportif bağlamı anlamalıdır.
6. Transfer AI yaş, kalite, potansiyel, mevki, sözleşme ve ekonomi bağlamını kullanmalıdır.
7. **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**
8. **Paran yoksa daha akıllı transfer yapmak zorundasın.**
9. Geçmiş açıklamalar, vaatler ve önemli kararlar unutulmamalıdır.
10. Bazı sonuçlar aylar/sezonlar sonra ortaya çıkabilmelidir.
11. Doğru karar her zaman açık olmamalıdır.
12. V1 gereksiz sistemlerle şişirilmemelidir.
13. Uzun kariyer otomatik simülasyonlarla test edilmelidir.
14. Aynı simulation version + seed + veri + karar dizisi aynı sonucu üretmelidir.
15. Ekonomi ne evrensel refah ne evrensel çöküş üretmelidir.
16. Transfer piyasası ne donmuş ne hiperaktif olmalıdır.
17. Teknik direktör önemlidir ama kadronun önüne geçemez.
18. Sözleşme süresi transfer değerinin gerçek girdisidir.
19. Serbest oyuncu ayrı piyasa davranışıdır.
20. Taksit banka borcu değildir; ayrı gelecek transfer yükümlülüğüdür.
21. Kiralıkta kalıcı kontrat parent club'da korunur.
22. Gelişmiş transfer yapıları seçenek olmalı, otomatik varsayılan olmamalıdır.
23. Taraftar güveni alt boyut + neden hafızası taşır.
24. Taraftar geçmişi her sezon nötre sıfırlanmamalıdır.
25. Medya açıklamayı sonraki eylemle birlikte değerlendirmelidir.
26. Vaat verildiği sezon başı bağlamını saklamalıdır.
27. Vaat üretiminde sezon sonu/gelecek bilgisi kullanılamaz.
28. `partial` gerçek ve ölçülebilir ara sonuçtur.
29. Birleşik gözlemsel katmanlar mümkün olduğunda aynı world report'u paylaşmalı; aynı dünya gereksiz yere yeniden simüle edilmemelidir.
30. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 3. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

Katman yönü:

- saf domain/simulation core,
- headless runner + seed replay + balance raporları,
- ileride versiyonlu persistence/save migration,
- application/use-case katmanı,
- en son Flutter presentation.

`WorldCareerEngine` no-op varsayılanlı hook'larla genişletilir:

- `WorldCareerHooks`: sportif/manager lifecycle,
- `WorldRosterHooks`: kontrat/kadro/maaş,
- `WorldFinanceHooks`: sezon içi ek finans akışı,
- `WorldTransferHooks`: transfer penceresi sonrası hareketler.

Deterministik RNG + cihaz saatinden bağımsız `GameDate` + integer minor-unit `Money` temel teknik kurallardır.

M12 ile `FanCareerEngine` ve `PromiseCareerEngine`, mevcut `AdvancedTransferCareerReport` üzerinden çalışabilen ikinci giriş noktasına sahiptir. Böylece M9+M11+M12 aynı world signature'ını paylaşır.

---

# 4. GitHub / CI çalışma kuralı

Repo public tutulur; açık kaynak lisansı yoktur, `LICENSE.md` proprietary notice içerir.

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1–M12 20 sezon headless runner zinciri

APK/AAB, büyük binary veya `actions/upload-artifact` yoktur. Artifact hedefi `0`.

M0–M12 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük refactor/migration/karmaşık hata için kullanılacak.

---

# 5. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS
8 kulüp, 56 maç/sezon. 100 sezon: 5.600 maç; ev `%45,2857`, beraberlik `%24,5893`, deplasman `%30,1250`, gol/maç `2,5864`, invariant `0`.

## M1 — 20 Sezon Yaşam Döngüsü — PASS
20 sezon / 1.120 maç. Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Yaşam Döngüsü — PASS
Başlangıç 144, final 148; 148 emeklilik, 152 youth intake, final yaş ortalaması `25,84`, validation `0`.

## M3 — Temel Ekonomi — PASS
Reddedilen ilk deneme: `1.017,03M` nakit, `0` borç, 8/8 veryStrong. Kabul: cash `124,28M`, debt `104,43M`, emergency `67,44M`, dengeli sağlık dağılımı.

## M4 — Basit Transfer Pazarı — PASS
Seed `20260903`: 32 transfer, `161,68M` hacim, `5,05M` avg fee, cash `96,38M`, debt `58,61M`.

## M5 — 48 Kulüp / 3 Lig — PASS
48 kulüp, 3×16, 14.400 maç/20 sezon, 864 başlangıç oyuncusu, terfi/düşme. Reddedilen önemli denemeler: 2 transfer + `3.966,16M` borç; 7 transfer + `2.268,60M` borç; 158 transfer + `1.909,01M` nakit. Kabul: transfer `71`, hacim `637,91M`, cash `862,25M`, debt `647,04M`, 10 farklı Taç Ligi şampiyonu. Açık not: Ufuk Ligi nakit birikimi yüksek.

## M6 — Teknik Direktör — PASS
96 manager, 5 profil, fit, sınırlı güç etkisi, board relationship, dismissal/retirement. Seed: 82 değişim, 60 farklı manager, avg impact `+0,922`, relationship `72,22`.

## M7 — Sözleşme + Gerçek Maaş — PASS
`PlayerContract`, renewal/release, free-agent, youth/transfer kontratı. Seed: final kontrat `874`, renewal `3.757`, release `1.143`, free signing `776`, wage bill `491,27M`, transfer `103`.

## M8 — Kiralık + Taksit — PASS
Parent kontratını koruyan loan; loan fee + `%45–80` maaş paylaşımı; upfront + iki sezon taksit. Taksit oranı yüksek olduğu için reddedilen denemeler: `146/183`, `145/189`, `108/147`, `86/156`. Kabul: kalıcı `140`, taksitli `68`, kiralık `478`, taksit taahhüdü `234,79M`, loan fee `113,15M`, cash `1.017,61M`, debt `378,97M`.

## M9 — Taraftar Beklentisi + Güven — PASS
Sporting/financial/transfer/identity boyutları. İlk model avg `61,06`, aralık `46–68` olduğu ve geçmişi fazla sildiği için reddedildi. Kabul: 960 snapshot, avg trust `64,88`, aralık `44–75`, reason `2.143`, validation `0`. M9 `identityTrust` bilerek nötr tutuldu.

## M10 — Medya Hafızası — PASS
Statement → sonraki eylem consistency/contradiction. İlk model `847/960` statement ile aşırı sık olduğu için reddedildi. Kabul: statement `556`, contradiction `22`, strong-broken `9`, consistent `385`, avg credibility `75,52`, aralık `49–87`.

## M11 — Başkan Vaatleri — PASS
Sezon başı bilgiden vaat; sezon sonunda fulfilled/partial/broken. Vaat tipleri: borç azaltma, finans istikrarı, üst yarı, kümede kalma, terfi, şampiyonluk yarışı. Kabul: `960` vaat, fulfilled `435`, partial `169`, broken `356`, avg `54,84`, financial `105`, sporting `855`, validation `0`.

## M12 — Vaat Sonucu → Taraftar Güveni — PASS
M9 ve M11 aynı `AdvancedTransferCareerReport` üzerinde birleşir; dünya iki kez simüle edilmez. Her vaat `identityTrust`, finansal vaatler ayrıca `financialTrust` reason üretir.

Kabul seed `20260903`:

- promise `960`
- promise reason `1.065`
- identity reason `960`
- financial reason `105`
- positive `677`
- negative `388`
- baseline overall `64,88`
- final overall `65,31`
- overall delta `+0,44`
- final identity avg `61,83`
- identity range `38–88`
- identity delta `+1,83`
- validation `0`

Kabul gerekçesi: vaat etkisi overall güveni sürüklemiyor fakat identity boyutunda gerçek çok sezonlu ayrışma yaratıyor.

CI guard: positive `600–750`, negative `330–450`, final overall `60–70`, average overall delta `-2..3`, identity avg `55–70`, min `25–50`, max `80–95`, identity delta `-3..6`.

Ayrıntı: `M12_VAAT_TARAFTAR_GUVENI.md`.

---

# 6. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure, fan trust/expectation, media credibility/contradiction, promise type/completion ve promise→reputation etkileri.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 7. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Minimum: autosave + önceki autosave yedeği + manuel save + migration.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState` ve çözülmemiş açıklamalar, aktif vaat + kompakt promise history. Tam sezon snapshot geçmişlerinin save'e gömülmesi zorunlu değildir.

---

# 8. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Resmî kulüp `wageBudget` sistemi yok.
3. Free-agent AI hâlâ basit ihtiyaç/affordability modelidir.
4. Manager maaşı/kontratı, başka kulüp teklifi ve spesifik transfer talebi yok.
5. Satın alma opsiyonu, bonus, sell-on ve takas yok.
6. Taraftar henüz seyirci/bilet/mağaza/sponsor/protestoyu geri beslemez.
7. Medya yalnız managerFuture ve aynı sezon consistency/contradiction çekirdeğine sahiptir.
8. M11/M12 AI kulüp için sezon başına bir resmi vaat kullanır; kullanıcı vaat seçimi, çok sezonlu vaat, tesis/genç dakika vaadi yok.
9. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
10. Flutter UI/APK bilinçli olarak başlamadı.

---

# 9. Sıradaki milestone — M13

## Vaat Sonuçlarının Medya Güvenilirliğine Etkisi

Amaç:

> **Başkanın resmi sözü yalnız taraftarın değil, medyanın da hafızasında kalacak.**

İlk M13 kapsamı:

- M11 promise resolution sonuçlarını M10 media credibility lifecycle'a bağlamak,
- tutulmayan resmi vaat için credibility cezası,
- tutulan zor vaat için sınırlı credibility ödülü,
- partial sonucu gerçek ara etki olarak korumak,
- vaat tipi/zorluğuna göre bağlamsal etki,
- manager statement credibility ile promise credibility'nin aynı başkan state'inde çakışmadan birleşmesi,
- mümkünse aynı alt world report'u paylaşmak,
- deterministic replay + 20 sezon balance guard.

M13 seçim sistemi değildir. Seçim için önce fan trust + media credibility + promise history'nin birlikte güvenli çalışması kanıtlanacaktır.

---

# 10. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş bu dosyaya yazılır.
- Yeni karar eskiyle çelişirse yeni karar geçerlidir; önemli tarihçe korunur.
