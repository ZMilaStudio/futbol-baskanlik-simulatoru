# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M16 PASS — sıradaki M17 / Başkan Profili + Yönetim Felsefesi Çekirdeği**  
**Proje önceliği:** Yan geliştirme; aktif ana projeleri aksatmayacak.  
**UI/APK:** Bilinçli olarak başlanmadı; önce simülasyon çekirdeği.

---

# 1. Proje kimliği

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri: **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

Başkanın alanı ekonomi/borç, teknik direktör seçimi, transfer politikası, sözleşme/maaş, taraftar, medya, vaat, seçim; ileride tesis, sponsor ve krizlerdir. Diziliş/antrenman/maç içi taktik teknik direktörün alanıdır. Dünya tamamen özgün/lisanssız olacaktır.

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
17. Seçim kaybı gerçek başkan devri üretir; yeniden seçim aynı incumbent tenure'ını sürdürür.
18. Kulüp temelli güven ile başkana özgü kişisel reputasyon ayrıdır.
19. Yeni başkan predecessor'ın kişisel reputasyonunu birebir devralmaz; kontrollü handover uygulanır.
20. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 2. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

- deterministik RNG + stable hash,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- headless runner + seed replay + balance guard,
- ileride versiyonlu save/load/migration,
- en son Flutter presentation.

`WorldCareerEngine` no-op varsayılanlı hook'larla genişletilir. M12 fan+promise aynı advanced report'u paylaşır. M13 manager+advanced transfer+promise+media tek world üretir. M14 aynı world üzerinde seçim üretir. M15 gerçek president tenure/turnover state ekler. M16 dünyayı yeniden simüle etmeden sezon olaylarını incumbent'a göre ardışık reputasyon state üzerinde replay eder.

M16 sırası:

`season events → fan/media/promise reputation → election → turnover → reputation handover → next season`

Handover V1:

- sporting trust korunur,
- financial trust korunur,
- transfer trust korunur,
- fan identity = `%25 eski + %75 nötr(60)`,
- media credibility = `%25 eski + %75 nötr(65)`.

---

# 3. GitHub / CI disiplini

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- tüm testler
- M0 100 sezon batch
- M1–M16 20 sezon headless runner zinciri

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M16 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu. Codex yalnız büyük refactor/migration/karmaşık hata için kullanılacak.

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

## M14 — Başkanlık Seçimi — PASS
240 seçim; 158 reelected, 82 lost, rate `%65,8`, avg approval `63,24`, avg challenger `60,08`, approval `37–84`, validation `0`.

## M15 — Başkanlık Görev Süresi + Devir — PASS
M14 sonucu korunur. `82` kayıp → `82` gerçek devir; `130` benzersiz başkan; 35 kulüpte devir; 24 kulüpte tekrar devir; avg outgoing tenure `6,93`; range `4–20`; validation `0`.

Denge notu: bir kulüp 5/5 seçimde turnover yaşadı. M15 bunu bastırmıyor; çoklu-seed testlerde sıklık izlenecek.

## M16 — Başkan Devrinde Kişisel İtibar — PASS

M15'teki kritik semantik sorun düzeltildi: yeni incumbent artık predecessor'ın kişisel media credibility / fan identity geçmişini birebir miras almıyor.

M16 dünyayı yeniden simüle etmez. M13 kaynak olayları ile M12/M14 fan nedenlerini sezon sezon yeni incumbent state üzerinde replay eder. Seçim sonuçları bu nedenle M14'ten küçük ölçüde ayrışabilir ve M16 kendi canonical election baseline'ına sahiptir.

Kabul seed `20260903`:

- elections `240`
- reelected `161`
- lost / turnover `79 / 79`
- reelection rate `%67,1`
- unique presidents `127`
- final media avg `72,42`
- media range `59–93`
- final identity avg `65,00`
- identity range `56–81`
- avg handover media delta `+0,13`
- avg handover identity delta `+2,18`
- validation `0`

M14–M15 regresyon baseline'ları aynı CI içinde değişmeden PASS olmaya devam eder.

Kabul guard'ları: reelected `145–175`, lost `65–95`, rate `0,60–0,75`, media avg `65–80`, media min `45–65`, media max `85–95`, identity avg `58–72`, identity min `48–62`, identity max `75–90`, avg handover media delta `-3..3`, avg identity delta `0,5..5`.

Custom başlangıç `seasonIndex=7`, 5 sezon testinde ilk seçim `10`, handover efektif sezonu `11` olarak doğrulanır.

Ayrıntı: `M16_BASKAN_DEVRI_KISISEL_ITIBAR.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure, fan trust, media credibility, promise completion, election approval/outcome, president tenure/turnover/reputation handover.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, çözülmemiş açıklamalar, aktif vaat + kompakt promise history, `PresidentTenureState`, president profile/id, election/turnover history ve kişisel reputasyon state.

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
9. M15'in kişisel reputasyon mirası sorunu M16'da çözüldü.
10. M15 baseline'da bir kulüp 5/5 seçimde turnover yaşadı; çoklu-seed sıklığı izlenmeli.
11. Başkan profili henüz ekonomi/transfer/manager kararlarını etkilemez.
12. M16 handover oranı V1 `%25 eski + %75 nötr`; çoklu-seed stres testinde gerekirse yeniden kalibre edilir.
13. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
14. Kullanıcı seçim kaybı → game-over/başka kulüp kariyeri henüz yok.
15. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M17

## Başkan Profili + Yönetim Felsefesi Çekirdeği

Amaç:

> **Başkan değişince yalnız isim ve itibar değil, kulübün yönetim yaklaşımı da değişebilsin.**

İlk kapsam:

- deterministik president management profile,
- mali disiplin / risk iştahı,
- transfer harcama iştahı,
- genç/altyapı yönelimi,
- teknik direktöre sabır gibi sınırlı yönetim eğilimleri,
- profil çeşitliliği ve seed determinism testi,
- ilk aşamada etkileri gözlemsel/karar ağırlığı olarak raporlamak,
- ekonomi/transfer/manager AI'a geri beslemeyi tek seferde kontrolsüz bağlamamak.

M17'nin amacı “her başkan farklı sayı” üretmek değil; ileride AI kararlarına bağlanabilecek tutarlı ve test edilebilir yönetim karakteri oluşturmaktır.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.
