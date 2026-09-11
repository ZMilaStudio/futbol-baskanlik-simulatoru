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

### `main`

**M0–M37 PASS ve `main` üzerindedir.**

Son kapalı ürün milestone'u:
**M37 — President Facility Decision Loop / Turnover Replanning I**.

En son M38 öncesi canlı `main` HEAD:
- `db1ad3d688b903f6fd295f74ed1f4c242b5d716d`
- commit: `docs: record continuation audit and next-scope recommendation`
- workflow run `34618873499` — **SUCCESS**
- `test` job `103327537619` — **SUCCESS**
- `canonical` job `103327537294` — **SUCCESS**
- analyzer/test ve M0–M37 zinciri yeşil
- artifacts hedefi `0`

### M38 — Facility Portfolio Core I — ACTIVE / PR-VALIDATED

Kullanıcı seçimiyle sonraki ürün yönü **stadium + training ground facility ailesi** olarak belirlendi.

Branch:
- `feat/m38-facility-portfolio-core`

PR:
- `#41` — **OPEN**
- başlık: `M38: facility portfolio core with stadium and training ground`
- kullanıcı açık merge onayı olmadan merge edilmeyecek

Code-bearing HEAD:
- `5bbcfa85b1abc9f56bdef7704577cc46e20636b8`

İlk PR CI run `34620543693` analyzer'da yalnız iki gereksiz test importu nedeniyle kırmızı oldu. Gerçek logdan kök neden çıkarıldı; `stadium_facility.dart` ve `training_ground_facility.dart` test importları kaldırıldı. Simülasyon davranışı değiştirilmedi.

Düzeltilmiş code-bearing PR CI:
- run `34620636024` — **SUCCESS**
- `test` job `103333639427` — **SUCCESS**, yaklaşık `2m54s`
- `dart analyze`: **No issues found!**
- normal/non-canonical test: **152 PASS**
- `canonical` job `103333639253` — **SUCCESS**, yaklaşık `3m33s`
- M0–M38 canonical runner zinciri: **PASS**
- artifacts: **0**
- iki job da sabit `7 dk` timeout sınırının rahat altında

M38 kapsamı:
- 48 kulübün tamamında persistent `academy + stadium + training ground` state
- stadium level `0..5`
- training-ground level `0..5`
- stadium/training upgrade maliyeti gerçek club cash'ten düşer
- upgrade sırasında gizli debt yaratılmaz
- yetersiz nakitte state değişmez
- stadium gerçek `matchdayRevenue` hattına bağlanır
- training ground gerçek offseason player-development hattına bağlanır
- training yalnız pozitif gelişim delta'sını artırır; yaşa bağlı gerilemeyi tersine çevirmez
- level `0` legacy davranışı korur
- eski academy yatırım API'si korunur ve yeni facility state'lerini silmez
- facility save formatı `v2`
- `v0 → v1 → v2` ve `v1 → v2` migration
- eski save'lerde stadium/training level `0` ile neutral açılır
- full portfolio save/load/resume parity korunur
- president-driven automatic stadium/training yatırım kararı M38 kapsamı dışındadır

M38 canonical:
- seed: `20260903`
- investment checkpoint: season `8`
- club: `t3_05`
- stadium: `0 → 1`
- training ground: `0 → 1`
- total spend: `9.00M`
- immediate cash delta: `9.00M`
- debt unchanged: `true`
- matchday revenue: `3.49M → 3.75M`
- stadium revenue raised: `true`
- training player: `y_t3_05_s4`
- ability: `57.4905 → 57.5290`
- training development raised: `true`
- save version: `2`
- save bytes: `217572`
- v1 migration neutral: `true`
- direct vs save-load resume: `true`
- final canonical result: **PASS**

Kalıcı M38 dokümanı:
- `M38_FACILITY_PORTFOLIO_CORE_I.md`

M38 henüz `main` üzerinde CLOSED/PASS değildir. Kapanış için PR #41 merge + post-merge `main` CI + artifact `0` doğrulaması gerekir.

### PR #40 — CI timeout remediation — CLOSED / MERGED

- branch: `ci/split-verification-jobs`
- PR `#40` — MERGED
- final PR HEAD: `ae5ab884dfdd10cd00a3ac86da835b562a9ed683`
- squash merge: `cba4e28bef09d4109a10380b4808eb39b7c1ffb4`
- timeout artırılmadı; her job `7 dk`
- test/canonical kapsamı azaltılmadı
- workflow `test` ve `canonical` olarak iki paralel job'a ayrıldı
- `actions/upload-artifact` yok
- post-merge main run `34617471052` SUCCESS
- docs-close HEAD `c02df87578a3fccccce6571b6fcdab0bc717528c` run `34617969538` SUCCESS
- analyzer temiz, 147 test, M0–M37 PASS, artifacts 0

