# M18 — Başkan Sabrı → Teknik Direktör Karar Eşiği I

## Amaç

M17'deki `managerPatience` trait'ini ilk kez gerçek simülasyon davranışına bağlamak.

> Aynı kötü performansa sabırlı başkan ile müdahaleci başkan aynı hızda teknik direktör değiştirmemelidir.

M18 yalnız teknik direktör kararını etkiler. Mali disiplin, risk, transfer hırsı ve altyapı yönelimi henüz AI kararlarına bağlanmaz.

## Neden iki geçişli mimari?

Başkan sabrı manager kararını değiştirir; manager kararı dünya sonuçlarını, medya/vaat/taraftar reputasyonunu ve dolayısıyla sonraki seçimleri etkileyebilir. Seçimler de sonraki başkanı belirlediği için tek seferde bağlamak döngüsel bağımlılık oluşturur.

M18 bu bağımlılığı kontrollü biçimde kırar:

1. Canonical M17 kariyeri çalışır ve president/turnover/management-profile zaman çizelgesini üretir.
2. Bu zaman çizelgesi M18 için sabit referans olur.
3. Aynı seed ile advanced world ikinci kez simüle edilir.
4. Her sezon incumbent başkanın `managerPatience` değeri `ManagerCareerController` dismissal eşiklerine verilir.
5. Farklı hoca kararları sonraki sezon manager impact ve transfer/ekonomi zincirini gerçekten değiştirir.

Bu nedenle M18 gerçek dünya divergence üretir fakat değişen dünyadan seçimleri henüz yeniden hesaplamaz. Bu geçici sınırlama sonraki birleşik-feedback milestone'unda kaldırılacaktır.

## Dismissal politikası V1

`managerPatience=60` nötr referanstır ve eski M6/M13 eşiklerini birebir korur.

| Patience | Board breakdown | Underperformance gap | Underperformance relationship | Relegation relationship |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 36 | 4 | 54 | 60 |
| 60 | 28 | 5 | 46 | 52 |
| 90 | 22 | 6 | 40 | 46 |

Düşük patience daha yüksek ilişki seviyesinde dahi değişim tetikleyebilir; yüksek patience ise daha ağır kötü performans ve daha düşük ilişki seviyesine kadar tolerans gösterir. Retirement kararı bu politikanın dışındadır ve eski kuralla çalışır.

## Kabul baseline — seed `20260903`

- karar snapshot: `960`
- canonical M13 baseline manager changes: `81`
- M18 patience-aware manager changes: `88`
- değişim farkı: `+7`
- binary dismissal decision differences: `93`
- downstream manager identity differences: `446 / 960`
- final manager assignment differences: `37 / 48`
- low-patience club-seasons: `232`
- high-patience club-seasons: `308`
- low-patience dismissal rate: `%16,4`
- high-patience dismissal rate: `%6,2`
- dismissal anındaki ortalama patience: `50,52`
- manager retained sezonlarda ortalama patience: `61,52`
- performance changes: `60`
- board breakdown changes: `25`
- retirements: `3`
- advanced-world transfer sayısı: `173 → 153`
- world signature değişti: `true`
- validation: `0`

## Yorum

İlk model kabul edildi.

Toplam manager change yalnız `81 → 88` olduğu için manager piyasası hiperaktif hale gelmedi. Buna rağmen düşük ve yüksek sabır grupları arasında yaklaşık 2,6 kat dismissal-rate farkı oluştu; trait gerçek davranış farkı yaratıyor.

`446` manager identity farkı 446 ayrı kovma değildir. `93` karar farkının sonraki sezonlarda farklı manager zincirleri üretmesinden kaynaklanan downstream yayılımdır.

Transfer sayısının `173 → 153` düşmesi doğrudan transfer trait'i etkisi değildir; farklı manager/world patikasının ikincil sonucudur. Yaklaşık `%11,6` sapma kabul edildi ancak regresyon guard'ına alındı.

## Kabul guard'ları

Canonical seed için:

- influenced manager changes `80–100`
- manager change delta `-5..20`
- decision differences `60–130`
- manager identity differences `300–600`
- final assignment differences `25–45`
- low-patience club-seasons `180–280`
- high-patience club-seasons `250–360`
- low dismissal rate `0,10–0,22`
- high dismissal rate `0,03–0,10`
- low/high dismissal-rate farkı en az `0,05`
- average dismissal patience `45–56`
- average retained patience `57–65`
- influenced transfers `120–200`
- baseline transfer farkı en fazla `50`

Ayrıca M6–M17 canonical runner'ları aynı CI içinde değişmeden PASS olmak zorundadır.

## Teknik parçalar

- `ManagerDismissalPolicy`
- `ManagerPatienceProvider`
- `PresidentManagerPatienceTimeline`
- `PresidentManagerPatienceCareerEngine`
- `PresidentManagerPatienceCareerReport`
- `PresidentManagerPatienceCareerValidator`
- `test/m18_president_manager_patience_test.dart`
- `tool/run_m18_president_manager_patience_career.dart`

## Açık sınır

M18'de president timeline M17'den exogenous alınır. Patience-aware world değiştiğinde yeni fan/media/promise/election sonucu henüz bu dünyadan türetilmez.

## Sıradaki milestone

**M19 — Başkan Sabrı + Seçim Geri Besleme Döngüsü.**

M18'in değişen manager/world patikasını reputasyon ve seçim zincirine geri bağlayarak president → manager → world → reputasyon → election → president döngüsünü tek tutarlı kariyer state'i haline getirmek.
