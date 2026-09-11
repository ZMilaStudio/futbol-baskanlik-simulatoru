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

Son kapalı ürün milestone'u:
**M40 — Stadium Capacity & Attendance Core I**.

Şu anda aktif yeni ürün milestone'u yoktur. **M41 kullanıcı yönü olmadan otomatik başlatılmaz.**

### M40 — CLOSED / MERGED / PASS

Branch: `feat/m40-stadium-capacity-attendance`
PR: `#43` — **CLOSED / MERGED**

Kullanıcı açıkça merge onayı verdi. PR #43 squash merge edildi.

Squash merge:
- `8edcdb67ee77f16e64b40d5b44588deae562625f`

Post-merge `main` CI:
- run `34652843932` — **SUCCESS**
- test job `103438699230` — **SUCCESS**
- canonical job `103438698979` — **SUCCESS**
- `dart analyze`: **No issues found!**
- `dart test --exclude-tags canonical-feedback`: **162 tests passed**
- **M0–M40 canonical runner zinciri: PASS**
- M40 canonical adımı: **SUCCESS / PASS**
- artifacts: **0**
- test job ≈ `2m55s`
- canonical job ≈ `4m26s`
- iki job da sabit `timeout-minutes: 7` sınırının altında

M40 davranışı:
- stadium level `0..5` korunur
- kapasite eğrisi `18.000 → 20.500 → 23.500 → 27.000 → 31.000 → 36.000`
- taraftar talebi deterministic club strength + league position üzerinden türetilir
- attendance = `min(capacity, demand)`
- occupancy basis-points olarak türetilir
- stadium level arttıkça ticket-yield katkısı artar
- M38'deki `%7,5 × level` matchday revenue etkisi kaldırılmaz; yeni modelde **gelir tavanı** olarak korunur
- düşük talepte boş koltuk yatırım getirisini bu tavanın altında bırakabilir
- güçlü talepte mevcut gelir tavanı tamamen realize edilebilir
- level `0` multiplier tam `10000 bps` ile legacy davranışı korur
- attendance/capacity derived state save'e yazılmaz; facility save formatı `v2` değişmez
- `FacilityRuntimeCareerEngine` attendance-aware multiplier kullanır
- save/load/resume determinism korunur

M40 canonical:
- target club `t1_01`
- capacities `18000, 20500, 23500, 27000, 31000, 36000`
- capacity monotonic `true`
- level zero legacy `true`
- weak demand `11700/36000`, occupancy `3250 bps`, realized multiplier `10750 bps`, underused `true`
- strong demand `20500/20500`, occupancy `10000 bps`, realized multiplier `10750 bps`, level-1 ceiling realized `true`
- real matchday revenue `9.84M → 10.58M`
- save/load continuation match `true`
- canonical result **PASS**

M38 regression notu: attendance-aware model sonrası M38 canonical hâlâ PASS; düşük-talep `t3_05` örneğinde matchday `3.49M → 3.54M`. M38 milestone zamanındaki flat-model çıktısı `3.49M → 3.75M` idi. M38 invariant'ı exact tutar değil, stadium upgrade'in real matchday revenue'yu artırmasıdır. Cash/debt/save/training/parity invariant'ları korunur.

Kalıcı M40 dokümanı: `M40_STADIUM_CAPACITY_ATTENDANCE_CORE_I.md`.

### M39 — CLOSED / MERGED / PASS

PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`

Post-merge `main` CI `34649669246` — **SUCCESS**:
- 157 normal/non-canonical test PASS
- M0–M39 canonical PASS
- artifacts 0
- test ≈ `3m00s`, canonical ≈ `4m21s`

M39: academy legacy first; president profile stadium/training targetları; `financialDiscipline` cash reserve; deterministic `training → stadium` round-robin; real cash/no hidden debt; turnover replanning; save/load parity.

Kalıcı M39 dokümanı: `M39_PRESIDENT_FACILITY_PORTFOLIO_DECISION_LOOP_I.md`.

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
- **M40** Stadium Capacity & Attendance Core I — **CLOSED / PASS / main**

## 5. Başkan trait wiring

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold + training-ground priority | M18 + M39 |
| `financialDiscipline` | transfer affordability/budget + academy/portfolio cash reserve | M20 + M36 + M39 |
| `transferAmbition` | completed transfer slots + stadium priority | M21 + M39 |
| `riskAppetite` | buyer max-bid ceiling + stadium priority | M23 + M39 |
| `youthOrientation` | youth/potential transfer preference + academy target/investment + training-ground priority | M24 + M33 + M36 + M37 + M39 |

## 6. Milestone geçmişi

**M0–M40 PASS / main.**

M0 Deterministik sezon çekirdeği; M1 20 sezon kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer pazarı; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya hafızası; M11 başkan vaatleri; M12 vaat→taraftar; M13 vaat→medya; M14 başkanlık seçimi; M15 görev süresi/devir; M16 başkan devrinde itibar; M17 yönetim profili; M18 manager patience; M19 manager/world↔election fixed-point; M20 financial discipline; M21 transfer ambition; M22 profile feedback orchestration; M23 risk appetite; M24 youth orientation; M25 save/load; M26 world snapshot; M27 advanced runtime; M28 history compaction; M29 president runtime; M30 fan/media/promise memory; M31 president resume; M32 long-career stress; M33 academy core; M34 facility persistence/finance; M35 academy runtime youth; M36 president→academy investment; M37 seasonal academy facility decision loop; M38 facility portfolio core; M39 president facility portfolio decision loop; M40 stadium capacity/attendance.

## 7. CI ve teknik borç durumu

- CI `test` + `canonical` iki paralel job'dur.
- Her job `timeout-minutes: 7`; artırılmaz.
- Hiçbir canonical/test kontrolü kaldırılmaz.
- Artifact hedefi `0`; `actions/upload-artifact` eklenmez.
- CI kırmızıysa gerçek log okunmadan patch atılmaz.
- M40 final PR HEAD run `34652334241` — SUCCESS.
- M40 post-merge main run `34652843932` — analyzer temiz, 162 test PASS, M0–M40 PASS, artifact 0.

## 8. Sonraki ürün yönü

M40 kapanmıştır. Şu anda aktif yeni milestone yoktur. **Yeni ürün milestone'u kullanıcı yönü olmadan otomatik seçilmez.**

Olası yönler:
- fan trust / demand bağlantısı ile attendance derinliği II
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
