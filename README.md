# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** PASS
- **M4 — Basit Transfer Pazarı:** PASS
- **M5 — 48 Kulüp / 3 Lig:** PASS
- **M6 — Teknik Direktör Sistemi:** PASS
- **M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi:** PASS
- **M8 — Gelişmiş Transfer Yapıları I / Kiralık + Taksit:** PASS
- **M9 — Taraftar Beklentisi + Güven Çekirdeği:** PASS

Flutter bağımlılığı henüz yoktur. Öncelik, başkanlık simülasyonunun uzun kariyer boyunca sağlam çalışan çekirdeğini mobil arayüzden önce otomatik testlerle kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

M5 seed `20260903` no-op baseline: 71 transfer, `637,91M` transfer hacmi, `862,25M` final nakit, `647,04M` final borç, validation `0`.

Ayrıntı: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi

Başkan saha içini yönetmez; doğru teknik direktörü seçer.

- 96 deterministik teknik direktör
- 5 profil
- coaching / youth development / man management / board cooperation / budget demand
- kulüp-kadro-lig-finans bağlamına göre uyum
- maç gücüne sınırlı `-2,5...+2,5` etki
- yönetim ilişkisi
- performans / yönetim kopması / emeklilik nedeniyle görev değişimi
- kovulan hocanın başka kulüpte yeniden çalışabilmesi

Seed `20260903`: 82 görev değişimi, 60 farklı hoca, ortalama etki `+0,922`, final ortalama board relationship `72,22`, validation `0`.

Ayrıntı: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

## M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi

- gerçek yıllık oyuncu maaşı
- başlangıç/bitiş sezonlu kontrat
- yenileme veya serbest kalma
- free-agent havuzu ve mevki ihtiyacına göre imza
- youth intake ilk profesyonel kontratı
- transfer sonrası yeni kontrat
- kontrat süresinin piyasa değerine etkisi

Seed `20260903`: 874 final aktif kontrat, 3.757 yenileme, 1.143 release, 776 free-agent signing, 32 final free agent, `491,27M` final yıllık maaş, 103 bonservis transferi, `1.060,80M` cash, `554,81M` debt, validation `0`.

Ayrıntı: `M7_OYUNCU_SOZLESMESI_MAAS.md`.

## M8 — Kiralık + Taksit

M8 ana transfer felsefesini gelişmiş yapılara açar:

> **Paran yoksa transfer yapamazsın değil; paran yoksa daha akıllı transfer yapmak zorundasın.**

- sezonluk `LoanAgreement`
- parent club kontratının korunması
- loan fee + `%45–80` maaş paylaşımı
- sezon sonunda otomatik dönüş
- upfront + iki gelecek sezon transfer taksiti
- `TransferInstallmentObligation`
- taksidin banka borcundan ayrı tutulması
- vadesinde gerçek alıcı/satıcı nakit akışı
- satıcı ekonomisine bağlı taksit kabulü
- bağlamsal kiralık ihtiyacı

Seed `20260903`: 140 kalıcı transfer, 68 taksitli, 478 kiralık, `234,79M` taksit taahhüdü, `113,15M` loan fee, final cash `1.017,61M`, debt `378,97M`, validation `0`.

Ayrıntı: `M8_KIRALIK_TAKSIT.md`.

## M9 — Taraftar Beklentisi + Güven

M9 taraftarı rastgele mutluluk sayacı yerine kulüp bağlamını okuyan bir domain'e dönüştürür.

- `FanState`: sporting / financial / transfer / identity
- ağırlıklı 0–100 overall trust
- 48×20 = 960 kulüp-sezon context snapshot
- lig sırası ve terfi/düşme
- takım gücü
- financial health, cash/debt, emergency borrowing
- permanent transfer / installment / loan davranışı
- 7 aktif bağlamsal beklenti tipi + final `none`
- neden kodlu güven değişimleri
- çok sezonluk hafıza; yalnız dış bantlarda yumuşak mean reversion
- deterministic replay + validator + headless runner

Temel imza davranışı: aynı borç krizi bağlamında akıllı kiralık transfer güvenini `+4`, aşırı harcama/taksit yükü `-4` etkileyebilir.

### M9 kabul baseline — seed `20260903`

- 20 sezon / 14.400 maç
- fan snapshot `960`
- final fan state `48`
- ortalama trust `64,88`
- final trust aralığı `44–75`
- boundary `0`
- trust reason `2.143`
- smart-loan expectation `9`
- financial-discipline expectation `58`
- validation `0`

İlk teknik PASS `46–68` aralığında kaldığı için reddedildi; yıllık 60'a dönüş geçmişi fazla siliyordu. Kabul modelinde hafıza korunarak aralık 31 puana çıktı.

Ayrıntı: `M9_TARAFTAR_GUVEN.md`.

## Mimari

Temel yön:

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

`WorldCareerEngine` kopyalanmadan no-op varsayılanlı hook'larla genişletilir:

- `WorldCareerHooks`: teknik direktör gibi sezon/sportif lifecycle,
- `WorldRosterHooks`: kontrat/kadro/gerçek maaş,
- `WorldFinanceHooks`: transfer taksiti gibi sezon içi ek finans akışları,
- `WorldTransferHooks`: kiralık gibi transfer penceresi sonrası ek hareketler.

M9 ilk sürümde M8 raporunu gözlemsel context olarak kullanır; taraftar henüz ekonomi veya maç motorunu geri beslemez. Önce bağlam doğruluğu kanıtlanır.

Deterministik RNG, cihaz saatinden bağımsız `GameDate` ve integer minor-unit `Money` temel teknik kurallardır.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_batch.dart 100
dart run tool/run_m1_career.dart 20260903
dart run tool/run_m2_player_career.dart 20260903
dart run tool/run_m3_economy_career.dart 20260903
dart run tool/run_m4_transfer_career.dart 20260903
dart run tool/run_m5_world_career.dart 20260903
dart run tool/run_m6_manager_career.dart 20260903
dart run tool/run_m7_contract_career.dart 20260903
dart run tool/run_m8_advanced_transfer_career.dart 20260903
dart run tool/run_m9_fan_career.dart 20260903
```

## CI prensibi

Tek hafif GitHub Actions workflow'u kullanılır:

- `dart analyze`
- tüm otomatik testler
- M0 100 sezon batch
- M1–M9 20 sezon headless runner'ları

APK/AAB, büyük binary veya `actions/upload-artifact` yoktur. Artifact hedefi `0`dır.

## Sıradaki milestone

**M10 — Medya Hafızası + Başkan Açıklamaları Çekirdeği.**

İlk hedef açıklamayı yalnız anlık metin seçimi yapmak değil; başkanın geçmiş sözlerini saklamak ve sonraki davranışla çelişki/uyum tespit edebilen deterministik bir medya güvenilirlik sistemi kurmaktır. İlk M10'da vaat/election ve Flutter UI yine kapsam dışı kalacaktır.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
