# Futbol Başkanlık Simülatörü — Simulation Core

ZMila Studio için geliştirilen deterministik, UI'dan bağımsız Dart futbol kulübü başkanlığı simülasyon çekirdeği.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

## Teknik durum

- **M0 — Deterministik Mini Lig:** PASS
- **M1 — 20 Sezon Yaşam Döngüsü:** PASS
- **M2 — Oyuncu Havuzu + Yaşlanma + Genç Üretimi:** PASS
- **M3 — Temel Kulüp Ekonomisi:** PASS
- **M4 — Basit Transfer Pazarı:** PASS
- **M5 — 48 Kulüp / 3 Lig:** PASS
- **M6 — Teknik Direktör Sistemi:** PASS
- **M7 — Oyuncu Sözleşmesi + Gerçek Maaş:** PASS
- **M8 — Kiralık + Taksit:** PASS
- **M9 — Taraftar Beklentisi + Güven:** PASS
- **M10 — Medya Hafızası + Başkan Açıklamaları:** PASS
- **M11 — Başkan Vaatleri + Takip:** PASS
- **M12 — Vaat Sonuçları → Taraftar Güveni:** PASS

Flutter bağımlılığı henüz yoktur. Öncelik, uzun kariyerde çalışan başkanlık simülasyonunu mobil arayüzden önce headless otomatik testlerle kanıtlamaktır.

## Dünya ölçeği

- 48 özgün kurgu kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / dünya sezonu
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ortak ekonomi, kontrat ve transfer pazarı

## Önemli tamamlanan katmanlar

### M6 — Teknik direktör
96 deterministik manager, 5 profil, kulüp/kadro/lig/finans uyumu, sınırlı maç gücü etkisi, board relationship ve görev değişimleri. Seed `20260903`: 82 değişim, 60 farklı manager, validation `0`.

### M7 — Sözleşme + maaş
Gerçek yıllık maaş, kontrat süresi, renewal/release, free-agent, youth ve transfer kontratları. Seed `20260903`: 874 final kontrat, 3.757 renewal, 1.143 release, 776 free signing, final wage bill `491,27M`.

### M8 — Kiralık + taksit
Parent club kontratını koruyan sezonluk kiralık; loan fee + maaş paylaşımı; upfront + gelecek taksit yükümlülükleri. Seed `20260903`: 140 kalıcı transfer, 68 taksitli, 478 kiralık, final cash `1.017,61M`, debt `378,97M`.

### M9 — Taraftar
Sporting / financial / transfer / identity boyutları, bağlamsal beklentiler ve neden hafızası. Seed `20260903`: 960 snapshot, avg trust `64,88`, final aralık `44–75`.

### M10 — Medya hafızası
Başkan açıklaması sonraki yönetim eylemiyle consistency/contradiction olarak çözülür. Güçlü destek verip hocayı değiştirmek credibility cezası üretir. Seed `20260903`: 556 statement, 22 contradiction, avg credibility `75,52`.

### M11 — Başkan vaatleri
Sezon başı bilgiden ölçülebilir vaat üretimi; fulfilled / partial / broken sezon sonu çözümlemesi. Seed `20260903`: 960 vaat, 435 fulfilled, 169 partial, 356 broken, avg score `54,84`.

### M12 — Vaat → taraftar güveni
M9 ve M11 aynı `AdvancedTransferCareerReport` üzerinde birleşir; dünya iki kez simüle edilmez. Her vaat identity trust, finans vaatleri ayrıca financial trust nedeni üretir.

Seed `20260903`: 1.065 promise reason; M9 baseline trust `64,88` → M12 `65,31`; identity avg `61,83`, aralık `38–88`; validation `0`.

Ayrıntı: `M12_VAAT_TARAFTAR_GUVENI.md`.

## Mimari

**Flutter mobil kabuk + saf Dart simülasyon çekirdeği + headless test runner.**

`WorldCareerEngine` no-op varsayılanlı hook'larla genişletilir. M9–M12 gibi gözlemsel/itibar katmanları mümkün olduğunda aynı alt dünya raporunu paylaşır; aynı katman için dünya yeniden simüle edilmez.

Temel teknik kurallar:

- deterministik seed/replay,
- cihaz saatinden bağımsız `GameDate`,
- integer minor-unit `Money`,
- banka borcundan ayrı transfer taksit yükümlülüğü,
- uzun kariyer invariant + denge guard'ları.

## Çalıştırma

```bash
dart pub get
dart analyze
dart test
dart run tool/run_m0_batch.dart 100
dart run tool/run_m5_world_career.dart 20260903
dart run tool/run_m8_advanced_transfer_career.dart 20260903
dart run tool/run_m9_fan_career.dart 20260903
dart run tool/run_m10_media_career.dart 20260903
dart run tool/run_m11_promise_career.dart 20260903
dart run tool/run_m12_promise_fan_career.dart 20260903
```

## CI prensibi

Tek hafif workflow: `dart analyze` + tüm testler + M0 100 sezon batch + M1–M12 20 sezon runner zinciri. APK/AAB, büyük binary ve `actions/upload-artifact` yoktur; artifact hedefi `0`dır.

## Sıradaki milestone

**M13 — Vaat Sonuçlarının Medya Güvenilirliğine Etkisi.**

Amaç, resmi vaat sonucunu M10 medya hafızasına bağlamak; tutulmayan vaatlerin başkan credibility'sini düşürmesi, tutulan zor vaatlerin ise sınırlı biçimde güçlendirmesidir. Seçim sistemi bundan sonra fan trust + media credibility + promise history temelinde kurulabilir.

## Lisans

Repository public tutulsa da kaynak kod açık kaynak lisansı altında değildir. Ayrıntılar için `LICENSE.md` dosyasına bakın.
