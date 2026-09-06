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

**M0–M29 PASS ve `main` üzerindedir.**

Son kapalı milestone: **M29 — President Runtime Snapshot I**.

M29 PR:
- PR `#30` — MERGED
- final PR HEAD: `8c1de528e0d7ef6d3671e0e71064b03bc1c9802e`
- squash merge commit: `467689aa29e4805dcd93f9448cc7a1c21ba8e8d1`
- final PR CI: run `33999480197`, job `101395663903` — SUCCESS
- merge sonrası `main` CI: run `34027200080`, job `101470178756` — SUCCESS
- analyzer PASS
- normal/non-canonical tests: `118` PASS
- M0–M18 runner zinciri PASS
- combined M19–M24 canonical profile feedback PASS
- M25 save/load PASS
- M26 world snapshot PASS
- M27 advanced runtime snapshot PASS
- M28 save history compaction PASS
- M29 president runtime snapshot PASS
- artifact `0`
- CI timeout `7 dk`

M29 canonical ölçümü:
- completed seasons: `8`
- next season index: `8`
- president club states: `48`
- completed election terms: `2`
- term offset: `0`
- M28 compact save: `736.274 bytes`
- M29 president save: `754.721 bytes`
- president-state overhead: `18.447 bytes`
- codec round-trip: PASS

Aktif teknik yön:

> **M29 kapandı. Sıradaki mantıklı save milestone'u fan/media/promise continuation memory katmanıdır.**

Önemli sınır: M29, current president/tenure/profile/reputation/election-cursor state'ini saklar; ayrıntılı fan/media/promise geçmişini henüz resumable yapmaz. Bu nedenle M29 tek başına tam president-domain 8+12 continuation iddiası taşımaz.

Canlı GitHub durumu her zaman eski sohbet notlarından üstündür.

## 4. M29 — President Runtime Snapshot I — PASS

M28 compact advanced runtime üzerine continuation-critical başkan state'i eklendi.

Ana parçalar:
- `PresidentClubRuntimeState`
- `PresidentRuntimeCheckpoint`
- `PresidentRuntimeSaveCodec`
- `test/m29_president_runtime_snapshot_test.dart`
- `tool/run_m29_president_runtime_snapshot.dart`
- workflow M29 runner adımı

Checkpoint state:
- nested M28 compact advanced runtime
- her 48 kulüp için current `PresidentTenureState`
- current `PresidentManagementProfile`
- current fan reputation skorları
- current media credibility
- election cursor: `electionInterval`, `completedElectionTerms`, `seasonsIntoCurrentTerm`

Codec:
- format `zmila-fbs-president-runtime`
- save version `1`
- canonical JSON
- FNV-1a checksum
- unsupported future version rejection
- sentetik `v0 → v1` migration
- checksum corruption rejection
- structural validation

M29 sırasında bulunan gerçek save-size sorunu:
- ilk tasarım M28 JSON save'ini M29 payload içinde string olarak tekrar JSON'a gömüyordu
- bu double-encoding nedeniyle overhead `222.895 bytes` oldu ve `<50.000` guard'ı kırıldı
- eşik gevşetilmedi
- nested M28 save doğrudan JSON object olarak saklandı
- düzeltme commit'i: `8c1de528e0d7ef6d3671e0e71064b03bc1c9802e`
- gerçek overhead `18.447 bytes` oldu

M29 kabul kriterleri:
- 48 current president state — PASS
- deterministic election cursor — PASS
- current management profile preservation — PASS
- current fan/media reputation preservation — PASS
- deterministic encode/decode round-trip — PASS
- checksum corruption rejection — PASS
- future version rejection — PASS
- v0→v1 migration — PASS
- M29 overhead `<50.000 bytes` — PASS
- analyzer — PASS
- normal tests — PASS
- M0–M29 runners — PASS
- artifact — `0`

Ayrıntı: `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`

## 5. Save/runtime zinciri

### M25 — Save/Load + Kayıt Versiyonlama I — PASS
- temel `CareerCheckpoint`
- canonical JSON / checksum / versioning / migration
- canonical save `1.039 bytes`
- `8 + 12 == 20`
- squash `c46d5fc99655476f389de82d861ce7a5e6a93aec`

### M26 — World Save Snapshot I — PASS
- 48 base club
- 3×16 next-season league membership
- players + finance + config
- canonical save `187.664 bytes`
- `8 + 12 == 20`
- squash `c721588f998f5d29495c8074d956e48e306a1dc8`

### M27 — Advanced World Runtime Snapshot I — PASS
- active contracts
- contract history
- loans + loan history
- installments
- manager pool/assignments/history
- canonical save `1.013.092 bytes`
- `8 + 12 == 20`
- squash `46e52be2b65910f200b4dee85647d1ae982b5d94`

### M28 — Save History Compaction / Historical Memory Policy I — PASS
- son 2 sezon contract/loan raw detail
- all-time aggregate history summary
- active state eksiksiz
- season-8 `1.013.092 → 736.274 bytes`
- küçülme `%27,3`
- season-20 compact `915.648 bytes`
- `8 + 12 == 20`
- squash `8fb9846c70b438641521a4023068a5a707d0ea38`

### M29 — President Runtime Snapshot I — PASS
- current president tenure/profile/reputation/election cursor
- 48 club state
- season-8 `754.721 bytes`
- M28 üzerine `18.447 bytes` overhead
- squash `467689aa29e4805dcd93f9448cc7a1c21ba8e8d1`

## 6. Başkan trait durumu

Beş trait'in tamamı gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

M25–M29 yeni trait davranışı eklemez; save/runtime güvenilirliği üzerinde çalışır.

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

## 7. Milestone geçmişi — kısa

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

## 8. Kalıcı teknik kurallar

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

## 9. CI politikası

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

Current profile runner:
`tool/run_m24_president_youth_orientation_feedback.dart 20260903`

Save/runtime runners:
- `tool/run_m25_save_load.dart 20260903`
- `tool/run_m26_world_save.dart 20260903`
- `tool/run_m27_advanced_runtime_save.dart 20260903`
- `tool/run_m28_save_history_compaction.dart 20260903`
- `tool/run_m29_president_runtime_snapshot.dart 20260903`

## 10. Açık teknik borç / sıradaki yön

- fan/media/promise historical/resumable memory henüz save kapsamında değil
- M29 current reputation skorlarını taşır ama detailed memory continuation sağlamaz
- M28 manager season history M27 strict invariantı nedeniyle hâlen tam tutulur
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- tesis yatırımının youth intake kalitesine etkisi henüz yok
- sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok

Sıradaki mantıklı milestone:

> **M30 adayı — Fan / Media / Promise Runtime Memory Snapshot I**

Amaç, M29'un sakladığı current president/reputation state'in arkasındaki continuation-critical fan/media/promise memory'yi deterministik ve migration-safe biçimde snapshot ederek gerçek president-domain resume zincirini genişletmektir.

Uzun vadeli hedef:

> **20–30 sezonluk kariyerin tüm kritik state'iyle deterministic, migration-safe ve makul boyutta kaydedilip devam ettirilebilmesi.**
