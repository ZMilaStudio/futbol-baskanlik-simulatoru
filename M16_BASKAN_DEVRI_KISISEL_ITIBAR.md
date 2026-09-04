# M16 — Başkan Devrinde Kişisel İtibar Devri

## Amaç

M15 seçim kaybını gerçek başkan değişimine çevirdi. Ancak M15 katmanında reputasyon kulüp bazlı akmaya devam ettiği için yeni incumbent predecessor'ın kişisel `fan identityTrust` ve `media credibility` geçmişini fiilen miras alıyordu.

M16 bu semantik hatayı düzeltir:

> Yeni başkan kulübün borcunu, kadrosunu ve kurumsal koşullarını devralır; predecessor'ın kişisel güvenilirliğini birebir devralmaz.

## Ardışık kariyer akışı

M16 seçimleri artık kariyer bittikten sonra topluca değerlendirmez. Tek kariyerde sıra şöyledir:

1. sezonun sportif/ekonomik/manager/transfer olayları,
2. taraftar nedenlerinin uygulanması,
3. medya açıklamasının sonraki manager eylemiyle çözülmesi,
4. vaat sonucunun taraftar ve medyaya uygulanması,
5. seçim sezonuysa approval/challenger değerlendirmesi,
6. kayıp varsa başkan turnover,
7. kişisel reputasyon handover,
8. sonraki sezon yeni incumbent state ile devam.

Dünya yeniden simüle edilmez. M13'ün `AdvancedTransferWorldCareerEngine + ManagerCareerController` kaynak dünyası ve mevcut promise/media olayları replay edilir.

## Reputasyon ayrımı

### Kulübe ait / kurumsal boyutlar

Başkan değişiminde aynen korunur:

- `sportingTrust`
- `financialTrust`
- `transferTrust`

Bunlar taraftarın kulübün mevcut gidişatına dair hafızasıdır.

### Başkana özgü kişisel boyutlar

Kontrollü normalizasyon uygulanır:

- `identityTrust`
- `media credibility`

V1 formülü:

`yeni = round(eski × 0,25 + nötr × 0,75)`

Nötr referanslar:

- fan identity: `60`
- media credibility: `65`

Örnek:

- identity `28` → `52`
- media `33` → `57`

Bu politika tam reset değildir. Kulübün yakın geçmişinin yeni başkan üzerindeki başlangıç algısına küçük bir izi kalır.

## Kabul baseline — seed 20260903

- seasons: `20`
- elections: `240`
- reelected: `161`
- lost: `79`
- turnovers: `79`
- unique presidents: `127`
- reelection rate: `%67,1`
- final media credibility avg: `72,42`
- media range: `59–93`
- final identity trust avg: `65,00`
- identity range: `56–81`
- avg handover media delta: `+0,13`
- avg handover identity delta: `+2,18`
- validation issues: `0`

M14 baseline `158/82`, M15 baseline `158/82` olarak kendi regresyon testlerinde aynen korunur. M16'da ardışık kişisel reputasyon handover sonraki seçim girdilerini değiştirdiği için `161/79` ayrı ve bilinçli bir baseline'dır.

## Kabul yorumu

Değişim küçüktür: yeniden seçim oranı M14'e göre yaklaşık `+1,3` puan oynar. Bu, handover'ın seçim sistemini ezmediğini gösterir.

Identity aralığının M12'deki `38–88` bandından M16'da `56–81` bandına sıkışması bilinçlidir: düşük/yüksek kişisel uçlar başkan değişimlerinde nötre yaklaşır. Aynı incumbent görevde kaldığında reputasyon geçmişi silinmez.

Ortalama handover identity delta'nın pozitif olması da beklenir; düşük kişisel güven seçim kaybı olasılığını yükselttiği için turnover gerçekleşen örnekler ortalamada nötr başlangıca doğru toparlanır.

## CI guard'ları

Seed `20260903` için:

- reelected `145–175`
- lost `65–95`
- reelection rate `0,60–0,75`
- media avg `65–80`
- media min `45–65`
- media max `85–95`
- identity avg `58–72`
- identity min `48–62`
- identity max `75–90`
- avg handover media delta `-3..3`
- avg handover identity delta `0,5..5`
- turnover count = loss count
- unique presidents = `48 + losses`
- validator issues = `0`

Ayrıca custom `seasonIndex=7`, 5 sezonluk kariyerde ilk seçim `10`, turnover handover efektif sezonu `11` olarak test edilir.

## Kapsam dışı

M16'da yapılmaz:

- president profile'ın transfer AI'a etkisi,
- president profile'ın manager kovma sabrına etkisi,
- sponsor/tesis kararları,
- kullanıcı seçim kaybı sonrası game-over veya başka kulüp teklifi,
- Flutter/UI.

## Sonraki milestone

**M17 — Başkan Profili + Yönetim Felsefesi Çekirdeği.**

Hedef deterministik ve test edilebilir başkan yönetim eğilimleri üretmek; bu profilleri hemen bütün AI sistemlerine bağlayıp dengeyi bozmak yerine önce ayrı bir domain ve rapor katmanı olarak kanıtlamaktır.
