# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 5 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen tam kapsamlı Android mobil futbol kulübü başkanlığı simülasyonu.

Ana kimlik değişmez:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Satış fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Alternatif slogan:

> **Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.**

Oyuncunun ana karar alanları:

- kulüp ekonomisi ve borç
- teknik direktör seçimi/görev güvenliği
- transfer stratejisi
- altyapı ve tesisler
- sponsorlar
- taraftar beklentisi/güveni
- medya açıklamaları ve hafıza
- başkan vaatleri
- başkanlık seçimleri
- krizler ve uzun vadeli kulüp sağlığı

Football Manager benzeri maç içi teknik direktörlük yapılmayacak. Oyuncu diziliş, antrenman, 63. dakika değişiklikleri veya duran top taktiğiyle uğraşmayacak.

Gerçek kulüp/futbolcu/lisanslı materyal kullanılmayacak.

## 2. Geliştirme stratejisi

Bu proje uzun süre ana aktif proje olmayacak; Kelime Avı / Minik Dedektif gibi mevcut aktif projeleri aksatmayacak küçük ama sağlam altyapı ilerlemeleri yapılacak.

Şu an görsel ekran veya APK hedefi yoktur. Öncelik:

> **Sağlam, deterministik ve uzun kariyerde otomatik test edilebilir simülasyon çekirdeği.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo public tutulur; kaynak kod açık kaynak lisansı altında değildir (`LICENSE.md`).

Codex kredisi gereksiz kullanılmaz. Büyük/refactor/test altyapısı gibi işlerde gerekirse kullanılır; şimdiye kadarki M0–M23 akışı GitHub araçlarıyla yürütüldü.

## 3. Teknik mimari

- Saf Dart simülasyon çekirdeği
- Flutter mobil kabuk daha sonra
- Deterministik seed/replay
- Cihaz saatinden bağımsız `GameDate`
- Integer minor-unit `Money`
- Headless runner + invariant/balance testleri
- Save/load ve migration daha sonraki milestone, fakat veri modeli sürüm uyumu baştan düşünülüyor
- APK/AAB üretmeyen core CI
- `actions/upload-artifact` yok, artifact hedefi `0`

Dünya ölçeği:

- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ekonomi, kontrat, transfer, manager, reputasyon ve seçim zinciri

Canonical kariyer seed'i: `20260903`.

## 4. Kalıcı tasarım prensipleri

1. Başkan teknik direktör değildir.
2. Mobil arayüz sade, arka plan sistemi derin olabilir.
3. Oyuncuya gereksiz sayı bombardımanı yapılmaz.
4. Taraftar bağlamı anlar; ekonomik gerçekliği yok saymaz.
5. Transfer AI gerçekçi ve alternatif finansman yollarını kullanabilir.
6. Doğru karar her zaman açık değildir.
7. Kısa vadeli sportif başarı ile uzun vadeli mali sağlık arasında gerilim vardır.
8. Geçmiş açıklamalar/vaatler unutulmaz.
9. Sonuçlar aylar/sezonlar sonra dönebilir.
10. Uzun kariyer otomatik test edilir.
11. İlk sürüm gereksiz kapsamla şişirilmez.
12. Bir başkan trait'i ilk bağlandığında yalnız tek karar noktasına etki eder; causal yön izole tutulur.
13. Neutral trait değeri eski davranışı birebir korumalıdır.
14. Feedback döngülerinde convergence/cycle kontrolü zorunludur.
15. Duplicate full-career canonical hesapları büyütülmez.

## 5. Milestone geçmişi

### M0 — Deterministik sezon çekirdeği — PASS

- temel lig/fixture/match simulation
- deterministic replay
- 100 sezon batch invariant testi

### M1 — 20 sezon kariyer — PASS

- sezon takvimi ve ardışık kariyer
- custom başlangıç sezonu/tarih desteği

### M2 — Oyuncu yaşam döngüsü — PASS

- yaşlanma/emeklilik
- genç oyuncu üretimi
- uzun vadede kadro devamlılığı

### M3 — Ekonomi — PASS

- exact `Money`
- sezon gelir/gider akışı
- borç/cash/financial health
- emergency borrowing

Denge denemelerinde universal prosperity/collapse yaratacak ayarlar reddedildi. Ekonomi tek yönlü zenginleşme veya kitlesel batış üretmeyecek şekilde guardlandı.

