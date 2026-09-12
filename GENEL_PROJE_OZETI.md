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
- her anlamlı proje durumu/kararı sonrası bu özet güncel tutulur
- docs→CI→docs sonsuz döngüsü üretilmez
- her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı gerekir
- merge sonrası `main` CI yeşil olmadan milestone CLOSED sayılmaz

## 2. CANLI DURUM — buradan devam et

**M0–M47 CLOSED / MERGED / PASS ve `main` üzerindedir.**

Aktif PR / milestone yok.

### Son kapanan milestone: M47 — Facility + Sponsor + Crisis Runtime Composition I

PR #50 explicit kullanıcı onayı sonrası squash merge edildi.

- Final PR HEAD: `5fb0c8a0c6de9717d0ba3dd93f0629b8d81bf1de`
- Final PR CI `34692763703`: **SUCCESS**
- Merge SHA: `dc26c2782026c6823c91d05015f4f507a7bac2f6`
- Post-merge main CI `34693305775`: **SUCCESS**
- analyzer: `No issues found!`
- **198 normal/non-canonical test PASS**
- **M0–M47 canonical PASS**
- artifacts: **0**
- test ve canonical job'ları 7 dakika sınırının altında

M47 canonical final:
- seasons=4
- target=`t1_01`
- facility levels=`2/2/2` (academy/stadium/training)
- target matchday revenue=`9,911,400 -> 11,398,110`
- crises=`40/192`
- forcedWiring=true
- debtPreserved=true
- sponsorStatePreserved=true
- financeReplacementMatch=true
- facilitiesPreserved=true
- stadiumEffect=true
- neutralM46Parity=true
- saveResumeMatch=true
- boundaryMatch=true
- saveBytes=935220

M47 kapsamı:
- M38 academy/stadium/training facility etkileri M46 sponsor+crisis PresidentDomain continuation runtime'ına aynı sezon simülasyonu içinde bağlandı
- her sezon yalnız bir kez world/PresidentDomain simülasyonu çalışır
- academy + training gerçek player lifecycle'a etki eder
- stadium + current fan trust gerçek matchday revenue'ya etki eder
- sponsor geliri economy'de legacy sponsor gelirinin replacement kaynağıdır; double-counting yok
- kriz facility+sponsor-aware economy sonrasında uygulanır
- sponsor state korunur; debt preservation korunur
- facility portfolio continuation-critical state olarak persist edilir; world state ikinci kez kopyalanmaz
- neutral facility level 0 yolu M46 ile birebir parity verir
- non-zero academy/stadium/training state save/load ve 2+2 resume determinism verir
- kalıcı canonical gate: `tool/run_m47_facility_sponsor_crisis_runtime_composition.dart`
- kalıcı doküman: `M47_FACILITY_SPONSOR_CRISIS_RUNTIME_COMPOSITION_I.md`

M47 **CLOSED / MERGED / PASS**.

## 3. Yakın milestone geçmişi

### M46 — Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- M44 crisis runtime + M45 sponsor runtime tek top-level career continuation yolunda compose edildi
- aynı PresidentDomain/world sezonu iki kez simüle edilmiyor
- sponsor-aware finance sonrası kriz uygulanıyor
- sponsor state korunuyor; kriz-adjusted finance/fan/media sonraki sponsor context'ine taşınıyor
- 2+2 save/resume parity
- PR #49 merge `f0455db0fd5f33dd1d50bb89aeabcb14e3d5d694`
- post-merge CI `34686218278`: 193 tests, M0–M46 PASS, artifact 0

