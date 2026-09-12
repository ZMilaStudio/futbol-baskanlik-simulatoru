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

**M0–M49 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**M50 — Player President Sponsor Decision Override I aktif.**

Branch: `feat/m50-player-president-sponsor-control`
PR: henüz açılmadı
Durum: implementation candidate branch üzerinde; canlı PR CI henüz yok.

### M50 seçiminin canlı kod gerekçesi

M49 ile oyuncu ilk kez controlled club facility yatırım kararını doğrudan verebilir hale geldi. Canlı M42/M45 sponsor kodunda ise yeni sponsor gerektiğinde `SponsorOfferEngine` üç deterministic gerçek teklif üretmesine rağmen seçim hâlâ `PresidentSponsorDecisionPolicy` tarafından tamamen AI ile yapılıyordu. Bu, mevcut player-president yüzeyindeki en doğrudan yüksek değerli ürün boşluğuydu.

M50 bu boşluğu kapatır:
- yalnız `controlledClubId` yeni/yenilenen sponsor sözleşmesini player provider ile seçebilir
- diğer 47 kulüp mevcut AI sponsor politikasını birebir sürdürür
- aktif çok yıllı kontrat bozulmaz; kontrat bitmeden yeni seçim istenmez
- oyuncu yalnız M42 tarafından üretilmiş gerçek tekliflerden birini seçebilir
- context: current president + management profile + league position + fan trust + media credibility + teklifler + AI önerisi
- seçilen teklif mevcut sponsor checkpoint/state zincirine girer ve gerçek economy `sponsorRevenue` satırını değiştirir
- player provider serialize edilmez; `controlledClubId` ve aktif sponsor kontratı mevcut save state içinde persist eder
- M49 facility player-control aynı engine içinde korunur
- sponsor provider yokken M49 exact parity hedeflenir

### M50 acceptance adayı

1. sponsor provider yokken M49 exact checkpoint/boundary parity
2. yalnız controlled club sponsor seçimi override; diğer 47 kulüp AI parity
3. farklı gerçek sponsor teklifleri gerçek economy sponsorRevenue satırını değiştirir
4. aktif çok yıllı player kontratı yeniden seçilmez ve save/load ile persist eder
5. deterministic sponsor + facility provider ile `2+2 == uninterrupted 4` exact checkpoint/boundary/decision parity

Yeni dosyalar:
- `lib/src/sponsor/player_president_sponsor_control.dart`
- `lib/player_president_sponsor_control.dart`
- `test/m50_player_president_sponsor_control_test.dart`
- `tool/run_m50_player_president_sponsor_control.dart`
- `M50_PLAYER_PRESIDENT_SPONSOR_DECISION_OVERRIDE_I.md`

CI workflow'a `Run M50 player president sponsor control` canonical adımı eklendi. PASS ancak canlı PR CI ile yazılacaktır.

## 3. Son kapanan milestone: M49 — Player President Facility Decision Override I

PR #52 kullanıcı tarafından açıkça onaylandı ve exact HEAD kilidiyle squash merge edildi.

- Final PR HEAD: `2dead082642228682bff6cded64ead38dc2f30d8`
- Final PR CI `34702117074`: **SUCCESS**
- Merge SHA: `c0c40bada13e3dd83c06cdba60093a7bb9b71304`
- Post-merge main CI `34704054636`: **SUCCESS**
- analyzer: `No issues found!`
- **208 normal/non-canonical test PASS**
- **M0–M49 canonical PASS**
- `Run M49 player president facility control`: **SUCCESS**
- artifacts: **0**
- `test` job yaklaşık **3:22**
- `canonical` job yaklaşık **5:10**
- iki job da 7 dakika sınırının altında

M49 canonical final:
- controlledClub=`t1_02`
- `aiParityCount=47`
- `playerWindows=3`
- player facility spend=`12,000,000`
- hold spend=`0`
- stadium upgrades=`1`
- matchday revenue=`10,168,800 -> 10,931,460`
- `neutralM48Parity=true`
- `debtPreserved=true`
- `cashSpendMatches=true`
- `controlledClubPersisted=true`
- `finalCheckpointMatch=true`
- `boundaryMatch=true`
- saveBytes=`1329011`

