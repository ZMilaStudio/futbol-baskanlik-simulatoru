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

**M0–M40 PASS ve `main` üzerindedir.**

Aktif ürün milestone'u:
**M41 — Attendance Demand & Fan Trust Integration II**.

Branch: `feat/m41-fan-trust-attendance-integration`
PR: `#44` — **OPEN / NOT MERGED / MERGE-READY**

Kullanıcı M41 yönünü açıkça onayladı. Code-bearing ve docs-inclusive HEAD canlı CI ile doğrulandı. PR mergeable durumdadır. Merge için kullanıcıdan ayrıca explicit onay gerekir.

### M41 kapsamı

- mevcut `FanState.overallTrust` stadium talebine bağlanır
- neutral fan trust `60`; bu değer M40 davranışını birebir korur
- fan trust demand multiplier: `7000 + fanTrust * 50 bps`
- trust `0 → 7000 bps`, `60 → 10000 bps`, `100 → 12000 bps`
- düşük trust aynı sportif bağlamda talebi bastırır; yüksek trust artırır
- `FacilityRuntimeCareerEngine` opsiyonel typed `Map<String, FanState>` alır
- fan state verilmezse neutral `60` kullanılır; legacy caller'lar değişmez
- fan map key'i `FanState.clubId` ile eşleşmelidir
- facility save formatı `v2` değişmez; fan state facility checkpoint'e kopyalanmaz
- aynı fan state save/load sonrası tekrar verildiğinde continuation deterministiktir
- 5 yeni normal test ve M41 canonical runner eklendi
- workflow'a M40 sonrasında `Run M41 fan trust attendance integration` gate'i eklendi
- `timeout-minutes: 7` ve artifact `0` kuralları korunur

### M41 PR CI kanıtı

Code-bearing HEAD: `215e5a0eed817037badfd5fc5086b8e4ff933756`
Run `34654802377` — **SUCCESS**
- test job `103444747764` — **SUCCESS**, ≈ `3m01s`
- canonical job `103444747982` — **SUCCESS**, ≈ `4m29s`
- analyzer: `No issues found!`
- **167 normal/non-canonical test PASS**
- **M0–M41 canonical PASS**
- artifacts: **0**

Docs-inclusive verified HEAD: `2a4bccdbde22f5f37a5893e20548ab6b022bf736`
Run `34655222974` — **SUCCESS**
- test job `103446093271` — **SUCCESS**
- canonical job `103446093339` — **SUCCESS**
- analyzer / normal tests SUCCESS
- M0–M41 canonical adımlarının tamamı SUCCESS
- artifacts: **0**
- PR #44 mergeable: `true`
- iki CI job'ı da sabit 7 dakika sınırının altında tamamlandı

M41 canonical:
- target club `t1_01`
- demand low / neutral / high: `15360 / 19200 / 22080`
- trust multipliers: `8000 / 10000 / 11500 bps`
- neutral M40 parity `true`
- trust demand ordered `true`
- real matchday revenue low → high: `10.29M → 12.06M`
- real fan revenue effect `true`
- save/load continuation match `true`
- result **PASS**

Kalıcı M41 dokümanı: `M41_ATTENDANCE_DEMAND_FAN_TRUST_INTEGRATION_II.md`.

### M40 — CLOSED / MERGED / PASS

PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`

Post-merge `main` CI `34652843932` — **SUCCESS**:
- analyzer clean
- 162 normal/non-canonical test PASS
- M0–M40 canonical PASS
- artifacts 0
- test ≈ `2m55s`, canonical ≈ `4m26s`

M40: stadium capacity curve `18k → 36k`; demand from club strength + league position; attendance bounded by capacity; occupancy/ticket-yield; M38 `+750 bps × level` effect retained as revenue ceiling; level 0 exact legacy; facility save v2 unchanged.

Kalıcı M40 dokümanı: `M40_STADIUM_CAPACITY_ATTENDANCE_CORE_I.md`.

### M39 — CLOSED / MERGED / PASS

PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`
Post-merge `main` CI `34649669246` — SUCCESS; 157 tests; M0–M39 PASS; artifacts 0.

M39: academy legacy first; president profile stadium/training targetları; `financialDiscipline` reserve; deterministic `training → stadium` round-robin; real cash/no hidden debt; turnover replanning; save/load parity.

## 4. Save/runtime/facility zinciri

- **M25** Save/Load + Versioning I
- **M26** World Save Snapshot I
- **M27** Advanced Runtime Snapshot I
- **M28** History Compaction
- **M29** President Runtime Snapshot
- **M30** Fan/Media/Promise Runtime Memory
- **M31** President Domain Resume
- **M32** 30-season stress
- **M33** Academy Investment Core
- **M34** Facility Persistence/Finance
- **M35** Academy Runtime Youth Integration
- **M36** President Youth → Academy Investment
- **M37** President Facility Decision Loop
- **M38** Facility Portfolio Core — academy + stadium + training; real effects; save v2
- **M39** President Facility Portfolio Decision Loop — president-driven portfolio investment
- **M40** Stadium Capacity & Attendance Core I — CLOSED / PASS / main
- **M41** Attendance Demand & Fan Trust Integration II — **PR #44 MERGE-READY / NOT MERGED**

## 5. Başkan / taraftar trait wiring

| Trait / state | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold + training-ground priority | M18 + M39 |
| `financialDiscipline` | transfer affordability/budget + academy/portfolio cash reserve | M20 + M36 + M39 |
| `transferAmbition` | completed transfer slots + stadium priority | M21 + M39 |
| `riskAppetite` | buyer max-bid ceiling + stadium priority | M23 + M39 |
| `youthOrientation` | youth/potential transfer preference + academy target/investment + training-ground priority | M24 + M33 + M36 + M37 + M39 |
| `FanState.overallTrust` | stadium demand → attendance → matchday revenue | M41 |

## 6. Milestone geçmişi

**M0–M40 PASS / main. M41 PR #44 MERGE-READY / NOT MERGED.**

M0 deterministik sezon; M1 20 sezon kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya; M11 vaatler; M12 vaat→taraftar; M13 vaat→medya; M14 seçim; M15 görev süresi/devir; M16 itibar handover; M17 yönetim profili; M18 manager patience; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility zinciri; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance (PR #44).

## 7. CI ve teknik borç durumu

- CI `test` + `canonical` iki paralel job'dur.
- Her job `timeout-minutes: 7`; artırılmaz.
- Hiçbir canonical/test kontrolü kaldırılmaz.
- Artifact hedefi `0`; `actions/upload-artifact` eklenmez.
- CI kırmızıysa gerçek log okunmadan patch atılmaz.
- Son kapalı main doğrulaması: M40 docs-only run `34653341164` — test SUCCESS, canonical SUCCESS, M0–M40 SUCCESS, artifact 0.
- M41 code-bearing PR run `34654802377` — analyzer clean, 167 test PASS, M0–M41 PASS, artifact 0.
- M41 docs-inclusive PR run `34655222974` — test SUCCESS, canonical SUCCESS, M0–M41 PASS, artifact 0.

## 8. Sonraki ürün yönü

Aktif çalışma **M41**'dir. PR #44 kullanıcı açıkça merge onayı vermeden ve post-merge main CI yeşil olmadan M41 CLOSED/PASS yapılmaz ve M42 başlatılmaz.

M41 sonrası yeni ürün milestone'u yine kullanıcı yönüyle seçilir.

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
