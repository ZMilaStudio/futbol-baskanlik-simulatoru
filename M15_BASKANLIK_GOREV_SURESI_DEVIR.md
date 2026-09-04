# M15 — Başkanlık Görev Süresi + Devir Çekirdeği

## Amaç

M14'teki `reelected / lost` sonucu artık yalnız rapor etiketi değildir. Her kulübün gerçek, deterministik bir incumbent başkanı ve görev süresi vardır.

## Tasarım sınırı

M15 seçim sonucunu değiştirmez. M14 election report aynen kullanılır.

- `reelected` → aynı başkan aynı tenure içinde devam eder.
- `lost` → challenger yeni incumbent olur.
- yeni başkan henüz transfer, ekonomi, teknik direktör veya vaat AI davranışını değiştirmez.
- kullanıcı game-over / başka kulübe geçiş / UI kapsam dışıdır.

Bu sınır bilinçlidir: önce kimlik ve tarihçe doğrulanır, sonra başkan değişiminin reputasyon ve karar sistemlerine geri beslemesi eklenir.

## Yeni modeller

### `PresidentProfile`

- deterministik `id`
- deterministik kurgu `name`

Başlangıç incumbent ve her seçim challenger'ı career seed + simulation version + club + election bağlamından üretilir.

### `PresidentTenureState`

- club ID
- incumbent profile
- kulüp içindeki tenure sıra numarası
- görev başlangıç sezonu
- mevcut tenure içindeki yeniden seçim sayısı

### `PresidentTurnoverEvent`

- seçim sezonu
- yeni başkanın göreve başlayacağı sezon
- çıkan/gelen başkan
- çıkan başkanın başlangıç sezonu
- biten görev süresi
- biten tenure içindeki yeniden seçim sayısı
- election margin / challenger strength

## Determinizm ve doğrulama

Validator M14 validator'ını da çalıştırır ve tüm seçimleri yeniden replay eder.

Her seçim kaybında tam bir turnover bulunmalıdır. Yeniden seçimde turnover bulunmamalıdır. Final incumbent state, replay sonunda üretilen state ile birebir aynı olmalıdır.

Başkan ID'leri yeniden kullanılmaz; aynı seed aynı kimlik ve devir zincirini üretir.

## Kabul baseline — seed `20260903`

20 sezon / 48 kulüp:

- elections: `240`
- reelected: `158`
- lost: `82`
- turnovers: `82`
- unique presidents: `130`
- turnover yaşayan kulüp: `35`
- birden fazla turnover yaşayan kulüp: `24`
- tek kulüpte maksimum turnover: `5`
- biten tenure ortalaması: `6,93 sezon`
- biten tenure aralığı: `4–20 sezon`
- validation: `0`

M14 baseline birebir korunmuştur.

## Kabul yorumu

`82 lost = 82 turnover` temel invariant sağlandı. Ortalama yaklaşık 7 sezonluk biten görev süresi, seçimlerin ne formalite ne de sürekli yönetim kaosu olduğunu gösteriyor.

Bir kulübün 20 sezondaki beş seçimin tamamında başkan değiştirmiş olması dikkat edilmesi gereken uç örnektir. M15 bunu yapay biçimde bastırmaz; çünkü kök neden M14 seçim sonuç dağılımıdır. Çoklu-seed uzun kariyer testlerinde bu olayın sıklığı ayrıca izlenecektir.

## Bilinen mimari borç

M15 başkan kimliğini değiştirir ancak M13/M14'ten gelen media credibility ve fan `identityTrust` hâlâ kulüp çizgisinde kesintisiz ilerler. Yeni başkanın predecessor'ın kişisel medya çelişkilerini tamamen miras alması doğru değildir.

Bu nedenle sıradaki milestone:

## M16 — Başkan Devrinde Kişisel İtibar Devri

Hedef:

- medya credibility'nin yeni başkanda kişisel başlangıç/normalizasyon kuralı,
- fan `identityTrust` için kontrollü reset/devir,
- sporting/financial/transfer gibi kulüp temelli taraftar güvenlerinin korunması,
- sonraki seçimlerin artık gerçek incumbent'ın kendi dönem reputasyonundan etkilenmesi,
- deterministik replay ve 20 sezon denge testi.
