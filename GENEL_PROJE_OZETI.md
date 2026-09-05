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
- ilerleyen aşamalarda altyapı, tesis, sponsor ve krizler
- uzun vadeli kulüp sağlığı

Football Manager benzeri maç içi taktik yönetimi yapılmaz. Oyuncu diziliş, antrenman, dakika bazlı oyuncu değişikliği veya duran top planlamaz.

Gerçek kulüp, futbolcu, logo veya lisanslı materyal kullanılmaz.

## 2. Geliştirme stratejisi

Futbol Başkanlık Simülatörü diğer aktif ZMila Studio projelerini aksatmadan sağlam altyapı milestone'larıyla ilerletilir.

Şu aşamada görsel ekran veya APK ana hedef değildir.

> **Önce sağlam, deterministik, uzun kariyerde otomatik test edilebilir simülasyon çekirdeği.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo public tutulur; kaynak kod açık kaynak lisansı altında değildir (`LICENSE.md`).

Codex gereksiz tüketilmez. Büyük çok-dosyalı refactor/test/migration işlerinde gerekirse kullanılır; çekirdek milestone'ların önemli bölümü doğrudan GitHub araçlarıyla yürütülür.

## 3. Güncel teknik durum

**M0–M26 PASS ve `main` üzerindedir. M27 davranış/test kabulü PASS; PR #28 final dokümantasyon/merge kapısındadır.**

M25 PR #26 squash merge:

`c46d5fc99655476f389de82d861ce7a5e6a93aec`

M25 merge sonrası `main` CI:

`33929524537` — PASS

M25 kapanış dokümantasyon `main` CI:

`33929813791` — PASS

M26 PR #27 final HEAD:

`311dc8be015aba571c1ef06995e953d750f46fe4`

M26 final PR CI:

`33930624622` — PASS

M26 PR #27 squash merge:

`c721588f998f5d29495c8074d956e48e306a1dc8`

M26 merge sonrası `main` CI:

`33930915685` — PASS

M26 canonical kapanış docs commit:

`a4c089ed361f08269c030cf8d1ef5bf32a6b83cd`

M26 kapanış docs CI:

`33932488669` — PASS, artifact `0`

M27 açık PR:

`#28 — M27: add advanced runtime save snapshot`

M27 ilk tam kabul CI:

`33933116072` — PASS

Bu koşuda:

- analyzer PASS
- `102` normal/non-canonical test PASS
- M0–M18 runner zinciri PASS
- combined M19–M24 canonical profile feedback PASS
- M25 save/load continuation PASS
- M26 world save continuation PASS
- M27 advanced runtime save continuation PASS
- artifact `0`
- timeout `5 dk` altında PASS

Aktif milestone:

> **M27 — Advanced World Runtime Snapshot I / final docs + merge kapısı**

M27 temiz merge edilirse sıradaki milestone:

> **M28 — Save History Compaction / Historical Memory Policy I**

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
- M25 `CareerCheckpoint` tabanlı temel sezon-sınırı save/resume
- M26 `WorldCheckpoint` tabanlı core world save/resume
- M27 `AdvancedRuntimeCheckpoint` tabanlı hook/controller runtime save/resume
- ayrı `CareerSaveCodec`, `WorldSaveCodec`, `AdvancedWorldSaveCodec`
- `saveVersion=1` + canonical JSON + corruption checksum
- explicit save failure kodları + migration fixture altyapısı
- restore constructor'ları ile controller state tekrar initial üretim yapmadan devam eder
- eski public `WorldCareerEngine.simulate()` semantiği korunur
- checkpoint-capable world yolu segment sonu offseason'u hazırlayarak gerçek next-season opening state üretir
- checkpoint-capable `WorldCareerEngine` API'si optional hook'ları kabul eder; default Noop path M26 davranışını korur
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
22. Save snapshot yalnız sahibi olduğu runtime state'i serileştirir; farklı controller/hook katmanlarının state'i tek milestone'a zorla yığılmaz.
23. Eski public simülasyon API'sinin davranışı save/checkpoint eklenirken sessizce değiştirilmez.
24. Segment bazlı world save gerçek next-season opening state üretmelidir; final offseason checkpoint yolunda eksik bırakılamaz.
25. Advanced runtime snapshot kapsamı controller/hook state sahipliğine göre katmanlandırılır; tek milestone'a tüm kariyer state'i zorla yığılmaz.
26. Checkpoint yalnız temiz sezon sınırında alınır; manager gibi sezon-içi pending state save sözleşmesine sızdırılmaz.
27. Continuation-critical state ile yalnız tarihçe/raporlama için tutulan append-only state aynı şey sayılmaz; save boyutu büyüyorsa bu ayrım ayrıca tasarlanır.
28. Yeni historical subsystem eklenmeden önce 20–30 sezon save büyümesi ölçülür ve kontrollü tutulur.

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

