# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M14 PASS — sıradaki M15 / Başkanlık Görev Süresi + Devir Çekirdeği**  
**Proje önceliği:** Yan geliştirme; aktif ana projeleri aksatmayacak.  
**UI/APK:** Bilinçli olarak başlanmadı; önce simülasyon çekirdeği.

---

# 1. Proje kimliği

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri: **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

Başkanın alanı: ekonomi/borç, teknik direktör seçimi, transfer politikası, sözleşme/maaş, taraftar, medya, vaat, seçim, ileride tesis, sponsor ve krizler. Diziliş/antrenman/maç içi taktik teknik direktörün alanıdır. Dünya tamamen özgün/lisanssız olacaktır.

Kalıcı ürün/teknik ilkeler:

1. Mobil UI sade, arka plan sistemleri derin olabilir.
2. Başarı yalnız kupa değil, mali sağlık ve sürdürülebilirliktir.
3. Kısa vadeli sportif başarı ile uzun vadeli kulüp sağlığı arasında gerçek gerilim olmalıdır.
4. Taraftar ekonomik/sportif bağlamı anlamalıdır.
5. **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**
6. **Paran yoksa daha akıllı transfer yapmak zorundasın.**
7. Geçmiş açıklama, vaat ve kararlar unutulmamalıdır.
8. Aynı simulation version + seed + veri + karar dizisi aynı sonucu üretmelidir.
9. Ekonomi ne evrensel refah ne evrensel çöküş üretmelidir.
10. Transfer piyasası ne donmuş ne hiperaktif olmalıdır.
11. Gelişmiş transfer yapıları seçenek olmalı, varsayılan olmamalıdır.
12. Taraftar güveni alt boyut + neden hafızası taşır ve her sezon nötre dönmez.
13. Medya açıklamayı sonraki eylemle birlikte değerlendirir.
14. Vaat sezon başı bağlamından üretilir; gelecek bilgisi kullanılamaz.
15. Reputasyon katmanları mümkün olduğunca aynı world report'u paylaşır.
16. Seçim tek bir kupaya/metriğe bağlı değildir.
17. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 2. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

- deterministik RNG + stable hash,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- headless runner + seed replay + balance guard,
- ileride versiyonlu save/load/migration,
- en son Flutter presentation.

`WorldCareerEngine` no-op varsayılanlı hook'larla genişletilir: `WorldCareerHooks`, `WorldRosterHooks`, `WorldFinanceHooks`, `WorldTransferHooks`.

M12 fan+promise aynı advanced report'u paylaşır. M13 `AdvancedTransferWorldCareerEngine + ManagerCareerController` ile manager+advanced transfer+promise+media tek world üretir. M14 M13 reputation report'unu temel alır ve promise-driven fan state'ini aynı advanced report üzerinden türetir; seçim için yeni dünya simüle edilmez.

---

# 3. GitHub / CI disiplini

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- tüm testler
- M0 100 sezon batch
- M1–M14 20 sezon headless runner zinciri

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M14 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük refactor/migration/karmaşık hata için kullanılacak.

---

# 4. Milestone geçmişi

## M0 — Deterministik Mini Lig — PASS
8 kulüp; 100 sezon = 5.600 maç; invariant `0`.

## M1 — 20 Sezon Yaşam Döngüsü — PASS
Seed `20260903`: Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4 şampiyonluk.

## M2 — Oyuncu Yaşam Döngüsü — PASS
144 başlangıç, 148 final; 148 emeklilik, 152 youth intake; yaş `25,84`.

## M3 — Ekonomi — PASS
İlk evrensel-refah modeli reddedildi. Kabul: cash `124,28M`, debt `104,43M`, emergency `67,44M`.

## M4 — Transfer — PASS
32 transfer, `161,68M` hacim, avg fee `5,05M`.

## M5 — 48 Kulüp / 3 Lig — PASS
14.400 maç/20 sezon. Kabul: 71 transfer, `637,91M` hacim, cash `862,25M`, debt `647,04M`, 10 farklı Taç Ligi şampiyonu. Açık: Ufuk Ligi nakit birikimi yüksek.

## M6 — Teknik Direktör — PASS
96 manager; 82 değişim, 60 farklı manager, avg impact `+0,922`, final relationship `72,22`.

## M7 — Sözleşme + Maaş — PASS
874 final kontrat, 3.757 renewal, 1.143 release, 776 free signing, wage bill `491,27M`.

