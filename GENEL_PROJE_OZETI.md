# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M19 PASS ve main'e merge — sıradaki M20 / Başkan Mali Disiplini → Transfer Bütçe Davranışı I**  
**Proje önceliği:** Yan geliştirme; aktif ana projeleri aksatmayacak.  
**UI/APK:** Bilinçli olarak başlanmadı; önce simülasyon çekirdeği.

---

# 1. Proje kimliği

Tam kapsamlı Android futbol kulübü **başkanlığı** simülasyonu. Oyuncu teknik direktör değil kulüp başkanıdır.

> **“Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.”**

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
15. Seçim tek bir kupaya/metriğe bağlı değildir.
16. Seçim kaybı gerçek başkan devri üretir.
17. Kulüp temelli güven ile başkana özgü reputasyon ayrıdır.
18. Yeni başkan predecessor'ın kişisel reputasyonunu birebir devralmaz.
19. Başkan yönetim profili bağımsız rastgele trait'ler değil tutarlı arketipler üretir.
20. Başkan profil etkileri sisteme tek tek bağlanmalı; bütün AI aynı anda değiştirilmemelidir.
21. Her yeni davranış etkisi eski canonical milestone'ları neutral/regresyon modunda bozmamalıdır.
22. Geri besleme döngüsü varsa convergence/cycle açıkça test edilmelidir.
23. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

---

# 2. Teknik mimari

**Flutter mobil kabuk + Flutter'dan bağımsız saf Dart simülasyon çekirdeği.**

Temel yapı:

- deterministik RNG + stable hash,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- headless runner + seed replay,
- uzun kariyer validator + balance guard,
- ileri aşamada versiyonlu save/load/migration,
- en son Flutter presentation.

Başkanlık zinciri:

- M13: manager + advanced transfer + promise + media world,
- M14: seçim,
- M15: president tenure/turnover,
- M16: incumbent'a bağlı kişisel reputasyon + handover,
- M17: management profile,
- M18: `managerPatience` gerçek manager dismissal kararlarına bağlanır,
- M19: patience-aware world reputasyon ve seçimlere geri beslenir.

M17 trait'leri:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Arketipler: `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist`.

## M18 ara mimarisi

M18 iki geçişliydi:

1. canonical president/profile timeline,
2. aynı seed advanced-world replay + president `managerPatience`.

`managerPatience=60` eski manager dismissal eşiklerini birebir korur. M18'de değişen world seçimlere geri dönmüyordu.

## M19 feedback mimarisi

M19 bu borcu deterministik **fixed-point replay** ile kapatır:

`president timeline → managerPatience → manager/world → promise/fan/media/reputasyon → election/turnover → president timeline`

Timeline değişirse aynı seed ile yeniden replay edilir. Timeline sabitlenirse convergence; daha önce görülen timeline tekrar oluşursa cycle kabul edilir. Varsayılan maksimum iterasyon `8`.

Fixed-point hesaplama bütün timeline'ı iteratif çözer ama `patienceProvider(clubId, seasonIndex)` yalnız o sezonda yürürlükteki başkanı uygular; gelecekteki başkanın trait'i geçmişe sızmaz. Bu bir literal tek-geçişli sezon orkestratörü değil, tarihsel olarak self-consistent equilibrium/replay çözümüdür.

M19 için mevcut motorlar yeniden kullanılabilir hale getirildi:

- `PromiseMediaCareerEngine.simulateFromAdvancedReport(...)`
- `PresidentReputationCareerEngine.simulateFromSourceReport(...)`
- `PresidentManagerPatienceTimeline.fromReputationReport(...)`

Eski `simulate()` yolları korunur ve bu replay fonksiyonlarına delege eder; M13–M18 canonical baseline'ları değişmedi.

---

