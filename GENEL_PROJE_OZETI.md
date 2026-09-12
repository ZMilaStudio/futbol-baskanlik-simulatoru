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
- `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır ve güncel tutulur.
- Docs→CI→docs sonsuz döngüsü üretilmez.
- Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı gerekir.
- Merge sonrası `main` CI yeşil olmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M54 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yok. Aktif geliştirme PR'ı yok.**

Son kapanan milestone: **M54 — Transfer Strategy World Runtime Bridge I**.

- Branch: `feat/m54-transfer-strategy-world-runtime-bridge`
- PR #57 — **MERGED / CLOSED**
- Final PR HEAD: `45405585e2263a1377c2d62b14a2e1449bdd3962`
- Squash merge SHA / code-bearing `main`: `837198d3480be5571d4eeae1934c72454f47dec1`
- Code-bearing PR CI `34722672195`: **SUCCESS**
- Final exact-head PR CI `34722977310`: **SUCCESS**
- Post-merge `main` CI `34723247609`: **SUCCESS**
- analyzer: `No issues found!`
- **233 normal/non-canonical test PASS**
- beş M54 acceptance testinin tamamı PASS
- **M0–M54 canonical PASS**
- `Run M54 transfer strategy world runtime bridge`: **SUCCESS**
- canonical marker: `M54_TRANSFER_STRATEGY_WORLD_BRIDGE_PASS neutralParity=true low=ready_forward high=young_forward worldWired=true deterministic=true worldClubs=48`
- artifacts: **0**

M54 **CLOSED / MERGED / PASS**.

Bu kapanış özeti commit'inin docs-only CI'ı bir kez doğrulanacaktır; sırf son run ID'yi bu dosyaya yazmak için yeni docs commit atılmayacaktır.

Sıradaki gerçek iş **M55'i seçmektir**. Kapsam tahminle açılmayacak; canlı `main` kodu ve player-president karar zinciri incelenip başkan olarak oyuncunun hâlâ veremediği en önemli gerçek karar seçilecektir. M54 bridge'inin controlled club için player-president transfer stratejisi override'ına açtığı seam güçlü doğal adaydır, ancak M55 adı/kapsamı canlı kod incelemesiyle kesinleştirilmelidir.

## 3. M54 kapsamı — Transfer Strategy World Runtime Bridge I

`WorldCareerEngine` permanent transfer penceresini lifecycle sonrasında doğrudan `TransferMarketEngine.simulateWindow` ile açar. Mevcut `WorldTransferHooks` yalnız transferlerden sonra çalıştığı için M53 stratejisini sezon sonrasında uygulamak çift-transfer ve finance/contract yan etkisi riski taşır.

M54 çözümü:
- `PresidentTransferStrategyWorldMarketEngine`, standart `TransferMarketEngine` yerine açıkça enjekte edilebilen opt-in adapterdır.
- Adapter gerçek market context'ini M53 `PresidentTransferStrategyRuntimeEngine`e aynı transfer penceresinin içinde verir.
- `PresidentTransferStrategyWorldBridge`, mevcut `WorldCareerEngine` dependency'lerini koruyup yalnız transfer market engine'i değiştirir.
- Default `WorldCareerEngine` ve M0–M53 production composition değiştirilmez.
- Caller explicit transfer policy map verirse profile provider bypass edilir ve map'ler delegate market'e aynen aktarılır.
- Contract years + installment flag korunur.
- Bridge stateless'tir; save version/migration yoktur.

M54 acceptance:
1. neutral bridge direct market exact signature parity — PASS
2. M53 youth strategy bridge üzerinden `ready_forward` → `young_forward` — PASS
3. explicit policy map provider bypass + delegate parity — PASS
4. gerçek 48-kulüp `WorldCareerEngine` wiring + neutral report/checkpoint save exact parity — PASS
5. fixed input determinism — PASS

M54 dosyaları:
- `lib/src/transfer/president_transfer_strategy_world_bridge.dart`
- `lib/president_transfer_strategy_world_bridge.dart`
- `test/m54_transfer_strategy_world_runtime_bridge_test.dart`
- `tool/run_m54_transfer_strategy_world_runtime_bridge.dart`
- `M54_TRANSFER_STRATEGY_WORLD_RUNTIME_BRIDGE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M54 production default path'i değiştirmez; köprü yalnız explicit injection ile çalışır. Böylece player-president transfer kararları için pre-window seam hazır olurken M0–M53 public/runtime semantiği korunur.

M54 **CLOSED / MERGED / PASS**.

## 4. Son kapanan milestone: M54 — Transfer Strategy World Runtime Bridge I

- Branch: `feat/m54-transfer-strategy-world-runtime-bridge`
- PR #57 — MERGED
- Final PR HEAD: `45405585e2263a1377c2d62b14a2e1449bdd3962`
- Merge SHA: `837198d3480be5571d4eeae1934c72454f47dec1`
- Code-bearing PR CI `34722672195`: SUCCESS
- Final exact-head PR CI `34722977310`: SUCCESS
- Post-merge `main` CI `34723247609`: SUCCESS
- analyzer clean; **233 tests PASS**; **M0–M54 canonical PASS**; artifacts **0**
- canonical marker: `M54_TRANSFER_STRATEGY_WORLD_BRIDGE_PASS neutralParity=true low=ready_forward high=young_forward worldWired=true deterministic=true worldClubs=48`

M54, M53 başkan transfer stratejisini gerçek `WorldCareerEngine` transfer penceresine opt-in ve stateless bir pre-window market bridge ile bağlar. Neutral parity, explicit-policy bypass, 48-club world wiring ve determinism kanıtlandı; default production path değiştirilmedi.

M54 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

- M53 President Transfer Strategy Runtime Hook I — PR #56 merge `f83e159793f80d7f53c40a0845e795339e400d3c`; 228 tests; M0–M53 PASS; artifact 0.
- M52 Player President Manager Decision Override I — PR #55 merge `bce9efe6c214526b0018110c5a10d2fa9e7ec5c8`; 223 tests; M0–M52 PASS; artifact 0.
- M51 Player President Crisis Decision Override I — PR #54 merge `4b2832f3bfb091ae3adaeb504a7369b1190b2438`; 218 tests; M0–M51 PASS; artifact 0.
- M50 Player President Sponsor Decision Override I — PR #53 merge `f8519d4f0be247f7029a2e29d4de10588d97736f`; 213 tests; M0–M50 PASS; artifact 0.
- M49 Player President Facility Decision Override I — PR #52 merge `c0c40bada13e3dd83c06cded64ead38dc2f30d8`; 208 tests; M0–M49 PASS; artifact 0.
- M48 President Facility Investment Runtime Integration I — PR #51 merge `63950ab4ad728fe6b6f4f0deb42323590ce5180a`; 203 tests; M0–M48 PASS; artifact 0.
- M47 Facility + Sponsor + Crisis Runtime Composition I — PR #50 merge `dc26c2782026c6823c91d05015f4f507a7bac2f6`; 198 tests; M0–M47 PASS; artifact 0.

## 6. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M49–M52 controlled club oyuncu başkan kararlarıdır; diğer kulüpler AI kalır
- M53 transfer trait'lerini gerçek transfer-market API'sinde birleştirir
- M54 M53 stratejisini real world transfer window'a opt-in pre-window bridge ile taşır; default production runtime değişmez

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
