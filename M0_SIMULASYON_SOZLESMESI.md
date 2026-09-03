# Futbol Başkanlık Simülatörü — M0 Simülasyon Sözleşmesi

**Milestone:** M0 — Deterministik Mini Lig Çekirdeği  
**Durum:** Tasarım kilidi  
**Amaç:** UI, transfer, oyuncu veri tabanı ve ekonomi eklemeden önce lig/maç simülasyonu omurgasının deterministik, test edilebilir ve ölçeklenebilir olduğunu kanıtlamak.

## M0 kapsamı

- 8 hayalî kulüp
- tek lig
- çift devreli lig sistemi
- 14 maç haftası
- haftada 4 maç
- toplam 56 maç
- kulüp başına 14 maç
- kulüp başına 7 iç saha + 7 deplasman
- sade takım güç puanı
- deterministik fikstür ve maç RNG'si
- Poisson tabanlı gol üretimi
- puan tablosu
- sezon raporu
- 100+ sezon headless test

M0'da Flutter UI, APK, transfer, futbolcu kadroları, teknik direktör, ekonomi, taraftar, medya, sponsor, altyapı, tesis, kupa ve yükselme/düşme yoktur.

## Simülasyon sözleşmesi

Aynı `simulationVersion`, veri seti, kariyer `seed` değeri ve karar girdileri aynı sonucu üretmelidir. M0'da kullanıcı kararı bulunmadığı için aynı seed + aynı kulüpler aynı sezon sonucunu vermelidir.

Maç seed'i:

`matchSeed = hash(careerSeed, seasonIndex, fixtureId, simulationVersion)`

Her maç kendi RNG akışını kullanır.

## M0 baseline matematiği

`d = clamp((homeStrength + 2) - awayStrength, -30, 30)`

`homeLambda = clamp(1.35 × exp(d / 45), 0.25, 3.50)`

`awayLambda = clamp(1.15 × exp(-d / 45), 0.25, 3.50)`

`homeGoals ~ Poisson(homeLambda)`

`awayGoals ~ Poisson(awayLambda)`

Referans güçler: `80, 76, 73, 70, 67, 64, 61, 58`.

Bağımsız 1.000 sezon kontrolünde yaklaşık `%44,6` ev galibiyeti, `%24,8–25,0` beraberlik, `%30,5–30,6` deplasman galibiyeti ve `2,58–2,59` gol/maç görülmüştür.

## Fikstür invariants

1. Her kulüp 14 maç oynar.
2. Her kulüp 7 iç saha ve 7 deplasman oynar.
3. Her iki kulüp çifti iki kez karşılaşır.
4. Aynı kulüp aynı turda iki maç oynayamaz.
5. Self-match yoktur.
6. Toplam 56 fixture vardır.
7. Fixture ID'leri benzersizdir.

## Puan tablosu

- Galibiyet 3
- Beraberlik 1
- Mağlubiyet 0

Sıralama: puan → averaj → atılan gol → galibiyet sayısı → kararlı `clubId` sırası.

## M0 kalite kapısı

M0 ancak şu maddelerin tamamı PASS olduğunda kapanır:

- 8 kulüp
- 56 fixture
- 14 round
- 7 iç / 7 deplasman
- deterministik match seed
- Poisson gol üretimi
- puan tablosu
- sezon raporu
- invariant validator
- aynı seed aynı sonuç
- farklı seed farklı sonuç davranışı
- 100 sezon testi PASS
- batch raporu

Sonraki milestone: **M1 — 20 Sezon Yaşam Döngüsü**.
