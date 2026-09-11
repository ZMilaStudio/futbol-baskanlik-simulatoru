# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 11 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

Değişmez ana fikir:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Alternatif slogan:

> **Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.**

Başkanın alanı: ekonomi/nakit/borç, teknik direktör seçimi ve görev güvenliği, transfer stratejisi, sözleşme/maaş, kiralık/taksit, taraftar güveni, medya hafızası, vaatler, seçimler, görev süresi ve tesis yatırımları. Football Manager benzeri maç içi taktik yönetimi yoktur. Gerçek kulüp/futbolcu/logo/lisanslı materyal kullanılmaz.

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
Canonical seed: `20260903`
Dünya: 48 özgün kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 14.400 maç/20 sezon, 864 başlangıç oyuncusu.

## 2. Geliştirme stratejisi

Öncelik deterministik, headless ve uzun kariyerde otomatik test edilebilir saf Dart simülasyon çekirdeğidir. Flutter/Android mobil kabuk daha sonra gelir.

Kalıcı ilkeler:
- deterministic seed/replay
- device-clock-independent `GameDate`
- integer minor-unit `Money`
- headless runner + invariant/balance guard
- eski public simulation semantiği sessizce değiştirilmez
- save/load/resume determinism ve parity korunur
- explicit save version + migration + checksum
- future save version güvenli reddedilir
- migration fixture/test zorunludur
- continuation-critical state ile historical state ayrılır
- history/save büyümesi ölçülür ve bounded tutulur
- PASS yalnız canlı CI kanıtıyla yazılır

## 3. CANLI DURUM — buradan devam et

**M0–M38 PASS ve `main` üzerindedir.**

Son kapalı ürün milestone'u:
**M38 — Facility Portfolio Core I**.

### PR #41 — M38 Facility Portfolio Core I — CLOSED / MERGED

Branch: `feat/m38-facility-portfolio-core`

PR:
- `#41` — **MERGED**
- başlık: `M38: facility portfolio core with stadium and training ground`
- final PR HEAD: `a85e2bc050bb3d40984afcd588042547bc2b3730`
- final PR CI run `34621413329` — **SUCCESS**
- test job `103336318547` — SUCCESS
- canonical job `103336319004` — SUCCESS
- analyzer: `No issues found!`
- 152 normal/non-canonical test PASS
- M0–M38 canonical PASS
- artifacts `0`

Kullanıcı açıkça merge onayı verdi. PR squash merge edildi.

Squash merge:
- `4a5c0b6585dffe3944dc8b9e4759a461c490b033`

Post-merge `main` CI:
- run `34624529493` — **SUCCESS**
- test job `103346289415` — **SUCCESS**
- canonical job `103346289304` — **SUCCESS**
- `dart analyze`: **No issues found!**
- `dart test --exclude-tags canonical-feedback`: **152 tests passed**
- M0–M38 canonical runner zinciri: **PASS**
- M38 canonical adımı: **SUCCESS**
- artifacts: **0**
- iki job da sabit `timeout-minutes: 7` sınırının altında tamamlandı

### M38 davranışı

- 48 kulübün tamamında persistent `academy + stadium + training ground` portfolio
- stadium level `0..5`
- training-ground level `0..5`
- stadium/training upgrade maliyeti gerçek club cash'ten düşer
- gizli borç yaratılmaz; yetersiz nakitte state değişmez
- stadium gerçek `matchdayRevenue` hattını etkiler
- training ground gerçek offseason player-development hattını etkiler
- training yalnız pozitif gelişim delta'sını artırır; yaşa bağlı gerilemeyi tersine çevirmez
- level `0` legacy davranışını korur
- eski academy yatırım API'si yeni facility state'lerini silmez
- facility save formatı `v2`
- `v0 → v1 → v2` ve `v1 → v2` neutral migration
- eski save'lerde stadium/training level `0` ile açılır
- full portfolio save/load/resume parity korunur
- president-driven automatic stadium/training yatırım kararı M38 kapsamı dışındadır

M38 canonical:
- seed `20260903`
- investment checkpoint season `8`
- club `t3_05`
- stadium `0 → 1`
- training ground `0 → 1`
- total spend `9.00M`
- immediate cash delta `9.00M`
- debt unchanged `true`
- matchday revenue `3.49M → 3.75M`
- training player `y_t3_05_s4`
- ability `57.4905 → 57.5290`
- save version `2`
- save bytes `217572`
- v1 migration neutral `true`
- direct vs save-load resume `true`

Kalıcı M38 dokümanı: `M38_FACILITY_PORTFOLIO_CORE_I.md`.

### PR #40 — CI timeout remediation — CLOSED / MERGED

- squash merge `cba4e28bef09d4109a10380b4808eb39b7c1ffb4`
- timeout artırılmadı; her job `7 dk`
- workflow `test` ve `canonical` olarak iki paralel job'a ayrıldı
- hiçbir test/canonical runner kaldırılmadı
- `actions/upload-artifact` yok; artifact hedefi `0`
- post-merge main run `34617471052` SUCCESS

### PR #39 — M34 analyzer temizliği — CLOSED / MERGED

- squash merge `4d49b67973b96424c2c73b9f25e3a1b2d636c829`
- 10 redundant M34 import kaldırıldı
- analyzer temiz, davranış değişmedi

### M37 — President Facility Decision Loop / Turnover Replanning I — PASS

