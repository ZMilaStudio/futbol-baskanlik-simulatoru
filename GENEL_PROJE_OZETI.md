# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M18 PASS adayı — PR #19 final kalite kapısında; sıradaki M19 / Başkan Sabrı + Seçim Geri Besleme Döngüsü**  
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
11. Başkan teknik direktör değildir; ancak teknik direktörün görev güvencesi başkan karakterinden etkilenebilir.
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
22. Her yeni davranış etkisi eski canonical milestone'ları neutral/regresyon modunda bozmamalıdır.
23. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 2. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

Deterministik RNG/stable hash, cihaz saatinden bağımsız `GameDate`, integer minor-unit `Money`, headless runner, seed replay, uzun kariyer validator ve balance guard kullanılır.

M13 manager+advanced transfer+promise+media tek world üretir. M14 seçim, M15 tenure/turnover, M16 incumbent'a bağlı ardışık kişisel reputasyon state ekler. M17 gerçek president zincirini management profile ile etiketler.

M17 trait'leri:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

M17 arketipleri: balanced, prudentBuilder, ambitiousSpender, youthArchitect, patientPlanner, interventionist.

M18 ilk gerçek profile-feedback katmanıdır. Döngüsel bağımlılık nedeniyle iki geçişlidir:

1. canonical M17 → president / turnover / management-profile timeline,
2. aynı seed advanced-world replay → incumbent `managerPatience` ile gerçek manager dismissal kararları.

`managerPatience=60` neutral referanstır ve eski M6/M13 dismissal eşiklerini birebir korur. M18'in değişen dünyasından seçimler henüz yeniden hesaplanmaz; bu sınır M19'da kaldırılacak.

---

# 3. GitHub / CI disiplini

