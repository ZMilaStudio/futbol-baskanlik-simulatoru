# M37 — President Facility Decision Loop / Turnover Replanning I

Durum: **CLOSED / PASS**

Tarih: 11 Eylül 2026

## Amaç

M36'daki başkan profili → academy yatırım kararını tek explicit checkpoint'ten çıkarıp sezonluk president facility decision loop'a bağlamak; her sezon mevcut başkan profiline göre academy hedefi, upgrade yoğunluğu ve protected cash reserve'i yeniden hesaplamak; başkan değişiminde yeni profile göre bir sonraki yatırım penceresini deterministic olarak yeniden planlamak ve save/load/resume continuity'yi korumak.

## Uygulanan davranış

- Academy yatırım kararı sezonluk decision window üzerinden yürür.
- Her pencerede current president profile yeniden okunur.
- `youthOrientation` target level / intensity'yi, `financialDiscipline` protected reserve'i sürer.
- Başkan değişiminde bir sonraki pencere yeni profile göre yeniden planlanır.
- Downgrade yoktur.
- Yatırım mevcut M34/M36 gerçek-cash finance path'ini kullanır; yetersiz nakitte gizli borç yaratılmaz.
- Facility decision, aynı facility-aware offseason youth lifecycle'dan önce çalışır.
- Decision history derived output'tur; save formatına append-only history eklenmez.
- Explicit orchestration çağrılmadıkça legacy/default simulation semantics değişmez.

## Acceptance testleri

M37 için canlı `main` CI'da üç doğrudan regression/parity testi PASS:

1. Academy policy her season window'da yeniden değerlendirilir.
2. President turnover sonrası replanning hemen gerçekleşir.
3. Save/load/resume decision loop kesintisiz continuation ile eşleşir.

Ayrıca aynı `main` CI, M0–M37 runner zincirinin tamamını PASS tamamlamıştır.

## Canonical sonuç

Seed: `20260903`

- Start checkpoint: season `8`
- Target club: `t3_05`
- Turnover season: `9`
- Decision windows: `2`
- Presidents: `m37-cautious-president → m37-youth-builder-president`
- Target levels: `0, 5`
- Applied upgrades: `0, 2`
- Academy path: `0→0, 0→2`
- Completed seasons: `10`
- Turnover replanned: `true`
- Split decisions match: `true`
- Youth history match: `true`
- Final checkpoint match: `true`
- Seasonal president facility decision loop: **PASS**

## GitHub / CI kanıtı

PR: `#38` — MERGED

Final PR HEAD:
`0030caef1c292d4f1d249f9a8ed5a2abcca041fb`

PR CI:
- run `34059375807`
- job `101557067196`
- `147` normal/non-canonical test PASS
- M0–M37 runner zinciri PASS
- artifacts `0`
- ilk denemede 7 dk workflow timeout'a ulaşıldı; timeout artırılmadı
- test runner optimize edildi ve final PR CI yaklaşık `4m22s` içinde SUCCESS oldu

Squash merge commit:
`ff1745671ce57fdaa56b937bf36f026f86b34ca5`

Merge sonrası `main` CI:
- run `34113979981`
- job `101716393026`
- conclusion: **SUCCESS**
- çalışma süresi yaklaşık `4m49s`; 7 dk timeout altında
- `dart analyze` adımı SUCCESS; 10 adet `unnecessary_import` info bildirimi failure değildir
- `dart test --exclude-tags canonical-feedback`: **147 tests passed**
- direct M37 regression/parity tests: **PASS**
- M0–M37 runner zinciri: **PASS**
- artifacts: **0**

## Determinism / save-resume kanıtı

Canlı `main` logunda M37 runner:
- `Split decisions match: true`
- `Youth history match: true`
- `Final checkpoint match: true`

Dolayısıyla kabul edilen M37 save/resume continuation deterministic parity şartını sağlıyor; aynı continuation yükleme sınırında farklı sonuç üretmiyor.

## Kapanan açık

M36 sonunda kalan tek-checkpoint academy investment davranışı artık başkan görev süresi boyunca sezonluk decision loop'a bağlandı ve president turnover sonrasında yeni profile göre güvenli/deterministic replanning yapıyor.

## Sonraki yön

Yeni milestone otomatik başlatılmadı. M37 canlı `main` CI ile kapanmıştır; sonraki ürün kapsamı kullanıcı yönlendirmesiyle seçilmelidir.
