# ZMila Studio — Futbol Başkanlık Simülatörü
## GENEL_PROJE_OZETI

**Son güncelleme:** 04.09.2026  
**Repo:** `ZMilaStudio/futbol-baskanlik-simulatoru` — Public / proprietary notice  
**Aktif teknik aşama:** **M22 PASS ve main'e merge — sıradaki M23 / Başkan Risk İştahı → Transfer Pazarlık Davranışı I**  
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
23. Profil trait'i davranışa bağlanırken **trait'in doğrudan kontrol ettiği karar eşiği** ile aggregate dünya sonucu birbirine karıştırılmamalıdır.
24. Yeni trait eklemek, aynı full-career fixed-point baseline'ını katman katman gereksiz tekrar çözerek CI maliyetini sınırsız büyütmemelidir.
25. Canonical guard kapsamı korunurken duplicate full-career hesaplar tek nested rapordan yeniden kullanılmalıdır.
26. UI/APK, çekirdek kanıtlanmadan öncelik değildir.

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
- M19: patience-aware world reputasyon ve seçimlere geri beslenir,
- M20: `financialDiscipline` gerçek transfer affordability/bütçe sınırlarına bağlanır,
- M21: `transferAmbition` gerçek transfer aktivite slotlarına bağlanır,
- M22: M19–M21 canonical profile-feedback doğrulamasını tek-pass nested orchestration ile ölçeklenebilir hale getirir; oyun davranışını değiştirmez.

M17 trait'leri:

- `financialDiscipline` — **bağlı / M20**
- `riskAppetite` — henüz bağlı değil; **M23 adayı**
- `transferAmbition` — **bağlı / M21**
- `youthOrientation` — henüz bağlı değil
- `managerPatience` — **bağlı / M18**

Arketipler: `balanced`, `prudentBuilder`, `ambitiousSpender`, `youthArchitect`, `patientPlanner`, `interventionist`.

## M18 ara mimarisi

M18 iki geçişliydi:

1. canonical president/profile timeline,
2. aynı seed advanced-world replay + president `managerPatience`.

`managerPatience=60` eski manager dismissal eşiklerini birebir korur. M18'de değişen world seçimlere geri dönmüyordu.

## M19 feedback mimarisi

M19 deterministik **fixed-point replay** ile feedback döngüsünü kapattı:

`president timeline → managerPatience → manager/world → promise/fan/media/reputasyon → election/turnover → president timeline`

Timeline değişirse aynı seed ile yeniden replay edilir. Timeline sabitlenirse convergence; daha önce görülen timeline tekrar oluşursa cycle kabul edilir. Varsayılan maksimum iterasyon `8`.

Fixed-point hesaplama bütün timeline'ı iteratif çözer ama provider yalnız ilgili sezonda yürürlükteki başkanı uygular; gelecekteki başkanın trait'i geçmişe sızmaz. Bu literal tek-geçişli sezon orkestratörü değil, tarihsel olarak self-consistent equilibrium/replay çözümüdür.

M19 için mevcut motorlar yeniden kullanılabilir hale getirildi:

- `PromiseMediaCareerEngine.simulateFromAdvancedReport(...)`
- `PresidentReputationCareerEngine.simulateFromSourceReport(...)`
- `PresidentManagerPatienceTimeline.fromReputationReport(...)`

Eski `simulate()` yolları korunur ve replay fonksiyonlarına delege eder; M13–M18 canonical baseline'ları değişmedi.

## M20 mali disiplin mimarisi

M20, M19 final feedback çözümünü baseline alır ve timeline'dan aynı anda iki profile trait'i okur:

- `managerPatience` → manager dismissal eşikleri,
- `financialDiscipline` → transfer bütçe/affordability eşikleri.

`TransferBudgetPolicy` üç gerçek sınır taşır:

- `reserveCash`,
- `windowSpendCapBps`,
- `totalCommitmentCapBps`.

Neutral `financialDiscipline=60` eski davranışı birebir korur:

- reserve `2,0M`,
- window cap `%35`,
- installment commitment cap `%90`.