Tek hafif workflow: `dart pub get` + `dart analyze` + tüm testler + M0 100 sezon + M1–M18 20 sezon runner zinciri.

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`. M0–M18 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu.

M17 PR #18 squash merge: `0003e6463e3cbc7052d407cc45c2594be8d861db`.

M18 branch: `m18-president-manager-patience`. PR: **#19**.

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
- M13: promise → media; 452 positive / 154 neutral / 354 negative; final credibility `72,38`; canonical advanced-world manager changes `81`, transfers `173`.

## M14 — Başkanlık Seçimi — PASS

Seed `20260903`: 240 seçim, 158 reelected, 82 lost, rate `%65,8`, avg approval `63,24`, challenger `60,08`, validation 0.

## M15 — Başkanlık Görev Süresi + Devir — PASS

M14 sonucu korunur. `82` kayıp → `82` gerçek turnover; `130` benzersiz başkan; avg outgoing tenure `6,93`, range `4–20`.

Açık denge notu: M15 baseline'da bir kulüp 5/5 seçimde turnover yaşadı; çoklu-seed sıklığı ileride izlenecek.

## M16 — Başkan Devrinde Kişisel İtibar — PASS

Başkan değişiminde sporting/financial/transfer trust korunur; identity ve media `%25 eski + %75 nötr` ile normalleştirilir. Sezon → reputasyon → election → turnover → handover → sonraki sezon sırası ardışık state olarak çalışır.

Kabul: elections `240`, reelected `161`, lost/turnover `79`, unique `127`, media avg `72,42` range `59–93`, identity avg `65,00` range `56–81`, validation 0.

## M17 — Başkan Profili + Yönetim Felsefesi — PASS

M16'nın `127` benzersiz başkanı deterministic management profile alır. Profil M16 davranışını değiştirmez.

Kabul seed `20260903`:

- profiles `127`
- 6/6 arketip aktif: `23 / 25 / 24 / 15 / 18 / 22`
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

Ayrıntı: `M17_BASKAN_PROFILI_YONETIM_FELSEFESI.md`.

## M18 — Başkan Sabrı → Teknik Direktör Karar Eşiği I — PASS ADAYI

M17'nin `managerPatience` trait'i gerçek `ManagerCareerController` dismissal kararlarına bağlandı. Neutral `60`, eski dismissal mantığını birebir korur; düşük sabır daha erken, yüksek sabır daha geç değişime gider. Retirement etkilenmez.

İlk seed `20260903` kabul baseline'ı:

- manager decision snapshot `960`
- baseline manager changes `81`
- patience-aware manager changes `88`
- change delta `+7`
- dismissal decision differences `93`
- downstream manager identity differences `446 / 960`
- final assignment differences `37 / 48`
- low-patience club-seasons `232`
- high-patience club-seasons `308`
- low-patience dismissal rate `%16,4`
- high-patience dismissal rate `%6,2`
- avg patience on dismissals `50,52`
- avg patience on retained seasons `61,52`
- reasons: performance `60`, board breakdown `25`, retirement `3`
- transfers `173 → 153`
- world changed `true`
- validation `0`
- analyzer PASS
- `70` test PASS
- M0–M18 runner zinciri PASS
- ilk CI artifact `0`

İlk model kabul edildi. Toplam manager change yalnız `%8,6` artarken düşük/yüksek sabır dismissal kültürü güçlü biçimde ayrıştı. `446` identity farkı 446 kovma değildir; `93` farklı kararın downstream manager zincirine yayılmasıdır. Transfer sayısındaki yaklaşık `%11,6` düşüş ikincil world-path etkisi olarak kabul edildi ve guard'a alındı.

Kabul guard'ları: influenced manager changes `80–100`, decision differences `60–130`, manager identity differences `300–600`, final assignments `25–45`, low dismissal rate `0,10–0,22`, high `0,03–0,10`, rate farkı en az `0,05`, influenced transfer `120–200`, baseline transfer sapması en fazla `50`.

Ayrıntı: `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure/change, fan/media/promise, election, president tenure/turnover/reputation, management profile ve profile-driven karar dağılımları.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, aktif vaat/kompakt history, `PresidentTenureState`, president ID, election/turnover history, kişisel reputasyon state. Management profile president ID+seed'den deterministik yeniden üretilebilir. M19 sonrası birleşik kariyerde current president + manager assignment + reputasyon state birlikte persist edilmelidir.

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
9. M16 handover V1 `%25 eski + %75 nötr`; çoklu-seed stres testinde izlenecek.
10. M17'nin diğer dört trait'i henüz gerçek AI davranışına bağlı değildir.
11. **M18 iki geçişlidir; patience-aware değişen world henüz seçim/reputation zincirine geri beslenmez.**
12. M18'de transfer `173→153`; manager-path kaynaklı ikincil etki guard altında izlenecek.
13. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
14. Kullanıcı seçim kaybı sonrası game-over/başka kulüp kariyeri yok.
15. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M19

## Başkan Sabrı + Seçim Geri Besleme Döngüsü

Amaç:

> **Başkanın hocaya sabrı dünyayı değiştiriyorsa, o değişen dünya aynı başkanın reputasyonunu ve sonraki seçimini de değiştirmelidir.**

İlk kapsam:

- M18 patience-aware manager/world patikasını canonical kariyer akışına bağlamak,
- fan/media/promise state'i değişen world üzerinden üretmek,
- election ve turnover'ı aynı değişen world üzerinden ardışık hesaplamak,
- yeni president'ın patience değerinin sonraki sezon manager kararlarına geçmesini sağlamak,
- `president → manager → world → reputasyon → election → president` geri besleme döngüsünü tek deterministic kariyer engine'inde kapatmak,
- iki geçişli M18 yaklaşımını birleşik state'e geçirmek,
- eski M6–M18 baseline'larını regresyon olarak korumak,
- yeni M19 için ayrı denge/election/manager baseline'ı üretmek.

M19 tamamlanmadan `financialDiscipline`, `transferAmbition`, `riskAppetite` veya `youthOrientation` trait'leri gerçek AI'a bağlanmayacak; önce manager feedback döngüsü mimari olarak doğru kapatılacak.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.
