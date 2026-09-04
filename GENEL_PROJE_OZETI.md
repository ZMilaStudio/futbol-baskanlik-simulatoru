# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 5 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen tam kapsamlı Android mobil futbol kulübü başkanlığı simülasyonu.

Değişmez ana kimlik:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Alternatif slogan:

> **Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.**

Başkanın ana sorumlulukları:

- ekonomi, nakit ve borç
- teknik direktör seçimi ve görev güvenliği
- transfer stratejisi
- sözleşme/maaş politikası
- kiralık/taksit seçenekleri
- taraftar beklentisi ve güveni
- medya açıklamaları ve hafıza
- başkan vaatleri
- başkanlık seçimleri ve görev süresi
- altyapı/tesis/sponsor/kriz sistemleri ilerleyen aşamalarda
- uzun vadeli kulüp sağlığı

Football Manager benzeri maç içi taktik yönetimi yapılmayacak. Oyuncu diziliş, antrenman, dakika bazlı oyuncu değişikliği veya duran top planlamaz.

Gerçek kulüp/futbolcu/lisanslı materyal kullanılmayacak.

## 2. Geliştirme stratejisi

Futbol Başkanlık Simülatörü diğer aktif ZMila Studio projelerini aksatmadan küçük ama sağlam altyapı milestone'larıyla ilerletilir.

Şu aşamada görsel ekran/APK ana hedef değildir.

> **Önce sağlam, deterministik, uzun kariyerde otomatik test edilebilir simülasyon çekirdeği.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo public tutulur; kaynak kod açık kaynak lisansı altında değildir (`LICENSE.md`).

Codex gereksiz tüketilmez. Büyük çok-dosyalı refactor/test/migration işlerinde gerekirse kullanılır; çekirdek milestone'ların önemli bölümü doğrudan GitHub araçlarıyla yürütülmüştür.

## 3. Güncel teknik durum

**M0–M25 PASS. M25 PR #26 final kalite kapısındadır; davranış ve runner kanıtları yeşildir.**

M24 squash merge:

`cfdca8f63dfa6c91fd2432031e0e2c34a8101a06`

M25 doğrulanmış PR CI:

`33925868414`

Aktif sıradaki milestone:

> **M26 — World Save Snapshot I**

M25 merge tamamlandığında bu bölüm gerçek squash merge SHA ile güncellenecektir.

## 4. Teknik mimari

- saf Dart simülasyon çekirdeği
- Flutter mobil kabuk daha sonra
- deterministik seed/replay
- cihaz saatinden bağımsız `GameDate`
- integer minor-unit `Money`
- headless runner + invariant/balance guard
- profile feedback için deterministic fixed-point replay
- convergence/cycle kontrolü
- neutral trait regresyonu
- `CareerCheckpoint` tabanlı sezon-sınırı save/resume
- `saveVersion=1` + canonical JSON + corruption checksum
- explicit save failure kodları + migration fixture altyapısı
- APK/AAB üretmeyen core CI
- `actions/upload-artifact` yok; artifact hedefi `0`

Dünya ölçeği:

- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ekonomi, oyuncu yaşam döngüsü, kontrat, transfer, manager, taraftar, medya, vaat, seçim ve başkan profili

Canonical kariyer seed'i:

`20260903`

## 5. Kalıcı tasarım ve mühendislik kuralları