Trait `20..90` clamp edilir. `d = discipline - 60`:

- reserve = `2.000.000 + d × 30.000`,
- window cap = `3500 - d × 25` bps, clamp `2500..4700`,
- commitment cap = `9000 - d × 50` bps, clamp `7000..11500`.

Örnek uçlar:

- discipline `20` → `0,8M / %45 / %110`,
- discipline `60` → `2,0M / %35 / %90`,
- discipline `90` → `2,9M / %27,5 / %75`.

Transfer penceresi `seasonIndex + 1` başkanını kullanır; seçim sonrası gelen başkan kendi ilk yaz transfer bütçesini kontrol eder.

M20 bilinçli olarak aday sıralaması, pozisyon ihtiyacı, seller ask, buyer max bid, `transferAmbition`, `riskAppetite` ve `youthOrientation` davranışını değiştirmez.

## M21 transfer hırsı mimarisi

M21, M20 final feedback çözümünü baseline alır ve üçüncü aktif trait'i ekler:

- `managerPatience` → manager görev güvenliği,
- `financialDiscipline` → transfer affordability,
- `transferAmbition` → buyer başına tamamlanabilecek transfer slotu.

`PresidentTransferAmbitionActivityPolicy`:

- ambition `<45` → `1` slot,
- `45..74` → `2` slot,
- `>=75` → `3` slot.

Neutral `transferAmbition=60` eski sabit `2` slotu birebir korur. Candidate shortlist `8`, oyuncu seçimi, seller ask, buyer max bid, affordability ve taksit mantığı değişmez.

Activity provider da transfer penceresi için `seasonIndex + 1` başkanını kullanır. Seçim sonrası gelen yeni başkan kendi ilk yaz penceresinin hem mali disiplinini hem transfer hırsını kontrol eder.

M21 feedback zinciri:

`M20 final president timeline → patience + discipline + ambition → advanced world → promise/fan/media/reputation → election → new president timeline → fixed point`.

## M22 profile-feedback orkestrasyonu

M22 **davranış değiştirmeyen** teknik ölçeklenebilirlik milestone'udur.

Sorun: M21 sonunda aynı canonical 20 sezonluk M19/M20/M21 zincirleri hem `dart test` içinde hem bağımsız runner'larda tekrar tekrar çözülüyor, CI `6:10` seviyesine çıkıyordu.

Temel gözlem:

- `PresidentTransferAmbitionFeedbackReport` zaten `m20Baseline` taşır,
- `PresidentFinancialDisciplineFeedbackReport` zaten `m19Baseline` taşır.

Dolayısıyla tek canonical M21 çözümü aynı anda M19, M20 ve M21 kanıtını taşır.

M22 uygulaması:

- `tool/profile_feedback_canonical_guard.dart` eklendi,
- M19/M20/M21 canonical denge guard'ları ortaklaştırıldı,
- M19 ve M20 runner canonical seed'de aynı guard'ları kullanır,
- M21 runner canonical seed'de tek simülasyondan:
  - `report.m20Baseline.m19Baseline` → M19,
  - `report.m20Baseline` → M20,
  - `report` → M21
  doğrular,
- üç pahalı full-career canonical test `canonical-feedback` tag'i aldı,
- normal test turu `dart test --exclude-tags canonical-feedback`,
- hızlı policy, neutral-regression, determinism ve M19 multi-seed convergence testleri normal test turunda kaldı,
- ayrı M19/M20 canonical CI runner tekrarları kaldırıldı,
- tek `Run M19-M21 canonical profile feedback career` adımı kaldı.

M22 canonical davranış invariant'ı:

> **Aynı seed aynı M19/M20/M21 dünyasını üretir; yalnız gereksiz tekrar çözümü kaldırılır.**

---

# 3. GitHub / CI disiplini

Tek hafif workflow:

- `dart pub get`
- `dart analyze`
- `dart test --exclude-tags canonical-feedback`
- M0 100 sezon batch
- M1–M18 20 sezon headless runner zinciri
- tek M19–M21 canonical profile-feedback runner