Universal prosperity veya universal collapse yaratan kalibrasyonlar reddedildi.

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

Kabul baseline:

- 140 permanent transfer
- 68 installment deal
- 478 loan
- final active loans `32`
- installment commitment `234,79M`
- loan fees `113,15M`
- validation `0`

Aşırı kiralık/taksit üreten ilk kalibrasyonlar reddedildi.

### M9 — Taraftar beklentisi + güven — PASS

- bağlamsal expectation
- sporting / financial / transfer / identity trust
- neden kodları

İlk `46..68` trust bandı fazla sıkışık olduğu için reddedildi.

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

İlk modelin 960 club-season'ın 847'sinde açıklama üretmesi fazla yüksek bulundu.

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

### M22 — Profile Feedback Orchestration I — PASS

Davranış değiştirmeyen performans/refactor milestone'u.

- ortak `tool/profile_feedback_canonical_guard.dart`
- full canonical testler `canonical-feedback` tag
- normal test `dart test --exclude-tags canonical-feedback`
- tek en yeni profile-feedback runner nested eski canonical guard'ları doğrular
- duplicate canonical runner tekrarları kaldırıldı

PR #23 merge:

`4ec358cf7131087176426ba5767ab4e4e65a36b3`

CI süresi M21 sonrası yaklaşık `6:10` seviyesinden güvenli olarak yaklaşık `2:51` seviyesine indirildi; timeout tekrar `5 dk` oldu.

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

Doğrudan causal invariant:

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

M24 yalnız candidate scoring içindeki bu signal'i ölçekler. Budget, transfer slotu, buyer max-bid, seller ask, installment acceptance, shortlist, pozisyon ihtiyacı, market value ve youth intake üretimi değişmez.

Doğrudan causal testte düşük yönelim `27 yaş / 79 ability` hazır oyuncuyu; yüksek yönelim `20 yaş / 72 ability / 92 potential` genç adayı ilk sıraya alır.

Canonical seed `20260903`:

- convergence `4`
- cycle `false`
- elections `240`
- reelected/lost `156/84 → 159/81`
- manager `85→86`
- transfers `133→157`
- volume `1.201,05M → 1.417,94M`
- installment deals `66→79`
- commitment `230,59M → 261,26M`
- cash `1.195,96M → 1.217,05M`
- debt `381,94M → 347,57M`
- emergency `189,81M → 144,39M`
- validation `0`

PR #25 squash merge:

`cfdca8f63dfa6c91fd2432031e0e2c34a8101a06`

Final PR CI `33923631356` PASS; artifact `0`.

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

Canonical seed `20260903`:

`20 sezon kesintisiz` ile `8 sezon → save → load → 12 sezon resume` fixture/match seviyesinde birebir eşittir.

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

PR #26 squash merge:

`c46d5fc99655476f389de82d861ce7a5e6a93aec`

Final branch CI `33926527304`: PASS.
Merge sonrası main CI `33929524537`: PASS.
Artifact `0`.

Ayrıntı: `M25_SAVE_LOAD_KAYIT_VERSIYONLAMA_I.md`

### M26 — World Save Snapshot I — PASS

M25'in save/version/migration temelini gerçek core world state'e genişletir.

Yeni çekirdek:

- `WorldCheckpoint`
- `WorldCareerSimulationResult`
- `WorldCareerEngine.simulateWithCheckpoint(...)`
- `WorldCareerEngine.resume(...)`
- `WorldSaveCodec`
- format `zmila-fbs-world`
- `saveVersion=1`
- canonical deterministic JSON
- FNV-1a corruption checksum
- explicit failure kodları
- sentetik `v0 → v1` migration

Snapshot state:

- orijinal `SimulationConfig`
- completed seasons / next season index
- 48 base club
- 3×16 next-season league membership
- next-season player/lifecycle state
- 48 club finance state

Kritik mimari karar:

Eski `WorldCareerEngine.simulate()` çağrının son sezonunda offseason hazırlamaz ve bu eski davranış korunur. Yeni checkpoint-capable yol ise segmentin final offseason'unu ayrıca hazırlayarak gerçek next-season opening state üretir.

