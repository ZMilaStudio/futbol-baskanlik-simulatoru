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

**M0–M34 PASS ve `main` üzerindedir.**

Son kapalı milestone: **M34 — Facility Persistence / Finance Orchestration I**.

M34 kapanış:
- PR `#35` — MERGED
- final PR HEAD: `a7adc874dd0ded55b2e87635508449fcf4aae786`
- PR CI: run `34048550465`, job `101527918362` — SUCCESS
- squash merge commit: `89fc20e663aacb96e75881528492ed2f0edf33f8`
- merge sonrası `main` CI: run `34049690296`, job `101530927660` — SUCCESS
- analyzer PASS
- normal/non-canonical tests: `137` PASS
- M0–M34 runner zinciri PASS
- artifact `0`
- CI timeout `7 dk`

M34 canonical sonucu:
- investment checkpoint season: `8`
- investment club: `t3_05`
- academy level: `2`
- yatırım harcaması: `9,00M`
- gerçek kasa düşüşü: `9,00M`
- save version: `1`
- save size: `214.737 bytes`
- academy facility records: `48`
- resume sonrası tamamlanan sezon: `20`
- facility state preserved: `true`
- direct continuation == save/load/resume: `true`
- finance-funded facility persistence: PASS

M34 kapsamı:
- 48 kulübün academy facility state'i persistent checkpoint zincirinde
- academy upgrade bedeli gerçek `ClubFinanceState.cash` üzerinden düşülüyor
- yetersiz nakitte yatırım uygulanmıyor ve gizli borç üretilmiyor
- cumulative facility investment spend saklanıyor
- versioned/checksummed save + synthetic v0→v1 migration
- save/load/resume facility + finance continuity
- public API export + test + canonical runner + CI gate

M34'te bilinçli olarak ertelenen:
- persisted academy level henüz full world career engine içindeki her offseason youth-intake üretimine end-to-end enjekte edilmiyor
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

### M34 — Facility Persistence / Finance Orchestration I — PASS
- 48 academy facility state persistent
- upgrade cost gerçek club cash'ten düşüyor
- yetersiz nakitte state değişmiyor / gizli borç yok
- versioned/checksummed facility save
- v0→v1 migration
- canonical save `214.737 bytes`
- save/load/resume facility state + finance continuity PASS

Ayrıntı:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`
- `M31_PRESIDENT_DOMAIN_RESUME_ORCHESTRATION_I.md`
- `M32_LONG_CAREER_SAVE_GROWTH_RESUME_STRESS_I.md`
- `M34_FACILITY_PERSISTENCE_FINANCE_ORCHESTRATION_I.md`

## 5. Başkan trait durumu

Beş trait gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference + academy target policy | M24 + M33 |

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

## 9. Açık teknik borç / sıradaki yön

Artık world + advanced runtime + president domain için 20 sezon split-career continuation ve 30 sezon multi-checkpoint stress kanıtı vardır. Save büyümesi bounded kalır. Academy facility level gerçek persistent state'e ve gerçek kulüp kasasına bağlanmıştır; save/load/resume sonrasında facility ve finance continuity kanıtlanmıştır.

Açık konular:
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- persisted academy level henüz full world career engine'de offseason youth intake üretimini end-to-end değiştirmiyor
- stadium / training-ground facility türleri henüz yok
- sponsor ve kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok
- long-career player/economy/manager denge metrikleri 30+ sezonda ayrıca ürün-balance milestone’u olarak sertleştirilebilir

Sıradaki mantıklı yön:

> **M35 adayı — Academy Runtime Youth Integration I**

Hedef:

> **M34'te persistent hale gelen academy facility level'i gerçek world/offseason player lifecycle akışına bağlamak; yatırım yapılan kulübün sonraki youth intake kalitesi persisted level'e göre değişmeli ve save/load/resume sonrası aynı kariyerle birebir deterministik kalmalıdır.**