APK/AAB, büyük binary veya `actions/upload-artifact` yok. Artifact hedefi `0`. Timeout tekrar `5 dk`.

M0–M22 geliştirmesinde Codex kredisi kullanılmadı; GitHub araçları yeterli oldu.

Son merge'ler:

- M17 PR #18 → `0003e6463e3cbc7052d407cc45c2594be8d861db`
- M18 PR #19 → `d1ca4de859c528470785f98a10baa4db8259d4ce`
- M18 sonrası canonical docs/main → `1cbd3da04816e4f6d29b2db367e7992451832367`
- M19 PR #20 → `183749baab40403b381003c527ce62fad946a9a6`
- M20 PR #21 → `b5f2c9488556855972b1be93f37dcb3114981d2e`
- M21 PR #22 → `d24670a5ea9dfa51ee32f7fe0bdda894e0972856`
- M22 PR #23 → `4ec358cf7131087176426ba5767ab4e4e65a36b3`

CI geçmişi:

- M18 merge-sonrası main `33894772996`: PASS, artifact `0`.
- M19 final PR `33911708201`: analyzer PASS, `73` test PASS, M0–M19 runner PASS, artifact `0`.
- M20 ilk ölçüm `33913165685`: analyzer PASS, `75` test PASS, M0–M19 runner PASS; canonical M20 baseline üretildi.
- M20 final PR `33914123377`: analyzer PASS, `76` test PASS, M0–M20 runner PASS, artifact `0`, yaklaşık `4:15`.
- M20 ara CI `33913975481`: yalnız Money test matcher tipinden kırıldı; model/katsayı değiştirilmeden matcher düzeltildi.
- M20 merge sonrası main `33914763660`: PASS.
- M21 ilk ölçüm `33915601227`: analyzer PASS, `79` test PASS, M0–M20 runner PASS; canonical M21 baseline üretildi.
- M21 final PR `33916301967`: analyzer PASS, `79` test PASS, M0–M21 runner PASS, artifact `0`, yaklaşık `6:10`; timeout `7 dk`ya çıkarıldı.
- M22 ilk ölçüm `33917924101`: analyzer PASS, `76` hızlı/non-duplicate test PASS, M0–M18 PASS, birleşik M19–M21 canonical PASS, artifact `0`, yaklaşık `2:06`.
- M22 final PR `33918259144`: `5 dk` timeout altında analyzer + `76` hızlı test + M0–M18 + birleşik M19–M21 canonical PASS, artifact `0`.

M22 ile M21 finaline göre yaklaşık `4:04`, yani yaklaşık `%66` CI süre kazanımı sağlandı. Bu kazanç test/guard kalitesini azaltarak değil, aynı full-career raporların duplicate çözümünü kaldırarak elde edildi.

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

Seed `20260903` kabul baseline'ı:

- iterations `4`
- converged `true`, cycle `false`
- elections `240`
- baseline/final reelected-lost `161/79 → 160/80`
- election outcome differences `55 / 240`
- manager changes `81 → 84`
- transfers `173 → 168`
- unique final presidents `128`
- world changed `true`
- validation `0`

Iteration path:

1. `88 manager / 153 transfer / 157-83 / diff50`
2. `84 / 173 / 160-80 / diff35`
3. `84 / 168 / 160-80 / diff2`
4. stable `84 / 168 / 160-80 / diff0`

Ek convergence güvenliği: seed `19011`, `19012`, `19013` için 8 sezon / max 8 iteration testlerinin tamamı cycle olmadan yakınsadı.

Final kalite: analyzer PASS, `73` test PASS, M0–M19 runner PASS, validation `0`, artifact `0`, PR #20 merge `183749baab40403b381003c527ce62fad946a9a6`.

Ayrıntı: `M19_BASKAN_SABRI_SECIM_GERI_BESLEME_DONGUSU.md`.

## M20 — Başkan Mali Disiplini → Transfer Bütçe Davranışı I — PASS

Neutral regresyon:

