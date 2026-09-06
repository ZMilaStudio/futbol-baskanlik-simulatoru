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

Başkanın alanı: ekonomi/nakit/borç, teknik direktör seçimi ve görev güvenliği, transfer stratejisi, sözleşme/maaş politikası, kiralık/taksit, taraftar güveni, medya hafızası, vaatler, seçimler ve görev süresi. İlerleyen aşamalarda altyapı, tesis, sponsor ve krizler eklenecek.

Football Manager benzeri maç içi taktik yönetimi yoktur. Gerçek kulüp/futbolcu/logo/lisanslı materyal kullanılmaz.

## 2. Geliştirme stratejisi

Öncelik görsel ekran veya APK değil; önce deterministik, headless ve uzun kariyerde otomatik test edilebilir saf Dart simülasyon çekirdeğidir. Flutter mobil kabuk daha sonra gelir.

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo public; açık kaynak lisansı yoktur (`LICENSE.md`).

Canonical seed: `20260903`

Dünya ölçeği:
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ekonomi
- oyuncu yaşam döngüsü
- kontrat
- transfer
- teknik direktör
- taraftar
- medya
- vaat
- seçim
- başkan profili

## 3. CANLI DURUM — yeni sohbet buradan devam etmeli

**M0–M30 PASS ve `main` üzerindedir.**

Son kapalı milestone: **M30 — Fan / Media / Promise Runtime Memory Snapshot I**.

M30 kapanış:
- PR `#31` — MERGED
- final PR HEAD: `acdb4a47d970fb11a007b0f85d7bd4f26dab806a`
- PR CI: run `34027937181`, job `101472145609` — SUCCESS
- squash merge commit: `f18b7850218c638f9692630509c03820d5652e5a`
- merge sonrası `main` CI: run `34033939065`, job `101488464335` — SUCCESS
- analyzer PASS
- normal/non-canonical tests: `125` PASS
- M0–M30 runner zinciri PASS
- artifact `0`
- CI timeout `7 dk`

M30 canonical ölçümü:
- completed seasons: `8`
- raw history seasons: `2`
- recent fan records: `96`
- recent media records: `96`
- current-term promises: `0` (season 8 election boundary)
- all-time fan reasons: `1195`
- all-time media statements: `217`
- all-time media contradictions: `7`
- all-time promises: `384`
- M29 president save: `754.721 bytes`
- M30 memory save: `802.906 bytes`
- memory overhead: `48.185 bytes`
- codec round-trip: PASS

Aktif teknik yön:

> **M31 adayı — President Domain Resume Orchestration I.**

Amaç, M30’da snapshot edilen president/fan/media/promise state’ini gerçek resume orchestration’a bağlayıp president-domain için split-career `8 + 12 == 20` kanıtı üretmektir.

Canlı GitHub durumu her zaman eski sohbet notlarından üstündür.

## 4. Save/runtime zinciri

### M25 — Save/Load + Kayıt Versiyonlama I — PASS
- temel `CareerCheckpoint`
- canonical JSON / checksum / versioning / migration
- canonical save `1.039 bytes`
- `8 + 12 == 20`

### M26 — World Save Snapshot I — PASS
- 48 base club
- 3×16 next-season league membership
- players + finance + config
- canonical save `187.664 bytes`
- `8 + 12 == 20`

### M27 — Advanced World Runtime Snapshot I — PASS
- contracts / loans / installments / manager runtime
- canonical season-8 save `1.013.092 bytes`
- `8 + 12 == 20`

### M28 — Save History Compaction / Historical Memory Policy I — PASS
- son 2 sezon contract/loan raw detail
- all-time aggregate summary
- season-8 `1.013.092 → 736.274 bytes`
- küçülme `%27,3`
- season-20 compact `915.648 bytes`
- `8 + 12 == 20`

### M29 — President Runtime Snapshot I — PASS
- current president tenure/profile/reputation/election cursor
- 48 club state
- season-8 `754.721 bytes`
- M28 üzerine `18.447 bytes` overhead

### M30 — Fan / Media / Promise Runtime Memory Snapshot I — PASS
- nested M29 president runtime
- exactly last 2 seasons raw fan detail
- exactly last 2 seasons raw media detail
- all-time bounded fan/media/promise summaries
- current election-term promise resolutions continuation-critical memory
- season-8 `802.906 bytes`
- M29 üzerine `48.185 bytes` overhead
- deterministic round-trip / checksum / migration guards PASS

