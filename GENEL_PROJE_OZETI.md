# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 6 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

Değişmez ana kimlik:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Alternatif slogan:

> **Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.**

Başkanın alanı: ekonomi/nakit/borç, teknik direktör seçimi ve görev güvenliği, transfer stratejisi, sözleşme/maaş politikası, kiralık/taksit, taraftar güveni, medya hafızası, vaatler, seçimler ve görev süresi. Football Manager benzeri maç içi taktik yönetimi yoktur. Gerçek kulüp/futbolcu/logo/lisanslı materyal kullanılmaz.

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

**M0–M35 PASS ve `main` üzerindedir.**

Son kapalı milestone: **M35 — Academy Runtime Youth Integration I**.

M35 kapanış:
- PR `#36` — MERGED
- final PR HEAD: `ca72c880f68543321c5ce03d9bfe11166dd40c0e`
- PR CI: run `34050440949`, job `101532971925` — SUCCESS
- squash merge commit: `20fc9636ff2993eede5667365d34c722f23aadc2`
- merge sonrası `main` CI: run `34056184347`, job `101548394932` — SUCCESS
- analyzer PASS
- normal/non-canonical tests: `140` PASS
- M0–M35 runner zinciri PASS
- artifact `0`
- CI timeout `7 dk`

M35 canonical sonucu:
- investment checkpoint season: `8`
- investment club: `t3_05`
- academy level: `2`
- baseline youth ability: `52,93`
- upgraded youth ability: `54,13`
- ability delta: `+1,20`
- baseline youth potential: `69,69`
- upgraded youth potential: `73,29`
- potential delta: `+3,60`
- resume sonrası tamamlanan sezon: `20`
- youth history match: `true`
- final checkpoint match: `true`
- academy runtime youth integration: PASS

M35 kapsamı:
- M34'te persistent olan academy facility level gerçek offseason `PlayerLifecycleEngine` akışına bağlandı
- persisted academy level gerçek deterministic youth intake kalitesini değiştiriyor
- ayrı/ikinci youth generator oluşturulmadı
- academy level 0 legacy world resume davranışını birebir koruyor
- save/load/resume youth history ve final facility/world checkpoint direct continuation ile eşleşiyor
- mevcut custom player-lifecycle davranışı delegation ile korunuyor
- test + canonical runner + CI gate eklendi

M35 ile kapanan M34 açığı:
- academy facility state artık yalnız save/finance verisi değil; gerçek kariyer offseason youth üretimine end-to-end etki ediyor

M35'te bilinçli olarak ertelenen:
- `youthOrientation` trait'inin persistent academy yatırım kararını otomatik sürmesi
- stadium / training-ground facility türleri
- Flutter/Android tesis yönetim ekranları

Canlı GitHub durumu her zaman eski sohbet notlarından üstündür.

## 4. Save/runtime zinciri

### M25 — Save/Load + Versioning I — PASS
- temel checkpoint
- canonical JSON / checksum / migration
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
- M30 checkpoint’inden gerçek president-domain resume
- saved tenure/fan/media/election cursor
- saved current-term promise scores
- bounded history continuation
- canonical `8 + 12 == 20`
- mid-term `5 + 3` resume PASS

### M32 — Long-Career Save Growth / Resume Stress I — PASS
- 30 sezon president-domain stress
- multi-checkpoint `6 + 7 + 9 + 8`
- her checkpoint’te encode/decode
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

Ayrıntı:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`
- `M31_PRESIDENT_DOMAIN_RESUME_ORCHESTRATION_I.md`
- `M32_LONG_CAREER_SAVE_GROWTH_RESUME_STRESS_I.md`
- `M34_FACILITY_PERSISTENCE_FINANCE_ORCHESTRATION_I.md`
- `M35_ACADEMY_RUNTIME_YOUTH_INTEGRATION_I.md`

## 5. Başkan trait durumu

Beş trait gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference + academy target policy | M24 + M33 |

Not: academy target policy vardır; bu target'ın gerçek persistent yatırım kararına otomatik uygulanması henüz yapılmamıştır.

## 6. Milestone geçmişi — kısa

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
- PASS yalnız canlı CI kanıtıyla yazılır
- artifact hedefi `0`
- `actions/upload-artifact` kullanılmaz
- CI timeout `7 dk`

## 8. CI politikası

Ana workflow:
- `dart analyze`
- `dart test --exclude-tags canonical-feedback`
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

## 9. Açık teknik borç / sıradaki yön

World + advanced runtime + president domain için 20 sezon split-career continuation ve 30 sezon multi-checkpoint stress kanıtı vardır. Save büyümesi bounded kalır. Academy facility artık gerçek persistent state'tir, gerçek kulüp kasasından finanse edilir ve gerçek offseason youth intake kalitesini değiştirir. Save/load/resume sonrası youth history deterministik olarak korunur.

Açık konular:
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- `youthOrientation` henüz academy yatırımını gerçek persistent kariyerde otomatik tetiklemiyor
- stadium / training-ground facility türleri henüz yok
- sponsor ve kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok
- long-career player/economy/manager denge metrikleri 30+ sezonda ayrıca ürün-balance milestone’u olarak sertleştirilebilir

Sıradaki mantıklı yön:

> **M36 adayı — President Youth Orientation → Academy Investment Orchestration I**

Hedef:

> **Başkanın `youthOrientation` trait'inden çıkan academy target level'i gerçek persistent facility yatırım kararına bağlamak; yatırım gerçek nakit/affordability kurallarına uymalı, başkan değişimlerinde yeni profile göre yön değiştirebilmeli ve save/load/resume sonrası kesintisiz kariyerle deterministik eşit kalmalıdır.**