- `financialDiscipline=60` → eski `2M / %35 / %90` transfer bütçesi,
- neutral provider'lı 4 sezonluk advanced world signature'ı provider olmayan eski world ile birebir aynı,
- M0–M19 canonical runner sonuçları korunur.

Seed `20260903` M19 baseline → M20 final:

- iterations `5`, converged `true`, cycle `false`
- elections `240`
- reelected/lost `160/80 → 158/82`
- election outcome difference `52 / 240`
- manager changes `84 → 83`
- transfers `168 → 153`
- transfer volume `1.562,93M → 1.387,32M`
- installment deals `81 → 80`
- installment commitment `278,90M → 279,65M`
- final cash `1.191,15M → 1.226,59M`
- final debt `347,04M → 363,58M`
- emergency borrowing `148,22M → 159,05M`
- unique final presidents `130`
- world changed `true`
- validation `0`

Iteration path:

1. `98 manager / 158 transfer / 1.461,45M / 157-83 / diff53`
2. `88 / 150 / 1.401,56M / 157-83 / diff34`
3. `84 / 160 / 1.466,16M / 156-84 / diff27`
4. `83 / 153 / 1.387,32M / 158-82 / diff12`
5. stable `83 / 153 / 1.387,32M / 158-82 / diff0`

Aggregate debt/emergency yönü trait'in doğrudan causal sonucu olarak yorumlanmaz. Doğrudan invariant mali disiplin arttıkça reserve artması, spend/commitment cap'in düşmesidir.

Final kalite: analyzer PASS, `76` test PASS, neutral signature PASS, M0–M20 runner PASS, validation `0`, artifact `0`, PR #21 merge `b5f2c9488556855972b1be93f37dcb3114981d2e`.

Ayrıntı: `M20_BASKAN_MALI_DISIPLIN_TRANSFER_BUTCE_DAVRANISI.md`.

## M21 — Başkan Transfer Hırsı → Transfer Aktivitesi I — PASS

M20'nin yakınsamış dünyası baseline alınır. `transferAmbition` yalnız buyer başına tamamlanabilecek transfer slotunu değiştirir; affordability M20'den gelir.

Neutral regresyon:

- ambition `<45 / 45..74 / >=75` → `1 / 2 / 3` slot,
- `transferAmbition=60` eski `2` slot davranışını korur,
- neutral activity provider'lı 4 sezonluk advanced world signature'ı provider olmayan eski world ile birebir aynı,
- M0–M20 canonical runner sonuçları korunur.

Seed `20260903` M20 baseline → M21 final:

- iterations `4`
- converged `true`, cycle `false`
- elections `240`
- reelected/lost `158/82 → 150/90`
- election outcome difference `48 / 240`
- manager changes `83 → 80`
- transfers `153 → 161`
- transfer volume `1.387,32M → 1.461,55M`
- installment deals `80 → 73`
- installment commitment `279,65M → 247,61M`
- final cash `1.226,59M → 1.180,63M`
- final debt `363,58M → 330,25M`
- emergency borrowing `159,05M → 123,89M`
- unique final presidents `138`
- world changed `true`
- validation `0`

Iteration path:

1. `88 manager / 145 transfer / 1.313,98M / 158-82 / diff48`
2. `82 / 148 / 1.356,44M / 151-89 / diff35`
3. `80 / 161 / 1.461,55M / 150-90 / diff7`
4. stable `80 / 161 / 1.461,55M / 150-90 / diff0`

M21 aggregate transfer sayısını `+8`, hacmi yaklaşık `%5,35` artırdı; piyasa hiperaktif olmadı. Ancak ürün invariant'ı aggregate artış değil, **low ambition slot < neutral slot < high ambition slot** ilişkisidir.

Canonical guard'lar:

- convergence zorunlu, cycle yasak,
- iteration `3–6`, final stable/election diff `0`,
- M20 baseline `158/82`, manager `83`, transfer `153`,
- final election diff `25–80`,
- final reelections `135–165`, losses `75–105`,
- final manager `70–95`, delta mutlak `≤20`,
- final transfers `140–185`, transfer delta mutlak `5–35`,
- transfer volume `1,2B–1,7B`, volume delta mutlak `≤300M`,
- installment deals `55–95`, commitment `180M–330M`,
- final cash `1,0B–1,4B`, debt `250M–430M`, emergency `80M–200M`,
- unique final presidents `120–150`,
- world değişmeli.