### M4 — Transfer pazarı — PASS

- market value
- buyer/seller mantığı
- pozisyon ihtiyacı
- teklif/ask pazarlığı

### M5 — 48 kulüp / 3 lig dünya — PASS

- 48 kulüp, 3×16 lig
- 20 sezon world simulation
- lig hareketleri
- ekonomi/transfer ölçeklenmesi

Denge kalibrasyonlarında donmuş veya hiperaktif pazar üreten denemeler reddedildi.

### M6 — Teknik direktör sistemi — PASS

- deterministik manager pool
- manager profilleri
- performans / board breakdown / emeklilik değişimleri
- manager impact gerçek dünya gücünü etkiler

Eski kabul baseline'ında yaklaşık 82 manager değişimi; sistem hem negatif hem güçlü pozitif manager impact üretebilir.

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
- upfront + iki sezon transfer taksiti
- transfer installment banka borcundan ayrı yükümlülük

İlk denemeler aşırıydı ve reddedildi:
- 183 transfer / 146 taksitli + 755 kiralık
- 145/189, 108/147 ve 86/156 gibi taksit oranları da yüksek bulundu

Kabul baseline:
- 140 permanent transfer
- 68 installment deal
- 478 loan
- final active loan 32
- installment commitment `234,79M`
- loan fee `113,15M`
- validation `0`

### M9 — Taraftar beklentisi + güven — PASS

- context-aware fan expectation
- sporting/financial/transfer/identity trust
- neden kodları
- finans ve sportif bağlama göre beklenti

İlk güven modeli `46–68` aralığında fazla sıkıştığı için reddedildi. Mean reversion yumuşatıldı.

Kabul:
- 960 club-season snapshot
- avg trust `64,88`
- range `44..75`
- boundary 0
- 2143 trust reason

### M10 — Medya hafızası — PASS

- `MediaStatement`
- stance ve credibility
- açıklama → sonraki manager kararı çelişkisi

İlk model 960 kulüp-sezonun 847'sinde açıklama ürettiği için reddedildi. Kabul baseline:
- 556 statement
- 22 contradiction
- 9 strong-support→dismiss contradiction
- credibility avg `75,52`, range `49..87`

### M11 — Başkan vaatleri — PASS

- preseason context ile ölçülebilir vaat üretimi
- fulfilled / partial / broken resolver
- gelecekteki sezon sonucuna bakarak vaat üretme yasak

Canonical:
- 960 vaat
- fulfilled 435
- partial 169
- broken 356
- avg score `54,84`

### M12 — Vaat → taraftar güveni — PASS

- tek advanced-world raporu paylaşılır
- promise sonucu identity trust'a, finans vaatleri financial trust'a kontrollü etki eder
- M9 baseline tekrar simüle edilmez

Canonical overall trust etkisi küçük tutuldu; identity trust tarihçe ayrıştırması sağlar.

### M13 — Vaat → medya güvenilirliği — PASS

- manager + advanced transfer + promise + media aynı world
- fulfilled/partial/broken medya credibility etkisi

Canonical:
- positive 452 / neutral 154 / negative 354
- statements 560
- contradictions 28
- credibility `74,88 → 72,38`

### M14 — Başkanlık seçimi I — PASS

- 4 sezonda bir deterministik seçim
- fan overall/identity + media credibility + promise sicili
- ilk sürüm gözlemsel, kariyeri kesmez

Canonical:
- 240 seçim
- 158 reelected / 82 lost
- approval avg `63,24`
- competitive 72

### M15 — Başkan görev süresi + devir — PASS

- reelected → aynı incumbent
- lost → challenger gerçek yeni `PresidentProfile`
- turnover history

Canonical:
- 82 loss = 82 gerçek devir
- unique presidents 130
- avg outgoing tenure `6,93`

Bir kulübün 5/5 seçim kaybetmesi gözlendi; M15'te seçim modelini değiştirmemek için özellikle düzeltilmedi, takip notu olarak bırakıldı.

### M16 — Başkan devrinde kişisel itibar — PASS

Başkan değişiminde club-level sporting/financial/transfer trust korunur; kişisel identity/media reputasyonu yeni başkan için kontrollü nötre yaklaşır.

Handover policy: yaklaşık `%25 geçmiş + %75 neutral`.

