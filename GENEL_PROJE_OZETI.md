# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 11 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

Değişmez ana kimlik:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Alternatif slogan:

> **Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.**

Başkanın alanı: ekonomi/nakit/borç, teknik direktör seçimi ve görev güvenliği, transfer stratejisi, sözleşme/maaş politikası, kiralık/taksit, taraftar güveni, medya hafızası, vaatler, seçimler, görev süresi ve tesis yatırımları. Football Manager benzeri maç içi taktik yönetimi yoktur. Gerçek kulüp/futbolcu/logo/lisanslı materyal kullanılmaz.

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Canonical seed: `20260903`

Dünya ölçeği:
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu

## 2. Geliştirme stratejisi

Öncelik deterministik, headless ve uzun kariyerde otomatik test edilebilir saf Dart simülasyon çekirdeğidir. Flutter/Android mobil kabuk daha sonra gelir.

Temel ilkeler:
- deterministik seed/replay
- cihaz saatinden bağımsız `GameDate`
- integer minor-unit `Money`
- headless runner + invariant/balance guard
- eski public simulation semantiği sessizce değiştirilmez
- save/load/resume determinism ve parity korunur
- explicit save version + migration + checksum
- future save version güvenli reddedilir
- migration fixture/test zorunludur
- continuation-critical state ile append-only historical state ayrılır
- history eklenmeden save büyümesi ölçülür
- PASS yalnız canlı CI kanıtıyla yazılır

## 3. CANLI DURUM — yeni sohbet buradan devam etmeli

**M0–M37 PASS ve `main` üzerindedir.**

Son kapalı ürün milestone'u:
**M37 — President Facility Decision Loop / Turnover Replanning I**.

### En son canlı `main` doğrulaması
- HEAD: `c02df87578a3fccccce6571b6fcdab0bc717528c`
- workflow run `34617969538` — **SUCCESS**
- `test` job `103324528411` — **SUCCESS**, yaklaşık `2m56s`
- `dart analyze`: **No issues found!**
- `dart test --exclude-tags canonical-feedback`: **147 tests passed**
- `canonical` job `103324528005` — **SUCCESS**, yaklaşık `4m25s`
- M0–M37 canonical runner zinciri: **PASS**
- artifacts: **0**
- bu doğrulama PR #40 sonrası paralel CI yapısının son `main` HEAD üzerinde de güvenli çalıştığını doğrular
- açık PR: **0**

### PR #40 — CI timeout remediation — CLOSED / MERGED

Kök sorun:
- `main` HEAD `14c37e4c3834e11e94435f4d6114ec8f6e52f78c`
- run `34614508900`, job `103312956069`
- `Analyze`, `Run tests`, M0–M37, `Post Checkout` ve `Complete job` adımlarının tamamı ayrı ayrı SUCCESS olmasına rağmen tek seri job yaklaşık `7m03s` sürdü ve sabit `7 dk` timeout nedeniyle overall `cancelled` oldu
- bu nedenle o HEAD yeşil kabul edilmedi

Düzeltme:
- branch: `ci/split-verification-jobs`
- PR `#40` — **MERGED**
- final PR HEAD: `ae5ab884dfdd10cd00a3ac86da835b562a9ed683`
- timeout **artırılmadı**; `timeout-minutes: 7` korundu
- hiçbir test veya canonical runner kaldırılmadı
- workflow iki paralel job'a ayrıldı:
  - `test`: checkout/setup/pub get + `dart analyze` + `dart test --exclude-tags canonical-feedback`
  - `canonical`: checkout/setup/pub get + M0–M37 runner zinciri
- `actions/upload-artifact` eklenmedi; artifact hedefi `0`
- simülasyon/save/runtime davranışında değişiklik yapılmadı

Final PR CI:
- run `34616348213` — **SUCCESS**
- `canonical` job `103319137873` — **SUCCESS**, yaklaşık `2m29s`
- `test` job `103319138074` — **SUCCESS**, yaklaşık `2m53s`
- analyzer SUCCESS
- 147 normal/non-canonical test PASS
- M0–M37 canonical runner zinciri PASS
- artifacts `0`

