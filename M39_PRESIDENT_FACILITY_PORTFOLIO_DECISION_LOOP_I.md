# M39 — President Facility Portfolio Decision Loop I

Durum: **PR-VERIFIED / AWAITING MERGE**

Canonical seed: `20260903`
PR: `#42` — `M39: president facility portfolio decision loop`
Code-bearing final HEAD: `712f8165ef66d11bc4f8f435820cfc3669073807`

## Amaç

M37'deki academy-only başkan tesis karar döngüsünü M38 ile gelen `stadium + training ground` portföyüne genişletmek; M37 academy semantiğini, gerçek nakit finansmanını, rezerv politikasını ve save/resume determinism'i korumak.

## Başkan trait → tesis politikası

- Stadium priority: `(transferAmbition * 2 + riskAppetite) ~/ 3`
- Training-ground priority: `(youthOrientation * 2 + managerPatience) ~/ 3`
- Portfolio cash reserve: `financialDiscipline` ve en güçlü portfolio priority ile türetilir; `800..2600 bps` aralığında bounded tutulur.
- Hedef seviye `0..5` bounded'dır.
- Yüksek priority bir karar penceresinde en fazla iki upgrade denemesi sağlar.

## Karar sırası ve legacy koruması

1. Academy yatırımı **önce** ve doğrudan mevcut M36/M37 `PresidentAcademyInvestmentOrchestrator` ile uygulanır.
2. Portfolio yatırımları deterministic round-robin olarak `training → stadium` sırasıyla her upgrade turunda denenir.
3. Her yatırım gerçek cash'ten düşer.
4. Gizli debt yaratılmaz.
5. Cash reserve ihlal edilecekse ilgili upgrade uygulanmaz.
6. Reserve nedeniyle aynı pencerede iki portfolio yatırımı birden zorunlu değildir; buna rağmen iki facility hedefi de başkan değişiminde yeniden planlanır.
7. İzole ve yeterli nakitli kabul testinde hem stadium hem training yatırımının uygulanabildiği ayrıca kanıtlanır.

## Turnover davranışı

Canonical senaryoda season 8'de cautious president, season 9'da portfolio-builder president kullanılır.

- target club: `t3_05`
- decision windows: `2`
- presidents: `m39-cautious-president → m39-portfolio-builder-president`
- academy path: `0→0, 0→2`
- training targets: `0, 5`
- training path: `0→0, 0→1`
- stadium targets: `0, 5`
- stadium path: `0→0, 0→0`
- applied portfolio upgrades: `0+0, 1+0`
- spend: `0.00M, 13.00M`

İkinci pencerede academy `9M` harcamasından sonra cash reserve yalnız training upgrade'ine izin verir; stadium target yine `5` olarak yeniden planlanmıştır fakat reserve nedeniyle bu pencerede uygulanmaz. Bu davranış finans disiplinini koruyan beklenen sonuçtur.

## M37 legacy parity

M39 kabul testi, aynı club/profile için M37 academy kararını ayrı çalıştırır ve M39 içindeki academy projection ile karşılaştırır:

- target level aynı
- before level aynı
- after level aynı
- applied upgrades aynı
- academy cash reserve aynı

Böylece portfolio genişlemesi M37 academy kararını geriye dönük değiştirmez.

## Save / resume determinism

Aynı canonical senaryo:

- direct `2 season`
- split `1 season + save/load + 1 season`

karşılaştırmasıyla doğrulandı.

Canonical sonuç:

- `Turnover replanned: true`
- `Split decisions match: true`
- `Youth history match: true`
- `Final checkpoint match: true`
- `President facility portfolio decision loop: PASS`

## CI kanıtı

Final code-bearing PR HEAD: `712f8165ef66d11bc4f8f435820cfc3669073807`

GitHub Actions:

- run `34636235546` — **SUCCESS**
- test job `103385080625` — **SUCCESS**
- canonical job `103385080891` — **SUCCESS**
- `dart analyze` — `No issues found!`
- normal/non-canonical tests — **157 tests passed**
- canonical chain — **M0–M39 PASS**
- M39 canonical step — **SUCCESS**
- test job wall time ≈ `2m56s`
- canonical job wall time ≈ `4m25s`
- both jobs fixed `timeout-minutes: 7` altında
- artifacts — **0**

## İlk CI failure ve düzeltme kanıtı

İlk PR run'ında turnover testi iki portfolio facility'sinin aynı dar cash-reserve penceresinde zorunlu olarak upgrade edilmesini bekliyordu. Gerçek logda stadium upgrade `0` kaldı.

Ara round-robin değişikliği fairness sağladı fakat cash reserve yine iki yatırımı aynı pencerede finanse etmeye yetmedi. Kök neden acceptance ile finance invariant arasındaki çelişkiydi; reserve veya debt kuralı gevşetilmedi.

Final kabul:

- iki facility target'ı turnover sonrası yeniden planlanır;
- reserve izin verdiği ölçüde en az bir portfolio yatırımı uygulanır;
- ayrı affordable test iki facility'nin de yatırım yapabildiğini kanıtlar;
- save/resume parity korunur.

Bu final kriterler gerçek CI'da yeşildir.

## Merge durumu

Bu doküman hazırlanırken PR #42 henüz merge edilmemiştir. `main` üzerinde M39 PASS ancak explicit kullanıcı merge onayı, squash merge ve post-merge `main` CI SUCCESS sonrasında ilan edilmelidir.
