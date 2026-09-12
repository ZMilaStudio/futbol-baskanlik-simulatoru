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
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz
- her kullanıcı mesajından sonra bu özet güncel tutulur
- sırf docs CI run numarasını tekrar yazmak için yeni docs commit üretilmez

## 2. CANLI DURUM — buradan devam et

**M0–M42 PASS ve `main` üzerindedir.**

Aktif ürün milestone'u henüz yok; sıradaki seçilmiş yön:
**M43 — Crisis Decision Core I**.

Kullanıcı bu çalışma oturumu için açık yetki verdi:
- yeşil milestone PR'ları ayrıca sormadan squash merge edilebilir
- bir milestone kapandıktan sonra canlı mimariye göre sonraki mantıklı milestone seçilip devam edilebilir
- bu yetki exact-head PR CI, post-merge `main` CI, 7 dakika timeout, determinism ve artifact=0 kurallarını kaldırmaz

## 3. Son kapalı milestone'lar

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 squash merge: `2868d725c4ba68601a732d98b913195d3c58a4a3`

Post-merge main CI `34660280556` — **SUCCESS**:
- test job `103461159435` — SUCCESS
- analyzer: `No issues found!`
- **173 normal/non-canonical test PASS**
- canonical job `103461159616` — SUCCESS
- **M0–M42 canonical PASS**
- artifacts: **0**
- iki job da 7 dakika sınırının altında

M42 kapsamı ve davranışı:
- tamamen kurgusal deterministic sponsor teklifleri
- teklif değeri kulüp gücü + fan trust + media credibility ile türetilir
- stable / balanced / bold teklifler
- garanti ödeme + performans bonusu + 1–3 sezon kontrat
- `financialDiscipline` ve `riskAppetite` sponsor seçiminde gerçek etkiye sahip
- kontrat başkan turnover olsa da bitene kadar devam eder
- kabul edilen kontrat geliri gerçek `sponsorRevenue` hattına akar
- sponsor sistemi kullanılmazsa legacy strength-only sponsor geliri korunur
- sponsor runtime save codec v1 + checksum + v0→v1 migration
- save/load continuation deterministic
- canonical: 48 kontrat; prudent `stable:3`, bold `bold:1`; gerçek sponsor geliri `12.33M`; legacy `13.28M`; save/resume match `true`

İlk PR CI failure'ı gerçek logdan çözüldü: economy API'ye eklenen opsiyonel `sponsorRevenueByClub` parametresi facility economy wrapper override imzasında eksikti; wrapper parametreyi delegate'e forward edecek şekilde düzeltildi.

Kalıcı doküman: `M42_SPONSOR_SYSTEM_I.md`.

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 squash merge: `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`
Post-merge main CI `34656211019`: 167 test PASS, M0–M41 PASS, artifact 0.
M41: `FanState.overallTrust` → stadium demand → attendance → matchday revenue; neutral trust 60 preserves M40; save/load continuation deterministic.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`
Post-merge main CI `34652843932`: 162 tests, M0–M40 PASS, artifacts 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`
Post-merge main CI `34649669246`: 157 tests, M0–M39 PASS, artifacts 0.

## 4. Sistem zinciri

M0 deterministik sezon; M1 kariyer; M2 oyuncu lifecycle; M3 ekonomi; M4 transfer; M5 48 kulüp/3 lig; M6 teknik direktör; M7 sözleşme/maaş; M8 kiralık/taksit; M9 taraftar; M10 medya; M11 vaatler; M12 vaat→taraftar; M13 vaat→medya; M14 seçim; M15 görev süresi/devir; M16 itibar handover; M17 yönetim profili; M18 manager patience; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility zinciri; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor system.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference
- `transferAmbition`: transfer activity + stadium priority
- `riskAppetite`: bid ceiling + stadium priority + sponsor risk/bonus preference
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance demand + sponsor offer quality
- `MediaState.credibility`: sponsor offer quality

## 5. Sıradaki yön — M43

**M43 — Crisis Decision Core I** seçildi.

Hedef: ekonomi/borç, taraftar güveni, medya güvenilirliği ve başkan yönetim profilini tek bir dar, deterministic başkanlık kriz kararında birleştirmek.

İlk tasarım ilkeleri:
- legacy simulation varsayılanında davranış değişmemeli
- mümkünse ayrı crisis domain + typed input/output; mevcut motorlara minimal entegrasyon
- kurgusal krizler; ilk sürüm dar kapsamlı
- başkan profili farklı kriz seçeneklerine gerçekten farklı karar vermeli
- kararın finans/fan/media üzerinde ölçülebilir etkisi olmalı ama sınırsız snowball yaratmamalı
- save/resume determinism ya stateless türetimle ya da explicit versioned checkpoint ile kanıtlanmalı
- canonical M43 gate + normal acceptance testleri eklenecek

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff/source-of-truth dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu oturumda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi.
8. M43 tamamlanırsa canlı `main` yeniden okunup sonraki ürün milestone'u seçilebilir.