Final kalite:

- analyzer PASS
- `79` test PASS
- neutral activity signature regresyonu PASS
- M0–M21 runner zinciri PASS
- bağımsız M21 runner aynı `4` iterasyonlu fixed point'i üretti
- validation `0`
- artifact `0`
- final CI `33916301967` yaklaşık `6 dk 10 sn`
- PR #22 squash merge `d24670a5ea9dfa51ee32f7fe0bdda894e0972856`

Ayrıntı: `M21_BASKAN_TRANSFER_HIRSI_TRANSFER_AKTIVITESI.md`.

## M22 — Profile Feedback Orchestration I — PASS

M22 yeni oyun davranışı eklemez. M19/M20/M21 canonical full-career doğrulamasındaki duplicate hesapları tek nested M21 çözümünde birleştirir.

İlk ölçüm CI `33917924101`:

- analyzer PASS,
- `76` hızlı/non-duplicate test PASS,
- M0–M18 runner PASS,
- birleşik M19–M21 canonical runner PASS,
- nested M19 final `160/80`,
- nested M20 final `158/82`, manager `83`, transfer `153`,
- M21 final **birebir korunur**: `4 iterasyon / 150-90 / 80 manager / 161 transfer`,
- M21 volume `1.461,55M`, installment `73 / 247,61M`, cash/debt/emergency `1.180,63M / 330,25M / 123,89M`, unique presidents `138`,
- validation `0`, artifact `0`,
- toplam süre yaklaşık `2:06`.

M21 final `6:10` → M22 `2:06`: yaklaşık `4:04` / `%66` kazanım. Timeout `7 → 5 dk` geri indirildi.

Final kalite:

- final PR CI `33918259144` PASS,
- `5 dk` timeout altında analyzer PASS,
- `76` hızlı/non-duplicate test PASS,
- M0–M18 runner PASS,
- birleşik M19–M21 canonical runner PASS,
- artifact `0`,
- simülasyon davranışı/canonical sonuç değişmedi,
- PR #23 squash merge `4ec358cf7131087176426ba5767ab4e4e65a36b3`.

Ayrıntı: `M22_PROFILE_FEEDBACK_ORKESTRASYON_I.md`.

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

Fixed-point M21 headless kariyer çözümü için bütün timeline yeniden üretilebilir. M22 yalnız test/CI tekrarını azaltır; gerçek interactive save/load için incremental season orchestration gereksinimi hâlâ ayrıca değerlendirilecektir.

---

# 7. Açık teknik / denge notları

1. Ufuk Ligi yüksek final nakit birikimi takip edilmeli.
2. Resmî ayrı `wageBudget` hâlâ yok; M20 yalnız transfer affordability sınırlarını ekledi.
3. Free-agent AI basittir.
4. Manager maaşı/kontratı, başka kulüp teklifi ve spesifik transfer talebi yok.
5. Satın alma opsiyonu, bonus, sell-on ve takas yok.
6. Taraftar henüz seyirci/bilet/mağaza/sponsor/protestoyu geri beslemez.
7. Medya serbest metin/çok yıllı konu ağı değildir.
8. AI kulüp sezon başına bir resmi vaat kullanır.
9. M16 handover V1 `%25 eski + %75 nötr`; çoklu-seed stres testinde izlenecek.
10. M17'nin `managerPatience`, `financialDiscipline`, `transferAmbition` trait'leri gerçek davranışa bağlıdır. `riskAppetite` ve `youthOrientation` henüz bağlı değildir.
11. M18 iki-geçişli seçim borcu M19'da fixed-point feedback ile kapandı; M20 ve M21 bu yaklaşımı yeni trait'lerle genişletti. Bu hâlâ literal incremental sezon orkestratörü değildir.
12. M19 canonical seed `4`, M20 `5`, M21 `4` iterasyonda yakınsadı. M19 için temsilî 3 kısa seed de yakınsadı; M20/M21 için geniş çoklu-seed convergence testi ileride yapılmalı.
13. M20/M21 aggregate finans sonuçları trait'in doğrudan causal yönü olarak yorumlanmamalıdır; doğrudan policy invariant'ları ayrı test edilir.
14. M21 final CI `6:10` ile duplicate full-career maliyetini görünür hale getirdi; M22 bu tekrarı kaldırıp aynı canonical sonucu `2:06` seviyesinde doğruladı.
15. M22 CI optimizasyonudur; engine içindeki historical fixed-point nesting tamamen kaldırılmış değildir. Yeni trait'ler yine mevcut feedback yapısına dikkatle eklenmelidir.
16. Sponsor, tesis ve kriz çekirdeğe bağlanmadı.
17. Kullanıcı seçim kaybı sonrası game-over/başka kulüp kariyeri yok.
18. Flutter UI/APK bilinçli olarak başlamadı.

