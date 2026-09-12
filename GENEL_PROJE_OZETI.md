# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 13 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
Canonical seed: `20260903`
Dünya: 48 özgün kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 14.400 maç/20 sezon, 864 başlangıç oyuncusu.

Kalıcı kurallar:
- Live GitHub > proje dosyaları > eski sohbetler.
- Deterministic seed/replay korunur; tarih `GameDate`, para integer minor-unit `Money` kullanır.
- Eski public simulation semantiği sessizce değiştirilmez.
- Save/load/resume determinism ve parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki paralel job: `test` + `canonical`; her job `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz.
- Her anlamlı proje durumu/kararı sonrası bu özet güncel tutulur.
- Docs→CI→docs sonsuz döngüsü üretilmez.
- Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı gerekir.
- Merge sonrası `main` CI yeşil olmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` 12 Eylül 2026 canlı `main` üzerinde bulunamadı ve repo aramasında da sonuç vermedi. Çalışma kuralları için dosyanın varlığı varsayılmaz; canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M52 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M53 — President Transfer Strategy Runtime Hook I.**

- Branch: `feat/m53-president-transfer-strategy-runtime-hook`
- PR: #56 — **OPEN / NOT MERGED**
- Base `main`: `48e7a8a687a06c427b7da22592e9249a515d7a9d`
- Verified code-bearing HEAD: `dc163489c868b4b17bf66ad89837703a72e83f03`
- Code-bearing PR CI: `34720756030` — **SUCCESS**
- analyzer: `No issues found!`
- **228 normal/non-canonical test PASS**
- beş M53 acceptance testinin tamamı PASS
- **M0–M53 canonical PASS**
- `Run M53 president transfer strategy runtime hook`: **SUCCESS**
- M53 canonical marker: `M53_PRESIDENT_TRANSFER_STRATEGY_RUNTIME_PASS neutralParity=true low=ready_forward high=young_forward deterministic=true policyCoverage=2`
- artifacts: **0**
- PR `mergeable=true`
- bu özet refresh commit'i sonrası oluşan final PR HEAD için CI yeniden doğrulanacaktır; sonucu yazmak için ikinci docs commit atılmayacaktır

M53 henüz merge edilmedi. Merge için final exact-head CI + artifact 0 doğrulamasından sonra kullanıcıdan **PR #56'ya özel açık merge onayı** alınmalıdır.

## 3. M53 kapsamı — President Transfer Strategy Runtime Hook I

M53, M20–M24 arasında geliştirilen başkan yönetim profili transfer davranışlarını tek bir gerçek `TransferMarketEngine.simulateWindow` çağrısına bağlayan stateless adapter katmanıdır.

Amaç M20–M24 transfer trait'lerini production transfer API'sinde kanıtlamak; **M0–M52 ana runtime zincirini bu milestone'da değiştirmemektir**. Player-president transfer override bir sonraki milestone'a bırakılır.

M53 mapping:
- `financialDiscipline` → `TransferBudgetPolicy`
- `transferAmbition` → `TransferActivityPolicy`
- `riskAppetite` → `TransferNegotiationPolicy`
- `youthOrientation` → `TransferYouthPreferencePolicy`

Sözleşmeler:
- Market içindeki her kulüp için exact president-profile coverage zorunludur; eksik/fazla profile map reddedilir.
- Hook stateless'tir; yeni save version/migration yoktur.
- Aynı input + seed + simulation version aynı sonucu üretir.
- Nötr başkan profilleri eski neutral `TransferMarketEngine` ile exact market signature parity verir.
- Mevcut M20–M24 policy formülleri yeniden yazılmaz; doğrudan reuse edilir.
- M53 mevcut M0–M52 runtime composition'ına bağlanmaz; bu nedenle eski runtime sonuçları değişmez.

M53 acceptance:
1. dört başkan transfer trait'i mevcut policy formüllerine exact map — PASS
2. exact club/profile coverage validation — PASS
3. youth strategy yeni hook üzerinden gerçek transfer adayını `ready_forward` → `young_forward` değiştirir — PASS
4. neutral profile map eski neutral market ile exact signature parity — PASS
5. sabit inputlarda deterministic runtime signature — PASS

