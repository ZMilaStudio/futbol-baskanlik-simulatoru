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

**M0–M43 PASS ve `main` üzerindedir.**

Sıradaki seçilmiş milestone:
**M44 — Crisis Runtime Integration I**

Kullanıcı bu oturumda yeşil milestone PR'larının ayrıca sorulmadan squash merge edilmesine ve kapanıştan sonra sonraki mantıklı milestone'a geçilmesine izin verdi. Exact-head CI, post-merge main CI, 7 dakika, determinism ve artifact=0 kuralları aynen zorunludur.

## 3. Son kapalı milestone'lar

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 squash merge: `27474a731aa73d291859828a1657d06579e69269`

Post-merge main CI `34680783652` — **SUCCESS**:
- test job `103518919732` — SUCCESS
- analyzer: `No issues found!`
- **179 normal/non-canonical test PASS**
- canonical job `103518919822` — SUCCESS
- **M0–M43 canonical PASS**
- artifacts: **0**
- iki job da 7 dakika sınırının altında

M43 kapsamı:
- ayrı legacy-safe `crisis` domain
- stateless deterministic `CrisisDecisionEngine`
- finance cash/debt + fan trust + media credibility + president profile typed context
- kriz türleri: liquidity squeeze / supporter unrest / media backlash
- threshold altı context kriz üretmez
- `financialDiscipline`, `riskAppetite`, `transferAmbition`, `managerPatience` gerçek karar farkı üretir
- bounded cash/fan/media etkileri
- cash sıfırın altına düşmez; debt değiştirilmez, gizli debt yok
- save formatı değişmez; reconstructed continuation state aynı result signature üretir
- canonical: prudent=`austerityPlan`, bold=`bridgeSpending`, supporter=`ambitionReset`, media=`transparentBriefing`, debtPreserved=`true`, saveResumeMatch=`true`

Kalıcı doküman: `M43_CRISIS_DECISION_CORE_I.md`.

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

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor system; M43 crisis decision core.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + M43 supporter/media crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + M43 liquidity/media response
- `transferAmbition`: transfer activity + stadium priority + M43 supporter response
- `riskAppetite`: bid ceiling + stadium priority + sponsor risk/bonus preference + M43 crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + M43 crisis pressure
- `MediaState.credibility`: sponsor offer quality + M43 crisis pressure
- finance cash/debt: M43 liquidity pressure and bounded cash effect

## 5. Sıradaki yön — M44

**M44 — Crisis Runtime Integration I** seçildi.

Hedef: M43 kriz motorunu gerçek başkanlık runtime/sezon akışına dar ve opt-in bir entegrasyonla bağlamak.

İlk tasarım ilkeleri:
- legacy varsayılan akış değişmemeli; kriz entegrasyonu açıkça etkinleştirilmeli veya ayrı wrapper üzerinden çalışmalı
- gerçek sezon sonunda mevcut finance/fan/media/president state kullanılarak kriz değerlendirilmeli
- kriz sonucu gerçek continuation state'e uygulanmalı
- karar/history typed ve deterministic olmalı
- save/resume parity korunmalı; continuation-critical yeni state gerekirse explicit versioning yapılmalı, gerekmiyorsa mevcut state'ten türetilmeli
- başkan turnover sonrasında yeni profil bir sonraki kriz kararını gerçekten değiştirebilmeli
- canonical M44 gate + normal acceptance testleri eklenecek

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Bu oturumda kullanıcı yeşil PR'ların sormadan merge edilmesine ve sonraki milestone'un seçilip devam edilmesine izin verdi.
