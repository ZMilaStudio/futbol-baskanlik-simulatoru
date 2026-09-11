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

## 2. Geliştirme stratejisi

Öncelik deterministik, headless ve uzun kariyerde otomatik test edilebilir saf Dart simülasyon çekirdeğidir. Flutter mobil kabuk daha sonra gelir.

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Canonical seed: `20260903`

Dünya ölçeği:
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu

## 3. CANLI DURUM — yeni sohbet buradan devam etmeli

**M0–M37 PASS ve `main` üzerindedir.**

Son kapalı milestone: **M37 — President Facility Decision Loop / Turnover Replanning I**.

### Bakım kapanışı — M34 analyzer import temizliği
- canlı `main` başlangıç SHA: `08d99227c5a0dd96c91c61a046472bdbf9625ebd`
- branch: `chore/cleanup-m34-analyzer-imports`
- PR `#39` — **MERGED**
- final PR HEAD: `c907cb9ca2c73047d7a82428dd52a5b51f648e77`
- amaç: M34 test/tool dosyalarında analyzer tarafından raporlanan 10 adet `unnecessary_import` info bildirimini davranış değiştirmeden kaldırmak
- etkilenen dosyalar: `test/m34_facility_persistence_finance_test.dart`, `test/m34_facility_save_migration_test.dart`, `tool/run_m34_facility_persistence_finance.dart`
- değişiklik yalnız redundant `src/...` importlarının kaldırılmasıdır; kullanılan semboller public `package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart` export'u üzerinden sağlanmaya devam eder
- final PR CI run `34612787096`, job `103307174934` — **SUCCESS**
- PR CI `dart analyze`: **No issues found!**
- PR CI `dart test --exclude-tags canonical-feedback`: **147 tests passed**
- PR CI M0–M37 runner zinciri: **PASS**
- PR CI artifacts: **0**
- final PR CI job süresi yaklaşık `4m54s`; sabit `7 dk` timeout sınırının altındadır
- squash merge SHA: `4d49b67973b96424c2c73b9f25e3a1b2d636c829`
- merge sonrası `main` CI run `34613733464`, job `103310367702` — **SUCCESS**
- `main` CI `dart analyze`: **No issues found!**
- `main` CI `dart test --exclude-tags canonical-feedback`: **147 tests passed**
- `main` CI M0–M37 runner zinciri: **PASS**
- M34 finance-funded facility persistence: **PASS**
- M37 split decisions / youth history / final checkpoint parity: **true / true / true**
- `main` CI artifacts: **0**
- `main` CI job süresi yaklaşık `5m34s`; sabit `7 dk` timeout sınırının altındadır
- M34 analyzer import teknik borcu kapanmıştır; simülasyon davranışında değişiklik yapılmamıştır

### Aktif CI timeout iyileştirmesi — PR #40
- güncel canlı `main` SHA: `14c37e4c3834e11e94435f4d6114ec8f6e52f78c`
- bu SHA için `main` CI run `34614508900`, job `103312956069` overall **CANCELLED**
- job `15:10:12–15:17:15` aralığında yaklaşık `7m03s` sürdüğü için sabit `7 dk` timeout sınırını birkaç saniye aştı
- bu run'da `Analyze`, `Run tests`, M0–M37 runner adımlarının tamamı, `Post Checkout` ve `Complete job` ayrı ayrı **SUCCESS** oldu; ancak overall job cancelled olduğu için güncel `main` HEAD yeşil kabul edilmez
- kök neden: analyzer + 147 normal/non-canonical test + M0–M37 canonical zincirinin tek job içinde seri çalışması ve runner performans varyansı için yeterli süre marjı bırakmaması
- timeout **artırılmadı**; `timeout-minutes: 7` korunuyor
- branch: `ci/split-verification-jobs`
- PR `#40` — **OPEN / MERGE EDİLMEDİ**
- ilk PR HEAD: `7a5827fb0d603d46a055c65a9050390915f327f6`
- workflow iki paralel 7 dakikalık job'a ayrıldı: `test` = analyze + 147 test; `canonical` = M0–M37 runner zinciri
- hiçbir test veya canonical runner kaldırılmadı; simülasyon/save/runtime davranışında değişiklik yok
- ilk PR CI run `34615466603`
- `test` job `103316169383` — **SUCCESS**, yaklaşık `2m55s`; `dart analyze`: **No issues found!**; **147 tests passed**
- `canonical` job `103316169041` — **SUCCESS**, yaklaşık `4m18s`; M0–M37 runner zinciri **PASS**
- canonical log M34: finance-funded facility persistence **PASS**
- canonical log M37: turnover replanned `true`; split decisions / youth history / final checkpoint parity = **true / true / true**
- PR CI artifacts: **0**
- paralel yapı ilk doğrulamada eski `~7m03s` kritik yolu `~4m18s` seviyesine indirip yaklaşık `2m42s` timeout marjı sağladı
- PR #40 merge için kullanıcı açık onayı zorunludur; son PR HEAD CI yeniden yeşil doğrulanmadan merge edilmez

