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

**M0–M50 CLOSED / MERGED / PASS ve `main` üzerindedir.**

Aktif milestone yok. **M51 henüz seçilmedi.** Yeni milestone seçmeden önce canlı `main` kodu incelenmeli ve kapsam gerçek ürün boşluğundan türetilmelidir; eski sohbetten veya tahminden milestone seçilmez.

`DEVRALMA_1_AYLIK_GPT.md` 12 Eylül 2026 canlı `main` üzerinde bulunamadı ve repo aramasında da sonuç vermedi. Bu nedenle çalışma kuralları için bu dosyanın varlığı varsayılmaz; canlı GitHub + bu özet esas alınır.

## 3. Son kapanan milestone: M50 — Player President Sponsor Decision Override I

PR #53 kullanıcı tarafından açıkça onaylandı ve exact HEAD kilidiyle squash merge edildi.

- Branch: `feat/m50-player-president-sponsor-control`
- PR: #53 — **MERGED**
- Final PR HEAD: `613f22409fd9f7270ebb552d1227ffebf8a5b3b7`
- Final PR CI `34705919064`: **SUCCESS**
- Merge SHA: `f8519d4f0be247f7029a2e29d4de10588d97736f`
- Post-merge `main` CI `34706438383`: **SUCCESS**
- analyzer: `No issues found!`
- **213 normal/non-canonical test PASS**
- **M0–M50 canonical PASS**
- `Run M50 player president sponsor control`: **SUCCESS**
- artifacts: **0**
- post-merge `test` job yaklaşık **2:11**
- post-merge `canonical` job yaklaşık **5:14**
- iki job da 7 dakika sınırının altında

M50 canonical final:
- controlledClub=`t1_02`
- `aiParityCount=47`
- `playerSponsorWindows=4`
- first canonical AI choice=`t1_02-s0-bold`
- first canonical player choice=`t1_02-s0-bold`
- controlled sponsor revenue=`13,766,445`
- `neutralM49Parity=true`
- `sponsorRevenueWired=true`
- `controlledContractPersisted=true`
- `controlledClubPersisted=true`
- `finalCheckpointMatch=true`
- `boundaryMatch=true`
- `decisionMatch=true`
- saveBytes=`2122969`

Not: canonical ilk pencerede AI ve player aynı `bold` teklifi seçmektedir. Gerçek override davranışı ayrı acceptance testinde AI seçiminden farklı gerçek teklif seçilerek doğrulanmıştır.

M50 kapsamı:
- M49 ile açılan player-president karar yüzeyi gerçek sponsor sözleşmesi seçimine genişletildi
- yalnız `controlledClubId` yeni/yenilenen sponsor kontratını player provider ile seçebilir
- diğer 47 kulüp mevcut `PresidentSponsorDecisionPolicy` AI yolunu aynen sürdürür
- aktif çok yıllı kontratlar bozulmaz ve kontrat bitmeden yeniden seçim istenmez
- oyuncu yalnız M42 `SponsorOfferEngine` tarafından üretilmiş deterministic gerçek tekliflerden birini seçebilir
- karar context'i current president, management profile, lig pozisyonu, fan trust, media credibility, teklifler ve AI önerisini içerir
- seçilen teklif gerçek sponsor checkpoint/state zincirine ve economy `sponsorRevenue` satırına bağlanır
- player provider serialize edilmez; controlled club ve aktif sponsor kontratı save/load içinde persist eder
- M49 facility player-control aynı engine içinde korunur
- sponsor provider yokken M49 exact parity korunur

M50 acceptance:
1. sponsor provider yokken M49 exact parity — PASS
2. yalnız controlled club sponsor seçimi override; diğer 47 kulüp AI parity — PASS
3. seçilen gerçek sponsor terms gerçek economy sponsorRevenue satırını değiştirir — PASS
4. aktif multi-year player kontratı yeniden seçilmez — PASS
5. save round-trip + deterministic `2+2 == uninterrupted 4` checkpoint/boundary/decision parity — PASS

Kalıcı M50 dosyaları:
- `lib/src/sponsor/player_president_sponsor_control.dart`
- `lib/player_president_sponsor_control.dart`
- `test/m50_player_president_sponsor_control_test.dart`
- `tool/run_m50_player_president_sponsor_control.dart`
- `M50_PLAYER_PRESIDENT_SPONSOR_DECISION_OVERRIDE_I.md`

M50 **CLOSED / MERGED / PASS**.

## 4. Önceki milestone: M49 — Player President Facility Decision Override I

- PR #52 merge SHA: `c0c40bada13e3dd83c06cdba60093a7bb9b71304`
- Final PR CI `34702117074`: **SUCCESS**
- Post-merge main CI `34704054636`: **SUCCESS**
- analyzer clean; **208 tests PASS**; **M0–M49 canonical PASS**; artifacts **0**
- controlled club için player facility kararı M48 boundary'sini override eder; diğer 47 kulüp AI kalır
- academy/training/stadium için pencere başına `0..2` upgrade talebi; reserve guard, debt koruması ve deterministic save/resume parity korunur

M49 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

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

## 6. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime; M45 sponsor runtime; M46 sponsor+crisis composition; M47 facility+sponsor+crisis composition; M48 president facility investment runtime; M49 player-president facility decision override; M50 player-president sponsor decision override.

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

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
9. Docs-only kapanış commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