- PR #38 merged
- squash merge `ff1745671ce57fdaa56b937bf36f026f86b34ca5`
- seasonal academy facility decision loop
- president profile'e göre target/intensity/reserve recompute
- turnover anında replanning
- downgrade yok
- gerçek cash path, gizli borç yok
- derived decision history
- save/load/resume parity

## 4. Save/runtime/facility zinciri

- **M25** Save/Load + Versioning I — temel checkpoint/version/checksum/migration; `8+12=20`
- **M26** World Save Snapshot I — 48 club/leagues/players/finance; canonical `187664 bytes`
- **M27** Advanced Runtime Snapshot I — contracts/loans/installments/manager; season8 `1013092 bytes`
- **M28** History Compaction — season8 `1013092 → 736274`, `%27.3`; season20 `915648`
- **M29** President Runtime Snapshot — 48 president states; season8 `754721 bytes`
- **M30** Fan/Media/Promise Runtime Memory — bounded memory; season8 `802906 bytes`
- **M31** President Domain Resume — canonical `8+12=20`, mid-term `5+3`
- **M32** 30-season stress — `6+7+9+8`, max save `<1.3M`, final parity
- **M33** Academy Investment Core — academy `0..5`, level0 legacy
- **M34** Facility Persistence/Finance — 48 academy states, real cash funding, no hidden debt
- **M35** Academy Runtime Youth Integration — persistent academy affects real youth generation; level2 canonical ability `+1.20`, potential `+3.60`
- **M36** President Youth → Academy Investment — youthOrientation + financialDiscipline drive real academy investment; canonical `0→2`, spend `9M`
- **M37** President Facility Decision Loop — seasonal reevaluation + turnover replanning
- **M38** Facility Portfolio Core — academy + stadium + training; real matchday/player-development effects; save v2; real cash; full parity

## 5. Başkan trait wiring

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget + academy cash reserve | M20 + M36 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential transfer preference + academy target/investment intensity | M24 + M33 + M36 + M37 |

M38 stadium/training yatırımları henüz president trait'lerine otomatik bağlı değildir; bu bilinçli scope sınırıdır.

## 6. Milestone geçmişi

**M0–M38 PASS.**

M0 Deterministik sezon çekirdeği; M1 20 sezon kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer pazarı; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya hafızası; M11 başkan vaatleri; M12 vaat→taraftar; M13 vaat→medya; M14 başkanlık seçimi; M15 görev süresi/devir; M16 başkan devrinde itibar; M17 yönetim profili; M18 manager patience; M19 manager/world↔election fixed-point; M20 financial discipline; M21 transfer ambition; M22 profile feedback orchestration; M23 risk appetite; M24 youth orientation; M25 save/load; M26 world snapshot; M27 advanced runtime; M28 history compaction; M29 president runtime; M30 fan/media/promise memory; M31 president resume; M32 long-career stress; M33 academy core; M34 facility persistence/finance; M35 academy runtime youth; M36 president→academy investment; M37 seasonal facility decision loop; M38 facility portfolio core.

## 7. Kalıcı teknik kurallar

- canonical seed `20260903`
- determinism ve save/resume parity korunur
- public legacy semantics sessizce değiştirilmez
- neutral/default provider eski davranışı korur
- fixed-point feedback deterministik; convergence/cycle detection korunur
- checkpoint = sonraki sezonun opening state'i
- future save version reddedilir
- migration fixture/test zorunlu
- level0 facility legacy davranışı korur
- facility yatırımı gerçek nakitten düşer; gizli debt yok
- financialDiscipline cash reserve'i korur
- CI `test` + `canonical` iki paralel job
- her job `timeout-minutes: 7`; artırılmaz
- artifact hedefi `0`; `actions/upload-artifact` eklenmez
- hiçbir CI hatası tahminle düzeltilmez; gerçek log okunur
- PR merge için her zaman kullanıcıdan açık onay gerekir

## 8. Sonraki ürün yönü

M38 kapanmıştır. Yeni milestone **otomatik seçilmez**.

Olası yönler:
- president-driven stadium/training investment decision loop
- stadium capacity / attendance derinliği
- sponsor sistemi
- crisis sistemi
- Android save slots / autosave / backup
- election-loss game-over / switch-club UX
- 30+ sezon denge sertleştirme

Kullanıcı ürün yönünü seçmeden M39 adı/kapsamı kesinleştirilmez.

## 9. Devir / çalışma talimatı

1. Önce canlı GitHub durumunu kontrol et.
2. Öncelik: **Live GitHub > proje dosyaları > eski sohbetler**.
3. `GENEL_PROJE_OZETI.md` kalıcı handoff/source-of-truth dosyasıdır; silinmez.
4. Branch/commit/PR/workflow/job/log/artifact durumunu gerektiğinde GitHub'dan doğrudan doğrula.
5. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
6. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
7. Eski public simülasyon semantiğini sessizce değiştirme.
8. Kullanıcı açıkça onaylamadan hiçbir PR'ı merge etme.
9. Yeni ürün milestone'unu kullanıcı yönü olmadan uydurma.
10. Bu proje sohbetinde her kullanıcı mesajından sonra, assistant yanıtı tamamlanmadan önce `GENEL_PROJE_OZETI.md` güncel tutulur. Yeni teknik durum/karar yoksa dosya gereksiz tekrarlarla şişirilmez; ancak yeni kararlar, CI kanıtları, commit/PR durumu ve aktif çalışma kuralları korunur.
11. Sırf bir docs commit'inin kendi CI run numarasını tekrar dosyaya yazmak için yeni docs commit'i üretme; sonsuz özet→CI→özet döngüsü yaratma.