### M37 kapanış
- PR `#38` — MERGED
- final PR HEAD: `0030caef1c292d4f1d249f9a8ed5a2abcca041fb`
- PR CI: run `34059375807`, job `101557067196` — SUCCESS
- `147` normal/non-canonical test PASS
- M0–M37 runner zinciri PASS
- artifact `0`
- ilk CI'da 7 dk workflow timeout nedeniyle overall cancelled olmuş ancak tüm test adımları SUCCESS; timeout yükseltilmemiştir
- test runner optimize edilerek final PR CI `4m22s` içinde yeşil tamamlanmıştır
- squash merge sonrası main SHA: `ff1745671ce57fdaa56b937bf36f026f86b34ca5`
- merge sonrası main CI: run `34113979981`, job `101716393026` — **SUCCESS**
- main CI `dart test --exclude-tags canonical-feedback`: **147 tests passed**
- main CI M0–M37 runner zinciri: **PASS**
- main CI artifact: **0**
- main CI M37 deterministic continuation: split decisions / youth history / final checkpoint parity = **true / true / true**
- main CI job süresi yaklaşık `4m49s`; 7 dk timeout sınırının altındadır
- `dart analyze` adımı SUCCESS; bu tarihsel M37 kapanış logunda failure olmayan 10 adet `unnecessary_import` info bildirimi vardı; bunlar daha sonra PR `#39` ile temizlenmiştir
- devir kapanış commit'i: `ce155658128b4b6b9a7ba6377d61730f97c6bf5e`
- devir kapanış commit'i CI: run `34609665300`, job `103296681707` — **SUCCESS**
- kapanış commit'i CI: **147 tests passed**, M0–M37 runner zinciri PASS, artifact `0`
- kapanış commit'i job süresi yaklaşık `6m58s`; 7 dk timeout sınırının altındadır

M37 amacı:
- academy yatırım kararını tek explicit checkpoint'ten çıkarıp sezonluk president facility decision loop'a bağlamak
- her sezonda 48 kulübün mevcut başkan profiline göre academy hedefi, upgrade yoğunluğu ve cash reserve'ü yeniden hesaplamak
- başkan değişiminde yeni profile göre bir sonraki yatırım penceresini otomatik yeniden planlamak
- downgrade yapmamak
- mevcut M34 gerçek-cash finance yolunu korumak; gizli borç yaratmamak
- yatırım penceresini facility-aware offseason youth lifecycle'dan önce çalıştırmak
- decision history'yi derived tutarak save büyümesini artırmamak
- split save/load/resume ile decision sequence, youth history ve final facility/world checkpoint'ın kesintisiz continuation ile eşleştiğini kanıtlamak
- orchestration explicit çağrılmadıkça eski/default simulation semantiğini değiştirmemek

M37 canonical sonucu:
- başlangıç season: `8`
- kulüp: `t3_05`
- başkan değişimi: season `9`
- decision window: `2`
- eski başkan profili: cautious
- yeni başkan profili: youth-builder
- academy hedefi: `0 → 5`
- uygulanan upgrade: `0 → 2`
- turnover replanning: `true`
- decision sequence parity: `true`
- youth history parity: `true`
- final checkpoint parity: `true`

### M36 kapanış
- PR `#37` — MERGED
- final PR HEAD: `67a1996202a4fca6c6b9fc3998c18f0ac5daa1ba`
- PR CI `34057110415`, job `101550909615` — SUCCESS
- squash merge `545a0c10345cbf12826c2bf615c5a5a20d2e99db`
- merge sonrası main CI `34057573190`, job `101552160184` — SUCCESS
- 144 normal/non-canonical test PASS
- M0–M36 runner zinciri PASS
- artifact 0