Canonical seçim `161/79`; personal reputation boundary'lere yapışmaz.

### M17 — Başkan profili / yönetim felsefesi — PASS

6 arketip, 5 trait:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

Arketipler:
- balanced
- prudentBuilder
- ambitiousSpender
- youthArchitect
- patientPlanner
- interventionist

Canonical:
- 127 profile
- tüm 6 arketip aktif
- 79 turnover'dan 67'sinde arketip değişiyor
- 57 anlamlı management philosophy değişimi
- avg profile distance `22,47`

### M18 — Manager patience → hoca karar eşiği — PASS

İlk gerçek profile trait etkisi.

Neutral `managerPatience=60` eski manager eşiklerini korur.

Canonical:
- manager changes `81→88`
- decision differences `93`
- low patience dismissal rate `%16,4`
- high patience `%6,2`
- final manager assignment difference `37/48`

M18 bilinçli olarak iki-geçişli shadow/reference timeline kullandı; seçimleri yeni world ile yeniden hesaplamadı. Bu sınırlama M19'da kapatıldı.

### M19 — Manager/world ↔ seçim fixed-point — PASS

Feedback zinciri:

`president timeline → patience-aware world → reputasyon → seçim → yeni president timeline`

Timeline sabitlenene kadar replay edilir.

Canonical:
- 4 iterasyon
- converged true / cycle false
- `161/79 → 160/80`
- manager `81→84`
- transfers `173→168`

Representative seed'ler `19011/19012/19013` de kısa horizon'da converge eder.

### M20 — Financial discipline → transfer bütçesi — PASS

Trait yalnız affordability alanına bağlandı.

Neutral `60`:
- reserve `2M`
- window spend cap `%35`
- installment commitment cap `%90`

Canonical:
- 5 iterasyon
- `160/80 → 158/82`
- manager `84→83`
- transfer `168→153`
- volume `1.387,32M`
- cash `1.226,59M`
- debt `363,58M`

Borç/emergency yönü causal ürün invariant'ı değildir; world feedback birleşik sonucudur.

### M21 — Transfer ambition → aktivite — PASS

Trait yalnız completed transfer slots kontrol eder:

- `<45 → 1`
- `45..74 → 2`
- `>=75 → 3`

Neutral `60 = 2` eski davranışı birebir korur.

Canonical:
- 4 iterasyon
- `158/82 → 150/90`
- manager `83→80`
- transfers `153→161`
- volume `1.461,55M`
- debt `330,25M`
- emergency `123,89M`

M21 sonrası CI nested fixed-point tekrarları nedeniyle yaklaşık 6:10'a yükseldi; timeout geçici olarak 7 dakikaya çıkarıldı.

### M22 — Profile Feedback Orchestration I — PASS

Davranış değiştirmeyen performans/refactor milestone'u.

Sorun: M19/M20/M21 canonical 20-sezon kariyerleri hem test hem ayrı runner'larda tekrar çözülüyordu.

Çözüm:
- ortak `tool/profile_feedback_canonical_guard.dart`
- full canonical testler `canonical-feedback` tag
- normal test `dart test --exclude-tags canonical-feedback`
- tek en yeni profile-feedback runner nested önceki raporları/guard'ları doğrular
- ayrı M19/M20 canonical runner tekrarları kaldırıldı

M21 baseline birebir korundu.

PR #23 merge: `4ec358cf7131087176426ba5767ab4e4e65a36b3`

Final CI `33918259144`:
- 76 hızlı/non-duplicate test PASS
- M0–M18 PASS
- M19–M21 combined PASS
- artifact 0
- süre ~2:51
- timeout tekrar 5 dk

### M23 — Risk appetite → transfer pazarlık tavanı — PASS

Trait yalnız buyer maximum bid ceiling'e bağlandı.

Policy:
- clamp risk `20..90`
- `(risk−60) × 20 bps`
- clamp `-800..+600 bps`

Örnek:
- risk20 → `-800`
- risk60 → `0`
- risk90 → `+600`

Neutral provider eski advanced-world signature'ını birebir korur.

Değiştirilmeyen alanlar:
- seller ask
- shortlist
- pozisyon ihtiyacı
- transfer slotu
- affordability
- installment acceptance
- candidate score

