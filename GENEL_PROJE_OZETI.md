# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 12 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
Canonical seed: `20260903`
Dünya: 48 özgün kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 14.400 maç/20 sezon, 864 başlangıç oyuncusu.

Kalıcı kurallar:
- Live GitHub > proje dosyaları > eski sohbetler
- deterministic seed/replay; `GameDate`; integer minor-unit `Money`
- eski public simulation semantiği sessizce değiştirilmez
- save/load/resume determinism ve parity korunur
- PASS yalnız canlı CI kanıtıyla yazılır
- CI iki paralel job: `test` + `canonical`; her job `timeout-minutes: 7`
- artifact hedefi `0`
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz
- her anlamlı proje durumu/kararı sonrası bu özet güncel tutulur
- docs→CI→docs sonsuz döngüsü üretilmez

## 2. CANLI DURUM — buradan devam et

**M0–M45 CLOSED / MERGED / PASS ve `main` üzerindedir.**

Son merge edilmiş milestone:
**M45 — Sponsor Runtime Integration I**

PR #48 squash merge: `92f4f1b99fa841866587a8067dd529735400c035`

Post-merge main CI `34684676105` — **SUCCESS**:
- test job `103529485118` — SUCCESS
- analyzer: `No issues found!`
- **189 normal/non-canonical test PASS**
- canonical job `103529485217` — SUCCESS
- **M0–M45 canonical PASS**
- artifacts: **0**
- iki job da 7 dakika sınırının altında

M45 canonical final:
- seasons=4
- contractsPerSeason=48
- revenueBySeason=`291473844.75, 294374236.50, 295295994.50, 299016546.25`
- cumulativeRevenue=`1180160622.00`
- preservedAcrossTurnover=2
- renewedByNewPresident=57
- saveBytes=730919
- financeReplacementMatch=true
- finalCheckpointMatch=true
- boundaryMatch=true

Kalıcı doküman: `M45_SPONSOR_RUNTIME_INTEGRATION_I.md`.

### Sıradaki seçilmiş milestone

**M46 — Sponsor + Crisis Runtime Composition I**

Canlı repo taraması sonucu açık bir M46 roadmap tanımı bulunmadı; README M26 seviyesinde kalmış durumda. M46 mevcut gerçek mimari boşluğa göre seçildi:
- M44 `CrisisRuntimeCareerEngine` PresidentDomain sezonunu kendi top-level runtime'ında sürüyor,
- M45 `SponsorRuntimeCareerEngine` sponsor-aware economy ile PresidentDomain sezonunu ayrı top-level runtime'ında sürüyor,
- iki sistem bugün aynı kariyerde tek public continuation yolu içinde birlikte çalışmıyor,
- bunları sırayla ayrı çalıştırmak aynı sezonun PresidentDomain/world hesaplarını tekrar simüle etme riski taşır.

M46 hedefi tek sezon akışında:
1. sponsor-aware gerçek ekonomi çözümü,
2. tamamlanan sezonun PresidentDomain state'i,
3. sezon sonu M44 crisis değerlendirmesi,
4. crisis-adjusted finance/fan/media state'inin sonraki sezon sponsor context'ine taşınması,
5. sponsor kontrat state'inin aynı composite checkpoint içinde korunması
zincirini **tek dünya simülasyonu** ile kurmaktır.

Kabul yönü:
- M45 sponsor revenue replacement/double-counting koruması aynen kalmalı,
- M44 crisis debt-preservation ve bounded effect kuralları aynen kalmalı,
- crisis kapalı/etkisiz konfigürasyonda birleşik runtime M45 ile parity vermeli,
- sponsor kontratları crisis nedeniyle sessizce bozulmamalı,
- crisis fan/media etkisi sonraki sponsor renewal context'ine gerçekten ulaşmalı,
- 2+2 save/resume = uninterrupted 4 sezon,
- normal acceptance + canonical M46 gate,
- artifact 0 ve her CI job <7 dakika.

M46 henüz branch/PR açılmadan önce son M45 docs-only `main` CI kapısı doğrulanacaktır.

## 3. Son kapalı milestone'lar

### M45 — Sponsor Runtime Integration I — CLOSED / MERGED / PASS
PR #48 squash merge: `92f4f1b99fa841866587a8067dd529735400c035`
Post-merge main CI `34684676105`: analyzer clean, **189 test PASS**, **M0–M45 PASS**, artifact **0**.