## M8 — Kiralık + Taksit — PASS
Yüksek taksit oranlı denemeler reddedildi. Kabul: 140 kalıcı, 68 taksitli, 478 kiralık; cash `1.017,61M`, debt `378,97M`.

## M9 — Taraftar — PASS
960 snapshot, avg trust `64,88`, aralık `44–75`, reason `2.143`.

## M10 — Medya Hafızası — PASS
İlk aşırı sık statement modeli reddedildi. Kabul: 556 statement, 22 contradiction, avg credibility `75,52`, aralık `49–87`.

## M11 — Başkan Vaatleri — PASS
960 vaat; 435 fulfilled, 169 partial, 356 broken, avg `54,84`; financial 105 / sporting 855.

## M12 — Vaat → Taraftar — PASS
Aynı advanced world. Baseline overall `64,88` → `65,31`; identity avg `61,83`, aralık `38–88`.

## M13 — Vaat → Medya — PASS
Manager + advanced transfer + promise + media tek shared world. Promise change 960; positive 452 / neutral 154 / negative 354. Baseline credibility `74,88` → `72,38`; aralık `36–93`; validation `0`.

## M14 — Başkanlık Seçimi Çekirdeği I — PASS

Dört sezonluk dönem sonunda seçim yapılır. 20 sezon / 48 kulüp = `240` seçim.

Approval ağırlıkları:

- fan overall `%35`
- fan identity `%15`
- media credibility `%25`
- son dört sezon promise score `%25`

Challenger strength career seed + simulation version + season + term + club ID ile deterministik üretilir. Seçim sonucu ilk sürümde gözlemseldir; dünya/kariyer akışını durdurmaz.

Kabul seed `20260903`:

- elections `240`
- reelected `158`
- lost `82`
- reelection rate `%65,8`
- avg approval `63,24`
- avg challenger `60,08`
- approval range `37–84`
- competitive `72`
- landslide wins `79`
- landslide losses `41`
- boundary `0`
- validation `0`

İlk model doğrudan kabul edildi: seçim yaklaşık üçte bir oranında kaybedilebiliyor, yakın yarış ve net sonuçlar birlikte mevcut; 0/100 yığılması yok.

CI guard: reelected `130–185`, lost `55–110`, rate `0,55–0,78`, avg approval `58–68`, avg challenger `56–64`, min `25–50`, max `75–90`, competitive `45–100`, landslide win `50–115`, landslide loss `20–70`, boundary `<=2`.

Custom initial season index testi: başlangıç `seasonIndex=7`, 5 sezon simülasyonda ilk seçim `seasonIndex=10` sonunda ve yalnız 48 seçim.

Ayrıntı: `M14_BASKANLIK_SECIMI.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure, fan trust, media credibility, promise completion, election approval/challenger/outcome; ileride president tenure/devir.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, çözülmemiş açıklamalar, aktif vaat + kompakt promise history, ileride `PresidentTenureState` ve seçim geçmişi.

---

# 7. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Resmî `wageBudget` yok.
3. Free-agent AI basit ihtiyaç/affordability modelidir.
4. Manager maaşı/kontratı, başka kulüp teklifi ve spesifik transfer talebi yok.
5. Satın alma opsiyonu, bonus, sell-on ve takas yok.
6. Taraftar henüz seyirci/bilet/mağaza/sponsor/protestoyu geri beslemez.
7. Medya managerFuture + promise credibility kapsamındadır; serbest metin/çok yıllı konu ağı yok.
8. AI kulüp sezon başına bir resmi vaat kullanır; kullanıcı vaat seçimi ve çok sezonlu vaat yok.
9. M14 election sonucu gözlemseldir; incumbent profile/devir ve kullanıcı game-over yok.
10. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
11. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M15

## Başkanlık Görev Süresi + Devir Çekirdeği

Amaç:

> **Seçimi kaybetmek yalnız raporda kalan bir etiket değil, kulüpte gerçekten başkan değişimi yaratacak.**

İlk kapsam:

- deterministik `PresidentProfile` / `PresidentTenureState`,
- 48 kulübe başlangıç incumbent başkan,
- görev başlangıç sezonu ve term numarası,
- M14 `reelected` ile tenure devamı,
- M14 `lost` ile yeni incumbent/devir,
- başkan değişim geçmişi,
- aynı seed ile aynı başkanlık zinciri,
- ilk aşamada yeni başkanın transfer/ekonomi AI davranışını değiştirmemesi,
- kullanıcı game-over/başka kulübe geçiş/UI kapsam dışı.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.