### PR #39 — M34 analyzer import temizliği — CLOSED / MERGED

- PR `#39` — MERGED
- final PR HEAD `c907cb9ca2c73047d7a82428dd52a5b51f648e77`
- 10 redundant M34 import kaldırıldı
- squash merge `4d49b67973b96424c2c73b9f25e3a1b2d636c829`
- analyzer `No issues found!`
- davranış değişmedi

### M37 kapanış — President Facility Decision Loop / Turnover Replanning I

- PR `#38` — MERGED
- final PR HEAD `0030caef1c292d4f1d249f9a8ed5a2abcca041fb`
- squash merge `ff1745671ce57fdaa56b937bf36f026f86b34ca5`
- final PR CI `34059375807` SUCCESS
- post-merge main CI `34113979981` SUCCESS
- 147 test PASS
- M0–M37 PASS
- artifacts 0

M37 davranışı:
- sezonluk academy facility decision loop
- başkan profiline göre target/intensity/reserve recompute
- turnover anında replanning
- downgrade yok
- gerçek M34 cash path; gizli borç yok
- derived decision history
- save/load/resume parity

M37 canonical:
- start season `8`
- club `t3_05`
- turnover season `9`
- decision windows `2`
- target `0 → 5`
- applied upgrades `0 → 2`
- academy path `0→0`, `0→2`
- turnover replanned `true`
- split decisions match `true`
- youth history match `true`
- final checkpoint match `true`

## 4. Save/runtime/facility zinciri

### M25 — Save/Load + Versioning I — PASS
- temel checkpoint/version/checksum/migration
- `8 + 12 == 20`

### M26 — World Save Snapshot I — PASS
- 48 club/leagues/players/finance
- canonical `187664 bytes`
- `8 + 12 == 20`

### M27 — Advanced World Runtime Snapshot I — PASS
- contracts/loans/installments/manager runtime
- season-8 `1013092 bytes`
- `8 + 12 == 20`

### M28 — Save History Compaction I — PASS
- season-8 `1013092 → 736274 bytes`
- reduction `%27.3`
- season-20 `915648 bytes`
- continuation parity korunur

### M29 — President Runtime Snapshot I — PASS
- 48 current president state + election cursor
- season-8 `754721 bytes`

### M30 — Fan / Media / Promise Runtime Memory Snapshot I — PASS
- bounded raw/current-term memory
- season-8 `802906 bytes`

### M31 — President Domain Resume Orchestration I — PASS
- canonical `8 + 12 == 20`
- mid-term `5 + 3` PASS

### M32 — Long-Career Save Growth / Resume Stress I — PASS
- 30 sezon
- `6 + 7 + 9 + 8`
- final uninterrupted 30 sezon ile birebir aynı
- max save `<1.3M bytes`
- first→final `-31517 bytes`

### M33 — Facilities / Academy Investment Core I — PASS
- academy level `0..5`
- level 0 legacy youth davranışı
- academy youth ability/potential uplift

### M34 — Facility Persistence / Finance Orchestration I — PASS on `main`
- 48 academy state
- gerçek cash-funded upgrade
- yetersiz nakitte mutation yok / gizli borç yok
- `main` baseline facility save v1: `214737 bytes`
- save/load/resume parity

M38 branch'te facility save portfolio v2'ye yükselmiştir:
- v2 save: `217572 bytes`
- academy M34 davranışı/parity aynı PR CI içinde tekrar PASS

### M35 — Academy Runtime Youth Integration I — PASS
- persistent academy gerçek offseason youth generation'a etki eder
- level 0 legacy resume eşitliği
- canonical level2: ability `+1.20`, potential `+3.60`
- save/load/resume parity

### M36 — President Youth Orientation → Academy Investment Orchestration I — PASS
- youthOrientation → academy target/intensity
- financialDiscipline → protected cash reserve
- canonical academy `0 → 2`, spend `9M`
- parity korunur

### M37 — President Facility Decision Loop / Turnover Replanning I — PASS
- seasonal decision loop
- turnover replanning
- no downgrade
- real cash finance path
- derived history
- split parity

### M38 — Facility Portfolio Core I — PR-VALIDATED
- academy + stadium + training-ground portfolio
- stadium gerçek matchday revenue etkisi
- training ground gerçek positive player-development etkisi
- level0 legacy semantics
- real cash / no hidden debt
- facility save v2 + v0/v1 migration
- 152 test
- M0–M38 canonical PASS on PR #41
- `main` kapanışı bekleniyor

