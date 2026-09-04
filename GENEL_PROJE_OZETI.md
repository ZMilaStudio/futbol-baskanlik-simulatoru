# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M17 PASS — sıradaki M18 / Başkan Sabri → Teknik Direktör Karar Eşiği I**  
**Proje önceliği:** Yan geliştirme; aktif ana projeleri aksatmayacak.  
**UI/APK:** Bilinçli olarak başlanmadı; önce simülasyon çekirdeği.

---

# 1. Proje kimliği

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu. Oyuncu teknik direktör değil kulüp başkanıdır. Ana satış fikri: **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

Başkanın alanı ekonomi/borç, teknik direktör seçimi, transfer politikası, sözleşme/maaş, taraftar, medya, vaat, seçim; ileride tesis, sponsor ve krizlerdir. Diziliş/antrenman/maç içi taktik teknik direktörün alanıdır. Dünya tamamen özgün/lisanssız olacaktır.

Kalıcı ilkeler:

1. Mobil UI sade, arka plan sistemleri derin olabilir.
2. Başarı yalnız kupa değil, mali sağlık ve sürdürülebilirliktir.
3. Kısa vadeli başarı ile uzun vadeli kulüp sağlığı arasında gerçek gerilim olmalıdır.
4. Taraftar ekonomik/sportif bağlamı anlamalıdır.
5. **Piyasa değeri ≠ satıcı talebi ≠ alıcının maksimum fiyatı.**
6. **Paran yoksa daha akıllı transfer yapmak zorundasın.**
7. Geçmiş açıklama, vaat ve kararlar unutulmamalıdır.
8. Aynı simulation version + seed + veri + karar dizisi aynı sonucu üretmelidir.
9. Ekonomi ne evrensel refah ne evrensel çöküş üretmelidir.
10. Transfer piyasası ne donmuş ne hiperaktif olmalıdır.
11. Başkan teknik direktör değildir.
12. Taraftar güveni neden hafızası taşır ve her sezon nötre dönmez.
13. Medya açıklamayı sonraki eylemle birlikte değerlendirir.
14. Vaat sezon başı bağlamından üretilir; gelecek bilgisi kullanılamaz.
15. Reputasyon katmanları mümkün olduğunca aynı world report'u paylaşır.
16. Seçim tek bir kupaya/metriğe bağlı değildir.
17. Seçim kaybı gerçek başkan devri üretir.
18. Kulüp temelli güven ile başkana özgü reputasyon ayrıdır.
19. Yeni başkan predecessor'ın kişisel reputasyonunu birebir devralmaz.
20. Başkan yönetim profili bağımsız rastgele trait'ler değil tutarlı arketipler üretir.
21. Başkan profil etkileri sisteme tek tek bağlanmalı; bütün AI aynı anda değiştirilmemelidir.
22. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 2. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

Deterministik RNG/stable hash, cihaz saatinden bağımsız `GameDate`, integer minor-unit `Money`, headless runner, seed replay, uzun kariyer validator ve balance guard kullanılır.

M13 manager+advanced transfer+promise+media tek world üretir. M14 seçim, M15 tenure/turnover, M16 incumbent'a bağlı ardışık kişisel reputasyon state ekler. M17 M16 raporundaki gerçek başkan kimliklerini `PresidentManagementProfile` ile gözlemsel olarak profiller; M16 dünyası ve seçim sonucu değişmez.

M17 trait'leri:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

M17 arketipleri: balanced, prudentBuilder, ambitiousSpender, youthArchitect, patientPlanner, interventionist.

---

# 3. GitHub / CI disiplini