Canonical seed `20260903`:

`20 sezon checkpoint-capable world` ile `8 sezon → world save → load → 12 sezon resume` birebir eşittir.

M26 runner kabul çıktısı:

- save version `1`
- checksum `0645c8a5`
- save boyutu `187664 bytes`
- loaded next season index `8`
- season replay match `true`
- final players match `true`
- final finance match `true`
- final leagues match `true`
- next checkpoint match `true`
- legacy fixture `v0 → v1`

M26 final PR CI `33930624622`: PASS.
PR #27 squash merge `c721588f998f5d29495c8074d956e48e306a1dc8`.
Merge sonrası `main` CI `33930915685`: PASS.
Canonical kapanış docs CI `33932488669`: PASS.
Tüm doğrulamalarda artifact `0`.

Ayrıntı: `M26_WORLD_SAVE_SNAPSHOT_I.md`

### M27 — Advanced World Runtime Snapshot I — DAVRANIŞ PASS / PR #28 FINAL KAPISI

M26 core world state'ini, gerçek hook/controller-owned sezonlar-arası state'e genişletir.

Yeni çekirdek:

- `AdvancedRuntimeCheckpoint`
- `AdvancedTransferRuntimeState`
- `ManagerRuntimeState`
- `AdvancedRuntimeSimulationResult`
- `AdvancedRuntimeCareerEngine`
- `AdvancedWorldSaveCodec`
- `PlayerContractController.restore(...)`
- `AdvancedTransferController.restore(...)`
- `ManagerCareerController.restore(...)`

M27 snapshot state:

- nested M26 `WorldCheckpoint`
- active contracts
- contract event history
- active loans
- loan history
- installment obligations
- manager pool
- 48 current manager assignment
- manager season history

Checkpoint yalnız temiz sezon sınırında üretilir; manager `_pending` state'i save'e yazılmaz ve restore sonrası boş başlar.

M26 `WorldCareerEngine.simulateWithCheckpoint(...)` ve `resume(...)` optional world/roster/finance/transfer hook parametreleri alacak şekilde genişletildi. Default Noop parametreler M26 davranışını birebir korur.

`AdvancedWorldSaveCodec`:

- format `zmila-fbs-advanced-world`
- save version `1`
- nested `WorldSaveCodec`
- canonical JSON
- FNV-1a corruption checksum
- future version rejection
- checksum-valid structural corruption rejection
- sentetik `v0 → v1` migration

Canonical seed `20260903`:

`20 sezon advanced runtime` ile `8 sezon → save → load → 12 sezon resume` birebir eşittir.

İlk tam PR CI `33933116072`:

- analyzer PASS
- `102` test PASS
- M0–M18 runner PASS
- M19–M24 canonical runner PASS
- M25 runner PASS
- M26 runner PASS
- M27 runner PASS
- artifact `0`
- timeout `5 dk` içinde PASS

M27 runner kabul çıktısı:

- save version `1`
- checksum `49e9d08e`
- save boyutu `1.013.092 bytes`
- split `8 + 12`
- loaded next season index `8`
- season replay match `true`
- final runtime checkpoint match `true`
- active contracts `897`
- contract events `3496`
- active loans `23`
- loan history `186`
- installment obligations `36`
- manager pool `96`
- manager assignments `48`
- manager seasons `8`
- legacy fixture `v0 → v1`

M27 bilinçli olarak şunları kapsamaz:

- president/reputation/election timeline
- fan/media/promise runtime memory
- Android file picker / save slot UI
- autosave/cloud save
- encryption/anti-cheat

Ayrıntı: `M27_ADVANCED_WORLD_RUNTIME_SNAPSHOT_I.md`

## 7. Başkan trait durumu — M27 sonrası

M17'de tanımlanan beş trait'in tamamı gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

M25–M27 yeni trait davranışı eklemedi; uzun kariyer kayıt güvenilirliği ve runtime restore katmanlarını kurdu.

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
- M26 world save continuation runner
- M27 advanced runtime save continuation runner

Current canonical profile runner:

`tool/run_m24_president_youth_orientation_feedback.dart 20260903`

Save runners:

- `tool/run_m25_save_load.dart 20260903`
- `tool/run_m26_world_save.dart 20260903`
- `tool/run_m27_advanced_runtime_save.dart 20260903`

Kurallar:

- artifact `0`
- `actions/upload-artifact` yok
- timeout `5 dk`
- canonical full-career testler duplicate çalıştırılmaz
- neutral profile path eski signature'ı korur
- save/load resume kesintisiz kariyerle aynı deterministic sonucu üretir
- future save version güvenli reddedilir
- migration fixture test edilir
- checksum-valid yapısal bozulma validator tarafından reddedilir
- checkpoint API eklenirken eski public simulation semantiği korunur
- save boyutu yeni runtime history eklendikçe ayrıca ölçülür

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
- M25 içinde tam advanced world save kapsamını tek seferde çözmek — migration/kapsam riskini gereksiz büyüttüğü için ertelendi
- checksum'u kriptografik güvenlik/anti-cheat gibi sunmak — reddedildi
- M26 içine kontrat + loan/installment + manager + president state'in tamamını zorla koymak — state sahipliği farklı controller/hook katmanlarında olduğu için reddedildi
- eski `WorldCareerEngine.simulate()` davranışını checkpoint uğruna değiştirmek — regresyon riski nedeniyle reddedildi
- M27 içine president/fan/media/promise history'nin tamamını da eklemek — save boyutu ve state sahipliği riski nedeniyle reddedildi
- M27'nin `1 MB+` save boyutunu görmezden gelip yeni append-only history katmanları eklemek — reddedildi

## 11. Açık teknik sınırlar / borçlar

- Current M19+ çözümü literal tek-pass sezon orkestratörü değil; fixed-point replay'dir.
- M25 save temel `CareerEngine` state'ini kapsar.
- M26 core `WorldCareerEngine` state'ini kapsar.
- M27 contract/loan/installment/manager runtime state'ini kapsar.
- President/reputation/election ve fan/media/promise runtime state henüz save kapsamına alınmadı.
- M27 8-sezon canonical save `1.013.092 bytes`; M26 aynı checkpoint `187.664 bytes`. Yaklaşık `5,4×` büyüme vardır.
- Ana büyüme kaynakları append-only `3496` contract event, `186` loan history ve manager season history kayıtlarıdır.
- Bu history'nin tamamı deterministic continuation için gerekli görünmemektedir; ancak ürün tarihçesi için kayıp yaşatmadan ayrı archive/summary policy gerekir.
- Gerçek cihaz dosya sistemi ve cloud save daha sonra.
- Otomatik save/yedek save slot politikası henüz platform katmanına bağlanmadı.
- Altyapı tesis yatırımının youth intake kalitesine etkisi henüz yok.
- Sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı.
- Seçim kaybında kullanıcı kariyerinin game-over / başka kulübe geçiş UX'i henüz yok.

## 12. M28 — sıradaki milestone

### Save History Compaction / Historical Memory Policy I

M27 correctness PASS olduktan sonra yeni runtime state eklemeden önce save boyutu mimari olarak kontrol altına alınacaktır.

Amaç:

> **Simulation continuation için gerçekten gerekli current state ile kullanıcıya rapor/tarihçe göstermek için tutulan historical state'i ayırmak.**

İlk çalışma alanları:

1. contract event history
2. loan history
3. manager season/change history

M28 kabul kriterleri:

- continuation-critical state açık olarak sınıflandırılacak
- historical state için compact/archive policy belirlenecek
- 20 sezon canonical save boyutu ölçülecek ve guard eklenecek
- compact save → load → resume, M27 full-history continuation ile aynı deterministic future world'ü üretmeli
- aktif contract/loan/installment/manager state kaybolmamalı
- kullanıcıya gerekli tarihçe için lossless veya kontrollü summary/archive sözleşmesi tanımlanmalı
- save version/migration güvenliği korunmalı
- M0–M27 baseline değişmemeli

M28 de platform depolaması değildir:

- Android file picker yok
- cloud save yok
- save slot UI yok
- encryption/anti-cheat yok

## 13. Uzun vadeli teknik yön

Save zinciri:

- M25: temel `CareerEngine` checkpoint — PASS
- M26: core `WorldCareerEngine` checkpoint — PASS
- M27: contract/loan/installment/manager advanced runtime checkpoint — davranış PASS / merge kapısı
- M28: save history compaction + historical memory policy
- M29 adayı: president/reputation/election runtime snapshot
- sonraki katman: fan/media/promise memory snapshot
- daha sonra platform save slotları, autosave/yedek politikası ve gerekirse cloud save

Uzun vadeli hedef, 20–30 sezonluk kariyerin tüm kritik state'iyle deterministic, migration-safe ve makul boyutta kaydedilip devam ettirilebilmesidir. Sonrasında 100/500/1000 kariyer batch QA genişletilecektir.