### M45 — Sponsor Runtime Integration I — CLOSED / MERGED / PASS
- PresidentDomain + Sponsor composite checkpoint/save codec
- sponsor revenue gerçek economy satırında replacement; double-counting yok
- current president + fan + media sponsor context'i
- multi-year kontrat turnover boyunca korunur; renewal current president ile yapılır
- 2+2 save/resume parity
- PR #48 merge `92f4f1b99fa841866587a8067dd529735400c035`
- post-merge CI `34684676105`: 189 tests, M0–M45 PASS, artifact 0

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
- gerçek sezon sonu finance/fan/media/current-president context'i
- crisis etkileri continuation state'ine yazılır
- debt değişmez; gizli borrowing yok
- save-version bump yok
- 2+2 save/resume parity
- PR #47 merge `43149da199e74e41dabe47534e4e4e887d8862e7`
- post-merge CI `34683153804`: 184 tests, M0–M44 PASS, artifact 0

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 merge `27474a731aa73d291859828a1657d06579e69269`; post-merge CI `34680783652`: 179 tests, M0–M43 PASS, artifact 0.

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 merge `2868d725c4ba68601a732d98b913195d3c58a4a3`; post-merge CI `34660280556`: 173 tests, M0–M42 PASS, artifact 0.

### M41 — Attendance Demand & Fan Trust Integration II — CLOSED / MERGED / PASS
PR #44 merge `8d1e901ceb4e13087b75f7df948a4cbe53c429ce`; post-merge CI `34656211019`: 167 tests, M0–M41 PASS, artifact 0.

### M40 — Stadium Capacity & Attendance Core I — CLOSED / MERGED / PASS
PR #43 merge `8edcdb67ee77f16e64b40d5b44588deae562625f`; post-merge CI `34652843932`: 162 tests, M0–M40 PASS, artifact 0.

### M39 — President Facility Portfolio Decision Loop I — CLOSED / MERGED / PASS
PR #42 merge `ea95f767eb95194455e012cb0b9ec5cc6e81667f`; post-merge CI `34649669246`: 157 tests, M0–M39 PASS, artifact 0.

## 4. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime integration; M45 sponsor runtime integration; M46 sponsor+crisis composition; M47 facility+sponsor+crisis composition.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + crisis pressure
- `MediaState.credibility`: sponsor offer quality + crisis pressure
- finance cash/debt: crisis pressure + bounded cash effect
- facility academy/training: real lifecycle/youth-development etkisi
- facility stadium + fan trust: real matchday revenue etkisi
- M44: crisis output gerçek next-season continuation state'ine taşınır
- M45: sponsor contract lifecycle + revenue gerçek continuation/economy akışına bağlıdır
- M46: sponsor+crisis aynı season boundary'de compose edilir
- M47: facility portfolio state ve etkileri M46 runtime ile aynı single-season simulation yolunda compose edilir

## 5. M47 kabul zinciri

1. Full 48-club academy/stadium/training portfolio exact coverage ile açılır veya restore edilir.
2. Academy + training map gerçek `PlayerLifecycleEngine` call'ına uygulanır.
3. Stadium + current fan trust gerçek matchday revenue multiplier'ını üretir.
4. Sponsor coordinator 48 kulüp kontrat/gelirini gerçek economy çağrılarında çözer; sponsor geliri replacement olarak uygulanır.
5. PresidentDomain sezonu yalnız bir kez tamamlanır.
6. Crisis tamamlanmış facility+sponsor-aware domain checkpoint'e uygulanır.
7. Crisis-adjusted domain + sponsor checkpoint + facility portfolio composite continuation state olarak taşınır.
8. Neutral facility portfolio M46 ile birebir parity verir.
9. Non-zero facility portfolio save/load round-trip ve 2+2 resume uninterrupted 4 sezonla aynıdır.
10. Debt, sponsor-state, finance-replacement ve boundary parity invariants korunur.

## 6. Sonraki milestone için gerçek ürün boşluğu

M47 facility seviyelerini birleşik runtime'da kullanır ve persist eder; ancak **M39 otomatik president facility investment decision loop henüz M47 birleşik runtime'a bağlanmamıştır**.

Bu nedenle canlı kod doğrulaması da aynı sonucu verirse güçlü M48 adayı:
**President Facility Investment Runtime Integration I** — M39 academy/stadium/training yatırım kararlarının M47 facility+sponsor+crisis continuation akışında gerçek sezon sınırında çalışması, real cash/reserve kullanması, turnover sonrası yeniden planlanması ve save/resume parity vermesi.

M48 henüz başlatılmadı; yeni milestone seçmeden önce canlı `main` tekrar doğrulanmalıdır.

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