1. Başkan teknik direktör değildir.
2. Mobil UI sade, arka plan sistemi derin olabilir.
3. Oyuncuya gereksiz sayı bombardımanı yapılmaz.
4. Taraftar bağlamı ve ekonomik gerçekliği anlamalıdır.
5. Transfer AI farklı finansman/karar yolları kullanabilir.
6. Doğru karar her zaman açık olmamalıdır.
7. Kısa vadeli sportif başarı ile uzun vadeli mali sağlık arasında gerilim olmalıdır.
8. Geçmiş açıklamalar ve vaatler unutulmamalıdır.
9. Karar sonuçları aylar/sezonlar sonra geri dönebilir.
10. Uzun kariyer otomatik test edilir.
11. İlk sürüm gereksiz kapsamla şişirilmez.
12. Bir başkan trait'i ilk davranış bağlantısında yalnız tek karar noktasına etki eder.
13. Neutral trait değeri eski davranışı birebir korumalıdır.
14. Feedback döngülerinde convergence/cycle kontrolü zorunludur.
15. Aynı canonical full-career hesaplar CI içinde gereksiz tekrar edilmez.
16. Aggregate metrik yönü, izole trait'in causal ürünüymüş gibi yorumlanmaz; causal invariant doğrudan test edilir.
17. Canlı GitHub durumu eski sohbet notlarından üstündür.
18. Save/load checkpoint devamı kesintisiz replay ile birebir aynı deterministic sonucu üretmelidir.
19. Save format sürümü açık olmalı; desteklenmeyen future version güvenli reddedilmelidir.
20. Migration yolu fixture/test olmadan kabul edilmez.
21. Checksum veri bozulma kontrolüdür; kriptografik güvenlik garantisi gibi sunulmaz.

## 6. Milestone geçmişi

### M0 — Deterministik sezon çekirdeği — PASS

- lig/fixture/match simülasyonu
- deterministic replay
- 100 sezon batch invariant testi

### M1 — 20 sezon kariyer — PASS

- ardışık sezon kariyeri
- custom başlangıç sezonu/tarih desteği

### M2 — Oyuncu yaşam döngüsü — PASS

- yaşlanma
- emeklilik
- genç oyuncu üretimi
- uzun vadeli kadro devamlılığı

### M3 — Ekonomi — PASS

- exact `Money`
- sezon gelir/gider akışı
- nakit/borç/financial health
- emergency borrowing

Universal prosperity veya universal collapse yaratan denemeler reddedildi.

### M4 — Transfer pazarı — PASS

- market value
- buyer/seller mantığı
- pozisyon ihtiyacı
- teklif/ask pazarlığı

Donmuş veya hiperaktif transfer pazarı üreten kalibrasyonlar reddedildi.

### M5 — 48 kulüp / 3 lig dünya — PASS

- 48 kulüp
- 3×16 lig
- 20 sezon world simulation
- terfi/düşme
- ortak ekonomi/transfer ölçeği

### M6 — Teknik direktör sistemi — PASS

- deterministik manager pool
- manager profilleri
- performance / board breakdown / retirement değişimleri
- manager impact gerçek kulüp gücünü etkiler

Canonical eski baseline yaklaşık 82 manager değişimi; negatif ve güçlü pozitif manager etkileri birlikte oluşur.

### M7 — Oyuncu sözleşmesi + gerçek maaş — PASS

- `PlayerContract`
- gerçek yıllık maaş yükü
- renewal/release/free-agent signing
- transfer sonrası yeni kontrat
- contract term market value etkisi

Canonical 20 sezon:

- active final contracts `874`
- renewals `3757`
- releases `1143`
- free signings `776`
- final free agents `32`
- annual wage bill `491,27M`

### M8 — Kiralık + taksit — PASS

- sezonluk loan
- loan fee
- maaş paylaşımı
- parent contract korunumu
- sezon sonu otomatik dönüş
- upfront + gelecek taksit
- transfer taksiti banka borcundan ayrı yükümlülük

Reddedilen ilk dengeler:

- 183 permanent / 146 taksitli + 755 loan
- taksit oranı 145/189
- 108/147
- 86/156

Kabul baseline:

- 140 permanent transfer
- 68 installment deal
- 478 loan
- final active loans `32`
- installment commitment `234,79M`
- loan fees `113,15M`
- validation `0`

### M9 — Taraftar beklentisi + güven — PASS

- bağlamsal expectation
- sporting / financial / transfer / identity trust
- neden kodları

İlk model `46..68` aralığında fazla sıkıştığı için reddedildi.

Kabul:

- 960 club-season snapshot
- avg trust `64,88`
- range `44..75`
- boundary `0`
- 2143 trust reason

### M10 — Medya hafızası — PASS