Ayrıntı dosyaları:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`
- `M31_PRESIDENT_DOMAIN_RESUME_ORCHESTRATION_I.md`
- `M32_LONG_CAREER_SAVE_GROWTH_RESUME_STRESS_I.md`
- `M34_FACILITY_PERSISTENCE_FINANCE_ORCHESTRATION_I.md`
- `M35_ACADEMY_RUNTIME_YOUTH_INTEGRATION_I.md`
- `M36_PRESIDENT_YOUTH_ACADEMY_INVESTMENT_ORCHESTRATION_I.md`
- `M37_PRESIDENT_FACILITY_DECISION_LOOP_TURNOVER_REPLANNING_I.md`
- `M38_FACILITY_PORTFOLIO_CORE_I.md`

## 5. Başkan trait durumu

Beş trait gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget + academy cash reserve | M20 + M36 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference + academy target + academy investment intensity | M24 + M33 + M36 + M37 |

M38 stadium/training yatırımları henüz president trait'lerine otomatik bağlanmamıştır; bu bilinçli scope sınırıdır.

## 6. Milestone geçmişi

`main`: **M0–M37 PASS**.

PR #41: **M38 PR-VALIDATED**, henüz main'de değil.

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
- M38 Facility Portfolio Core I — ACTIVE / PR #41

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
- facility level 0 legacy davranışı korur
- facility yatırımı gerçek cash ile finanse edilir; gizli borç yok
- persistent academy gerçek offseason youth generation'a etki eder
- stadium etkisi yalnız facility-aware runtime'da gerçek matchday revenue hattına bağlanır
- training-ground etkisi yalnız facility-aware runtime'da pozitif player-development delta'sına bağlanır
- training ground negatif gelişim/yaşa bağlı düşüşü tersine çevirmez
- facility-aware continuation mevcut lifecycle/economy motorlarını delegate eder
- president academy investment gerçek facility finance path'ini kullanır
- `financialDiscipline` academy yatırımında protected cash reserve üretir
- PASS yalnız canlı CI kanıtıyla yazılır
- artifact hedefi `0`
- `actions/upload-artifact` kullanılmaz
- CI timeout her job için `7 dk`; yavaşlığı gizlemek için artırılmaz
- kullanıcı açık onayı olmadan PR merge edilmez

## 8. CI politikası — güncel

Ana workflow iki paralel job kullanır.

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
- M25–M32 save/runtime runner'ları
- M33 academy facility core
- M34 facility persistence/finance
- M35 academy runtime youth
- M36 president academy investment
- M37 president facility decision loop
- M38 facility portfolio core — PR #41 branch'te ekli

Her job:
- `timeout-minutes: 7`
- artifact hedefi `0`
- `actions/upload-artifact` yok

M38 code-bearing PR kanıtı:
- run `34620636024`
- `test` `103333639427` SUCCESS
- `canonical` `103333639253` SUCCESS
- analyzer `No issues found!`
- 152 tests PASS
- M0–M38 PASS
- artifacts 0

## 9. Açık ürün yönleri

Aktif seçilmiş yön:
- **M38 Facility Portfolio Core I — stadium + training ground** — PR #41 açık, merge bekliyor

M38 sonrasında otomatik seçilmemesi gereken açık yönler:
- president-driven stadium/training investment policy / facility decision loop extension
- Android file system / save-slot UI / autosave / backup / cloud save
- sponsor sistemi
- kriz sistemi
- seçim kaybında game-over / başka kulübe geçiş UX'i
- 30+ sezon player/economy/manager balance sertleştirmesi
- stadium capacity/attendance gibi daha ayrıntılı tesis ekonomisi

Kapatılmış teknik borçlar:
- M34 10 adet `unnecessary_import` — PR #39
- tek-job 7 dk CI kritik yolu — PR #40 ile iki paralel job

## 10. DEVRALMA / ÇALIŞMA TALİMATI

Bu dosyayı okuyan başka bir ChatGPT/Codex oturumu projeyi yarım bırakmadan devralabilmelidir.

Zorunlu çalışma biçimi:
1. Önce `GENEL_PROJE_OZETI.md` ve ilgili milestone dokümanlarını oku.
2. Eski sohbet anlatımlarını canlı GitHub durumunun yerine koyma. `main`, PR, commit ve Actions sonuçlarını canlı kontrol et.
3. Bir milestone'ı CLOSED/PASS saymadan önce ilgili `main` CI run/job sonucunu canlı doğrula.
4. CI başarısızsa gerçek failure logunu çıkar; varsayım yapma; kök nedeni düzelt; branch/PR üzerinde test et; kullanıcı onayı olmadan merge etme.
5. CI yeşilse artifact `0` olduğunu doğrula; ilgili milestone dokümanını ve bu özeti canlı kanıtla güncelle.
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
