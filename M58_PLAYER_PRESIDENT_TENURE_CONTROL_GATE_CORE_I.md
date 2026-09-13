# M58 — Player President Tenure Control Gate Core I

## Amaç

M49–M57 ile oyuncu başkanın controlled club üzerindeki karar yüzeyleri açıldı; ancak bu kontrol yalnız kulüp kimliğine bağlıydı. Gerçek başkanlık seçimi kaybedilip yeni AI başkan göreve geldiğinde bile aynı kulüp provider'ları teorik olarak çalışmaya devam edebiliyordu.

M58 bu yaşam döngüsü açığını tek bir persisted control identity/gate ile temel seviyede kapatır.

## Kapsam

- controlled club'ın gerçek incumbent `presidentId` değeri player-president kimliği olarak capture edilir.
- control state `active` veya `lost` olur.
- gerçek runtime'da incumbent `presidentId` değişirse gate kalıcı olarak `lost` olur.
- turnover sezonu ve successor president id kaydedilir.
- reelection / aynı incumbent kimliği control'ü aktif tutar.
- bir kez `lost` olan control daha sonra eski kimlik görülse bile reaktive olmaz.
- gate state deterministik save codec ile persist edilir.
- seçim motoru, president generation, reputation ve provider davranışları değiştirilmez.

## Bilinçli sınır

M58 core gate'i oluşturur; M49–M57 provider'larının tümünü aynı commit içinde yeniden kablolamaz. Bir sonraki composition milestone bu gate'i karar provider'larının ortak yetki kontrolüne bağlayabilir. Bu ayrım özellikle M56/M57 medya/vaat etkilerinin seçimi beslemesi nedeniyle seçim sonucunu sonradan yamalamamak için bilinçlidir.

## Acceptance

1. gerçek incumbent kimliği active player control olarak capture edilir.
2. gerçek 3→4 sezon seçim turnover'ı control'ü kalıcı kapatır.
3. gerçek reelection aynı control'ü aktif tutar.
4. loss sticky'dir; daha sonra identity match olsa bile reactivation olmaz.
5. gate save/load + president-domain save/resume deterministik olarak aynı turnover sonucunu üretir.

## Canonical marker

`M58_PLAYER_PRESIDENT_TENURE_CONTROL_GATE_PASS`

## Durum

ACTIVE / NOT MERGED — canlı CI kanıtı bekleniyor.