- `MediaStatement`
- stance
- credibility
- açıklama → sonraki manager kararı çelişkisi

İlk model 960 club-season'ın 847'sinde açıklama ürettiği için reddedildi.

Kabul:

- statements `556`
- contradictions `22`
- strong-support→dismiss `9`
- credibility avg `75,52`
- range `49..87`

### M11 — Başkan vaatleri — PASS

- preseason bağlamdan ölçülebilir vaat
- fulfilled / partial / broken resolver
- vaat üretirken sezon sonu geleceğini okuma yasak

Canonical:

- promises `960`
- fulfilled `435`
- partial `169`
- broken `356`
- avg score `54,84`

### M12 — Vaat → taraftar güveni — PASS

- tek advanced-world raporu paylaşılır
- promise sonucu identity trust'a kontrollü etki eder
- finans vaatleri ayrıca financial trust'a etki eder
- overall fan trust yeni katman tarafından ele geçirilmez

### M13 — Vaat → medya güvenilirliği — PASS

- manager + advanced transfer + promise + media aynı world
- fulfilled/partial/broken credibility etkisi

Canonical:

- positive `452`
- neutral `154`
- negative `354`
- statements `560`
- contradictions `28`
- credibility `74,88 → 72,38`

### M14 — Başkanlık seçimi I — PASS

- 4 sezonda bir deterministik seçim
- fan overall/identity + media credibility + promise sicili
- ilk sürüm gözlemsel

Canonical:

- elections `240`
- reelected/lost `158/82`
- approval avg `63,24`
- competitive `72`

### M15 — Başkan görev süresi + devir — PASS

- reelected → aynı incumbent
- lost → challenger gerçek yeni `PresidentProfile`
- turnover history

Canonical:

- 82 loss = 82 turnover
- unique presidents `130`
- avg outgoing tenure `6,93`

Bir kulübün 5/5 seçim kaybetmesi gözlendi; M15'te seçim modelini değiştirmemek için özellikle düzeltilmedi.

### M16 — Başkan devrinde kişisel itibar — PASS

Başkan değişiminde kurumsal sporting/financial/transfer trust korunur; kişisel identity/media reputasyonu kontrollü nötre yaklaşır.

Handover yaklaşık `%25 geçmiş + %75 neutral`.

Canonical seçim `161/79`; personal reputation boundary'lere yapışmaz.

### M17 — Başkan yönetim profili — PASS

6 arketip:

- balanced
- prudentBuilder
- ambitiousSpender
- youthArchitect
- patientPlanner
- interventionist

5 trait:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Canonical:

- profiles `127`
- tüm 6 arketip aktif
- 79 turnover'dan 67 arketip değişimi
- 57 meaningful philosophy change
- avg profile distance `22,47`

### M18 — Manager patience → hoca karar eşiği — PASS

İlk gerçek profile trait etkisi.

Neutral `managerPatience=60` eski eşikleri korur.

Canonical:

- manager changes `81→88`
- decision differences `93`
- low patience dismissal `%16,4`
- high patience `%6,2`
- final assignment differences `37/48`

M18 iki-geçişli reference timeline kullandı; election feedback M19'da kapatıldı.

### M19 — Manager/world ↔ seçim fixed-point — PASS

Zincir:

`president timeline → patience-aware world → reputasyon → seçim → yeni timeline`

Canonical:

- `4` iterasyon
- converged `true`
- cycle `false`
- `161/79 → 160/80`
- manager `81→84`
- transfers `173→168`

Representative seeds `19011/19012/19013` kısa horizon'da converge eder.

### M20 — Financial discipline → transfer affordability — PASS

Trait yalnız bütçe/affordability alanına bağlandı.

Neutral `60`:

- reserve `2M`
- window spend cap `%35`
- installment commitment cap `%90`

Canonical:

- `5` iterasyon
- `160/80 → 158/82`
- manager `84→83`
- transfer `168→153`
- volume `1.387,32M`
- cash `1.226,59M`
- debt `363,58M`

Borç/emergency yönü causal invariant değildir.