M53 dosyaları/değişiklikleri:
- `lib/src/transfer/president_transfer_strategy_runtime.dart`
- `lib/president_transfer_strategy_runtime.dart`
- `test/m53_president_transfer_strategy_runtime_hook_test.dart`
- `tool/run_m53_president_transfer_strategy_runtime_hook.dart`
- `M53_PRESIDENT_TRANSFER_STRATEGY_RUNTIME_HOOK_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

İlk discovery sırasında vaat ve sözleşme kararları da incelendi. Promise seçimini ana player runtime'a temiz bağlamak M47→M52 dependency zincirinde gereksiz constructor yüzeyi yaratıyordu; sözleşme yenilemeyi sezon-sonu wrapper ile tersine çevirmek ise free-agent/transfer yan etkilerini bozma riski taşıyordu. Bu nedenle M53, transfer stratejisinin önce güvenli alt seviye runtime hook'u olarak seçildi.

M53 sonrası doğal aday: doğrulanmış hook'u player-president/runtime transfer penceresine compose ederek kontrollü kulübün transfer stratejisini oyuncuya açmak.

## 4. Son kapanan milestone: M52 — Player President Manager Decision Override I

- Branch: `feat/m52-player-president-manager-control`
- PR #55 — **MERGED**
- Verified code-bearing HEAD: `e4383fffc371a53b1fd94a16e0add86b1f6636e1`
- Final PR HEAD: `46e0baa63cca2f514d5061e7974991f5bfbc1c66`
- Merge SHA: `bce9efe6c214526b0018110c5a10d2fa9e7ec5c8`
- Post-merge `main` CI `34713457292`: **SUCCESS**
- docs-close commit: `48e7a8a687a06c427b7da22592e9249a515d7a9d`
- docs-close CI `34713802493`: **SUCCESS**
- analyzer clean; **223 tests PASS**; **M0–M52 canonical PASS**; artifacts **0**

M52 sonucu:
- controlled club için sezon-sonu manager `retain` / `replace` ve gerçek aday seçimi player override alır.
- diğer 47 kulüp AI parity'sini korur.
- retirement zorunlu ayrılıktır.
- seçilen uygun manager gerçek assignment state'ine yazılır ve sonraki gerçek sezonda takımı çalıştırır.
- player keyfi manager nesnesi/state enjekte edemez; deterministic gerçek manager pool adaylarıyla sınırlıdır.
- facility + sponsor + crisis player-control zinciri ve save/resume parity korunur.

M52 canonical final:
- controlledClub=`t1_02`
- `aiParityCount=47`
- `managerDecisionWindows=4`
- `changedFromAiCount=4`
- first AI review=`retain`
- first player review=`replace`
- first AI manager=`manager_074`
- first player manager=`manager_020`
- `neutralM51Parity=true`
- `nextSeasonWired=true`
- `retainOverride=true`
- `finalCheckpointMatch=true`
- `boundaryMatch=true`
- saveBytes=`6878904`

M52 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

### M51 — Player President Crisis Decision Override I — CLOSED / MERGED / PASS
- PR #54 merge `4b2832f3bfb091ae3adaeb504a7369b1190b2438`
- post-merge CI `34710810668`: 218 tests, M0–M51 PASS, artifact 0
- controlled club gerçek kriz aksiyonunu seçer; diğer 47 kulüp AI kalır
- yalnız M43 kanonik aksiyonları seçilebilir; debt korunur

### M50 — Player President Sponsor Decision Override I — CLOSED / MERGED / PASS
- PR #53 merge `f8519d4f0be247f7029a2e29d4de10588d97736f`
- post-merge CI `34706438383`: 213 tests, M0–M50 PASS, artifact 0
- controlled club yeni/yenilenen sponsor teklifini seçer; aktif çok yıllı kontratlar korunur

### M49 — Player President Facility Decision Override I — CLOSED / MERGED / PASS
- PR #52 merge `c0c40bada13e3dd83c06cdba60093a7bb9b71304`
- post-merge CI `34704054636`: 208 tests, M0–M49 PASS, artifact 0
- controlled club facility yatırımını seçer; diğer 47 kulüp AI kalır

### M48 — President Facility Investment Runtime Integration I — CLOSED / MERGED / PASS
- PR #51 merge `63950ab4ad728fe6b6f4f0deb42323590ce5180a`
- post-merge CI `34698950932`: 203 tests, M0–M48 PASS, artifact 0

### M47 — Facility + Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- PR #50 merge `dc26c2782026c6823c91d05015f4f507a7bac2f6`
- post-merge CI `34693305775`: 198 tests, M0–M47 PASS, artifact 0

### M46 — Sponsor + Crisis Runtime Composition I — CLOSED / MERGED / PASS
- PR #49 merge `f0455db0fd5f33dd1d50bb89aeabcb14e3d5d694`
- post-merge CI `34686218278`: 193 tests, M0–M46 PASS, artifact 0

### M45 — Sponsor Runtime Integration I — CLOSED / MERGED / PASS
- PR #48 merge `92f4f1b99fa841866587a8067dd529735400c035`
- post-merge CI `34684676105`: 189 tests, M0–M45 PASS, artifact 0

### M44 — Crisis Runtime Integration I — CLOSED / MERGED / PASS
- PR #47 merge `43149da199e74e41dabe47534e4e4e887d8862e7`
- post-merge CI `34683153804`: 184 tests, M0–M44 PASS, artifact 0

### M43 — Crisis Decision Core I — CLOSED / MERGED / PASS
PR #46 merge `27474a731aa73d291859828a1657d06579e69269`; post-merge CI `34680783652`: 179 tests, M0–M43 PASS, artifact 0.

### M42 — Sponsor System I — CLOSED / MERGED / PASS
PR #45 merge `2868d725c4ba68601a732d98b913195d3c58a4a3`; post-merge CI `34660280556`: 173 tests, M0–M42 PASS, artifact 0.

## 6. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M37 academy facility; M38 facility portfolio; M39 president portfolio decision loop; M40 stadium capacity/attendance; M41 fan trust→attendance; M42 sponsor core; M43 crisis core; M44 crisis runtime; M45 sponsor runtime; M46 sponsor+crisis composition; M47 facility+sponsor+crisis composition; M48 president facility investment runtime; M49 player-president facility decision override; M50 player-president sponsor decision override; M51 player-president crisis decision override; M52 player-president manager decision override; M53 president transfer strategy runtime hook.

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
- M49: controlled club player facility override; diğer kulüpler AI
- M50: controlled club player sponsor override; aktif kontratlar korunur
- M51: controlled club player crisis override; diğer 47 kulüp exact AI
- M52: controlled club player manager override; gerçek next-season assignment'a bağlıdır
- M53: M20–M24 transfer traits tek gerçek transfer-window adapterında birleşir; ana M52 runtime henüz değişmez

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
9. Docs-only kapanış/refresh commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