Squash merge:
- merge SHA: `cba4e28bef09d4109a10380b4808eb39b7c1ffb4`

Post-merge `main` CI:
- run `34617471052` — **SUCCESS**
- `canonical` job `103322872761` — **SUCCESS**, yaklaşık `3m00s`
- `test` job `103322873053` — **SUCCESS**, yaklaşık `2m53s`
- analyzer SUCCESS
- 147 normal/non-canonical test PASS
- M0–M37 runner zinciri PASS
- artifacts `0`
- sabit 7 dk timeout artık iki paralel job üzerinde geniş güvenlik marjıyla korunuyor

### PR #39 — M34 analyzer import temizliği — CLOSED / MERGED

- branch: `chore/cleanup-m34-analyzer-imports`
- PR `#39` — **MERGED**
- final PR HEAD: `c907cb9ca2c73047d7a82428dd52a5b51f648e77`
- yalnız M34 test/tool dosyalarındaki 10 adet `unnecessary_import` info bildirimi kaldırıldı
- final PR CI run `34612787096`, job `103307174934` — SUCCESS
- analyzer: `No issues found!`
- 147 test PASS
- M0–M37 PASS
- artifacts `0`
- squash merge SHA: `4d49b67973b96424c2c73b9f25e3a1b2d636c829`
- post-merge main CI run `34613733464`, job `103310367702` — SUCCESS
- analyzer temizliği sonrası simülasyon davranışı değişmedi

### M37 kapanış — President Facility Decision Loop / Turnover Replanning I

- PR `#38` — MERGED
- final PR HEAD: `0030caef1c292d4f1d249f9a8ed5a2abcca041fb`
- squash merge: `ff1745671ce57fdaa56b937bf36f026f86b34ca5`
- final PR CI run `34059375807`, job `101557067196` — SUCCESS
- post-merge main CI run `34113979981`, job `101716393026` — SUCCESS
- 147 test PASS
- M0–M37 PASS
- artifacts `0`

M37 davranışı:
- academy yatırım kararı tek explicit checkpoint yerine sezonluk president facility decision loop ile çalışır
- her sezon mevcut başkan profiline göre academy target, upgrade intensity ve cash reserve yeniden hesaplanır
- başkan değişiminde yeni profile göre yatırım planı yeniden yapılır
- downgrade yoktur
- gerçek M34 cash/affordability yolu korunur; gizli borç yaratılmaz
- facility-aware offseason youth lifecycle mevcut lifecycle'ı delegate eder
- decision history derived tutulur; save büyümesine yeni persisted history eklenmez
- explicit orchestration çağrılmadıkça eski/default public simulation semantiği değişmez

M37 canonical:
- start checkpoint: season `8`
- club: `t3_05`
- turnover season: `9`
- decision windows: `2`
- presidents: cautious → youth-builder
- target levels: `0 → 5`
- applied upgrades: `0 → 2`
- academy path: `0→0`, `0→2`
- turnover replanned: `true`
- split decisions match: `true`
- youth history match: `true`
- final checkpoint match: `true`

## 4. Save/runtime/facility zinciri

### M25 — Save/Load + Versioning I — PASS
- temel checkpoint, canonical JSON/checksum/migration
- `8 + 12 == 20`

### M26 — World Save Snapshot I — PASS
- 48 club/leagues/players/finance
- canonical save `187.664 bytes`
- `8 + 12 == 20`

### M27 — Advanced World Runtime Snapshot I — PASS
- contracts/loans/installments/manager runtime
- season-8 `1.013.092 bytes`
- `8 + 12 == 20`

### M28 — Save History Compaction I — PASS
- son 2 sezon contract/loan detail + all-time summary
- season-8 `1.013.092 → 736.274 bytes`
- `%27,3` küçülme
- season-20 compact save `915.648 bytes`
- `8 + 12 == 20`

### M29 — President Runtime Snapshot I — PASS
- current president tenure/profile/fan/media/election cursor
- 48 club state
- season-8 `754.721 bytes`

