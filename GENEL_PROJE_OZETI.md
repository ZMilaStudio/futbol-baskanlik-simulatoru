# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 12 Eylül 2026

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

## 2. Geliştirme stratejisi ve kalıcı ilkeler

Öncelik deterministik, headless ve uzun kariyerde otomatik test edilebilir saf Dart simülasyon çekirdeğidir. Flutter/Android mobil kabuk daha sonra gelir.

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

**M0–M39 PASS ve `main` üzerindedir.**

Son kapalı ürün milestone'u:
**M39 — President Facility Portfolio Decision Loop I**.

Yeni M40 kapsamı henüz seçilmemiştir. Yeni ürün milestone'u kullanıcı yönü olmadan otomatik başlatılmaz.

### PR #42 — M39 President Facility Portfolio Decision Loop I — CLOSED / MERGED

Branch: `feat/m39-president-facility-portfolio-loop`

Final PR doğrulaması:
- final PR HEAD: `ea4f1481b563cdd5d8386eb253c476cfb980194c`
- final PR CI run `34648104716` — **SUCCESS**
- test job `103423632663` — **SUCCESS**
- canonical job `103423632885` — **SUCCESS**
- analyzer: `No issues found!`
- **157 normal/non-canonical test PASS**
- **M0–M39 canonical PASS**
- M39 canonical step — **SUCCESS**
- artifacts `0`
- iki job da sabit `timeout-minutes: 7` sınırının altında

Kullanıcı açıkça merge onayı verdi. PR #42 squash merge edildi.

Squash merge:
- `ea95f767eb95194455e012cb0b9ec5cc6e81667f`

Post-merge `main` CI:
- run `34649669246` — **SUCCESS**
- test job `103428619127` — **SUCCESS**
- canonical job `103428619421` — **SUCCESS**
- `dart analyze`: **No issues found!**
- `dart test --exclude-tags canonical-feedback`: **157 tests passed**
- M0–M39 canonical runner zinciri: **PASS**
- M39 canonical adımı: **SUCCESS**
- artifacts: **0**
- test job ≈ `3m00s`
- canonical job ≈ `4m21s`
- iki job da sabit `timeout-minutes: 7` sınırının altında

M39 artık **CLOSED / PASS / main** durumundadır.

### M39 davranışı

- M37 academy kararı aynı orchestrator ile önce uygulanır; legacy academy target/before/after/upgrades/reserve semantiği korunur.
- stadium priority: `(transferAmbition * 2 + riskAppetite) ~/ 3`
- training-ground priority: `(youthOrientation * 2 + managerPatience) ~/ 3`
- `financialDiscipline` gerçek cash reserve politikasına girer.
- stadium/training target level `0..5` bounded'dır.
- portfolio upgrade denemeleri deterministic round-robin `training → stadium` sırasındadır.
- cash reserve meşru biçimde sonraki yatırımı engelleyebilir; reserve/debt invariant gevşetilmez.
- gerçek cash kullanılır; gizli debt yaratılmaz.
- downgrade yoktur.
- president turnover sonrasında iki portfolio target'ı bir sonraki season window'da yeniden hesaplanır.
- direct `2 season` ile `1 + save/load + 1` decision/youth/final checkpoint parity korunur.

M39 canonical:
- seed `20260903`
- start checkpoint season `8`
- target club `t3_05`
- turnover season `9`
- presidents `m39-cautious-president → m39-portfolio-builder-president`
- academy path `0→0, 0→2`
- training targets `0, 5`
- training path `0→0, 0→1`
- stadium targets `0, 5`
- stadium path `0→0, 0→0`
- applied portfolio upgrades `0+0, 1+0`
- spend `0.00M, 13.00M`
- completed seasons `10`
- turnover replanned `true`
- split decisions match `true`
- youth history match `true`
- final checkpoint match `true`
- canonical result `PASS`