Tek hafif workflow: `dart pub get` + `dart analyze` + tüm testler + M0 100 sezon + M1–M17 20 sezon runner zinciri.

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`. M0–M17 boyunca Codex kredisi kullanılmadı; GitHub araçları yeterli oldu.

---

# 4. Milestone geçmişi

## M0–M8 — Temel dünya / ekonomi / oyuncu / transfer / manager / kontrat — PASS

- M0: 8 kulüp, 100 sezon, invariant 0.
- M1: deterministik 20 sezon yaşam döngüsü.
- M2: player ageing/retirement/youth intake.
- M3: ekonomi; evrensel-refah ilk modeli reddedildi.
- M4: temel transfer piyasası.
- M5: 48 kulüp / 3 lig / 14.400 maç / terfi-düşme.
- M6: manager profili ve değişimleri; seed baseline `82` manager change.
- M7: kontrat/maaş/free agent.
- M8: 140 kalıcı, 68 taksitli, 478 kiralık; validation 0.

## M9–M13 — Taraftar / medya / vaat reputasyonu — PASS

- M9: 960 fan snapshot, avg trust `64,88`, range `44–75`.
- M10: 556 statement, 22 contradiction, avg credibility `75,52`.
- M11: 960 vaat; 435 fulfilled / 169 partial / 356 broken, avg `54,84`.
- M12: promise → fan; final overall `65,31`, identity avg `61,83`.
- M13: promise → media; 452 positive / 154 neutral / 354 negative; final credibility `72,38`.

## M14 — Başkanlık Seçimi — PASS

Seed `20260903`: 240 seçim, 158 reelected, 82 lost, rate `%65,8`, avg approval `63,24`, challenger `60,08`, validation 0.

## M15 — Başkanlık Görev Süresi + Devir — PASS

M14 sonucu korunur. `82` kayıp → `82` gerçek turnover; `130` benzersiz başkan; avg outgoing tenure `6,93`, range `4–20`.

Açık denge notu: M15 baseline'da bir kulüp 5/5 seçimde turnover yaşadı; çoklu-seed sıklığı ileride izlenecek.

## M16 — Başkan Devrinde Kişisel İtibar — PASS

Başkan değişiminde sporting/financial/transfer trust korunur; identity ve media `%25 eski + %75 nötr` ile normalleştirilir. Sezon → reputasyon → election → turnover → handover → sonraki sezon sırası gerçek ardışık state olarak çalışır.

Kabul: elections `240`, reelected `161`, lost/turnover `79`, unique `127`, media avg `72,42` range `59–93`, identity avg `65,00` range `56–81`, validation 0.

## M17 — Başkan Profili + Yönetim Felsefesi — PASS

M16'nın `127` benzersiz başkanı deterministic management profile alır. Profil M16 davranışını henüz değiştirmez.

Kabul seed `20260903`:

- profiles `127`
- youthArchitect `23`
- interventionist `25`
- prudentBuilder `24`
- patientPlanner `15`
- balanced `18`
- ambitiousSpender `22`
- financial avg `60,48`, range `28–90`
- risk avg `54,98`, range `20–90`
- transfer avg `56,54`, range `29–90`
- youth avg `59,90`, range `30–90`
- manager patience avg `57,94`, range `20–90`
- avg turnover profile distance `22,47`
- archetype-changing turnovers `67 / 79`
- meaningful management changes `57 / 79`
- M16 election/turnover baseline `161/79` aynen korunur
- validation `0`

İlk model doğrudan kabul edildi. Altı arketipin tamamı dengeli dağılıyor; turnover'ların çoğu gerçek yönetim felsefesi farkı yaratabilecek profil değişimi üretiyor.

Ayrıntı: `M17_BASKAN_PROFILI_YONETIM_FELSEFESI.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure, fan/media/promise, election, president tenure/turnover/reputation ve management profile dağılımı.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, aktif vaat/kompakt history, `PresidentTenureState`, president ID, election/turnover history, kişisel reputasyon state. Management profile deterministik olarak president ID+seed'den yeniden üretilebilir; save'e kopyalanması zorunlu değildir.

---

# 7. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Resmî `wageBudget` yok.
3. Free-agent AI basittir.
4. Manager maaşı/kontratı, başka kulüp teklifi ve spesifik transfer talebi yok.
5. Satın alma opsiyonu, bonus, sell-on ve takas yok.
6. Taraftar henüz seyirci/bilet/mağaza/sponsor/protestoyu geri beslemez.
7. Medya serbest metin/çok yıllı konu ağı değildir.
8. AI kulüp sezon başına bir resmi vaat kullanır.
9. M15'in kişisel reputasyon mirası sorunu M16'da çözüldü.
10. M16 handover V1 `%25 eski + %75 nötr`; çoklu-seed stres testinde izlenecek.
11. **M17 yönetim profili gözlemseldir; henüz ekonomi/transfer/manager kararlarını etkilemez.**
12. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
13. Kullanıcı seçim kaybı sonrası game-over/başka kulüp kariyeri yok.
14. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M18

## Başkan Sabri → Teknik Direktör Karar Eşiği I

Amaç:

> **Aynı kötü sonuçlara sabırlı başkan ile müdahaleci başkan aynı hızda teknik direktör kovmamalı.**

İlk kapsam:

- yalnız `managerPatience` gerçek manager karar sistemine bağlanacak,
- yüksek sabır dismissal/performance pressure eşiğini kontrollü yükseltecek,
- düşük sabır eşiği kontrollü düşürecek,
- manager market ne donacak ne hiperaktif hale gelecek,
- M6 baseline ayrı regresyon olarak korunacak; M18 kendi profil-aware baseline'ına sahip olacak,
- başkan değişiminden sonra yeni incumbent'ın patience değeri sonraki manager kararlarına yansıyacak,
- ekonomi/transfer/youth trait'leri M18'de davranışa bağlanmayacak.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.
