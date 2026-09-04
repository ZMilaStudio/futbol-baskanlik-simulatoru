# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M13 PASS — sıradaki M14 / Başkanlık Seçimi Çekirdeği I**  
**Proje önceliği:** Yan geliştirme; Kelime Avı ve Minik Dedektif gibi aktif projeleri aksatmayacak.  
**UI/APK:** Bilinçli olarak başlanmadı; simülasyon çekirdeği öncelikli.

---

# 1. Proje kimliği ve değişmez ilkeler

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri: **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**  
Alternatif: **“Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.”**

Başkan ekonomi, teknik direktör, transfer stratejisi, borç, altyapı/tesis, sponsor, taraftar, medya, vaat, kriz ve uzun vadeli kulüp sağlığını yönetir. Diziliş/antrenman/maç içi mikro taktik teknik direktörün işidir. Dünya tamamen özgün/lisanssız olacaktır.

Kalıcı teknik/ürün kuralları:

1. Mobil UI sade, arka plan sistemleri derin olabilir.
2. Başarı yalnız kupa değildir; mali sağlık ve sürdürülebilirliktir.
3. Kısa vadeli başarı ile uzun vadeli sağlık arasında gerçek gerilim olmalıdır.
4. Taraftar ekonomik/sportif bağlamı anlamalıdır.
5. **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**
6. **Paran yoksa daha akıllı transfer yapmak zorundasın.**
7. Geçmiş açıklama, vaat ve önemli kararlar unutulmamalıdır.
8. Doğru karar her zaman açık olmamalıdır.
9. Aynı simulation version + seed + veri + karar dizisi aynı sonucu üretmelidir.
10. Ekonomi ne evrensel refah ne evrensel çöküş üretmelidir.
11. Transfer piyasası ne donmuş ne hiperaktif olmalıdır.
12. Sözleşme süresi transfer değerinin gerçek girdisidir.
13. Taksit banka borcu değildir; ayrı gelecek transfer yükümlülüğüdür.
14. Kiralıkta kalıcı kontrat parent club'da korunur.
15. Gelişmiş transfer yapıları seçenek olmalı, varsayılan olmamalıdır.
16. Taraftar güveni alt boyut + neden hafızası taşır ve her sezon nötre sıfırlanmaz.
17. Medya açıklamayı sonraki eylemle birlikte değerlendirir.
18. Vaat verildiği sezon başı bağlamını saklar; gelecek bilgisiyle üretilemez.
19. `partial` gerçek ara sonuçtur.
20. Reputasyon katmanları mümkün olduğunda aynı world report'u paylaşır; dünya gereksiz yere tekrar simüle edilmez.
21. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 2. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

- saf domain/simulation core
- headless runner + seed replay + denge raporları
- ileride versiyonlu persistence/save migration
- application/use-case
- en son Flutter presentation

`WorldCareerEngine` no-op varsayılanlı hook'larla genişletilir: `WorldCareerHooks`, `WorldRosterHooks`, `WorldFinanceHooks`, `WorldTransferHooks`.

Deterministik RNG + cihaz saatinden bağımsız `GameDate` + integer minor-unit `Money` temel teknik kurallardır.

M12'de fan ve promise aynı `AdvancedTransferCareerReport`u paylaşmaya başladı. M13'te `AdvancedTransferWorldCareerEngine + ManagerCareerController` tek world üretir; manager, advanced transfer, promise ve media bu ortak dünya üzerinde birleştirilir.

---

# 3. GitHub / CI disiplini

Repo public; açık kaynak lisansı yok, `LICENSE.md` proprietary notice içerir.

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- `dart test`
- M0 100 sezon batch
- M1–M13 20 sezon headless runner zinciri

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M13 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük refactor/migration/karmaşık hata için kullanılacak.

---

# 4. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS
8 kulüp, 56 maç/sezon; 100 sezon = 5.600 maç; invariant `0`.

## M1 — 20 Sezon Yaşam Döngüsü — PASS
Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Yaşam Döngüsü — PASS
144 başlangıç, 148 final; 148 emeklilik, 152 youth intake; yaş `25,84`.

## M3 — Ekonomi — PASS
İlk model evrensel refah ürettiği için reddedildi. Kabul: cash `124,28M`, debt `104,43M`, emergency `67,44M`.

## M4 — Transfer — PASS
32 transfer, `161,68M` hacim, avg fee `5,05M`.

## M5 — 48 Kulüp / 3 Lig — PASS
14.400 maç/20 sezon. Reddedilen ekonomi/transfer uçları sonrası kabul: 71 transfer, `637,91M` hacim, cash `862,25M`, debt `647,04M`, 10 farklı Taç Ligi şampiyonu. Açık: Ufuk Ligi nakit birikimi yüksek.

