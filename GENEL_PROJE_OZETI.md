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
- deterministic seed/replay
- `GameDate`, integer minor-unit `Money`
- eski public simulation semantiği sessizce değiştirilmez
- save/load/resume determinism ve parity korunur
- explicit save version + migration + checksum
- future save version güvenli reddedilir
- continuation-critical state ile historical state ayrılır
- PASS yalnız canlı CI kanıtıyla yazılır
- CI iki paralel job: `test` + `canonical`
- her job `timeout-minutes: 7`; artırılmaz
- artifact hedefi `0`
- CI kırmızıysa gerçek log okunmadan patch atılmaz

## 2. CANLI DURUM — buradan devam et

**M0–M41 PASS ve `main` üzerindedir.**

Aktif milestone:
**M42 — Sponsor System I**

Branch: `feat/m42-sponsor-system-core`
PR: `#45` — **OPEN / NOT MERGED / CODE-BEARING VERIFIED**

Kullanıcı 12 Eylül gecesi bu çalışma oturumu için açıkça sürekli yetki verdi:
- yeşil milestone PR'ları ayrıca sormadan merge edilebilir
- bir milestone kapandıktan sonra canlı mimariye göre bir sonraki mantıklı milestone seçilip devam edilebilir
- bu geçici gece yetkisi kalite/CI kurallarını kaldırmaz; exact-head ve post-merge main doğrulamaları yine zorunludur

### M42 kapsamı

- tamamen kurgusal, deterministik sponsor teklifleri
- teklif değeri: kulüp gücü + taraftar güveni + medya güvenilirliği
- stable / balanced / bold teklif profilleri
- garanti yıllık ödeme + performans bonusu
- 1–3 sezon kontrat
- `financialDiscipline` + `riskAppetite` sponsor seçimini etkiler
- mevcut çok yıllı kontrat başkan değişse bile sözleşme bitene kadar devam eder
- gerçek sponsor geliri `BasicEconomyEngine.sponsorRevenue` satırına akabilir
- sponsor sistemi çağrılmazsa eski strength-only sponsor gelir semantiği birebir korunur
- facility economy wrapper yeni opsiyonel sponsor gelir parametresini forward eder
- sponsor runtime checkpoint + save codec v1
- checksum + sentetik v0→v1 migration
- save/load continuation parity
- 6 yeni normal test + M42 canonical runner
- workflow'a M41 sonrası `Run M42 sponsor system core` gate'i eklendi

### M42 CI geçmişi

İlk PR run `34659361772` FAILED:
- kök neden: `BasicEconomyEngine.simulateSeason` API'sine eklenen opsiyonel `sponsorRevenueByClub` parametresi `_FacilityAwareEconomyEngine` override imzasında yoktu
- gerçek log incelendi; davranış failure değildi
- fix: wrapper imzasına parametre eklendi ve delegate'e forward edildi

Code-bearing verified HEAD:
`dc2828828a0cc9120d96981a54c7c05c2da3c73d`

Run `34659455731` — **SUCCESS**
- test job `103458732601` — SUCCESS
- analyzer: `No issues found!`
- **173 normal/non-canonical test PASS**
- canonical job `103458732736` — SUCCESS
- **M0–M42 canonical PASS**
- artifacts: **0**
- test ≈ `1m54s`
- canonical ≈ `4m32s`
- iki job da 7 dakika sınırının altında

M42 canonical:
- target `t1_01`
- contracts `48`
- prudent choice `t1_01-s0-stable:3`
- bold choice `t1_01-s0-bold:1`
- real sponsor revenue `12.33M`
- legacy sponsor revenue `13.28M`
- save/resume match `true`
- result **PASS**

Kalıcı doküman: `M42_SPONSOR_SYSTEM_I.md`.

Sıradaki zorunlu adım: docs-inclusive exact PR HEAD CI'ını yeniden doğrula. SUCCESS + 173 tests + M0–M42 PASS + artifact 0 ise gece yetkisiyle PR #45 squash merge edilebilir. Ardından exact merge SHA `main` CI doğrulanır ve M42 CLOSED/PASS yapılır.

## 3. Son kapalı milestone'lar

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 squash merge: `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`
Post-merge main CI `34656211019`: analyzer clean, 167 test PASS, M0–M41 PASS, artifact 0.
Docs close main HEAD: `891091a9f777bb7095f649634553d73b39a0858e`; docs CI `34656606160` SUCCESS.

M41: `FanState.overallTrust` → stadium demand → attendance → matchday revenue; neutral trust 60 preserves M40; save/load continuation deterministic.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`
Post-merge main CI `34652843932`: 162 tests, M0–M40 PASS, artifacts 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`
Post-merge main CI `34649669246`: 157 tests, M0–M39 PASS, artifacts 0.

## 4. Sistem zinciri

M0 deterministik sezon; M1 kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya; M11 vaatler; M12 vaat→taraftar; M13 vaat→medya; M14 seçim; M15 görev süresi/devir; M16 itibar handover; M17 yönetim profili; M18 manager patience; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility zinciri; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor system (aktif PR #45).

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority
- `financialDiscipline`: transfer affordability + facility reserve + sponsor contract preference
- `transferAmbition`: transfer activity + stadium priority
- `riskAppetite`: bid ceiling + stadium priority + sponsor bonus/risk preference
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance demand + M42 sponsor offer quality
- `MediaState.credibility`: M42 sponsor offer quality

## 5. Sonraki yön

M42 başarıyla kapanırsa, gece yetkisi kapsamında canlı `main` tekrar okunup bir sonraki ürün milestone'u seçilebilir. En doğal aday: **M43 — Crisis Decision Core I**; ekonomi/borç, taraftar güveni, medya güvenilirliği ve başkan profillerini gerçek başkanlık kriz kararında birleştiren, mümkünse stateless ve legacy-safe dar kapsamlı bir sistem.

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff/source-of-truth dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu gece oturumunda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi. Bu yetki exact-head/post-merge doğrulama zorunluluğunu kaldırmaz.
8. Her kullanıcı mesajından sonra assistant yanıtı tamamlanmadan önce bu özet güncel tutulur.
9. Sırf bir docs commit'inin kendi CI run numarasını tekrar dosyaya yazmak için yeni docs commit'i üretme; sonsuz özet→CI→özet döngüsü yaratma.
