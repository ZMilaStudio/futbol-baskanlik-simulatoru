# M53 — President Transfer Strategy Runtime Hook I

## Amaç

M20–M24 arasında geliştirilen başkan yönetim profili transfer davranışlarını gerçek `TransferMarketEngine` penceresine tek ve deterministik bir adapter üzerinden bağlamak.

M53 bilinçli olarak mevcut M0–M52 ana runtime zincirini değiştirmez. Böylece yeni alt seviye sözleşme önce bağımsız olarak kanıtlanır; player-president transfer kararının ana kariyer runtime'ına kompozisyonu sonraki milestone'a bırakılır.

## Kapsam

`PresidentTransferStrategyRuntimeEngine` her kulüp için mevcut `PresidentManagementProfile` değerlerini şu dört kanonik politikaya dönüştürür:

- `financialDiscipline` → `TransferBudgetPolicy`
- `transferAmbition` → `TransferActivityPolicy`
- `riskAppetite` → `TransferNegotiationPolicy`
- `youthOrientation` → `TransferYouthPreferencePolicy`

Üretilen policy map'leri aynı gerçek `TransferMarketEngine.simulateWindow` çağrısına birlikte verilir.

## Sözleşmeler

- Tüm market kulüpleri için tam ve tekil başkan profili coverage zorunludur.
- Hook stateless'tir; yeni save formatı veya migration yoktur.
- Aynı input + aynı seed + aynı simulation version aynı sonucu üretmelidir.
- Tüm özellikleri nötr olan profil, eski nötr transfer marketiyle birebir aynı sonucu üretmelidir.
- M0–M52 runtime davranışına doğrudan müdahale edilmez.

## Kabul kriterleri

1. Dört başkan özelliği mevcut M20–M24 policy formüllerine birebir map edilir.
2. Eksik/fazla başkan profili coverage reddedilir.
3. M24'te kanıtlanan gençlik tercihi yeni runtime hook üzerinden gerçek transfer adayını değiştirir.
4. Nötr profile sahip tüm kulüpler eski `TransferMarketEngine` sonucu ile exact signature parity verir.
5. Sabit inputlarda determinism korunur.
6. Normal test paketi ve M0–M53 canonical zinciri yeşildir.
7. Workflow artifact üretmez.

## M53 sonrası

Bir sonraki doğal adım, bu doğrulanmış hook'u player-president runtime zincirine compose ederek kontrollü kulübün transfer stratejisini oyuncuya açmaktır. Bu iş M53'ün kapsamı değildir.