### M30 — Fan / Media / Promise Runtime Memory Snapshot I — PASS
- son 2 sezon raw fan/media detail
- all-time bounded summary
- current-term promise memory
- season-8 `802.906 bytes`

### M31 — President Domain Resume Orchestration I — PASS
- M30 checkpoint'ten gerçek president-domain resume
- saved tenure/fan/media/election cursor
- saved current-term promise scores
- canonical `8 + 12 == 20`
- mid-term `5 + 3` PASS

### M32 — Long-Career Save Growth / Resume Stress I — PASS
- 30 sezon stress
- multi-checkpoint `6 + 7 + 9 + 8`
- her checkpoint encode/decode
- final state uninterrupted 30 sezon ile birebir aynı
- save `<1.300.000 bytes`
- first→final growth `-31.517 bytes`
- 20 sezon sonrası manager detail compaction
- deterministic manager pool replenishment

### M33 — Facilities / Academy Investment Core I — PASS
- academy level `0..5`
- youthOrientation → academy target policy
- deterministic youth ability/potential bonus
- level 0 legacy youth davranışını korur
- level 5 ability/potential uplift canonical olarak kanıtlandı

### M34 — Facility Persistence / Finance Orchestration I — PASS
- 48 academy facility state persistent
- upgrade cost gerçek club cash'ten düşer
- yetersiz nakitte state değişmez / gizli borç yok
- versioned/checksummed facility save
- v0→v1 migration
- canonical save `214.737 bytes`
- save/load/resume facility + finance continuity PASS

### M35 — Academy Runtime Youth Integration I — PASS
- persistent academy level gerçek offseason lifecycle'a enjekte edilir
- level 0 legacy world resume ile birebir aynı
- canonical level 2 delta: ability `+1,20`, potential `+3,60`
- save/load/resume youth history direct continuation ile eşleşir
- final facility/world checkpoint eşleşir

### M36 — President Youth Orientation → Academy Investment Orchestration I — PASS
- `youthOrientation` gerçek academy target + yatırım yoğunluğunu belirler
- yüksek youth profile daha agresif upgrade yapar
- `financialDiscipline` protected cash reserve üretir
- gerçek cash/affordability path korunur
- canonical academy `0 → 2`, spend `9,00M`
- save/load/resume youth history + final checkpoint eşleşir

### M37 — President Facility Decision Loop / Turnover Replanning I — PASS
- sezonluk facility decision loop
- başkan profiline göre target/intensity/reserve recompute
- turnover replanning
- downgrade yok
- gerçek cash finance path korunur
- decision history derived
- split save/load/resume parity + multi-president turnover kanıtlandı