M49 kapsamı:
- oyunun ilk explicit player-president decision override API'si eklendi
- `controlledClubId` ile yalnız bir kulüp player-controlled facility kararına bağlanır
- diğer 47 kulüp exact M48/M39 AI facility yatırım yolunu sürdürür
- player academy/training/stadium için pencere başına `0..2` upgrade talep edebilir
- academy-first ve training→stadium round-robin sırası korunur
- M39 reserve bps guard'ları player kararında da geçerlidir; debt değişmez, hidden borrowing yoktur
- deterministic karar context'i current president, cash/debt, facility levels, AI targets ve reserve değerlerini içerir
- controlled club wrapper checkpoint/save içine persist edilir
- player provider serialize edilmez; aynı deterministic provider ile `2+2 == uninterrupted 4` exact parity verir
- provider yokken M49 runtime M48 ile birebir parity verir
- 5 yeni acceptance testi; toplam **208 test**
- kalıcı canonical gate: `tool/run_m49_player_president_facility_control.dart`
- kalıcı doküman: `M49_PLAYER_PRESIDENT_FACILITY_DECISION_OVERRIDE_I.md`

M49 **CLOSED / MERGED / PASS**.

## 4. Yakın milestone geçmişi

### M48 — President Facility Investment Runtime Integration I — CLOSED / MERGED / PASS
- M39 başkan facility yatırım politikası M47 birleşik facility+sponsor+crisis runtime'a bağlandı
- PR #51 merge `63950ab4ad728fe6b6f4f0deb42323590ce5180a`
- post-merge main CI `34698950932`: 203 tests, M0–M48 PASS, artifact 0

### M47 — Facility + Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- facility state ve etkileri sponsor+crisis PresidentDomain continuation runtime ile tek-season simulation yolunda compose edildi
- PR #50 merge `dc26c2782026c6823c91d05015f4f507a7bac2f6`
- post-merge CI `34693305775`: 198 tests, M0–M47 PASS, artifact 0

### M46 — Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- sponsor + crisis tek top-level continuation runtime'ında compose edildi
- sponsor-aware finance sonrası kriz uygulanır
- sponsor state korunur; kriz-adjusted finance/fan/media sonraki sponsor context'ine ulaşır
- PR #49 merge `f0455db0fd5f33dd1d50bb89aeabcb14e3d5d694`
- post-merge CI `34686218278`: 193 tests, M0–M46 PASS, artifact 0

### M45 — Sponsor Runtime Integration I — CLOSED / MERGED / PASS
- PresidentDomain + Sponsor composite checkpoint/save codec
- sponsor revenue gerçek economy satırında replacement; double-counting yok
- multi-year kontrat turnover boyunca korunur; renewal current president ile yapılır
- PR #48 merge `92f4f1b99fa841866587a8067dd529735400c035`
- post-merge CI `34684676105`: 189 tests, M0–M45 PASS, artifact 0

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
- crisis etkileri continuation state'ine yazılır; debt değişmez
- PR #47 merge `43149da199e74e41dabe47534e4e4e887d8862e7`
- post-merge CI `34683153804`: 184 tests, M0–M44 PASS, artifact 0

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 merge `27474a731aa73d291859828a1657d06579e69269`; post-merge CI `34680783652`: 179 tests, M0–M43 PASS, artifact 0.

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 merge `2868d725c4ba68601a732d98b913195d3c58a4a3`; post-merge CI `34660280556`: 173 tests, M0–M42 PASS, artifact 0.

## 5. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime; M45 sponsor runtime; M46 sponsor+crisis composition; M47 facility+sponsor+crisis composition; M48 president facility investment runtime; M49 player-president facility decision override; M50 player-president sponsor decision override (aktif branch).

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
- M49: controlled club için player facility kararı M48 boundary'sini override eder; diğer kulüpler AI kalır
- M50: controlled club için yeni sponsor seçimi player override alır; aktif kontratlar ve diğer kulüpler mevcut sponsor lifecycle/AI yolunu korur

## 6. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
