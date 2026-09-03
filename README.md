# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen Futbol Başkanlık Simülatörü'nün deterministik, UI'dan bağımsız Dart simülasyon çekirdeği.

Temel oyun kimliği: **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** PASS
- **M4 — Basit Transfer Pazarı:** PASS
- **M5 — 48 Kulüp / 3 Lig:** PASS
- **M6 — Teknik Direktör Sistemi:** PASS
- **M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi:** sıradaki milestone

Flutter bağımlılığı henüz yoktur. Amaç maç, sezon, oyuncu yaşam döngüsü, ekonomi, transfer ve başkanlık sistemlerini mobil arayüzden önce otomatik testlerle doğrulamaktır.

## M0–M5 kısa özet

M0 ile deterministik lig/maç motoru; M1 ile 20 sezon kariyer; M2 ile oyuncu yaşlanması, emeklilik ve genç üretimi; M3 ile nakit/borç ekonomisi; M4 ile doğrudan bonservisli transfer pazarı; M5 ile 48 kurgu kulüp ve 3 liglik dünya ölçeği doğrulandı.

M5 seed `20260903` baseline'ı: 20 sezon, 14.400 maç, 864 başlangıç / 906 final oyuncu, 228 lig hareketi, 71 transfer, `637,91M` transfer hacmi, `862,25M` final nakit, `647,04M` final borç ve validation `0`.

Ayrıntılar: `M5_48_KULUP_3_LIG.md`.

## M6 — Teknik Direktör Sistemi

M6 ile başkanlık kimliğinin ilk gerçek teknik direktör katmanı eklendi:

- 96 kişilik deterministik kurgu teknik direktör havuzu
- 5 profil: `balanced`, `youthDeveloper`, `budgetBuilder`, `starManager`, `resultsFirst`
- itibar, coaching, genç geliştirme, insan yönetimi, yönetim uyumu ve bütçe talebi
- kulüp/kadro/lig/finans bağlamına göre teknik direktör uyumu
- maç gücüne sınırlı `-2,5...+2,5` teknik direktör etkisi
- sezon sonu beklenen sıra / gerçek sıra değerlendirmesi
- yönetim ilişkisi
- performans, yönetim kopması ve emeklilik nedeniyle görev değişimi
- kovulan hocanın başka kulüpte yeniden çalışabilmesi
- her kulüpte tek aktif teknik direktör ve deterministik kariyer sürekliliği
- manager report + validator + headless runner

`WorldCareerEngine` varsayılan olarak `NoopWorldCareerHooks` kullanmaya devam eder. Böylece M5 yolu ve baseline'ı manager sistemi eklenmesine rağmen değişmedi. M6 manager katmanı aynı motorun üzerine hook olarak bağlandı.

### Kabul edilen M6 baseline — seed `20260903`

- 20 sezon / 14.400 maç
- manager havuzu: `96`
- görev yapan farklı manager: `60`
- toplam görev değişimi: `82`
- performans nedeniyle: `51`
- yönetim ilişkisi kopması: `29`
- emeklilik: `2`
- ortalama strength etkisi: `+0,922`
- AI atamalarında etki aralığı: `-0,371...+1,977`
- negatif etkili kulüp-sezon: `29`
- `+1,5` ve üzeri güçlü pozitif kulüp-sezon: `77`
- final ortalama yönetim ilişkisi: `72,22`
- transfer: `84`
- transfer hacmi: `777,02M`
- final nakit: `1.048,02M`
- final borç: `582,36M`
- acil finansman: `473,40M`
- manager validation issue: `0`

AI çoğunlukla uygun hoca seçtiği için negatif etkiler sınırlıdır. Model doğrudan testte kötü başkanlık tercihi için `-2,5`, çok güçlü uyum için `+2,5` sınırına ulaşabilmektedir.

M6'da `youthDevelopment` şimdilik uyum ve genç kadrolu takımın manager etkisinde kullanılır; bireysel oyuncu gelişim eğrisini henüz doğrudan değiştirmez. Teknik direktör maaş/sözleşmesi, transfer talebi, başka kulüpten teklif ve medya davranışı da sonraki katmanlardadır.

Ayrıntılar: `M6_TEKNIK_DIREKTOR_SISTEMI.md`.

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
```

## CI prensibi

GitHub Actions yalnız Dart bağımlılıklarını kurar, analiz/testleri ve headless simülasyon koşularını çalıştırır. APK/AAB veya büyük artifact üretilmez/yüklenmez.

M6 kabul kalite kapısı:

- `dart analyze`: PASS
- otomatik test: M0–M6 PASS
- M0–M6 headless runner zinciri: PASS
- M5 eski baseline: korunuyor
- M6 validation issue: `0`
- artifact: `0`

## Sıradaki milestone

**M7 — Oyuncu Sözleşmesi + Gerçek Maaş Sistemi.**

Amaç M3'teki geçici `WageModel` köprüsünü kaldırmak; oyunculara gerçek sözleşme süresi ve maaş bağlamak, sözleşme bitişi/yenileme/serbest kalma davranışını kurmak ve ekonomi ile transfer değerini gerçek kontrat verisiyle beslemektir. Bu katman tamamlanmadan taksit/kiralık/bonus gibi gelişmiş transfer yapılarının eklenmesi ertelenecektir.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
