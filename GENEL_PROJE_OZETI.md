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

### M37 kapanış
- PR `#38` — MERGED
- final PR HEAD: `0030caef1c292d4f1d249f9a8ed5a2abcca041fb`
- PR CI: run `34059375807`, job `101557067196` — SUCCESS
- analyzer PASS
- `147` normal/non-canonical test PASS
- M0–M37 runner zinciri PASS
- artifact `0`
- ilk CI'da 7 dk workflow timeout nedeniyle overall cancelled olmuş ancak tüm test adımları SUCCESS; timeout yükseltilmemiştir
- test runner optimize edilerek final PR CI `4m22s` içinde yeşil tamamlanmıştır
- squash merge sonrası main SHA: `ff1745671ce57fdaa56b937bf36f026f86b34ca5`
- merge sonrası main CI: run `34113979981` — **son doğrulama sırasında in_progress**

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

### M37 — President Facility Decision Loop / Turnover Replanning I — MERGED; main CI son kontrol bekliyor
- sezonluk/periodik facility decision loop
- her sezon başkan profiline göre target/upgrade intensity/reserve recompute
- başkan değişiminde turnover replanning
- downgrade yok
- gerçek cash finance path korunur
- decision history derived; save growth'a yeni persisted history eklenmez
- split save/load/resume parity + multi-president turnover kanıtı

Ayrıntı dosyaları:
- `M29_PRESIDENT_RUNTIME_SNAPSHOT_I.md`
- `M30_FAN_MEDIA_PROMISE_RUNTIME_MEMORY_SNAPSHOT_I.md`
- `M31_PRESIDENT_DOMAIN_RESUME_ORCHESTRATION_I.md`
- `M32_LONG_CAREER_SAVE_GROWTH_RESUME_STRESS_I.md`
- `M34_FACILITY_PERSISTENCE_FINANCE_ORCHESTRATION_I.md`
- `M35_ACADEMY_RUNTIME_YOUTH_INTEGRATION_I.md`
- `M36_PRESIDENT_YOUTH_ACADEMY_INVESTMENT_ORCHESTRATION_I.md`

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

M0–M36 PASS. M37 MERGED ve main CI doğrulaması sürüyor.

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
- M37 President Facility Decision Loop / Turnover Replanning I — MERGED; post-merge CI pending at last verification

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

Ana workflow temel olarak:
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
- M36 president youth investment orchestration
- M37 president facility decision loop / turnover replanning

## 9. Açık teknik borç / sıradaki yön

M0–M36 için canlı PASS kanıtı vardır. M37 kodu merge edilmiştir; post-merge main CI tamamlanmadan M37 CLOSED/PASS etiketi kesinleştirilmemelidir.

Açık konular:
- Android file system / save-slot UI / autosave / backup / cloud save daha sonra
- stadium / training-ground facility türleri henüz yok
- sponsor ve kriz sistemleri henüz çekirdek milestone olarak uygulanmadı
- seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok
- long-career player/economy/manager denge metrikleri 30+ sezonda ayrıca ürün-balance milestone'u olarak sertleştirilebilir
- academy/facility karar döngüsünün daha geniş facility türlerine yayılması sonraki ürün kararıdır

Sıradaki yön, M37 main CI sonucu alındıktan sonra yeniden değerlendirilmelidir. Yeni milestone otomatik varsayılmamalıdır.

## 10. DEVRALMA / ÇALIŞMA TALİMATI

Bu dosyayı okuyan başka bir ChatGPT/Codex oturumu projeyi **yarım bırakmadan** devralabilmelidir.

Zorunlu çalışma biçimi:
1. Önce `GENEL_PROJE_OZETI.md` ve ilgili milestone dokümanlarını oku.
2. Eski sohbet anlatımlarını canlı GitHub durumunun yerine koyma. `main`, PR, commit ve Actions sonuçlarını canlı kontrol et.
3. M37 için özellikle main run `34113979981` durumunu kontrol et. Yeşil değilse M37'yi CLOSED/PASS yazma.
4. CI başarısızsa gerçek failure logunu çıkar; varsayım yapma; kök nedeni düzelt; yeni branch/PR aç; test et; kullanıcı onayı olmadan merge etme.
5. CI yeşilse artifact `0` olduğunu doğrula ve ancak bundan sonra M37 kapanış dokümanını oluştur/güncelle ve bu özeti canlı kanıtla güncelle.
6. Her milestone'da M0–önceki milestone davranışını koru. Yeni özellik eklerken eski public simulation semantiğini sessizce değiştirme.
7. Determinism, save/load/resume parity, migration, invariant ve balance guard'larını koru.
8. CI timeout `7 dk` sabittir. Yavaş testleri gizlemek için timeout artırma; test runner'ı optimize et.
9. `actions/upload-artifact` ekleme; artifact hedefi `0`.
10. Kullanıcı açıkça onay vermeden PR merge etme.
11. Kullanıcı `Devam et` dediğinde küçük durum raporları vermek yerine araçları kullanarak gerçek işi ilerlet. Yalnız hard blocker varsa dur.
12. Her kapanan milestone için ilgili kapanış `.md` dosyasını ve bu özeti güncelle; kapanışı canlı CI kanıtına bağla.
13. Yeni milestone'a başlamadan önce ürün kapsamını ve mevcut runtime/save mimarisini bozacak gereksiz refactor yapma.
14. Kodda değişiklik yaparken minimum, hedefli ve test edilebilir değişiklik tercih et.

### 1 aylık geçici devir notu

Bu proje yaklaşık **1 aylığına başka bir ChatGPT hesabı/oturumu tarafından devralınacaktır**. Devir alan model, bu dosyayı tek başına okuyup projeyi sürdürebilecek seviyede hareket etmelidir. Öncelik hız değil **doğruluk + canlı CI kanıtı + mevcut davranışın korunmasıdır**.

Özellikle:
- M37'nin merge edilmiş olması, post-merge main CI yeşil olmadan milestone'un kapandığı anlamına gelmez.
- M37'den sonra yeni milestone'u sırf "sıradaki mantıklı fikir" diye otomatik başlatma; önce M37 kapanışını doğrula ve kullanıcı talimatını bekle.
- Kullanıcı onayını gerektiren merge/release gibi işlemleri kendi başına yapma.
- Kod değişikliklerini GitHub üzerinde gerçekleştir; kullanıcının düşük disk alanını gereksiz yere tüketme.
- Bir hata görürsen gerçek log → kök neden → minimal düzeltme → test → PR akışını izle.
- "Yeşil gibi görünüyor", "muhtemelen düzeldi" veya eski sohbet notuna dayanarak PASS deme.

Bu devir dosyası kalıcı proje dokümantasyonu değildir; geçici çalışma talimatı olarak kullanılacaktır.
