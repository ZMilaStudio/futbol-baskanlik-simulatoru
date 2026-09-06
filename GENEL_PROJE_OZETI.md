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

**M0–M32 PASS ve `main` üzerindedir.**

Son kapalı milestone: **M32 — Long-Career Save Growth / Resume Stress I**.

M32 kapanış:
- PR `#33` — MERGED
- final PR HEAD: `6aad9a828c7a14b307110a2c42243c79ca2ab1e6`
- final PR CI: run `34040555580`, job `101506407496` — SUCCESS
- squash merge commit: `e2db172feda810173b1710a37e53c7550823ba6f`
- merge sonrası `main` CI: run `34043191414`, job `101513506266` — SUCCESS
- analyzer PASS
- normal/non-canonical tests: `129` PASS
- M0–M32 runner zinciri PASS
- artifact `0`
- CI timeout `7 dk`

M32 canonical sonucu:
- stres kariyeri: `30 sezon`
- split zinciri: `6 + 7 + 9 + 8`
- checkpoint sezonları: `6, 13, 22, 30`
- save bytes: `793.813, 898.786, 741.371, 762.296`
- ilk → final büyüme: `-31.517 bytes`
- maksimum save: `898.786 bytes`
- final checkpoint == kesintisiz 30 sezon: PASS
- repeated encode/decode idempotency: PASS
- bounded save size: PASS
- final president states: `48`
- recent fan records: `96`
- recent media records: `96`
- season 30 manager pool: `117`
- season 22+ compact manager raw history: son `2 sezon`

M32 önemli düzeltmeleri:
- eski manager pool gerçekten tükendiğinde deterministic successor manager üretimi eklendi
- 20 sezon ve altındaki eski M27/M28 manager semantiği korunur
- 21+ sezon compact save’lerde manager raw season detail yalnız son 2 sezon tutulur
- all-time manager summary sayıları korunur
- long-career manager checkpoint validator contiguous suffix’i destekler
- future entrant manager `startAge` kariyer başlangıcındaki biyolojik yaş olarak doğrulanır

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

Ayrıntı:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`
- `M31_PRESIDENT_DOMAIN_RESUME_ORCHESTRATION_I.md`
- `M32_LONG_CAREER_SAVE_GROWTH_RESUME_STRESS_I.md`

## 5. Başkan trait durumu

Beş trait gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

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

## 9. Açık teknik borç / sıradaki yön

Artık world + advanced runtime + president domain için hem 20 sezon split-career continuation hem 30 sezon multi-checkpoint stress kanıtı vardır. Save büyümesi bounded kalır ve manager pool uzun kariyerde deterministic biçimde yenilenebilir.

Açık konular:
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- tesis yatırımının youth intake kalitesine etkisi henüz yok
- sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok
- long-career player/economy/manager denge metrikleri 30+ sezonda ayrıca ürün-balance milestone’u olarak sertleştirilebilir

Sıradaki mantıklı yön:

> **M33 adayı — Facilities / Academy Investment Core I**

Hedef:

> **Başkanın uzun vadeli yatırım kararını gerçek oyun sistemine bağlamak: tesis/altyapı harcaması nakit ve borcu etkilesin; altyapı seviyesi sonraki sezonların youth intake kalitesine deterministic ve ölçülebilir etki etsin; yatırım kararının kısa vadeli finansal bedeli ile uzun vadeli kadro faydası arasında gerçek başkanlık trade-off’u oluşsun.**
