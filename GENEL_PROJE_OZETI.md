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

**M0–M53 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M54 — Transfer Strategy World Runtime Bridge I.**

- Branch: `feat/m54-transfer-strategy-world-runtime-bridge`
- Base `main`: `0697a2d127f5c5021be18f19a33b4eef503fa045`
- PR: henüz açılmadı
- CI: henüz doğrulanmadı
- M54 production default path'i değiştirmez; bridge opt-in'dir.
- Hedef: M53 başkan transfer stratejisini gerçek `WorldCareerEngine` transfer penceresine transfer seçilmeden önce güvenli biçimde bağlamak.

M54 merge edilmedi. Kod/test/canonical tamamlandıktan sonra PR açılacak; final exact-head CI + artifact 0 + mergeable=true doğrulanmadan kullanıcıdan merge onayı istenmeyecek.

## 3. M54 kapsamı — Transfer Strategy World Runtime Bridge I

Canlı mimari incelemede `WorldCareerEngine` permanent transfer penceresini lifecycle sonrasında doğrudan `TransferMarketEngine.simulateWindow` ile açtığı görüldü. Mevcut `WorldTransferHooks` yalnız transferlerden sonra çalıştığı için M53 stratejisini sezon sonrasında uygulamak çift-transfer ve finance/contract yan etkisi riski taşır.

M54 çözümü:
- `PresidentTransferStrategyWorldMarketEngine`, `TransferMarketEngine` yerine açıkça enjekte edilebilen adapterdır.
- Adapter gerçek market inputlarını alır ve M53 `PresidentTransferStrategyRuntimeEngine`i aynı transfer penceresinin içinde çağırır.
- `PresidentTransferStrategyWorldBridge`, mevcut `WorldCareerEngine` dependency'lerini koruyup yalnız transfer market engine'i değiştirir.
- Default `WorldCareerEngine` ve M0–M53 production composition değiştirilmez.
- Caller explicit transfer policy map verirse profile provider bypass edilir ve map'ler delegate market'e aynen aktarılır.
- Bridge stateless'tir; save version/migration yoktur.

M54 acceptance hedefleri:
1. neutral bridge direct market exact signature parity
2. M53 youth strategy bridge üzerinden `ready_forward` → `young_forward`
3. explicit policy map provider bypass + delegate parity
4. gerçek 48-kulüp `WorldCareerEngine` wiring + neutral report/checkpoint exact parity
5. fixed input determinism

M54 dosyaları:
- `lib/src/transfer/president_transfer_strategy_world_bridge.dart`
- `lib/president_transfer_strategy_world_bridge.dart`
- `test/m54_transfer_strategy_world_runtime_bridge_test.dart`
- `tool/run_m54_transfer_strategy_world_runtime_bridge.dart`
- `M54_TRANSFER_STRATEGY_WORLD_RUNTIME_BRIDGE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M54 başarıyla kapanırsa doğal sonraki aday, bu pre-window bridge'in profile-provider yüzeyinde yalnız controlled club için player-president transfer stratejisi override'ı compose etmektir. Bu henüz ayrı bir milestone olarak seçilmemiştir.

## 4. Son kapanan milestone: M53 — President Transfer Strategy Runtime Hook I

- Branch: `feat/m53-president-transfer-strategy-runtime-hook`
- PR #56 — MERGED
- Final PR HEAD: `0f56d40195d149daafcd65abfdd77073d5c7eb0d`
- Merge SHA: `f83e159793f80d7f53c40a0845e795339e400d3c`
- Post-merge `main` CI `34721440607`: SUCCESS
- docs-close commit: `0697a2d127f5c5021be18f19a33b4eef503fa045`
- docs-close CI `34721780422`: SUCCESS
- analyzer clean; **228 tests PASS**; **M0–M53 canonical PASS**; artifacts **0**

M53 sonucu:
- `financialDiscipline` → transfer budget policy
- `transferAmbition` → transfer activity policy
- `riskAppetite` → negotiation policy
- `youthOrientation` → youth preference policy
- exact president-profile coverage zorunlu
- neutral strategy exact market parity
- deterministic gerçek transfer-window adapter
- canonical marker: `neutralParity=true low=ready_forward high=young_forward deterministic=true policyCoverage=2`

M53 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

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
- fan/media/finance/facility/sponsor/crisis state continuation-critical akışlarda kullanılır
- M49–M52 controlled club oyuncu başkan kararlarıdır; diğer kulüpler AI kalır
- M53 transfer trait'lerini gerçek transfer-market API'sinde birleştirir
- M54 M53 stratejisini real world transfer window'a opt-in pre-window bridge ile taşır; default runtime henüz değişmez

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