M36 canonical: season8, `t3_05`, youthOrientation 90, financialDiscipline 60, target5, cap2, reserve1500bps, academy 0→2, spend9.00M, resume20, youth history/final checkpoint parity true.

Canlı GitHub durumu her zaman eski sohbet notlarından üstündür. **Bir milestone'ı CLOSED/PASS saymadan önce canlı main CI kanıtını kontrol et.**

## 4. Save/runtime/facility zinciri

### M25 — Save/Load + Versioning I — PASS
- temel checkpoint, canonical JSON/checksum/migration
- `8 + 12 == 20`

### M26 — World Save Snapshot I — PASS
- 48 club / leagues / players / finance
- canonical save `187.664 bytes`
- `8 + 12 == 20`

### M27 — Advanced World Runtime Snapshot I — PASS
- contracts / loans / installments / manager runtime
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
- M30 checkpoint'inden gerçek president-domain resume
- saved tenure/fan/media/election cursor
- saved current-term promise scores
- bounded history continuation
- canonical `8 + 12 == 20`
- mid-term `5 + 3` resume PASS

### M32 — Long-Career Save Growth / Resume Stress I — PASS
- 30 sezon president-domain stress
- multi-checkpoint `6 + 7 + 9 + 8`
- her checkpoint'te encode/decode
- final state kesintisiz 30 sezonla birebir aynı
- save boyutu `<1.300.000 bytes`
- ilk → final büyüme `-31.517 bytes`
- 20 sezondan sonra manager detail compaction
- manager pool tükenmesine deterministic replenishment

### M33 — Facilities / Academy Investment Core I — PASS
- academy level `0..5`
- youthOrientation → academy target policy
- deterministic youth ability/potential bonus
- level 0 legacy youth davranışını korur
- level 5 canonical ortalamada ability/potential artışı kanıtlandı

### M34 — Facility Persistence / Finance Orchestration I — PASS
- 48 academy facility state persistent
- upgrade cost gerçek club cash'ten düşüyor
- yetersiz nakitte state değişmiyor / gizli borç yok
- versioned/checksummed facility save
- v0→v1 migration
- canonical save `214.737 bytes`
- save/load/resume facility state + finance continuity PASS

### M35 — Academy Runtime Youth Integration I — PASS
- persistent academy level gerçek offseason lifecycle'a enjekte edilir
- level 0 legacy world resume ile birebir aynı
- academy level gerçek generated youth ability/potential'ı değiştirir
- canonical level 2 delta: ability `+1,20`, potential `+3,60`
- save/load/resume youth history direct continuation ile eşleşir
- final facility/world checkpoint eşleşir

### M36 — President Youth Orientation → Academy Investment Orchestration I — PASS
- `youthOrientation` → gerçek academy target + yatırım yoğunluğu
- yüksek youth profile aynı kulüpte daha agresif upgrade yapar
- `financialDiscipline` protected cash reserve üretir
- gerçek cash/affordability yolu korunur
- canonical academy `0 → 2`, spend `9,00M`
- save/load/resume youth history + final checkpoint eşleşir

### M37 — President Facility Decision Loop / Turnover Replanning I — PASS
- sezonluk/periodik facility decision loop
- her sezon başkan profiline göre target/upgrade intensity/reserve recompute
- başkan değişiminde turnover replanning
- downgrade yok
- gerçek cash finance path korunur
- decision history derived; save growth'a yeni persisted history eklenmez
- split save/load/resume parity + multi-president turnover kanıtı
- post-merge `main` CI run `34113979981` / job `101716393026` SUCCESS
- canonical split decisions, youth history ve final checkpoint parity = true
- artifact 0

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

## 6. Milestone geçmişi — kısa

M0–M37 PASS.