## M6 — Teknik Direktör — PASS
96 manager; 82 değişim, 60 farklı manager, avg impact `+0,922`, final relationship `72,22`.

## M7 — Sözleşme + Maaş — PASS
874 final kontrat, 3.757 renewal, 1.143 release, 776 free signing, wage bill `491,27M`.

## M8 — Kiralık + Taksit — PASS
Yüksek taksit oranlı dört deneme reddedildi. Kabul: 140 kalıcı, 68 taksitli, 478 kiralık; cash `1.017,61M`, debt `378,97M`.

## M9 — Taraftar — PASS
İlk model geçmişi fazla nötrlüyordu. Kabul: 960 snapshot, avg trust `64,88`, aralık `44–75`, reason `2.143`. `identityTrust` M9'da nötr bırakıldı.

## M10 — Medya Hafızası — PASS
İlk model `847/960` statement ile fazla sıktı. Kabul: 556 statement, 22 contradiction, avg credibility `75,52`, aralık `49–87`.

## M11 — Başkan Vaatleri — PASS
960 vaat; 435 fulfilled, 169 partial, 356 broken, avg `54,84`; financial 105 / sporting 855. Altı vaat tipi aktif.

## M12 — Vaat → Taraftar — PASS
Aynı advanced world üzerinde promise + fan. 1.065 promise reason; baseline overall `64,88` → `65,31`; identity avg `61,83`, aralık `38–88`, validation `0`.

## M13 — Vaat → Medya — PASS
Manager + advanced transfer + promise + media tek shared world üzerinde.

İlk PR CI test fixture'ında olmayan generic reason enum adları nedeniyle analyzer fail verdi; yalnız test fixture düzeltildi, domain davranışı değişmedi.

Kabul seed `20260903`:

- promise change `960`
- positive `452`
- neutral `154`
- negative `354`
- statement `560`
- contradiction `28`
- manager change `81`
- baseline credibility `74,88`
- final credibility `72,38`
- delta `-2,50`
- aralık `36–93`
- boundary `0`
- validation `0`

Kabul gerekçesi: vaat geçmişi medyada gerçek sinyal üretiyor ama manager statement hafızasını ezmiyor ve 0/100 yığılması oluşturmuyor.

CI guard: positive `350–550`, neutral `100–250`, negative `280–450`, statement `400–700`, contradiction `10–80`, manager changes `50–120`, baseline credibility `65–82`, final `62–80`, delta `-8..3`, min `20–55`, max `82–96`, boundary `<=2`.

Ayrıntı: `M13_VAAT_MEDYA_GUVENILIRLIGI.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure, fan trust, media credibility, promise completion ve birleşik reputasyon etkileri.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, çözülmemiş önemli açıklamalar, aktif vaat + kompakt promise history. Tam sezon snapshot geçmişi save'e gömülmek zorunda değildir.

---

# 7. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Resmî `wageBudget` yok.
3. Free-agent AI basit ihtiyaç/affordability modelidir.
4. Manager maaşı/kontratı, başka kulüp teklifi ve spesifik transfer talebi yok.
5. Satın alma opsiyonu, bonus, sell-on ve takas yok.
6. Taraftar henüz seyirci/bilet/mağaza/sponsor/protestoyu geri beslemez.
7. Medya managerFuture + promise credibility kapsamındadır; serbest metin/çok yıllı konu ağı yok.
8. AI kulüp sezon başına bir resmi vaat kullanır; kullanıcı vaat seçimi, çok sezonlu vaat, tesis/genç dakika vaadi yok.
9. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
10. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M14

## Başkanlık Seçimi Çekirdeği I

Amaç:

> **Başkanın yıllarca biriktirdiği güven, medya itibarı ve verdiği sözler sonunda görevde kalıp kalmamasına etki edecek.**

İlk kapsam:

- deterministik `PresidentApprovalState`,
- fan overall/identity trust + media credibility + promise history girdileri,
- seçim dönemini örneğin dört sezonda bir değerlendirme,
- incumbent approval ve challenger strength,
- `reelected / lost` sonucu,
- ölçülebilir neden katkıları,
- aşırı tek metriğe bağımlı olmayan ağırlıklandırma,
- ilk aşamada gözlemsel; seçim kaybı dünya simülasyonunu durdurmaz,
- 20 sezon / 48 kulüp election distribution + deterministic replay + validator.

M14'te başka kulübe geçiş veya kullanıcı UI gerekmez. Önce seçim mekanizmasının adil/bağlamsal dağılımı kanıtlanır.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş bu dosyaya yazılır.
- Yeni karar eskiyle çelişirse yeni karar geçerlidir; önemli tarihçe korunur.