Ayrıntı dosyaları:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`
- `M31_PRESIDENT_DOMAIN_RESUME_ORCHESTRATION_I.md`
- `M32_LONG_CAREER_SAVE_GROWTH_RESUME_STRESS_I.md`
- `M34_FACILITY_PERSISTENCE_FINANCE_ORCHESTRATION_I.md`
- `M35_ACADEMY_RUNTIME_YOUTH_INTEGRATION_I.md`
- `M36_PRESIDENT_YOUTH_ACADEMY_INVESTMENT_ORCHESTRATION_I.md`
- `M37_PRESIDENT_FACILITY_DECISION_LOOP_TURNOVER_REPLANNING_I.md`

## 5. Başkan trait durumu

Beş trait gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget + academy cash reserve | M20 + M36 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference + academy target + gerçek academy yatırım yoğunluğu | M24 + M33 + M36 + M37 |

## 6. Milestone geçmişi

M0–M37 PASS.

- M0 Deterministik sezon çekirdeği
- M1 20 sezon kariyer
- M2 Oyuncu yaşam döngüsü
- M3 Ekonomi
- M4 Transfer pazarı
- M5 48 kulüp / 3 lig
- M6 Teknik direktör
- M7 Sözleşme + maaş
- M8 Kiralık + taksit
- M9 Taraftar
- M10 Medya hafızası
- M11 Başkan vaatleri
- M12 Vaat → taraftar
- M13 Vaat → medya
- M14 Başkanlık seçimi
- M15 Görev süresi + devir
- M16 Başkan devrinde itibar
- M17 Yönetim profili
- M18 Manager patience
- M19 Manager/world ↔ election fixed-point
- M20 Financial discipline
- M21 Transfer ambition
- M22 Profile feedback orchestration
- M23 Risk appetite
- M24 Youth orientation
- M25 Save/load
- M26 World snapshot
- M27 Advanced runtime snapshot
- M28 History compaction
- M29 President runtime snapshot
- M30 Fan/media/promise runtime memory
- M31 President domain resume orchestration
- M32 Long-career save/resume stress
- M33 Facilities / Academy Investment Core I
- M34 Facility Persistence / Finance Orchestration I
- M35 Academy Runtime Youth Integration I
- M36 President Youth Orientation → Academy Investment Orchestration I
- M37 President Facility Decision Loop / Turnover Replanning I

## 7. Kalıcı teknik kurallar

- deterministic seed/replay
- device-clock-independent `GameDate`
- integer minor-unit `Money`
- headless runner + invariant/balance guard
- deterministic fixed-point profile feedback
- convergence/cycle detection
- neutral trait eski davranışı korur
- checkpoint bir sonraki sezonun opening state'idir
- explicit save version + migration + checksum
- future version güvenli reddedilir
- migration fixture/test zorunludur
- eski public simulation semantiği sessizce değiştirilmez
- continuation-critical state ile append-only historical state ayrılır
- history eklenmeden save growth ölçülür
- ilk 20 sezon canonical manager davranışı korunur
- 21+ sezon manager history compact olabilir ama all-time summary kaybolmaz
- facility level 0 legacy youth generation davranışını korur
- facility yatırımı gerçek cash ile finanse edilir; gizli borç yok
- persistent academy gerçek offseason youth generation'a etki eder
- facility-aware continuation mevcut lifecycle'ı delegate eder
- president academy investment gerçek facility finance path'ini kullanır
- `financialDiscipline` academy yatırımında protected cash reserve üretir
- PASS yalnız canlı CI kanıtıyla yazılır
- artifact hedefi `0`
- `actions/upload-artifact` kullanılmaz
- CI timeout her job için `7 dk`; yavaşlığı gizlemek için artırılmaz

## 8. CI politikası — güncel

Ana workflow iki paralel job kullanır:

### `test`
- checkout
- Dart setup
- `dart pub get`
- `dart analyze`
- `dart test --exclude-tags canonical-feedback`

### `canonical`
- checkout
- Dart setup
- `dart pub get`
- M0–M18 runner zinciri
- combined M19–M24 canonical runner
- M25 save/load
- M26 world save
- M27 advanced runtime save
- M28 history compaction
- M29 president runtime snapshot
- M30 president domain memory snapshot
- M31 president domain resume
- M32 long-career save/resume stress
- M33 facilities/academy investment core
- M34 facility persistence/finance orchestration
- M35 academy runtime youth integration
- M36 president youth academy investment orchestration
- M37 president facility decision loop/turnover replanning

Her job:
- `timeout-minutes: 7`
- artifact `0`
- `actions/upload-artifact` yok

PR #40 post-merge main kanıtı:
- run `34617471052`
- `test` `103322873053` SUCCESS
- `canonical` `103322872761` SUCCESS

## 9. Açık ürün yönleri

Yeni milestone otomatik varsayılmamalıdır. Sonraki ürün kapsamı kullanıcı yönlendirmesiyle seçilmelidir.

### 11 Eylül 2026 devam denetimi — ürün kapsamı henüz seçilmedi
- canlı `main`: `c02df87578a3fccccce6571b6fcdab0bc717528c`; CI SUCCESS; açık PR yok
- `lib/src/facility` bugün dört academy-odaklı parçadan oluşur: `academy_facility.dart`, `facility_investment_orchestrator.dart`, `president_academy_investment_orchestrator.dart`, `president_facility_decision_loop.dart`
- `FacilityRuntimeCheckpoint` yalnız `academyFacilities` state'ini persist eder; generic stadium/training-ground state henüz yoktur
- `finance` altyapısı mevcut ve M34 gerçek cash yatırım yoluyla facility harcamasını doğrulamıştır
- ayrı bir sponsor veya kriz domain klasörü/modülü yoktur; bu yönler daha çapraz ve sıfırdan sistem işi gerektirir
- teknik öneri: kullanıcı tesis genişlemesini seçerse **stadium + training-ground facility ailesi**, mevcut persistence/finance/decision-loop altyapısını en az riskle yeniden kullanabilecek doğal devam hattıdır
- bu teknik öneri **yeni milestone seçimi değildir**; milestone numarası/başlığı kullanıcı ürün yönünü seçmeden oluşturulmaz

Açık seçenekler:
- stadium + training-ground facility ailesi — teknik olarak en doğal devam önerisi
- sponsor sistemi
- kriz sistemi
- Android file system / save-slot UI / autosave / backup / cloud save
- seçim kaybında game-over / başka kulübe geçiş UX'i
- 30+ sezon player/economy/manager balance sertleştirmesi

Kapatılmış teknik borçlar:
- M34 10 adet `unnecessary_import` — PR #39 ile kapandı
- tek-job 7 dk CI kritik yolu — PR #40 ile iki paralel job'a ayrılarak kapandı

## 10. DEVRALMA / ÇALIŞMA TALİMATI

Bu dosyayı okuyan başka bir ChatGPT/Codex oturumu projeyi yarım bırakmadan devralabilmelidir.

Zorunlu çalışma biçimi:
1. Önce `GENEL_PROJE_OZETI.md` ve ilgili milestone dokümanlarını oku.
2. Eski sohbet anlatımlarını canlı GitHub durumunun yerine koyma. `main`, PR, commit ve Actions sonuçlarını canlı kontrol et.
3. Bir milestone'ı CLOSED/PASS saymadan önce ilgili `main` CI run/job sonucunu canlı doğrula.
4. CI başarısızsa gerçek failure logunu çıkar; varsayım yapma; kök nedeni düzelt; yeni branch/PR aç; test et; kullanıcı onayı olmadan merge etme.
5. CI yeşilse artifact `0` olduğunu doğrula; ilgili kapanış dokümanını ve bu özeti canlı kanıtla güncelle.
6. Her milestone'da M0–önceki milestone davranışını koru.
7. Determinism, save/load/resume parity, migration, invariant ve balance guard'larını koru.
8. CI timeout `7 dk` sabittir. Performans sorununu gizlemek için artırma; workflow/runner'ı optimize et.
9. `actions/upload-artifact` ekleme; artifact hedefi `0`.
10. Kullanıcı açıkça onay vermeden PR merge etme.
11. Kullanıcı `Devam et` dediğinde araçlarla gerçek işi ilerlet; yalnız hard blocker varsa dur.
12. Her kapanan milestone için ilgili kapanış `.md` dosyasını ve bu özeti güncelle; kapanışı canlı CI kanıtına bağla.
13. Yeni milestone'a başlamadan önce ürün kapsamını otomatik seçme ve gereksiz refactor yapma.
14. Kod değişikliklerinde minimum, hedefli ve test edilebilir yaklaşım kullan.
15. Bu proje sohbetinde her kullanıcı mesajından sonra, assistant yanıtı tamamlanmadan önce `GENEL_PROJE_OZETI.md` güncel tutulur. Yeni teknik durum/karar yoksa dosya gereksiz tekrarlarla şişirilmez; ancak yeni kararlar, CI kanıtları, commit/PR durumu ve aktif çalışma kuralları korunur.

### Geçici devir tamamlandı

`DEVRALMA_1_AYLIK_GPT.md` tamamen okundu, kalıcı kuralları bu özette korunmaktadır ve geçici dosya repo'dan kaldırılmıştır.

Canlı GitHub durumu her zaman eski sohbet notlarından üstündür.