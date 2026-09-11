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

**M0–M41 PASS ve `main` üzerindedir.**

Son kapalı ürün milestone'u:
**M41 — Attendance Demand & Fan Trust Integration II**.

Şu anda aktif yeni ürün milestone'u yoktur. **M42 kullanıcı yönü olmadan otomatik başlatılmaz.**

### M41 — CLOSED / MERGED / PASS

Branch: `feat/m41-fan-trust-attendance-integration`
PR: `#44` — **CLOSED / MERGED**

Kullanıcı açıkça merge onayı verdi. PR #44 exact verified HEAD üzerinden squash merge edildi.

Final PR HEAD:
- `41c8c54b59df03089d3483acec4828a5522a76d0`

Final PR CI:
- run `34655656524` — **SUCCESS**
- test job `103447366209` — **SUCCESS**
- canonical job `103447366453` — **SUCCESS**
- analyzer: `No issues found!`
- **167 normal/non-canonical test PASS**
- **M0–M41 canonical PASS**
- artifacts: **0**
- iki job da sabit `timeout-minutes: 7` sınırının altında

Squash merge:
- `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`

Post-merge `main` CI:
- run `34656211019` — **SUCCESS**
- test job `103449085096` — **SUCCESS**
- canonical job `103449085129` — **SUCCESS**
- `dart analyze`: **No issues found!**
- `dart test --exclude-tags canonical-feedback`: **167 tests passed**
- **M0–M41 canonical runner zinciri: PASS**
- M41 canonical adımı: **SUCCESS / PASS**
- artifacts: **0**
- iki job da sabit `timeout-minutes: 7` sınırının altında

M41 davranışı:
- mevcut `FanState.overallTrust` stadium talebine bağlandı
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

M41 canonical:
- target club `t1_01`
- demand low / neutral / high: `15360 / 19200 / 22080`
- trust multipliers: `8000 / 10000 / 11500 bps`
- neutral M40 parity `true`
- trust demand ordered `true`
- real matchday revenue low → high: `10.29M → 12.06M`
- real fan revenue effect `true`
- save/load continuation match `true`
- canonical result **PASS**

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
- **M41** Attendance Demand & Fan Trust Integration II — **CLOSED / PASS / main**

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

**M0–M41 PASS / main.**

M0 deterministik sezon; M1 20 sezon kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya; M11 vaatler; M12 vaat→taraftar; M13 vaat→medya; M14 seçim; M15 görev süresi/devir; M16 itibar handover; M17 yönetim profili; M18 manager patience; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility zinciri; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance.

## 7. CI ve teknik borç durumu

- CI `test` + `canonical` iki paralel job'dur.
- Her job `timeout-minutes: 7`; artırılmaz.
- Hiçbir canonical/test kontrolü kaldırılmaz.
- Artifact hedefi `0`; `actions/upload-artifact` eklenmez.
- CI kırmızıysa gerçek log okunmadan patch atılmaz.
- M41 final PR HEAD run `34655656524` — analyzer clean, 167 test PASS, M0–M41 PASS, artifact 0.
- M41 post-merge main run `34656211019` — analyzer clean, 167 test PASS, M0–M41 PASS, artifact 0.

## 8. Sonraki ürün yönü

M41 kapanmıştır. Şu anda aktif yeni milestone yoktur. **M42 kullanıcı yönü olmadan otomatik seçilmez veya başlatılmaz.**

Olası yönler canlı kod mimarisine göre yeniden değerlendirilmelidir; önce `main` ve bu özet okunur, ardından kullanıcı ürün yönü verir.

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
