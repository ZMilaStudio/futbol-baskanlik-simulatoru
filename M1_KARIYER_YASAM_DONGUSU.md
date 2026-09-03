# Futbol Başkanlık Simülatörü — M1 Kariyer Yaşam Döngüsü

**Milestone:** M1 — 20 Sezon Yaşam Döngüsü  
**Durum:** **PASS** — PR #2 GitHub Actions: analyze PASS, 7/7 test PASS, M0 regresyon PASS, M1 20 sezon PASS, validation issue 0.  
**Amaç:** M0'daki tek sezon motorunu, henüz oyuncu/transfer/ekonomi eklemeden deterministik uzun kariyer omurgasına dönüştürmek.

## Kapsam

- `GameDate` ile telefon saatinden bağımsız oyun tarihi
- sezon index'inin ardışık ilerlemesi
- 20 sezonun tek kariyer içinde arka arkaya simülasyonu
- her sezon sonunda yeni sezon state'i
- kulüp güçlerinde sınırlı ve deterministik sezonlar arası değişim
- kariyer raporu
- kariyer validator'ı
- aynı seed ile aynı 20 sezonluk kariyer
- farklı seed ile farklı kariyer davranışı
- 20 sezon CLI koşusu

M1'de oyuncu havuzu, transfer, ekonomi, teknik direktör, taraftar, medya, sponsor, tesis, Flutter UI ve APK yoktur.

## Tarih sözleşmesi

Varsayılan kariyer başlangıcı `2026-07-01` olarak kullanılır.

20 sezonluk M1 koşusu:

- ilk sezon index: `0`
- son sezon index: `19`
- başlangıç: `2026-07-01`
- kariyer penceresi sonu: `2046-07-01`

`GameDate`, cihazın gerçek tarih/saatinden bağımsızdır.

## Sezonlar arası kulüp gücü

M1'de gerçek kadro ve oyuncu gelişimi henüz olmadığı için kulüp gücü geçici bir köprü modeliyle değişir.

Her kulüp için:

1. kariyer başlangıç gücü baseline olarak kaydedilir,
2. yeni sezon için kulübe özel deterministik RNG seed'i üretilir,
3. en fazla `±1.5` rastgele sezonluk hareket uygulanır,
4. mevcut güç baseline'dan uzaklaştıkça `%20` mean-reversion uygulanır,
5. güç baseline'ın `±4.0` dışına çıkamaz.

Bu model nihai futbol gelişim modeli değildir. M2'de oyuncu havuzu geldiğinde takım gücü kadrodan türetilecek ve bu geçici model kaldırılabilecek/değiştirilebilecektir.

## Determinizm

Kulüp gücü evrim seed'i şu bağlamdan türetilir:

- career seed
- simulation version
- yeni sezon index'i
- club ID
- sabit `club-strength-evolution` domain etiketi

Bu sayede aynı seed + aynı veri seti aynı sezon güçlerini ve aynı kariyer sonuçlarını üretir.

## M1 invariants

- kariyer tam 20 sezon içerir,
- toplam maç sayısı `20 × 56 = 1120` olur,
- sezon index'leri ardışıktır,
- sezon tarih pencereleri ardışıktır,
- her sezon M0 `SeasonValidator` kontrolünden geçer,
- final kulüp ID'leri benzersizdir,
- kulüp güçleri baseline'ın `±4.0` aralığında kalır,
- aynı seed aynı şampiyon dizisini ve final güçlerini üretir.

## Kalite kapısı

M1 ancak GitHub Actions üzerinde aşağıdakilerin tamamı PASS olduğunda kapanır:

- `dart analyze`
- tüm M0 + M1 testleri
- M0 100 sezon batch regresyon testi
- M1 20 sezon kariyer CLI koşusu
- sıfır validation issue

Gerçek seed `20260903` koşusu: 20 sezon / 1.120 maç; şampiyonluklar Vadişehir 10, Kuzey Yıldızı 6, Demirkent 4; validation issue 0.

Sonraki milestone: **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi**.