# 3. GitHub / CI disiplini

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- tüm testler
- M0 100 sezon batch
- M1–M19 20 sezon headless runner zinciri

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`.

M0–M19 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu.

Son merge'ler:

- M17 PR #18 → `0003e6463e3cbc7052d407cc45c2594be8d861db`
- M18 PR #19 → `d1ca4de859c528470785f98a10baa4db8259d4ce`
- M18 sonrası canonical docs/main → `1cbd3da04816e4f6d29b2db367e7992451832367`
- M19 PR #20 → `183749baab40403b381003c527ce62fad946a9a6`

M18 merge-sonrası main güvenlik CI `33894772996`: PASS, artifact `0`.
M19 final PR CI `33911708201`: analyzer PASS, `73` test PASS, M0–M19 runner PASS, artifact `0`.

---

# 4. Milestone geçmişi

## M0–M8 — Temel dünya / ekonomi / oyuncu / transfer / manager / kontrat — PASS

- M0: 8 kulüp, 100 sezon, 5.600 maç, invariant `0`.
- M1: deterministik 20 sezon yaşam döngüsü.
- M2: player ageing/retirement/youth intake.
- M3: ilk evrensel-refah modeli reddedildi; kabul cash `124,28M`, debt `104,43M`, emergency `67,44M`.
- M4: 32 transfer, `161,68M` hacim.
- M5: 48 kulüp / 3 lig / 14.400 maç; 71 transfer, cash `862,25M`, debt `647,04M`. Ufuk Ligi yüksek nakit birikimi açık denge notudur.
- M6: 82 manager değişimi, 80 dismissal, 2 retirement, avg impact `+0,922`.
- M7: 874 final kontrat, 3.757 renewal, 1.143 release, 776 free signing.
- M8: 140 kalıcı, 68 taksitli, 478 kiralık; validation `0`.

## M9–M13 — Taraftar / medya / vaat — PASS

- M9: 960 fan snapshot, avg trust `64,88`, range `44–75`.
- M10: 556 statement, 22 contradiction, avg credibility `75,52`.
- M11: 960 vaat; 435 fulfilled / 169 partial / 356 broken, avg `54,84`.
- M12: promise → fan; final overall `65,31`, identity avg `61,83`.
- M13: promise → media; 452 positive / 154 neutral / 354 negative, final credibility `72,38`. Canonical advanced-world manager changes `81`, transfers `173`.

## M14 — Başkanlık Seçimi — PASS

Seed `20260903`: 240 seçim, 158 reelected, 82 lost, rate `%65,8`, avg approval `63,24`, challenger `60,08`, validation `0`.

## M15 — Başkanlık Görev Süresi + Devir — PASS

M14 sonucu korunur. `82` kayıp → `82` turnover; `130` benzersiz başkan; avg outgoing tenure `6,93`, range `4–20`.

Açık denge notu: bir kulüp baseline'da 5/5 seçimde turnover yaşadı; çoklu-seed sıklığı izlenecek.

## M16 — Başkan Devrinde Kişisel İtibar — PASS

Handover: sporting/financial/transfer trust korunur; identity ve media `%25 eski + %75 nötr` ile normalleştirilir.

Seed `20260903`:

- elections `240`
- reelected/lost `161 / 79`
- unique presidents `127`
- media avg `72,42`, range `59–93`
- identity avg `65,00`, range `56–81`
- validation `0`

## M17 — Başkan Profili + Yönetim Felsefesi — PASS

Seed `20260903`:

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
- M16 `161/79` korunur
- validation `0`

Ayrıntı: `M17_BASKAN_PROFILI_YONETIM_FELSEFESI.md`.

## M18 — Başkan Sabrı → Teknik Direktör Karar Eşiği I — PASS

Seed `20260903`:

- decision snapshots `960`
- manager changes `81 → 88`
- dismissal decision differences `93`
- downstream manager identity differences `446 / 960`
- final assignment differences `37 / 48`
- low/high patience club-seasons `232 / 308`
- low/high dismissal rate `%16,4 / %6,2`
- avg dismissal/retained patience `50,52 / 61,52`
- reasons: performance `60`, board breakdown `25`, retirement `3`
- transfers `173 → 153`
- world changed `true`
- validation `0`
- analyzer PASS, sıkı `70` test PASS, M0–M18 runner PASS, artifact `0`

`446` manager identity farkı 446 kovma değildir; `93` farklı kararın sonraki sezonlara yayılmasıdır.

Kabul guard'ları: manager changes `80–100`, delta `-5..20`, decision diff `60–130`, manager identity diff `300–600`, final assignment diff `25–45`, low dismissal `0,10–0,22`, high `0,03–0,10`, rate farkı `≥0,05`, influenced transfers `120–200`, baseline transfer sapması `≤50`.

Ayrıntı: `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`.

## M19 — Başkan Sabrı + Seçim Geri Besleme Döngüsü — PASS

M18'in değişen world'ü fan/media/promise/reputasyon ve seçimlere geri bağlandı. İlk büyük sezon-motoru refactor'u yerine fixed-point replay seçildi; canonical seed temiz yakınsadığı ve temsilî çoklu-seed testi geçtiği için yaklaşım kabul edildi.

Seed `20260903` kabul baseline'ı:

- iterations `4`
- converged `true`
- cycle `false`
- elections `240`
- baseline reelected/lost `161 / 79`
- final reelected/lost `160 / 80`
- baseline/final election outcome differences `55 / 240`
- turnover membership differences `55`
- baseline/final manager changes `81 → 84`
- baseline/final transfers `173 → 168`
- unique final presidents `128`
- world changed `true`
- validation `0`

Iteration path:

1. `manager=88`, `transfer=153`, `157/83`, election diff `50`
2. `manager=84`, `transfer=173`, `160/80`, election diff `35`
3. `manager=84`, `transfer=168`, `160/80`, election diff `2`
4. `manager=84`, `transfer=168`, `160/80`, election diff `0`, timeline sabit

`55` election difference 55 net ekstra turnover değildir; kazanım/kayıp yönleri karşılıklı değişir ve final net kayıp yalnız `79 → 80` olur.

Canonical guard'lar:

- convergence zorunlu, cycle yasak,
- iteration `2–6`,
- son iteration stable ve election diff `0`,
- baseline M16 `161/79`, manager `81`, transfer `173`,
- ilk feedback turu M18 `88 manager / 153 transfer`,
- final-vs-baseline election difference `25–90`,
- final reelections `140–175`, losses `65–100`,
- final manager changes `75–100`, manager delta mutlak `≤25`,
- final transfers `130–210`, transfer delta mutlak `≤60`,
- unique final presidents `110–145`,
- world değişmeli.

Ek convergence güvenliği: seed `19011`, `19012`, `19013` için 8 sezon / max 8 iteration testlerinin tamamı cycle olmadan yakınsadı.

Final kalite:

- analyzer PASS
- `73` test PASS
- M0–M19 runner zinciri PASS
- bağımsız M19 runner aynı `4` iterasyonlu fixed point'i üretti
- validation `0`
- artifact `0`
- PR #20 squash merge `183749baab40403b381003c527ce62fad946a9a6`

Ayrıntı: `M19_BASKAN_SABRI_SECIM_GERI_BESLEME_DONGUSU.md`.

---

# 5. Uzun kariyer kalite hedefi

- geliştirici: 20 sezon
- temel denge: 100 kariyer × 20 sezon
- regresyon: 500 × 30 sezon
- büyük sürüm stres: 1.000 × 30 sezon

İzlenecekler: oyuncu popülasyonu/yaş, cash/debt, wage/revenue, transfer/loan/installment, şampiyonluk/terfi, manager tenure/change, fan/media/promise, election, president tenure/turnover/reputation, management profile, profile-driven kararlar ve feedback convergence/cycle.

Her başarısız kariyer seed ile replay edilebilmelidir.

---

# 6. Save/load yönü

Aday metadata: `saveVersion`, `gameVersion`, `simulationVersion`, `dataVersion`, `careerSeed`, current `GameDate`, checksum/integrity, migration history.

Kalıcı state adayları: installment/active loans, `FanState`, `MediaState`, aktif vaat + kompakt history, `PresidentTenureState`, president ID, election/turnover history, manager assignment ve kişisel reputasyon state. Management profile president ID+seed'den deterministik yeniden üretilebilir.

Fixed-point M19 headless kariyer çözümü için bütün timeline yeniden üretilebilir. Gerçek interactive save/load aşamasında incremental season orchestration gereksinimi yeniden değerlendirilecek.

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
10. M17'nin `financialDiscipline`, `riskAppetite`, `transferAmbition`, `youthOrientation` trait'leri henüz gerçek AI davranışına bağlı değildir.
11. M18 iki-geçişli seçim borcu M19'da fixed-point feedback ile kapandı; ancak bu literal incremental sezon orkestratörü değildir.
12. M19 canonical seed 4 iterasyonda; temsilî 3 seed de 8 sezon içinde yakınsadı. 100+ kariyerde convergence oranı ileride ölçülmeli.
13. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
14. Kullanıcı seçim kaybı sonrası game-over/başka kulüp kariyeri yok.
15. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M20

## Başkan Mali Disiplini → Transfer Bütçe Davranışı I

Amaç:

> **Mali disiplinli ve savurgan başkan aynı kasa/borç koşulunda aynı transfer harcama sınırına sahip olmamalı.**

İlk kapsam:

- yalnız `financialDiscipline` gerçek harcama/borç toleransına bağlanacak,
- `transferAmbition` ve `riskAppetite` aynı milestone'a eklenmeyecek,
- neutral profile eski advanced-transfer davranışını koruyacak,
- düşük mali disiplin daha yüksek harcama/borç toleransı, yüksek disiplin daha sert bütçe sınırı üretecek,
- transfer piyasası donmayacak veya hiperaktif olmayacak,
- transfer etkisi M19 feedback world/election zincirine yansıyacak,
- ekonomi ve transfer dengesi ayrı guard'larla ölçülecek.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.
