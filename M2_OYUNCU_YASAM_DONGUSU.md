# Futbol Başkanlık Simülatörü — M2 Oyuncu Yaşam Döngüsü

**Milestone:** M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi  
**Amaç:** M1'in 20 sezonluk kariyer omurgasına gerçek oyuncu nüfusu eklemek ve kadroların yıllar içinde deterministik biçimde yaşayıp yenilenebildiğini kanıtlamak.

## Kapsam

- 8 kulüp × 18 oyuncu = 144 kişilik başlangıç havuzu
- pozisyonlar: kaleci, defans, orta saha, forvet
- oyuncu yaşı
- mevcut seviye (`ability`)
- potansiyel (`potential`)
- deterministik gelişim / düşüş
- deterministik emeklilik yaşı
- sezonlar arası yaşlanma
- her kulüp için sezon başına 1 genç oyuncu üretimi
- kadrodan türetilen takım gücü
- 20 sezon oyuncu kariyeri
- oyuncu nüfusu ve kariyer validator'ı

M2'de transfer, sözleşme, maaş, ekonomi, teknik direktör, taraftar, medya, sponsor, tesis, Flutter UI ve APK yoktur.

## Başlangıç kadrosu

Her kulüp 18 oyuncu ile başlar:

- 2 kaleci
- 6 defans
- 6 orta saha
- 4 forvet

Başlangıç yaşları 17–33 arasındadır. Oyuncu seviyesi kulübün M0 referans gücü çevresinde deterministik olarak üretilir. Genç oyuncular daha düşük mevcut seviye fakat daha yüksek gelişim payı taşıyabilir.

## Takım gücü

M2 oyuncu kariyerinde M1'in geçici kulüp güç evrimi kullanılmaz. Takım gücü her sezon oyunculardan türetilir.

Referans ilk 11:

- 1 kaleci
- 4 defans
- 3 orta saha
- 3 forvet

Pozisyon eksiği varsa kalan en iyi oyuncular kullanılır ve küçük bir pozisyon dengesizliği cezası uygulanır.

## Oyuncu gelişimi

- 16–20: potansiyel boşluğuna bağlı güçlü gelişim
- 21–23: orta düzey gelişim
- 24–26: plato / küçük gelişim
- 27–29: hafif düşüş riski
- 30+: kademeli fiziksel düşüş
- 34+: daha belirgin düşüş

Oyuncu `ability` değeri kendi `potential` değerini geçemez.

## Emeklilik

Her oyuncunun 34–38 arasında deterministik emeklilik yaşı vardır. Oyuncu sezon geçişinde bu yaşa ulaştığında aktif havuzdan çıkar.

## Genç üretimi

Her sezon geçişinde her kulüp 1 genç oyuncu üretir. 20 sezonluk koşuda 19 sezon geçişi olduğu için toplam genç üretimi:

`19 × 8 = 152 oyuncu`

Genç oyuncu yaşı 16–18 aralığındadır. Üretim seviyesi kulübün başlangıç referans gücüne bağlanır; böylece yalnızca yaşlanan kadrolar yüzünden bütün ligin 20 yılda aşağı doğru sürüklendiği bir güç sarmalı oluşmaz. Pozisyon seçiminde kadro eksikleri önceliklendirilir; kadro dengeliyse ağırlıklı deterministik seçim yapılır. Nadir yüksek potansiyelli genç üretimi mümkündür.

## Determinizm

Başlangıç oyuncuları, oyuncu gelişimi, emeklilik zamanlaması ve genç üretimi aşağıdaki bağlamlardan kararlı seed türeterek çalışır:

- career seed
- simulation version
- season index
- club ID / player ID
- domain etiketi

Aynı seed + aynı veri seti aynı 20 sezonluk oyuncu nüfusunu ve maç sonuçlarını üretmelidir.

## M2 kalite kapısı

- `dart analyze` PASS
- tüm M0 + M1 + M2 testleri PASS
- M0 100 sezon regresyonu PASS
- M1 20 sezon kariyer regresyonu PASS
- M2 20 sezon oyuncu kariyeri PASS
- 1.120 maç tamamlanmalı
- başlangıç oyuncu sayısı 144 olmalı
- 152 genç üretimi gerçekleşmeli
- emeklilikler gerçekleşmeli
- her kulüp her sezon en az 11 aktif oyuncuya sahip olmalı
- oyuncu ID'leri benzersiz kalmalı
- oyuncu sayısı korunum denklemi tutmalı
- validation issue = 0
- CI artifact = 0

Sonraki milestone: **M3 — Temel Kulüp Ekonomisi**.
