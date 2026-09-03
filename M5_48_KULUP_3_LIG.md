# Futbol Başkanlık Simülatörü — M5 / 48 Kulüp / 3 Lig

**Milestone:** M5 — 48 Kulüp / 3 Lig  
**Durum:** **PASS — kalite kapısı kapandı**  
**Amaç:** M0–M4 ile kanıtlanan lig, oyuncu yaşam döngüsü, ekonomi ve transfer sistemlerini ilk kez gerçek oyun ölçeğine taşımak.

## Dünya ölçeği

M5 dünyası tamamen özgün içerikten oluşur:

- 48 kurgu kulüp
- 3 kurgu lig
- lig başına 16 kulüp
- kulüp başına 30 lig maçı
- lig başına 240 maç
- dünya sezonu başına 720 lig maçı
- 20 sezonda 14.400 lig maçı
- başlangıçta kulüp başına 18 oyuncu
- toplam 864 başlangıç oyuncusu

Ligler:

1. **Taç Ligi**
2. **Birlik Ligi**
3. **Ufuk Ligi**

## Terfi / düşme

Her sezon sonu, final sezon hariç:

- Taç Ligi son 3 → Birlik Ligi
- Birlik Ligi ilk 3 → Taç Ligi
- Birlik Ligi son 3 → Ufuk Ligi
- Ufuk Ligi ilk 3 → Birlik Ligi

Böylece her sezon geçişinde 12 lig hareketi oluşur.

20 sezonluk kariyerde 19 sezon arası geçiş vardır:

`19 × 12 = 228` lig hareketi.

`WorldCareerValidator`, terfi/düşme kararlarının gerçek sezon tablolarıyla birebir uyuştuğunu ve her ligde her zaman 16 benzersiz kulüp kaldığını doğrular.

## Teknik yaklaşım

M0–M4 çekirdeği yeniden yazılmadı. Üstüne `WorldCareerEngine` eklendi.

Her sezon:

1. üç lig mevcut `SeasonEngine` ile ayrı ayrı oynatılır,
2. lig sonuçları bir dünya sezonu altında birleştirilir,
3. lig seviyesine göre ekonomi çalıştırılır,
4. terfi/düşme hesaplanır,
5. oyuncular yaşlanır / emekli olur,
6. 48 kulübün her biri için genç oyuncu üretilir,
7. ortak 48 kulüplük transfer pazarı çalışır,
8. transfer sonrası finans ve kadrolar sonraki sezona taşınır.

Bu yapı M0–M4 testlerini korur; eski motorlar ayrı regresyon testleriyle aynı çıktıları üretmeye devam eder.

## Lig bazlı ekonomi

M5 ile `BasicEconomyEngine` geriye dönük uyumlu iki opsiyonel ölçek kazandı:

- `economicScaleBps`: gelir ve ilk finans büyüklüğü
- `costScaleBps`: maaş ve işletme gideri

Varsayılan değerler `%100 / %100` olduğu için M0–M4 değişmedi.

Kabul edilen M5 geçici ölçekleri:

| Lig | Gelir ölçeği | Maliyet ölçeği |
|---|---:|---:|
| Taç Ligi | %100 | %100 |
| Birlik Ligi | %90 | %85 |
| Ufuk Ligi | %80 | %75 |

Bu oranlar nihai oyun ekonomisi değildir. Gerçek oyuncu sözleşmesi ve maaş sistemi geldiğinde yeniden kalibre edilecektir.

## Reddedilen kalibrasyonlar

### Deneme 1 — RED

Alt lig gelir ölçekleri `%76 / %58`, maliyetler tam ölçekliydi.

20 sezon sonucu:

- transfer: `2`
- transfer hacmi: `17,00M`
- final nakit: `105,05M`
- final borç: `3.966,16M`
- validation issue: `0`

Teknik olarak sağlamdı ancak ekonomi alt ligleri borç ölüm sarmalına sokuyor ve transfer pazarı donuyordu.

### Deneme 2 — RED

Gelirler `%90 / %80` yapıldı ancak maliyetler hâlâ yeterince düşmemişti.

- transfer: `7`
- hacim: `58,48M`
- final nakit: `237,18M`
- final borç: `2.268,60M`
- acil finansman: `2.688,27M`
- `debtCrisis`: `34/48`

Pazar ve borç yapısı hâlâ kabul edilmedi.

### Deneme 3 — RED / karşı uç

Gelir `%90 / %80`, maliyet `%80 / %65` yapıldı.

- transfer: `158`
- hacim: `1.556,01M`
- final nakit: `1.909,01M`
- final borç: `318,16M`
- acil finansman: `113,71M`
- `veryStrong`: `22/48`

Borç problemi çözüldü ama dünya aşırı servet biriktirdiği için kabul edilmedi.

## Kabul edilen M5 baseline

