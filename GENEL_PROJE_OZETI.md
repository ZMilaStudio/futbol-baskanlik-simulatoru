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

**M48 — President Facility Investment Runtime Integration I aktif; PR #51 PR-VERIFIED / NOT MERGED.**

### M48 — President Facility Investment Runtime Integration I — PR-VERIFIED / NOT MERGED

Branch: `feat/m48-president-facility-investment-runtime`
PR: #51
Code-bearing verified HEAD: `5a6bd0e695af214cf16530138ed3ba318effad46`
Code-bearing CI run `34695693706` — **SUCCESS**:
- analyzer: `No issues found!`
- **203 normal/non-canonical test PASS**
- **M0–M48 canonical PASS**
- M48 canonical PASS
- artifacts: **0**
- test job yaklaşık **3:21**
- canonical job yaklaşık **5:04**
- iki job da 7 dakika sınırının altında

İlk PR run `34695336114` analyzer'da test tarafında 1 gerçek hata + 3 unnecessary-import bilgisiyle kırmızıydı. Gerçek failure logu incelendi; generated `PresidentProfile` üzerindeki yanlış `.presidentId` erişimi `.id` olarak düzeltildi ve üç gereksiz import kaldırıldı. Sonraki analyzer/test ve canonical run'ları yeşil oldu.

M48 canonical final:
- seasons=4
- prepared investment boundaries=3
- president facility decisions=144
- academy/training/stadium upgrades=`70/45/33`
- total facility investment spend=`634,000,000`
- invested club windows=`73`
- stadium target=`t1_02`
- matchday revenue=`10,168,800 -> 10,922,000`
- currentPresidentMatch=true
- sponsorStatePreserved=true
- debtPreserved=true
- cashSpendMatches=true
- investmentActive=true
- stadiumEffect=true
- finalSeasonNoInvestment=true
- finalSeasonM47Parity=true
- saveResumeMatch=true
- boundaryMatch=true
- saveBytes=922058

M48 kapsamı:
- M39 başkan facility yatırım politikası M47 birleşik facility+sponsor+crisis runtime'a bağlandı
- yatırım kararı tamamlanmış sezon + crisis boundary sonrasında ve yalnız gerçek bir sonraki sezon varsa çalışır
- karar post-season/post-crisis **current president** profiliyle alınır; turnover otomatik replanning yaratır
- M39 academy-first ve training→stadium round-robin sırası aynen yeniden kullanılır
- gerçek next-season cash düşer; debt değişmez; reserve kuralları korunur
- yeni facility state aynı M47 checkpoint'e yazılır ve sonraki sezon real lifecycle/matchday ekonomisini etkiler
- final sezon sonrası yatırım yok; M47 final-season semantiği korunur
- mevcut M47 save codec kullanılır; save-version bump yok
- 5 yeni acceptance testi; toplam 203 test
- kalıcı canonical gate: `tool/run_m48_president_facility_investment_runtime.dart`
- kalıcı doküman: `M48_PRESIDENT_FACILITY_INVESTMENT_RUNTIME_INTEGRATION_I.md`

M48 henüz `main` üzerinde değildir. Code-bearing teknik kapılar tamamlandı. Kalan zorunlu kapılar:
1. docs-inclusive exact PR HEAD CI doğrulaması
2. exact HEAD analyzer + 203 tests + M0–M48 + artifact 0
3. PR head/mergeability doğrulaması
4. PR #51 için açık kullanıcı merge onayı
5. onay sonrası squash merge
6. post-merge `main` CI yeşil doğrulaması
7. ardından M48 CLOSED / MERGED / PASS

## 3. Son kapanan milestone: M47 — Facility + Sponsor + Crisis Runtime Composition I

PR #50 explicit kullanıcı onayı sonrası squash merge edildi.

- Final PR HEAD: `5fb0c8a0c6de9717d0ba3dd93f0629b8d81bf1de`
- Final PR CI `34692763703`: **SUCCESS**
- Merge SHA: `dc26c2782026c6823c91d05015f4f507a7bac2f6`
- Post-merge main CI `34693305775`: **SUCCESS**
- analyzer: `No issues found!`
- **198 test PASS**
- **M0–M47 canonical PASS**
- artifacts: **0**
- final docs-only CI `34693569906`: **SUCCESS**, artifact 0

M47 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

### M46 — Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- sponsor + crisis tek top-level continuation runtime'ında compose edildi
- aynı PresidentDomain/world sezonu iki kez simüle edilmez
- sponsor-aware finance sonrası kriz uygulanır
- sponsor state korunur; kriz-adjusted finance/fan/media sonraki sponsor context'ine ulaşır
- PR #49 merge `f0455db0fd5f33dd1d50bb89aeabcb14e3d5d694`
- post-merge CI `34686218278`: 193 tests, M0–M46 PASS, artifact 0

### M45 — Sponsor Runtime Integration I — CLOSED / MERGED / PASS
- PresidentDomain + Sponsor composite checkpoint/save codec
- sponsor revenue gerçek economy satırında replacement; double-counting yok
- current president + fan + media sponsor context'i
- multi-year kontrat turnover boyunca korunur; renewal current president ile yapılır
- PR #48 merge `92f4f1b99fa841866587a8067dd529735400c035`
- post-merge CI `34684676105`: 189 tests, M0–M45 PASS, artifact 0

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
- gerçek sezon sonu finance/fan/media/current-president context'i
- crisis etkileri continuation state'ine yazılır
- debt değişmez; gizli borrowing yok
- save-version bump yok
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

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime integration; M45 sponsor runtime integration; M46 sponsor+crisis composition; M47 facility+sponsor+crisis composition; M48 president facility investment runtime integration (PR #51, henüz merge edilmedi).

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- `FanState.overallTrust`: attendance + sponsor offer quality + crisis pressure
- `MediaState.credibility`: sponsor offer quality + crisis pressure
- finance cash/debt: crisis pressure + facility affordability/reserve
- academy/training: real lifecycle/youth-development etkisi
- stadium + fan trust: real attendance/matchday revenue etkisi
- M44: crisis output next-season continuation state'ine taşınır
- M45: sponsor contract lifecycle + revenue gerçek continuation/economy akışına bağlıdır
- M46: sponsor+crisis aynı season boundary'de compose edilir
- M47: facility state ve etkileri M46 ile tek-season simulation yolunda compose edilir
- M48: M39 current-president facility yatırım kararları M47 continuation boundary'sine bağlanır

## 6. M48 kabul zinciri

1. M47 sezonu yalnız bir kez tamamlanır.
2. Crisis-adjusted post-season current president state okunur.
3. Gelecek sezon varsa academy kararı önce uygulanır.
4. Aynı M39 portfolio orchestrator training→stadium round-robin kararını uygular.
5. Cash gerçek next-season finance state'inden düşer; debt değişmez.
6. Sponsor state ve PresidentDomain memory korunur.
7. Güncellenen facility portfolio aynı M47 checkpoint'e yazılır.
8. Sonraki sezon yeni facility seviyeleri gerçek academy/training/stadium etkisine dönüşür.
9. Final sezon sonrası yatırım uygulanmaz; tek-sezon M48 M47 ile parity verir.
10. Existing M47 codec ile save/load round-trip ve 2+2 resume uninterrupted 4 sezonla aynıdır.

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