Kapsam:
- ayrı sponsor-aware full runtime entegrasyonu; legacy public PresidentDomain davranışı sessizce değiştirilmedi
- `PresidentDomainMemoryCheckpoint + SponsorRuntimeCheckpoint` için explicit composite runtime checkpoint/save codec
- üç lig boyunca tek season-scoped sponsor economy coordinator; aynı kulüp bir sezonda iki kez sponsor çözümünden geçemez
- M42 sponsor geliri gerçek economy `sponsorRevenue` satırında legacy strength-only sponsor gelirinin **replacement** kaynağıdır; double-counting yok
- yeni sponsor seçimleri gerçek current president + fan + media context'i kullanır
- çok yıllı kontratlar gerçek president turnover boyunca korunur
- kontrat expiry sonrası renewal mevcut başkan profiliyle yapılır
- global 48-kulüp sponsor state'i sezon sonunda deterministik üretilir
- 2+2 save/resume = uninterrupted 4 sezon
- acceptance testleri + canonical M45 gate eklendi

Canonical kanıt:
- her sezonda 48 aktif sponsor kontratı
- 4 sezonda cumulative sponsor revenue `1,180,160,622.00`
- turnover boyunca korunan kontrat: 2
- yeni başkan tarafından yenilenen kontrat: 57
- `financeReplacementMatch=true`
- `finalCheckpointMatch=true`
- `boundaryMatch=true`

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
PR #47 squash merge: `43149da199e74e41dabe47534e4e4e887d8862e7`
Post-merge main CI `34683153804`: analyzer clean, **184 test PASS**, **M0–M44 PASS**, artifact **0**.

Kapsam:
- ayrı opt-in `CrisisRuntimeCareerEngine`; legacy `PresidentDomainCareerEngine` değiştirilmedi
- gerçek sezon sonunda finance/fan/media/current-president state'inden M43 crisis context
- cash etkisi gerçek `WorldCheckpoint.nextSeasonFinanceStates` continuation state'ine
- fan/media etkisi gerçek `PresidentRuntimeCheckpoint.clubs` continuation state'ine
- debt değişmez; gizli borrowing yok
- mevcut PresidentDomain save codec yeterli; save-version bump yok
- 2+2 save/resume = uninterrupted 4 sezon
- gerçek president turnover crisis policy'yi değiştirebilir
- runtime threshold 55; M43 core defaultu değişmedi
- kalıcı frequency guard kriz oranının %75'e ulaşmasını reddeder

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 squash merge: `27474a731aa73d291859828a1657d06579e69269`
Post-merge main CI `34680783652`: analyzer clean, **179 test PASS**, **M0–M43 PASS**, artifact **0**.

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 squash merge: `2868d725c4ba68601a732d98b913195d3c58a4a3`
Post-merge main CI `34660280556`: analyzer clean, **173 test PASS**, **M0–M42 PASS**, artifact **0**.

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 squash merge: `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`; post-merge CI `34656211019`: 167 test PASS, M0–M41 PASS, artifact 0.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`; post-merge CI `34652843932`: 162 tests, M0–M40 PASS, artifact 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`; post-merge CI `34649669246`: 157 tests, M0–M39 PASS, artifact 0.

## 4. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime integration; M45 sponsor runtime integration.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + crisis pressure
- `MediaState.credibility`: sponsor offer quality + crisis pressure
- finance cash/debt: crisis pressure + bounded cash effect
- M44: crisis output gerçek next-season continuation state'ine taşınır
- M45: sponsor kontrat lifecycle + revenue gerçek PresidentDomain continuation/economy akışına bağlıdır
- M46 hedefi: M44 + M45 etkilerini tek season boundary/continuation runtime'ında compose etmek

## 5. M46 çalışma yönü

Canlı koddan doğrulanan entegrasyon sırası:
1. M45 sponsor coordinator gerçek economy çağrıları sırasında 48 kulüp sponsor kontrat/gelirini çözer.
2. PresidentDomain sezonu tamamlanır ve next-season domain checkpoint oluşur.
3. M44 `CrisisRuntimeIntegrationEngine.apply(...)` bu tamamlanmış domain checkpoint'e uygulanabilir; crisis engine stateless olduğundan ayrı crisis save state gerektirmez.
4. Crisis-adjusted domain checkpoint, M45 sponsor checkpoint ile yeniden tek composite checkpoint olarak taşınır.
5. Sonraki sponsor sezonu current president + crisis-adjusted fan/media state'ini okur.

M46 için yeni save formatı gerekip gerekmediği implementasyon sırasında kanıtla belirlenecek; mevcut M45 `SponsorPresidentRuntimeCheckpoint` domain+sponsor state'i crisis etkilerini domain içinde zaten taşıyabildiği için **save-version bump varsayılmayacaktır**.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu oturumda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi.
