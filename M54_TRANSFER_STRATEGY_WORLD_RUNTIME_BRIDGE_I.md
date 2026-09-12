# M54 — Transfer Strategy World Runtime Bridge I

## Amaç

M53 ile kanıtlanan başkan transfer stratejisi adapterını gerçek `WorldCareerEngine` transfer penceresine güvenli, opt-in ve deterministik bir köprü üzerinden bağlamak.

M54 player-president transfer override değildir. Bu milestone, M53 strateji katmanının gerçek dünya transfer penceresinde **tek kez ve transfer seçilmeden önce** çalışabilmesi için güvenli runtime seam sağlar.

## Neden ayrı milestone?

`WorldCareerEngine` permanent transfer penceresini lifecycle sonrasında doğrudan `TransferMarketEngine.simulateWindow` ile açar. Mevcut `WorldTransferHooks` yalnız permanent transferlerden sonra çalışır. Bu nedenle sezon sınırı sonrasında transfer state'ini yeniden yazmak çift-transfer veya finance/contract yan etkisi üretme riski taşır.

M54 bu riski ortadan kaldırır: `PresidentTransferStrategyWorldMarketEngine`, standart `TransferMarketEngine` yerine açıkça enjekte edilir ve M53'ü aynı gerçek pencerenin içinde çağırır.

## Sözleşme

- Default `WorldCareerEngine` kodu ve davranışı değiştirilmez.
- Bridge yalnız açıkça enjekte edildiğinde çalışır.
- M53 policy mapping'leri yeniden yazılmaz; `PresidentTransferStrategyRuntimeEngine` reuse edilir.
- Provider gerçek pencere context'ini alır: clubs, prepared players, closing finance states, career seed, season index ve simulation version.
- M53 exact club/profile coverage validation korunur.
- Contract years ve installment flag aynen delegate market'e taşınır.
- Caller explicit transfer policy map gönderirse bridge provider'ı çalıştırmaz; explicit map'ler doğrudan delegate'e forward edilir.
- Bridge stateless'tir; yeni save version veya migration yoktur.
- Aynı input + seed + simulation version aynı sonucu üretir.
- Nötr başkan profilleri eski neutral transfer market ile exact signature parity verir.
- M0–M53 production runtime composition bu milestone'da bridge'i kullanmaz; eski runtime semantiği değişmez.

## Acceptance

1. Nötr profile bridge direct market signature'ı standart `TransferMarketEngine` ile exact eşittir.
2. M53 youth stratejisi bridge üzerinden gerçek transfer adayını `ready_forward` → `young_forward` değiştirir.
3. Explicit policy map verildiğinde profile provider bypass edilir ve delegate parity korunur.
4. Bridge gerçek 48-kulüp `WorldCareerEngine` transfer penceresine bağlanır; nötr profillerde report + checkpoint save exact parity verir.
5. Sabit inputlarda bridge deterministiktir.

## Dosyalar

- `lib/src/transfer/president_transfer_strategy_world_bridge.dart`
- `lib/president_transfer_strategy_world_bridge.dart`
- `test/m54_transfer_strategy_world_runtime_bridge_test.dart`
- `tool/run_m54_transfer_strategy_world_runtime_bridge.dart`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

## Sonraki doğal adım

M54 başarılı olduktan sonra player-president transfer strategy override, bu pre-window bridge'in profile provider yüzeyinde kontrollü kulüp için gerçek oyuncu kararını compose edebilir. Bunun kapsamı ayrı milestone olarak canlı `main` üzerinden seçilmelidir.