---

# 8. Sıradaki milestone — M23

## Başkan Risk İştahı → Transfer Pazarlık Davranışı I

Amaç:

> **Aynı bütçe ve aynı transfer aktivitesine sahip iki başkandan riskli olanı, pazarlıkta daha yüksek fiyat eşiğine çıkabilmeli; temkinli olan daha erken vazgeçmeli.**

Trait ayrımı kesin:

- `financialDiscipline` = **ne kadarını karşılayabilir / ne kadar rezerv bırakır**,
- `transferAmbition` = **kaç transfer slotu kovalar**,
- `riskAppetite` = **mevcut affordability içinde pazarlıkta ne kadar yukarı çıkmaya razı olur**,
- `youthOrientation` = M23'e bağlanmayacak.

İlk kapsam:

- yalnız `riskAppetite` gerçek transfer teklif/pazarlık tavanına bağlanacak,
- ilk aday karar noktası mevcut `buyer max bid` / `maxBidBps`,
- neutral `riskAppetite=60` mevcut teklif davranışını birebir korumalı,
- düşük risk daha düşük bid ceiling, yüksek risk daha yüksek bid ceiling üretmeli,
- teklif tavanı affordability/bütçeyi aşmak için arka kapı olmayacak,
- M20 reserve/window/commitment sınırları aynen korunacak,
- M21 `1/2/3` slot mantığı aynen korunacak,
- seller ask değişmeyecek,
- candidate shortlist `8` değişmeyecek,
- pozisyon ihtiyacı değişmeyecek,
- oyuncu yaş/potential tercihleri değişmeyecek,
- `youthOrientation` eklenmeyecek,
- neutral provider yolu eski advanced-world signature'ını birebir korumalı,
- doğrudan causal invariant: **low-risk max bid < neutral max bid < high-risk max bid**,
- aggregate transfer sayısı/hacmi kontrollü kalmalı; piyasa hiperaktif olmamalı,
- feedback convergence/cycle güvenliği korunmalı.

M23 CI kuralı:

- M22'nin birleşik canonical profile-feedback doğrulaması genişletilecek,
- M19/M20/M21 için yeniden ayrı full-career koşular eklenmeyecek,
- duplicate canonical test/runner geri getirilmeyecek,
- artifact `0`,
- 5 dakikalık CI hedefi korunacak; gerekirse önce tekrar maliyeti optimize edilecek, timeout körlemesine artırılmayacak.

Önerilen branch: `m23-president-risk-appetite-negotiation`.

---

# 9. Çalışma disiplini

- Büyük değişiklik: branch + PR + CI.
- Kullanıcı mikro test operatörü yapılmaz.
- Mümkün olan en büyük mantıklı iş tek döngüde tamamlanır.
- Codex kredisi minimum tutulur.
- Canlı `main` eski sohbet notlarından üstündür.
- Önemli karar/test/reddedilen deneme/açık sorun/sıradaki iş canonical özet dosyasına yazılır.