Seed `20260903` / 20 sezon:

- sezon: `20`
- maç: `14.400`
- başlangıç oyuncusu: `864`
- final oyuncusu: `906`
- lig hareketi: `228`
- transfer: `71`
- transfer hacmi: `637,91M`
- ortalama bonservis: `8,98M`
- final toplam nakit: `862,25M`
- final toplam borç: `647,04M`
- toplam acil finansman: `569,03M`
- transfer pazarına katılan farklı kulüp: `35`
- farklı Taç Ligi şampiyonu: `10`
- validation issue: `0`

Final finansal sağlık:

- `veryStrong`: 16
- `solid`: 14
- `balanced`: 8
- `debtCrisis`: 10

Final lig ortalama güçleri:

- Taç Ligi: `72,01`
- Birlik Ligi: `65,54`
- Ufuk Ligi: `59,21`

Bu sıralama lig seviyelerinin sportif olarak ayrıştığını gösterir.

Final lig finans toplamları:

- Taç Ligi: cash `241,93M`, debt `364,86M`
- Birlik Ligi: cash `213,52M`, debt `230,12M`
- Ufuk Ligi: cash `406,79M`, debt `52,06M`

**Açık denge notu:** Ufuk Ligi'nin final nakdinin üst liglerden yüksek olması nihai ekonomi tasarımı olarak kabul edilmemektedir. Kulüpler ligler arasında hareket ettiği ve M5 maaş modeli gerçek sözleşmelere dayanmadığı için bu aşamada veri bütünlüğünü bozan bir hata sayılmadı. Gerçek sözleşme/maaş sistemi geldiğinde lig bazlı maliyet ve nakit birikimi yeniden kalibre edilecektir.

## Taç Ligi şampiyon çeşitliliği

20 sezonda 10 farklı kulüp şampiyon oldu. Seed `20260903` örneği:

- Vadişehir FK: 3
- Demirkent: 3
- Gölhisar: 3
- Ufukşehir: 2
- Hisar Birliği: 2
- Mavi Liman: 2
- Altın Vadi: 2
- Irmak Birliği: 1
- Güneşyaka: 1
- Poyrazkent: 1

Bu baseline'da tek kulübün 20 sezon boyunca ligi kilitlemesi görülmedi.

## Kalıcı M5 sanity guard'ları

Seed `20260903` için geniş regresyon sınırları:

- 20 sezon
- 48 kulüp
- 3 × 16 lig üyeliği
- 14.400 maç
- 228 lig hareketi
- final oyuncu: `600–1.150`
- transfer: `60–600`
- transfer hacmi: `200M–4B`
- final nakit: `150M–1,5B`
- final borç: `>0` ve `<1,5B`
- acil finansman: `<1,5B`
- en az 2 finansal sağlık sınıfı
- `debtCrisis` en fazla 20 kulüp
- en az 4 farklı Taç Ligi şampiyonu
- transfer pazarına en az 20 farklı kulüp katılımı

Transfer alt sınırı ilk başta veriye dayanmadan `80` seçilmişti. Kabul edilen koşuda 71 transfer, 35 farklı katılımcı ve 637,91M hacim oluştuğu için bunun donmuş pazar olmadığı görüldü; geniş regresyon bariyeri `60` olarak kalibre edildi.

## Kalite kapısı

M5 aşağıdaki doğrulamalarla kapatıldı:

- `dart analyze`: PASS
- otomatik test: `23/23 PASS`
- M0 100 sezon: PASS
- M1 20 sezon: PASS
- M2 20 sezon: PASS
- M3 20 sezon: PASS
- M4 20 sezon: PASS
- M5 20 sezon / 48 kulüp / 3 lig: PASS
- M5 validation issue: `0`
- artifact: `0`

PR #6 squash merge ile `main`e alındı. Merge commit: `0b83168b89159565b497379a9bf95774875778d2`.

## M5'in önemi

M5 ile ilk kez projenin başlangıçta belirlenen büyük teknik hedefi kanıtlandı:

> 48 kurgu kulüp + 3 lig + yaşayan oyuncu havuzu + ekonomi + transfer pazarı + terfi/düşme, 20 sezon boyunca otomatik çalışabiliyor.

Bu, henüz oynanabilir ürün veya nihai denge değildir; ancak simülasyon çekirdeğinin oyun ölçeğine çıkabildiğini gösteren ilk büyük teknik eşiktir.

## Sonraki milestone

**M6 — Teknik Direktör Sistemi** önerilir.

Amaç başkanlık kimliğini güçlendirmektir: teknik direktör profilleri, işe alma/kovma, bütçe ve transfer talepleri, genç oyuncu yaklaşımı, yönetim ilişkisi ve sportif performansa etkisi.

M6'da da Flutter UI/APK zorunlu değildir.
