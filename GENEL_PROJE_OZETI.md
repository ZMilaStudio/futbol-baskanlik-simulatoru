# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M15 PASS — sıradaki M16 / Başkan Devrinde Kişisel İtibar Devri**  
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
17. Seçim kaybı başkan kimliğinde gerçek devir üretir; yeniden seçim aynı incumbent tenure'ını sürdürür.
18. Kulüp temelli reputasyon ile başkana özgü reputasyon uzun vadede ayrıştırılmalıdır.
19. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

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

M12 fan+promise aynı advanced report'u paylaşır. M13 manager+advanced transfer+promise+media tek world üretir. M14 M13 reputation report'u ve aynı advanced world'den promise-driven fan state'ini kullanarak seçim üretir. M15 M14 election report'unu değiştirmeden deterministik başkan kimliği, tenure state ve seçim kaybı kaynaklı turnover history ekler.

---

# 3. GitHub / CI disiplini

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- tüm testler
- M0 100 sezon batch
- M1–M15 20 sezon headless runner zinciri

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M15 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük refactor/migration/karmaşık hata için kullanılacak.

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
140 kalıcı, 68 taksitli, 478 kiralık; cash `1.017,61M`, debt `378,97M`.

## M9 — Taraftar — PASS
960 snapshot, avg trust `64,88`, aralık `44–75`, reason `2.143`.

## M10 — Medya Hafızası — PASS
556 statement, 22 contradiction, avg credibility `75,52`, aralık `49–87`.

## M11 — Başkan Vaatleri — PASS
960 vaat; 435 fulfilled, 169 partial, 356 broken, avg `54,84`; financial 105 / sporting 855.

## M12 — Vaat → Taraftar — PASS
Baseline overall `64,88` → `65,31`; identity avg `61,83`, aralık `38–88`.

## M13 — Vaat → Medya — PASS
Promise change 960; positive 452 / neutral 154 / negative 354. Baseline credibility `74,88` → `72,38`; aralık `36–93`; validation `0`.

## M14 — Başkanlık Seçimi Çekirdeği I — PASS
Dört sezonluk dönem sonunda seçim. Approval: fan overall `%35`, fan identity `%15`, media `%25`, term promise score `%25`.

Seed `20260903`: elections `240`, reelected `158`, lost `82`, rate `%65,8`, avg approval `63,24`, avg challenger `60,08`, range `37–84`, competitive `72`, landslide wins `79`, landslide losses `41`, boundary `0`, validation `0`.

Custom initial `seasonIndex=7` testinde ilk seçim `10` sonunda doğru üretildi.

Ayrıntı: `M14_BASKANLIK_SECIMI.md`.

## M15 — Başkanlık Görev Süresi + Devir — PASS

M14 seçim sonucu aynen korunur; yeni state katmanı seçim sonuçlarını başkan kimliği ve tenure history'ye çevirir.

- deterministik başlangıç incumbent profili,
- deterministik challenger profili,
- `reelected` → aynı başkan / aynı tenure,
- `lost` → challenger yeni incumbent,
- outgoing tenure süresi ve yeniden seçim geçmişi,
- final incumbent state,
- tüm devir zincirini replay eden validator.

Kabul seed `20260903`:

- elections `240`
- reelected `158`
- lost `82`
- turnovers `82`
- unique presidents `130`
- turnover yaşayan kulüp `35`
- birden fazla turnover yaşayan kulüp `24`
- max turnover/club `5`
- avg outgoing tenure `6,93 sezon`
- tenure range `4–20`
- validation `0`

İlk model doğrudan kabul edildi. M14 sonucu değişmedi ve her kayıp seçim birebir başkan devri üretti.

Denge notu: bir kulüp beş seçimin beşinde de başkan değiştirdi. M15 bunu bastırmıyor; kök dağılım M14'e ait. Çoklu-seed testlerde tekrar sıklığı izlenecek.

CI kabul guard'ları: elections `240`, reelected `158`, lost/turnover `82`, unique presidents `130`, clubs changed `32–39`, repeat clubs `20–29`, max turnover `4–5`, avg outgoing tenure `6–8`, min tenure `4`, max tenure `16–20`.

Ayrıntı: `M15_BASKANLIK_GOREV_SURESI_DEVIR.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure, fan trust, media credibility, promise completion, election approval/outcome, president tenure/turnover.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, çözülmemiş açıklamalar, aktif vaat + kompakt promise history, `PresidentTenureState`, başkan kimliği ve kompakt election/turnover history.

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
9. **M15'te yeni incumbent predecessor'ın media credibility ve fan identity geçmişini fiilen miras alır; kişisel reputasyon devri M16'da düzeltilmeli.**
10. M15 baseline'da bir kulüp 5/5 seçimde turnover yaşadı; çoklu-seed sıklığı izlenmeli.
11. Başkan profili henüz ekonomi/transfer/manager kararlarını etkilemez.
12. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
13. Kullanıcı seçim kaybı → game-over/başka kulüp kariyeri henüz yok.
14. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M16

## Başkan Devrinde Kişisel İtibar Devri

Amaç:

> **Yeni başkan kulübün borcunu ve kadrosunu devralır; predecessor'ın kişisel söz ve medya güvenilirliğini ise birebir devralmamalıdır.**

İlk kapsam:

- başkan değişiminde media credibility için kontrollü başlangıç/normalizasyon,
- fan `identityTrust` için kontrollü reset/devir,
- sporting/financial/transfer gibi kulüp temelli fan boyutlarının korunması,
- yeni incumbent'ın sonraki dört sezonunun kendi reputasyon geçmişini oluşturması,
- term promise score'un mevcut dönem başkanına doğru bağlanması,
- sonraki seçimlerin gerçek incumbent state'iyle ardışık simülasyonu,
- deterministic replay + 20 sezon denge/turnover raporu.

Başkan karakter profillerinin ekonomi/transfer AI'a etkisi M16'ya zorla eklenmeyecek; önce kişisel reputasyon semantiği doğru kurulacak.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.