- M0 Deterministik sezon çekirdeği — PASS
- M1 20 sezon kariyer — PASS
- M2 Oyuncu yaşam döngüsü — PASS
- M3 Ekonomi — PASS
- M4 Transfer pazarı — PASS
- M5 48 kulüp / 3 lig — PASS
- M6 Teknik direktör — PASS
- M7 Sözleşme + maaş — PASS
- M8 Kiralık + taksit — PASS
- M9 Taraftar — PASS
- M10 Medya hafızası — PASS
- M11 Başkan vaatleri — PASS
- M12 Vaat → taraftar — PASS
- M13 Vaat → medya — PASS
- M14 Başkanlık seçimi — PASS
- M15 Görev süresi + devir — PASS
- M16 Başkan devrinde itibar — PASS
- M17 Yönetim profili — PASS
- M18 Manager patience — PASS
- M19 Manager/world ↔ election fixed-point — PASS
- M20 Financial discipline — PASS
- M21 Transfer ambition — PASS
- M22 Profile feedback orchestration — PASS
- M23 Risk appetite — PASS
- M24 Youth orientation — PASS
- M25 Save/load — PASS
- M26 World snapshot — PASS
- M27 Advanced runtime snapshot — PASS
- M28 History compaction — PASS
- M29 President runtime snapshot — PASS
- M30 Fan/media/promise runtime memory — PASS
- M31 President domain resume orchestration — PASS
- M32 Long-career save/resume stress — PASS
- M33 Facilities / Academy Investment Core I — PASS
- M34 Facility Persistence / Finance Orchestration I — PASS
- M35 Academy Runtime Youth Integration I — PASS
- M36 President Youth Orientation → Academy Investment Orchestration I — PASS
- M37 President Facility Decision Loop / Turnover Replanning I — PASS

## 7. Kalıcı teknik kurallar

- deterministic seed/replay
- cihaz saatinden bağımsız `GameDate`
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
- history eklenmeden save büyümesi ölçülür
- ilk 20 sezonun canonical manager davranışı korunur
- 21+ sezon compact manager history bounded tutulabilir; all-time summary kaybolmaz
- facility level 0 eski youth-generation davranışını korur
- facility yatırımı gerçek cash ile finanse edilir; yetersiz nakitte gizli borç yaratılmaz
- persistent academy level gerçek offseason youth generation'a etki eder
- facility-aware continuation ayrı bir youth generator kurmaz; mevcut lifecycle davranışını delegate eder
- president academy investment gerçek facility finance path'ini kullanır
- `financialDiscipline` academy investment sırasında protected cash reserve üretir
- PASS yalnız canlı CI kanıtıyla yazılır
- artifact hedefi `0`
- `actions/upload-artifact` kullanılmaz
- CI timeout `7 dk`; performans sorununu gizlemek için artırılmaz

## 8. CI politikası

`main` üzerindeki mevcut workflow bu kayıt anında analyzer/test/canonical zincirini tek seri job'da çalıştırmaktadır; güncel `main` HEAD bu nedenle runner varyansında 7 dakika sınırını birkaç saniye aşarak cancelled olmuştur.

PR `#40` ile önerilen ve PR CI'da doğrulanan yapı:
- iki paralel job: `test` ve `canonical`
- her iki job için `timeout-minutes: 7`
- `test`: `dart analyze` + `dart test --exclude-tags canonical-feedback`
- `canonical`: M0–M18 runner zinciri, combined M19–M24 canonical runner ve M25–M37 zinciri
- hiçbir doğrulama kaldırılmaz
- artifact üretimi eklenmez
- ilk PR doğrulaması: test `~2m55s`, canonical `~4m18s`, ikisi de SUCCESS

Canonical kapsam:
- M0–M18 runner zinciri
- combined M19–M24 canonical runner
- M25 save/load
- M26 world save
- M27 advanced runtime save
- M28 history compaction
- M29 president runtime snapshot
- M30 president domain memory snapshot
- M31 president domain resume orchestration
- M32 long-career save/resume stress
- M33 facilities / academy investment core
- M34 facility persistence / finance orchestration
- M35 academy runtime youth integration
- M36 president youth investment orchestration
- M37 president facility decision loop / turnover replanning

## 9. Açık teknik borç / sıradaki yön

M0–M37 davranışları için canlı PASS kanıtı vardır. M37 post-merge `main` CI run `34113979981`, job `101716393026` SUCCESS; `147` normal/non-canonical test PASS; M0–M37 runner zinciri PASS; artifact `0`; save/load/resume decision/youth/final checkpoint parity true.

