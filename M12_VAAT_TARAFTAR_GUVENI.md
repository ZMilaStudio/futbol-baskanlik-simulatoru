# M12 — Vaat Sonuçlarının Taraftar Güvenine Etkisi

## Amaç

M11'de ölçülebilir hâle gelen başkan vaatlerini M9 taraftar hafızasına bağlamak.

Temel ürün kuralı:

> Tutulan ve bozulan sözler taraftarın başkana bakışını değiştirmeli; ancak tek başına bütün taraftar sistemini ezmemelidir.

## Mimari karar

M9 ve M11 ayrı ayrı yeni dünya simülasyonu çalıştırmaz. `PromiseFanCareerEngine` bir kez `AdvancedTransferCareerReport` üretir ve aynı raporu hem `PromiseCareerEngine.simulateFromAdvancedReport` hem `FanCareerEngine.simulateFromAdvancedReport` için kullanır.

Bu sayede:

- aynı sezon/maç/ekonomi gerçeği paylaşılır,
- katmanlar arasında seed drift oluşmaz,
- CI süresi gereksiz yere iki dünya simülasyonu kadar büyümez,
- eski M9 ve M11 `simulate()` API'leri korunur.

## Promise → fan etkisi

Her vaat sonucu bir `identityTrust` nedeni üretir.

- fulfilled `challengeTitle` / `earnPromotion`: `+3`
- diğer fulfilled: `+2`
- partial: `+1`
- broken `avoidRelegation`: `-4`
- broken title / promotion / finansal vaat: `-3`
- diğer broken: `-2`

Finansal vaatler (`reduceDebt`, `stabilizeFinances`) ayrıca `financialTrust` nedeni üretir:

- fulfilled: `+2`
- partial: `+1`
- broken: `-2`

M9 baseline'ında `identityTrust` bilerek nötr `60` kalır. M12 bu boyuta ilk gerçek çok sezonlu başkan kimliği sinyalini verir.

## Kabul baseline — seed 20260903 / 20 sezon / 48 kulüp

- vaat: `960`
- promise trust reason: `1.065`
- identity reason: `960`
- financial reason: `105`
- pozitif reason: `677`
- negatif reason: `388`
- M9 baseline overall trust: `64,88`
- M12 final overall trust: `65,31`
- ortalama overall fark: `+0,44`
- ortalama final identity trust: `61,83`
- final identity aralığı: `38–88`
- ortalama identity farkı: `+1,83`
- validation: `0`

## Neden kabul edildi?

Overall trust yalnız `+0,44` değişti. Bu, vaat etkisinin sportif/finansal/transfer geçmişini bastırmadığını gösterir.

Buna karşılık identity trust `38–88` aralığına açıldı. Yani uzun kariyerde sözünü tutan ve sürekli bozan başkan profilleri gerçek biçimde ayrışıyor.

İlk M12 modeli bu nedenle ayrıca oran kalibrasyonu gerektirmeden kabul edildi.

## CI guard

Seed `20260903` için geniş regresyon bantları:

- positive reason `600–750`
- negative reason `330–450`
- baseline overall `60–70`
- final overall `60–70`
- average overall delta `-2..3`
- average identity `55–70`
- minimum identity `25–50`
- maximum identity `80–95`
- average identity delta `-3..6`

Ek invariantlar:

- her vaat tam bir identity reason üretir,
- her finansal vaat tam bir ek financial reason üretir,
- M9 baseline raporunda identity nötr kalır,
- M9/M11/M12 aynı advanced-world signature'ını paylaşır,
- aynı seed aynı birleşik signature'ı üretir.

## Kapsam dışı

M12 henüz:

- medya credibility etkisi,
- seçim,
- seyirci/bilet/mağaza/sponsor geri beslemesi,
- kullanıcı tarafından vaat seçimi,
- Flutter UI

içermez.

## Sonraki yön

M13: vaat sonucunu medya hafızasına bağlamak. Böylece tutulmayan resmi vaat hem taraftar kimlik güvenini hem başkanın medya güvenilirliğini etkileyebilecek; seçim sistemi daha sonra bu iki bağımsız sinyali kullanabilecek.