### M21 — Transfer ambition → aktivite — PASS

Trait yalnız completed transfer slots kontrol eder:

- `<45 → 1`
- `45..74 → 2`
- `>=75 → 3`

Neutral `60 = 2` eski davranışı birebir korur.

Canonical:

- `4` iterasyon
- `158/82 → 150/90`
- manager `83→80`
- transfers `153→161`
- volume `1.461,55M`
- debt `330,25M`
- emergency `123,89M`

M21 sonrası CI nested fixed-point tekrarları nedeniyle yaklaşık 6:10'a yükseldi; timeout geçici 7 dakikaya çıktı.

### M22 — Profile Feedback Orchestration I — PASS

Davranış değiştirmeyen performans/refactor milestone'u.

Sorun:

M19/M20/M21 canonical full-career hesapları test ve ayrı runner'larda tekrar çözülüyordu.

Çözüm:

- ortak `tool/profile_feedback_canonical_guard.dart`
- full canonical testler `canonical-feedback` tag
- normal test `dart test --exclude-tags canonical-feedback`
- tek en yeni profile-feedback runner nested önceki raporları doğrular
- ayrı duplicate canonical runner tekrarları kaldırıldı

M21 baseline birebir korundu.

PR #23 merge:

`4ec358cf7131087176426ba5767ab4e4e65a36b3`

Final güvenli CI yaklaşık `2:51`; timeout tekrar `5 dk`.

### M23 — Risk appetite → transfer pazarlık tavanı — PASS

Trait yalnız buyer max-bid ceiling'e bağlandı.

Policy:

- clamp `20..90`
- adjustment `(risk - 60) × 20 bps`
- clamp `-800..+600 bps`
- neutral `60 = 0 bps`

Seller ask, shortlist, affordability, slot ve candidate scoring değişmez.

PR #24 merge:

`17142c39bfeed20fce931e8810f30ba4ba98a322`

Canonical:

- `5` iterasyon
- `150/90 → 156/84`
- manager `80→85`
- transfers `161→133`
- volume `1.201,05M`
- installment deals `66`
- commitment `230,59M`
- cash `1.195,96M`
- debt `381,94M`
- emergency `189,81M`
- validation `0`

Causal invariant yalnız:

> low risk max-bid < neutral max-bid < high risk max-bid

### M24 — Youth orientation → genç/potansiyel transfer tercihi — PASS

M17'deki son davranışsız trait gerçek karar noktasına bağlandı.

Policy:

- `youthOrientation=20` → youth signal `%60`
- `60` → `%100` / neutral
- `90` → `%130`

Youth signal:

- gelişim payı `potential - ability`, clamp `0..20`
- gelişim katkısı `upside × 0.25`
- yaş `<=23` → `+4`
- yaş `>=31` → `-4`

M24 yalnız bu signal'i candidate scoring içinde ölçekler.

Değişmeyenler:

- budget/affordability
- transfer slotu
- buyer max-bid
- seller ask
- installment acceptance
- shortlist büyüklüğü
- pozisyon ihtiyacı
- market value
- youth intake üretim miktarı/kalitesi

Neutral `60` eski advanced-world signature'ını birebir korur.

Doğrudan causal test:

Aynı gerçek transfer penceresinde düşük yönelim daha hazır `27 yaş / 79 ability` oyuncuyu; yüksek yönelim `20 yaş / 72 ability / 92 potential` oyuncuyu ilk aday olarak seçer.

Canonical M24 — seed `20260903`:

- convergence `4`
- cycle `false`
- elections `240`
- reelected/lost `156/84 → 159/81`
- election differences `49`
- manager `85→86`
- transfers `133→157`
- volume `1.201,05M → 1.417,94M`
- installment deals `66→79`
- commitment `230,59M → 261,26M`
- cash `1.195,96M → 1.217,05M`
- debt `381,94M → 347,57M`
- emergency `189,81M → 144,39M`
- unique presidents `129`
- world changed `true`
- validation `0`

Iteration path:

`91/141/156-84 → 88/154/155-85 → 86/157/159-81 → stable 86/157/159-81`

PR #25 squash merge:

`cfdca8f63dfa6c91fd2432031e0e2c34a8101a06`

Final PR CI `33923631356`:

- analyzer PASS
- normal/non-canonical tests PASS
- direct candidate-selection causal test PASS
- M0–M18 runner PASS
- combined M19–M24 canonical runner PASS
- nested M19/M20/M21/M23 guards PASS
- artifact `0`
- 5 dakikalık timeout altında PASS

Aggregate transfer/hacim/borç yönü M24 için causal ürün invariant'ı sayılmaz.

### M25 — Save/Load + Kayıt Versiyonlama I — PASS

İlk save/load milestone'u temel `CareerEngine` sezon-sınırı checkpoint'i üzerinde çalışır.

Yeni çekirdek:

- `CareerCheckpoint`
- `CareerSimulationResult`
- `CareerEngine.simulateWithCheckpoint(...)`
- `CareerEngine.resume(...)`
- eski `CareerEngine.simulate(...)` API'si korunur
- `CareerSaveCodec`
- `saveVersion=1`
- canonical deterministic JSON
- FNV-1a 32-bit corruption checksum
- explicit `SaveLoadFailure`
- sentetik `v0 → v1` migration fixture

Checkpoint semantiği:

> kayıt state'i, **bir sonraki sezonun başlangıç state'idir**.

Taşınan state:

- orijinal `SimulationConfig`
- kariyer başlangıç tarihi
- tamamlanan sezon sayısı
- baseline club strengths
- next-season club state

Canonical seed `20260903` kabul testi:

`20 sezon kesintisiz` ile `8 sezon → save → load → 12 sezon resume` karşılaştırılır.

Karşılaştırma fixture/match seviyesindedir:

- season index/seed
- champion
- club strengths
- fixture skorları
- expected goals
- match seed
- final report clubs
- next checkpoint clubs

Sonuçların tamamı birebir eşittir.

M25 runner kabul çıktısı:

- save version `1`
- checksum `536de64d`
- save boyutu `1039 bytes`
- loaded next season index `8`
- loaded next season date `2034-07-01`
- season replay match `true`
- final report clubs match `true`
- next checkpoint clubs match `true`
- legacy fixture `v0 → v1`

Doğrulanmış runner CI `33925868414`:

- analyzer PASS
- `87` normal/non-canonical test PASS
- 6 M25 save/load testi PASS
- M0–M18 runner PASS
- combined M19–M24 canonical runner PASS
- M25 save/load runner PASS
- M24 canonical baseline değişmedi
- artifact `0`
- timeout `5 dk` içinde PASS

Checksum yalnız accidental corruption detection içindir; kriptografik güvenlik/anti-cheat değildir.

**M25 tam M24 world save değildir.** Player/economy/contracts/loans/installments/manager/president state'in tam snapshot'ı M26 ve devam milestone'larına bırakılmıştır.

Ayrıntı:

`M25_SAVE_LOAD_KAYIT_VERSIYONLAMA_I.md`

## 7. Başkan trait durumu — M25 sonrası

M17'de tanımlanan beş trait'in tamamı gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

M25 yeni trait davranışı eklemedi; uzun kariyer kayıt güvenilirliğine geçti.

## 8. Canonical feedback tablosu

Seed `20260903`, 20 sezon:

| Milestone | Iterasyon | Reelected/Lost | Manager | Transfer | Hacim |
|---|---:|---:|---:|---:|---:|
| M19 | 4 | `160/80` | 84 | 168 | — |
| M20 | 5 | `158/82` | 83 | 153 | `1.387,32M` |
| M21 | 4 | `150/90` | 80 | 161 | `1.461,55M` |
| M23 | 5 | `156/84` | 85 | 133 | `1.201,05M` |
| M24 | 4 | `159/81` | 86 | 157 | `1.417,94M` |

## 9. CI ve kalite politikası

Tek workflow:

- `dart analyze`
- `dart test --exclude-tags canonical-feedback`
- M0 100-season batch
- M1–M18 ayrı headless runner
- tek en yeni profile-feedback runner nested M19+ canonical guard'ları birlikte doğrular
- M25 save/load continuation runner

Current canonical profile runner:

`tool/run_m24_president_youth_orientation_feedback.dart 20260903`

Current save runner:

`tool/run_m25_save_load.dart 20260903`

Kurallar:

- artifact `0`
- `actions/upload-artifact` yok
- timeout `5 dk`
- canonical full-career testler duplicate çalıştırılmaz
- neutral profile path eski signature'ı korur
- save/load resume kesintisiz kariyerle aynı deterministic sonucu üretir
- future save version güvenli reddedilir
- migration fixture test edilir

## 10. Reddedilen / ertelenen fikirler

- 3D maç motoru — ilk sürüm kapsamı dışında
- online multiplayer — ilk sürüm kapsamı dışında
- gerçek kulüpler/futbolcular/lisanslı logolar — kullanılmayacak
- FM seviyesinde detaylı taktik/antrenman — başkanlık kimliğine aykırı
- aşırı kiralık/taksit pazarı — M8 kalibrasyonlarında reddedildi
- fan trust'ın dar `46..68` bandı — M9'da reddedildi
- 847 medya açıklaması/960 club-season — M10'da fazla yüksek bulundu
- başkan profilinin beş trait'ini aynı milestone'da dünyaya bağlama — causal izlenebilirlik için reddedildi
- aggregate world sonucu tek trait'in causal yönüymüş gibi yorumlama — yasaklandı
- M25 içinde tam advanced world save kapsamını tek seferde çözmek — migration/kapsam riskini gereksiz büyüteceği için ertelendi
- checksum'u kriptografik güvenlik/anti-cheat gibi sunmak — reddedildi

## 11. Açık teknik sınırlar / borçlar

- Current M19+ çözümü literal tek-pass sezon orkestratörü değil; fixed-point replay'dir.
- M25 save yalnız temel `CareerEngine` sezon-sınırı state'ini kapsar; tam advanced world snapshot henüz yok.
- Player/economy/contracts/loan/installment/manager/president state'in save kapsamı M26+ konusudur.
- Gerçek cihaz dosya sistemi ve cloud save daha sonra.
- Otomatik save/yedek save slot politikası henüz platform katmanına bağlanmadı.
- Altyapı tesis yatırımının youth intake kalitesine etkisi henüz yok.
- Sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı.
- Seçim kaybında kullanıcı kariyerinin game-over / başka kulübe geçiş UX'i henüz yok.

## 12. M26 — sıradaki milestone

### World Save Snapshot I

Amaç M25'in doğrulanmış format/sürüm/migration temelini gerçek sezon-sınırı dünya state'ine genişletmektir.

İlk öncelik adayları:

1. league/club assignment
2. club finance state
3. player roster/lifecycle state
4. player contracts
5. transfer installment obligations
6. active loan agreements
7. manager assignment

President/reputation/election timeline aynı milestone'a aşırı kapsam yaratırsa ayrı M27 takip milestone'una bırakılabilir.

M26 kabul kuralı:

> **world save → load → devam, aynı seed'deki kesintisiz world simülasyonuyla birebir deterministic sonuç üretmelidir.**

M26 ilk aşamada yine şunları kapsamayacak:

- Android dosya seçici
- cloud save
- Google Play Games save
- çoklu kullanıcı hesabı
- save slot UI
- encryption/anti-cheat

Önce gerçek world state snapshot sözleşmesi.

## 13. Ana uzun vadeli teknik hedef

UI'dan bağımsız çekirdeğin:

- 48 kulüp
- 3 lig
- oyuncu yaşam döngüsü
- ekonomi
- manager
- kontrat
- transfer/loan/installment
- taraftar/media/promise
- seçim/başkan profili
- versioned save/load + migration

ile **20–30 sezonu deterministik ve migration-safe biçimde** sürdürebilmesi.

Sonrasında 100/500/1000 kariyer batch QA genişletilecek.
