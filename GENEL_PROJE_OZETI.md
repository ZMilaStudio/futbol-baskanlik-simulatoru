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

Aktif ürün milestone'u:
**M40 — Stadium Capacity & Attendance Core I**.

Branch: `feat/m40-stadium-capacity-attendance`

M40 şu anda **ACTIVE / NOT YET CI-VERIFIED / NOT MERGED** durumundadır.

### M40 hedefi ve mevcut branch kapsamı

- mevcut stadium level `0..5` korunur
- kapasite eğrisi: `18.000 → 20.500 → 23.500 → 27.000 → 31.000 → 36.000`
- taraftar talebi deterministic olarak club strength + league position üzerinden türetilir
- attendance her zaman `min(capacity, demand)` ile kapasiteye bounded kalır
- occupancy basis-points olarak türetilir
- stadium level arttıkça ticket-yield katkısı artar
- M38'deki `%7,5 × level` matchday revenue etkisi kaldırılmaz; yeni modelde **gelir tavanı** olarak korunur
- düşük talepte boş koltuk nedeniyle yatırım getirisi bu tavanın altında kalabilir
- güçlü talepte mevcut M38 gelir tavanı tamamen realize edilebilir
- level `0` matchday multiplier tam `10000 bps` kalarak legacy davranışı korur
- yeni attendance/capacity state save'e yazılmaz; stadium level + sezon bağlamından türetildiği için facility save formatı `v2` değişmez
- gerçek `FacilityRuntimeCareerEngine` ekonomisi attendance-aware multiplier kullanır
- save/load/resume determinism korunacak
- M40 için 5 yeni normal test ve yeni canonical runner branch'e eklendi
- workflow'a M39 sonrasında `Run M40 stadium capacity attendance core` adımı eklendi
- `timeout-minutes: 7` ve artifact `0` kuralları değişmedi

M40 için henüz PASS yazılmaz. PR açılıp gerçek GitHub Actions analyzer/test/canonical/log/artifact kanıtı alınacaktır.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS

PR #42 squash merge:
- `ea95f767eb95194455e012cb0b9ec5cc6e81667f`

Post-merge `main` CI:
- run `34649669246` — **SUCCESS**
- test job `103428619127` — **SUCCESS**
- canonical job `103428619421` — **SUCCESS**
- analyzer: `No issues found!`
- **157 normal/non-canonical test PASS**
- **M0–M39 canonical PASS**
- artifacts `0`
- test job ≈ `3m00s`
- canonical job ≈ `4m21s`
- iki job da sabit `timeout-minutes: 7` sınırının altında

M39 davranışı:
- M37 academy kararı aynı orchestrator ile önce uygulanır
- stadium priority: `(transferAmbition * 2 + riskAppetite) ~/ 3`
- training-ground priority: `(youthOrientation * 2 + managerPatience) ~/ 3`
- `financialDiscipline` gerçek cash reserve politikasına girer
- portfolio upgrade denemeleri deterministic round-robin `training → stadium`
- gerçek cash kullanılır, gizli debt ve downgrade yoktur
- president turnover stadium/training target'larını yeniden planlar
- direct `2 season` ile `1 + save/load + 1` decision/youth/final checkpoint parity korunur

M39 canonical: target `t3_05`, academy `0→0, 0→2`, training target `0,5` / path `0→0,0→1`, stadium target `0,5` / path `0→0,0→0`, spend `0M,13M`, turnover replanned `true`, split decisions/youth/final checkpoint parity `true`.

Kalıcı M39 dokümanı: `M39_PRESIDENT_FACILITY_PORTFOLIO_DECISION_LOOP_I.md`.

## 4. Save/runtime/facility zinciri

