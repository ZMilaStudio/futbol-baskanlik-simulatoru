# M13 — Vaat Sonuçlarının Medya Güvenilirliğine Etkisi

## Amaç

M11'deki resmi başkan vaatlerini M10 medya hafızasına bağlamak.

> Resmi söz yalnız taraftarın değil, medyanın da hafızasında kalır.

## Ortak dünya mimarisi

M10 ve M11 ayrı kariyer simülasyonlarında birleştirilmez. M13 tek bir gerçek dünya üretir:

1. `ManagerCareerController` oluşturulur.
2. `AdvancedTransferWorldCareerEngine`, manager controller'ı `WorldCareerHooks` olarak kullanarak bir kez çalışır.
3. Aynı world report'tan `ManagerCareerReport` kurulur.
4. M10 statement geçmişi `MediaCareerEngine.fromManagerReport` ile üretilir.
5. M11 vaatleri aynı `AdvancedTransferCareerReport` üzerinde çözülür.
6. Her sezon önce manager statement credibility değişimi, ardından o sezonun promise credibility değişimi aynı `MediaState` üzerine uygulanır.

Bu yapı manager, gelişmiş transfer, vaat ve medya katmanlarının aynı sportif/ekonomik gerçeğe bakmasını sağlar.

## Promise → media etkisi

Vaat etkisi bilinçli olarak sınırlıdır; medya credibility bir promise skoruna dönüşmez.

- fulfilled `challengeTitle`, `earnPromotion` veya finansal vaat: `+2`
- diğer fulfilled: `+1`
- partial: `0`
- broken `avoidRelegation`: `-3`
- broken title / promotion / finansal vaat: `-2`
- diğer broken: `-1`

Outer safety rail:

- pozitif etki projected credibility `>88` ise 1 puan yumuşatılır,
- negatif etki projected credibility `<30` ise 1 puan yumuşatılır,
- final değer `0–100` clamp edilir.

## İlk CI hatası

İlk PR koşusu üretim kodunda değil, M13 unit test fixture'ında durdu. Testte M11'de bulunmayan `targetMet / nearTarget / targetMissed` enum adları kullanılmıştı. Test mevcut `PromiseResolutionReason` değerlerine geçirildi; domain davranışı değiştirilmedi.

## Kabul baseline — seed 20260903 / 20 sezon / 48 kulüp

Ortak advanced+manager dünyası nedeniyle M13 baseline M10'un manager-only baseline'ıyla birebir aynı olmak zorunda değildir.

- promise change: `960`
- pozitif: `452`
- nötr: `154`
- negatif: `354`
- media statement: `560`
- contradiction: `28`
- manager change: `81`
- baseline media credibility: `74,88`
- promise etkili final credibility: `72,38`
- ortalama promise kaynaklı net fark: `-2,50`
- final credibility aralığı: `36–93`
- boundary club: `0`
- validation: `0`

## Kabul gerekçesi

Promise history medya güvenilirliğini görünür biçimde etkiliyor fakat M10 manager statement hafızasını ezmiyor. `-2,50` ortalama fark 20 sezon için anlamlı ancak kontrollü; `36–93` aralığı kulüp geçmişini ayrıştırırken 0/100 yığılması oluşturmuyor.

## CI guard

Seed `20260903` için geniş regresyon bantları:

- positive `350–550`
- neutral `100–250`
- negative `280–450`
- statements `400–700`
- contradictions `10–80`
- manager changes `50–120`
- baseline credibility `65–82`
- final credibility `62–80`
- average delta `-8..3`
- min credibility `20–55`
- max credibility `82–96`
- boundary `<=2`

Ek invariantlar:

- positive + neutral + negative = 960,
- manager world = advanced-transfer world,
- promise advanced report = ortak advanced report,
- baseline media manager report = ortak manager report,
- credibility zinciri statement → promise sırasını korur,
- aynı seed aynı birleşik signature'ı üretir.

## Kapsam dışı

M13 seçim değildir. Kullanıcı kampanyası, rakip aday, oy oranı, görev kaybı ve yeni kulübe geçiş henüz yoktur.

## Sonraki yön

M14 için doğal eşik oluştu: fan trust + media credibility + promise history artık birlikte kullanılabilecek durumda. Sıradaki milestone başkanlık seçimi çekirdeğinin ilk gözlemsel sürümü olacaktır.