Ayrıntı:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`

## 5. Başkan trait durumu

Beş trait'in tamamı gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

Canonical M24 seed `20260903`:
- convergence `4`
- cycle `false`
- elections `240`
- reelected/lost `159/81`
- manager `86`
- transfers `157`
- transfer volume `1.417,94M`
- installment deals `79`
- commitment `261,26M`
- cash `1.217,05M`
- debt `347,57M`
- emergency `144,39M`
- validation `0`

## 6. Milestone geçmişi — kısa

- M0 Deterministik sezon çekirdeği — PASS
- M1 20 sezon kariyer — PASS
- M2 Oyuncu yaşam döngüsü — PASS
- M3 Ekonomi — PASS
- M4 Transfer pazarı — PASS
- M5 48 kulüp / 3 lig world — PASS
- M6 Teknik direktör sistemi — PASS
- M7 Oyuncu sözleşmesi + maaş — PASS
- M8 Kiralık + taksit — PASS
- M9 Taraftar beklentisi + güven — PASS
- M10 Medya hafızası — PASS
- M11 Başkan vaatleri — PASS
- M12 Vaat → taraftar güveni — PASS
- M13 Vaat → medya güvenilirliği — PASS
- M14 Başkanlık seçimi — PASS
- M15 Başkan görev süresi + devir — PASS
- M16 Başkan devrinde kişisel itibar — PASS
- M17 Başkan yönetim profili — PASS
- M18 Manager patience feedback — PASS
- M19 Manager/world ↔ election fixed-point — PASS
- M20 Financial discipline feedback — PASS
- M21 Transfer ambition feedback — PASS
- M22 Profile feedback orchestration — PASS
- M23 Risk appetite feedback — PASS
- M24 Youth orientation feedback — PASS
- M25 temel save/load — PASS
- M26 world snapshot — PASS
- M27 advanced runtime snapshot — PASS
- M28 history compaction — PASS
- M29 president runtime snapshot — PASS
- M30 fan/media/promise runtime memory snapshot — PASS

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
- unsupported future version güvenli reddedilir
- migration fixture/test zorunludur
- eski public simulation semantiği save uğruna sessizce değişmez
- farklı controller-owned state tek milestone'a zorla yığılmaz
- continuation-critical state ile append-only historical state ayrılır
- historical state eklenmeden önce save büyümesi ölçülür
- PASS yalnız canlı CI kanıtıyla yazılır
- artifact hedefi `0`
- `actions/upload-artifact` kullanılmaz
- CI timeout `7 dk`

## 8. CI politikası

Ana workflow:
- `dart analyze`
- `dart test --exclude-tags canonical-feedback`
- M0–M18 headless runner zinciri
- tek combined M19–M24 canonical profile-feedback runner
- M25 save/load
- M26 world save
- M27 advanced runtime save
- M28 history compaction
- M29 president runtime snapshot
- M30 president domain memory snapshot

Save/runtime runners:
- `tool/run_m25_save_load.dart 20260903`
- `tool/run_m26_world_save.dart 20260903`
- `tool/run_m27_advanced_runtime_save.dart 20260903`
- `tool/run_m28_save_history_compaction.dart 20260903`
- `tool/run_m29_president_runtime_snapshot.dart 20260903`
- `tool/run_m30_president_domain_memory_snapshot.dart 20260903`

## 9. Açık teknik borç / sıradaki yön

- M30 memory snapshot var, fakat president-domain resume orchestration henüz explicit bağlanmadı
- full president-domain `8 + 12 == 20` kanıtı henüz yok
- M28 manager season history M27 strict invariantı nedeniyle hâlen tam tutulur
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- tesis yatırımının youth intake kalitesine etkisi henüz yok
- sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok

Sıradaki mantıklı milestone:

> **M31 — President Domain Resume Orchestration I**

Hedef:

> **M30 checkpoint’inden yüklenen başkan/fan/media/vaat state’iyle 8 sezon + save/load + 12 sezon devamın kesintisiz 20 sezon president-domain sonucuyla deterministik olarak eşleşmesi.**

Uzun vadeli hedef:

> **20–30 sezonluk kariyerin tüm kritik state'iyle deterministic, migration-safe ve makul boyutta kaydedilip devam ettirilebilmesi.**