**Güncel `main` HEAD `14c37e4c3834e11e94435f4d6114ec8f6e52f78c` için en son run `34614508900` / job `103312956069` overall CANCELLED'dır.** Bütün test/runner adımları SUCCESS olsa da sabit 7 dk sınırı yaklaşık 3 saniye aşılmıştır; bu nedenle güncel main CI yeşil sayılmaz. PR `#40` bu aktif teknik borcu timeout artırmadan iki paralel job'a bölerek düzeltmektedir ve ilk PR CI doğrulaması başarılıdır. Merge için kullanıcı onayı beklenir.

Açık ürün konuları:
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- stadium / training-ground facility türleri henüz yok
- sponsor ve kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok
- long-career player/economy/manager denge metrikleri 30+ sezonda ayrıca ürün-balance milestone'u olarak sertleştirilebilir
- academy/facility karar döngüsünün daha geniş facility türlerine yayılması sonraki ürün kararıdır

Kapatılan bakım: M34 test/tool importlarındaki 10 adet `unnecessary_import` bildirimi PR `#39` ile temizlendi. Squash merge `4d49b67973b96424c2c73b9f25e3a1b2d636c829`; post-merge `main` CI run `34613733464` / job `103310367702` SUCCESS; analyzer `No issues found!`; 147 test; M0–M37 PASS; artifact 0.

Yeni milestone otomatik varsayılmamalıdır. Sonraki ürün kapsamı kullanıcı yönlendirmesiyle seçilmelidir.

## 10. DEVRALMA / ÇALIŞMA TALİMATI

Bu dosyayı okuyan başka bir ChatGPT/Codex oturumu projeyi **yarım bırakmadan** devralabilmelidir.

Zorunlu çalışma biçimi:
1. Önce `GENEL_PROJE_OZETI.md` ve ilgili milestone dokümanlarını oku.
2. Eski sohbet anlatımlarını canlı GitHub durumunun yerine koyma. `main`, PR, commit ve Actions sonuçlarını canlı kontrol et.
3. Bir milestone'ı CLOSED/PASS saymadan önce ilgili `main` CI run/job sonucunu canlı doğrula; eski doküman kaydı tek başına yeterli değildir.
4. CI başarısızsa gerçek failure logunu çıkar; varsayım yapma; kök nedeni düzelt; yeni branch/PR aç; test et; kullanıcı onayı olmadan merge etme.
5. CI yeşilse artifact `0` olduğunu doğrula; ilgili kapanış `.md` dosyasını ve bu özeti canlı kanıtla güncelle.
6. Her milestone'da M0–önceki milestone davranışını koru. Yeni özellik eklerken eski public simulation semantiğini sessizce değiştirme.
7. Determinism, save/load/resume parity, migration, invariant ve balance guard'larını koru.
8. CI timeout `7 dk` sabittir. Yavaş testleri gizlemek için timeout artırma; test runner'ı optimize et.
9. `actions/upload-artifact` ekleme; artifact hedefi `0`.
10. Kullanıcı açıkça onay vermeden PR merge etme.
11. Kullanıcı `Devam et` dediğinde küçük durum raporları vermek yerine araçları kullanarak gerçek işi ilerlet. Yalnız hard blocker varsa dur.
12. Her kapanan milestone için ilgili kapanış `.md` dosyasını ve bu özeti güncelle; kapanışı canlı CI kanıtına bağla.
13. Yeni milestone'a başlamadan önce ürün kapsamını ve mevcut runtime/save mimarisini bozacak gereksiz refactor yapma.
14. Kodda değişiklik yaparken minimum, hedefli ve test edilebilir değişiklik tercih et.
15. Bu proje sohbetinde her kullanıcı mesajından sonra, assistant yanıtı tamamlanmadan önce `GENEL_PROJE_OZETI.md` güncel tutulur. Yeni teknik durum/karar yoksa dosya gereksiz tekrarlarla şişirilmez; ancak yeni kararlar, CI kanıtları, commit/PR durumu ve aktif çalışma kuralları özet içinde korunur.

### Geçici devir tamamlandı

`DEVRALMA_1_AYLIK_GPT.md` tamamen okundu ve kalıcı kuralları bu özette korunmaktadır. M37 post-merge `main` CI canlı olarak doğrulandı; M37 kapanış dokümanı oluşturuldu. Geçici devir dosyası bu kapanış işlemiyle repo'dan kaldırılmıştır.