Canonical seed `20260903`:
- iterations `5`
- converged true / cycle false
- elections 240
- M21 baseline `150/90`
- M23 final `156/84`
- election differences 44
- manager `80→85`
- transfers `161→133`
- volume `1.461,55M→1.201,05M`
- installment deals `73→66`
- commitment `247,61M→230,59M`
- cash `1.180,63M→1.195,96M`
- debt `330,25M→381,94M`
- emergency `123,89M→189,81M`
- unique presidents 132
- validation 0

Iteration path:
`91/148/156-84 → 88/147/157-83 → 82/140/159-81 → 85/133/156-84 → stable 85/133/156-84`

Aggregate transfer hacmi/borç yönü risk trait'inin causal invariant'ı değildir. Doğrudan invariant:

> `low risk max-bid < neutral max-bid < high risk max-bid`

PR #24 merge:
`17142c39bfeed20fce931e8810f30ba4ba98a322`

Final PR CI `33920702055`:
- analyzer PASS
- 78 hızlı/non-canonical test PASS
- M0–M18 runner PASS
- birleşik M19–M23 canonical runner PASS
- nested M19 `160/80`, M20 `158/82`, M21 `150/90`
- M23 `5 iterasyon / 156-84 / 85 manager / 133 transfer`
- validation 0
- artifact 0

## 6. Şu an aktif trait durumu

Gerçek davranışa bağlı:
- managerPatience
- financialDiscipline
- transferAmbition
- riskAppetite

Henüz bağlanmadı:
- **youthOrientation**

## 7. Açık teknik riskler / sınırlar

- Fixed-point feedback kabul edilmiş çözümdür; literal tek-pass seasonal orchestration değildir.
- Her yeni trait aynı nested replay modeline yeni duplicate canonical hesap eklememeli; M22 yapısı genişletilmelidir.
- Long career balance guard'ları canonical seed'e fazla overfit edilmemeli; causal unit/regression invariant'ları ayrı tutulmalı.
- Aggregate cash/debt/transfer direction tek trait'in causal sonucu olarak yorumlanmamalı.
- Save/load + migration sistemi henüz gerçek implementation milestone'una gelmedi.
- UI/Flutter/APK henüz hedef değil.
- 3D maç motoru, online multiplayer, gerçek kulüpler/futbolcular ilk kapsam dışında.

## 8. Sıradaki milestone — M24

**Başkan Altyapı Yönelimi → Genç Oyuncu / Transfer Tercihi I**.

Önerilen ilk ve tek causal kontrol noktası:

`youthOrientation` → transfer candidate scoring içindeki gençlik/potansiyel ağırlığı.

Kural:
- neutral `youthOrientation=60` mevcut M23 dünyasını birebir korumalı
- academy intake kalitesi aynı milestone'da değiştirilmemeli
- genç oyuncu üretim adedi aynı milestone'da değiştirilmemeli
- affordability / slot / max-bid aynı kalmalı
- M22 duplicate-free canonical runner M24'e genişletilmeli

M24'ün amacı "altyapı başkanı her zaman daha çok transfer yapar" değildir; aynı transfer pazarı içinde genç/potansiyelli adaya verdiği **tercih ağırlığının** değişmesidir.

## 9. Dokümantasyon

Son teknik belgeler:

- `M18_BASKAN_SABRI_TEKNIK_DIREKTOR_KARAR_ESIGI.md`
- `M19_BASKAN_SABRI_SECIM_GERI_BESLEME_DONGUSU.md`
- `M20_BASKAN_MALI_DISIPLIN_TRANSFER_BUTCE_DAVRANISI.md`
- `M21_BASKAN_TRANSFER_HIRSI_TRANSFER_AKTIVITESI.md`
- `M22_PROFILE_FEEDBACK_ORKESTRASYON_I.md`
- `M23_BASKAN_RISK_ISTAHI_TRANSFER_PAZARLIK_DAVRANISI.md`

## 10. Çalışma kuralı

Her önemli çalışma sonunda bu dosyada:
- alınan kararlar
- tamamlanan işler
- test/CI sonuçları
- reddedilen denemeler
- açık sorunlar
- sonraki işler
- teknik mimari
- simülasyon baselineları

güncellenir.

Eski kararlarla yeni açık karar çelişirse en yeni karar geçerlidir. Canlı GitHub durumu eski sohbet notlarından üstündür.