Not: builder window'da academy `9M` harcadıktan sonra reserve yalnız training upgrade'ine izin verir; stadium target `5` olarak yeniden planlanmış olsa da aynı pencerede uygulanmaz. Ayrı affordable M39 testi aynı portfolio policy altında hem stadium hem training yatırımının gerçekleşebildiğini doğrular.

Kalıcı M39 dokümanı: `M39_PRESIDENT_FACILITY_PORTFOLIO_DECISION_LOOP_I.md`.

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
- **M37** President Facility Decision Loop — seasonal academy reevaluation + turnover replanning
- **M38** Facility Portfolio Core — academy + stadium + training; real matchday/player-development effects; save v2; full parity
- **M39** President Facility Portfolio Decision Loop — president-driven stadium/training targets, reserve-safe seasonal investment, turnover replanning, save/resume parity

### M38 temel davranışı

- 48 kulübün tamamında persistent `academy + stadium + training ground` portfolio
- stadium/training level `0..5`
- facility upgrade maliyeti gerçek club cash'ten düşer; gizli debt yok
- stadium gerçek `matchdayRevenue` hattını etkiler
- training ground gerçek offseason player-development hattını etkiler
- training yalnız pozitif gelişim delta'sını artırır
- level `0` legacy davranışını korur
- facility save formatı `v2`; `v0 → v1 → v2` ve `v1 → v2` neutral migration
- full portfolio save/load/resume parity korunur

M38 canonical: stadium `0→1`, training `0→1`, spend `9M`, debt unchanged, matchday `3.49M→3.75M`, player ability `57.4905→57.5290`, v1 migration neutral, direct/resume parity `true`.

## 5. Başkan trait wiring

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold + training-ground priority | M18 + M39 |
| `financialDiscipline` | transfer affordability/budget + academy/portfolio cash reserve | M20 + M36 + M39 |
| `transferAmbition` | completed transfer slots + stadium priority | M21 + M39 |
| `riskAppetite` | buyer max-bid ceiling + stadium priority | M23 + M39 |
| `youthOrientation` | youth/potential transfer preference + academy target/investment + training-ground priority | M24 + M33 + M36 + M37 + M39 |

## 6. Milestone geçmişi

**M0–M39 PASS / main.**

M0 Deterministik sezon çekirdeği; M1 20 sezon kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer pazarı; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya hafızası; M11 başkan vaatleri; M12 vaat→taraftar; M13 vaat→medya; M14 başkanlık seçimi; M15 görev süresi/devir; M16 başkan devrinde itibar; M17 yönetim profili; M18 manager patience; M19 manager/world↔election fixed-point; M20 financial discipline; M21 transfer ambition; M22 profile feedback orchestration; M23 risk appetite; M24 youth orientation; M25 save/load; M26 world snapshot; M27 advanced runtime; M28 history compaction; M29 president runtime; M30 fan/media/promise memory; M31 president resume; M32 long-career stress; M33 academy core; M34 facility persistence/finance; M35 academy runtime youth; M36 president→academy investment; M37 seasonal academy facility decision loop; M38 facility portfolio core; M39 president facility portfolio decision loop.

## 7. CI ve teknik borç durumu

- PR #39: 10 redundant M34 import temizlendi; analyzer temiz.
- PR #40: tek-job 7 dakika timeout riski giderildi; workflow `test` + `canonical` iki paralel job'a ayrıldı.
- Her job `timeout-minutes: 7`; artırılmaz.
- Hiçbir canonical/test kontrolü kaldırılmadı.
- Artifact hedefi `0`; `actions/upload-artifact` eklenmez.
- Son M39 post-merge main doğrulaması: run `34649669246` SUCCESS, 157 test PASS, M0–M39 PASS, artifact 0.

## 8. Sonraki ürün yönü

M39 kapanmıştır. Yeni milestone **otomatik seçilmez**.

Olası yönler:
- stadium capacity / attendance derinliği
- sponsor sistemi
- crisis sistemi
- Android save slots / autosave / backup
- election-loss game-over / switch-club UX
- 30+ sezon denge sertleştirme

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