- **M25** Save/Load + Versioning I — temel checkpoint/version/checksum/migration; `8+12=20`
- **M26** World Save Snapshot I — 48 club/leagues/players/finance
- **M27** Advanced Runtime Snapshot I — contracts/loans/installments/manager
- **M28** History Compaction — bounded history/save
- **M29** President Runtime Snapshot — 48 president states
- **M30** Fan/Media/Promise Runtime Memory — bounded memory
- **M31** President Domain Resume — canonical `8+12=20`, mid-term resume
- **M32** 30-season stress — multi-save chain + final parity
- **M33** Academy Investment Core — academy `0..5`, level0 legacy
- **M34** Facility Persistence/Finance — real cash funding, no hidden debt
- **M35** Academy Runtime Youth Integration — academy affects real youth generation
- **M36** President Youth → Academy Investment — profile-driven real academy investment
- **M37** President Facility Decision Loop — seasonal academy reevaluation + turnover replanning
- **M38** Facility Portfolio Core — academy + stadium + training; real matchday/player-development effects; save v2; full parity
- **M39** President Facility Portfolio Decision Loop — president-driven stadium/training targets, reserve-safe investment, turnover replanning
- **M40** Stadium Capacity & Attendance Core I — **ACTIVE / branch**; stadium gelir etkisini kapasite + talep + attendance ile derinleştiriyor

### M38 temel davranışı

- 48 kulübün tamamında persistent `academy + stadium + training ground` portfolio
- stadium/training level `0..5`
- facility upgrade maliyeti gerçek club cash'ten düşer; gizli debt yok
- stadium gerçek `matchdayRevenue` hattını etkiler
- training ground gerçek offseason player-development hattını etkiler
- level `0` legacy davranışını korur
- facility save formatı `v2`; neutral migration korunur
- full portfolio save/load/resume parity korunur

## 5. Başkan trait wiring

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold + training-ground priority | M18 + M39 |
| `financialDiscipline` | transfer affordability/budget + academy/portfolio cash reserve | M20 + M36 + M39 |
| `transferAmbition` | completed transfer slots + stadium priority | M21 + M39 |
| `riskAppetite` | buyer max-bid ceiling + stadium priority | M23 + M39 |
| `youthOrientation` | youth/potential transfer preference + academy target/investment + training-ground priority | M24 + M33 + M36 + M37 + M39 |

## 6. Milestone geçmişi

**M0–M39 PASS / main. M40 ACTIVE / branch / CI bekliyor.**

M0 Deterministik sezon çekirdeği; M1 20 sezon kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer pazarı; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya hafızası; M11 başkan vaatleri; M12 vaat→taraftar; M13 vaat→medya; M14 başkanlık seçimi; M15 görev süresi/devir; M16 başkan devrinde itibar; M17 yönetim profili; M18 manager patience; M19 manager/world↔election fixed-point; M20 financial discipline; M21 transfer ambition; M22 profile feedback orchestration; M23 risk appetite; M24 youth orientation; M25 save/load; M26 world snapshot; M27 advanced runtime; M28 history compaction; M29 president runtime; M30 fan/media/promise memory; M31 president resume; M32 long-career stress; M33 academy core; M34 facility persistence/finance; M35 academy runtime youth; M36 president→academy investment; M37 seasonal academy facility decision loop; M38 facility portfolio core; M39 president facility portfolio decision loop; M40 stadium capacity/attendance (active).

## 7. CI ve teknik borç durumu

- CI `test` + `canonical` iki paralel job'dur.
- Her job `timeout-minutes: 7`; artırılmaz.
- Hiçbir canonical/test kontrolü kaldırılmaz.
- Artifact hedefi `0`; `actions/upload-artifact` eklenmez.
- CI kırmızıysa gerçek log okunmadan patch atılmaz.
- Son kapalı main doğrulaması: docs-only run `34650277198` — test SUCCESS, canonical SUCCESS, M0–M39 SUCCESS, artifact 0.

## 8. Sonraki ürün yönü

Aktif çalışma **M40**'tır. M40 doğrulanıp explicit kullanıcı merge onayı alınmadan yeni M41 başlatılmaz.

M40 sonrası olası yönler:
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
