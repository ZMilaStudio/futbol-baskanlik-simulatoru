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
- her kullanıcı mesajından sonra bu özet güncel tutulur
- docs→CI→docs sonsuz döngüsü üretilmez

## 2. CANLI DURUM — buradan devam et

**M0–M42 PASS ve `main` üzerindedir.**

Aktif milestone:
**M43 — Crisis Decision Core I**

Branch: `feat/m43-crisis-decision-core`
PR: henüz açılmadı
Durum: **CODE COMPLETE / CI NOT YET VERIFIED**

Kullanıcı bu oturumda yeşil milestone PR'larının ayrıca sorulmadan squash merge edilmesine ve kapanıştan sonra sonraki mantıklı milestone'a geçilmesine izin verdi. Exact-head CI, post-merge main CI, 7 dakika, determinism ve artifact=0 kuralları aynen zorunludur.

### M43 kapsamı
- yeni ayrı `crisis` domain; legacy akışlara varsayılan entegrasyon yok
- stateless deterministic `CrisisDecisionEngine`
- finance cash/debt + `FanState.overallTrust` + `MediaState.credibility` + `PresidentManagementProfile` typed inputları
- kriz türleri: liquidity squeeze / supporter unrest / media backlash
- en yüksek pressure deterministic olarak kriz türünü seçer; threshold altı context kriz üretmez
- başkan profili gerçek aksiyon farkı üretir (`financialDiscipline`, `riskAppetite`, `transferAmbition`, `managerPatience`)
- karar etkileri bounded cash/fan/media delta üretir
- negatif cash sıfırda clamp edilir; gizli debt yaratılmaz ve mevcut debt değiştirilmez
- save formatı büyütülmez: sistem stateless olduğu için reconstructed continuation state aynı kriz sonucu/signature üretir
- 6 normal acceptance testi
- `tool/run_m43_crisis_decision.dart` canonical runner
- workflow'a M42 sonrası `Run M43 crisis decision core` gate'i eklendi

Sıradaki adım: PR aç, exact-head analyzer + normal test + M0–M43 canonical + artifact=0 doğrula. Failure varsa gerçek logdan düzelt. Yeşil exact HEAD gece yetkisiyle squash merge edilebilir; ardından post-merge `main` CI doğrulanıp M43 CLOSED/PASS yapılır.

## 3. Son kapalı milestone'lar

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 squash merge: `2868d725c4ba68601a732d98b913195d3c58a4a3`
Post-merge main CI `34660280556`: analyzer clean, **173 test PASS**, **M0–M42 PASS**, artifact **0**.
M42: deterministic fictional sponsor offers; fan/media offer quality; president risk/finance preference; multi-year contracts; real economy sponsor revenue; save codec v1 + migration + deterministic resume.
Kalıcı doküman: `M42_SPONSOR_SYSTEM_I.md`.
Docs-close main commit `0839be62cd9221b19f0b7990681faac86a8d697c`; docs CI `34679910122` SUCCESS, artifact 0.

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 squash merge: `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`; post-merge CI `34656211019`: 167 test PASS, M0–M41 PASS, artifact 0.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 squash merge: `8edcdb67ee77f16e64b40d5b44588deae562625f`; post-merge CI `34652843932`: 162 tests, M0–M40 PASS, artifact 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 squash merge: `ea95f767eb95194455e012cb0b9ec5cc6e81667f`; post-merge CI `34649669246`: 157 tests, M0–M39 PASS, artifact 0.

## 4. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor system; M43 crisis decision core (aktif).

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + M43 supporter/media crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + M43 liquidity/media response
- `transferAmbition`: transfer activity + stadium priority + M43 supporter response
- `riskAppetite`: bid ceiling + stadium priority + sponsor risk/bonus preference + M43 crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + M43 crisis pressure
- `MediaState.credibility`: sponsor offer quality + M43 crisis pressure
- finance cash/debt: M43 liquidity pressure and bounded cash effect

## 5. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu oturumda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi.
