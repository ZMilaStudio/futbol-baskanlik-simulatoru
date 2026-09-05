# Futbol Başkanlık Simülatörü — Sohbet Devri

Tarih: 5 Eylül 2026

Bu dosya yeni ana sohbetin doğrudan kaldığı yerden devam etmesi için hazırlanmıştır. Canlı GitHub durumu eski sohbet notlarından üstündür.

## 1. Ana durum

- Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
- `main`: **M0–M27 PASS**
- Aktif milestone: **M28 — Save History Compaction / Historical Memory Policy I**
- Aktif branch: `m28-save-history-compaction`
- Açık PR: **#29**
- Canonical seed: `20260903`
- CI politikası: timeout `5 dk`, artifact hedefi `0`, `actions/upload-artifact` yok.

## 2. M27 kesin kapanış

M27 — Advanced World Runtime Snapshot I tamamen kapalı ve `main` üzerindedir.

- PR #28 final docs HEAD: `8956e558a9b1c509f46404cc80cc4084102e1285`
- Final PR CI: `33933550850` — PASS
- Squash merge SHA: `46e52be2b65910f200b4dee85647d1ae982b5d94`
- Merge sonrası main CI: `33933781498` — PASS
- Canonical kapanış docs CI: `33944395011` — PASS
- Artifact: `0`

M27 canonical 8-sezon advanced save:

- checksum `49e9d08e`
- save boyutu `1.013.092 bytes`
- active contracts `897`
- contract events `3496`
- active loans `23`
- loan history `186`
- installment obligations `36`
- manager pool `96`
- manager assignments `48`
- manager seasons `8`
- `8 + 12` continuation == kesintisiz `20` sezon

M26 aynı checkpoint boyutu `187.664 bytes` idi. M27 yaklaşık `5,4×` büyüdü. Bu büyümenin ana kaynağı append-only historical state'tir.

## 3. M28 amacı

Continuation-critical current state ile yalnız geçmiş/raporlama amacı taşıyan history state ayrılacak.

İlk alanlar:

1. contract event history
2. loan history
3. manager season/change history

Kabul hedefleri:

- aktif contract/loan/installment/manager state eksiksiz korunacak
- compact save → load → resume, full-history M27 ile aynı deterministic geleceği üretmeli
- yakın dönem ham history kontrollü tutulmalı
- eski tarih için kompakt summary/archive sözleşmesi bulunmalı
- 20 sezon save boyutu ölçülmeli ve guard eklenmeli
- save version/migration/checksum güvenliği korunmalı
- M0–M27 baseline değişmemeli

Platform save UI/cloud/encryption M28 kapsamı değildir.

## 4. M28 branch'te şu anda bulunan ilk implementasyon

PR #29 HEAD (ilk CI'daki commit):

`3759dcd0e2297335b5c1cbb8d5e95911e7a17c15`

Eklenen ana parçalar:

- `AdvancedHistorySummary`
- `CompactAdvancedRuntimeCheckpoint`
- `AdvancedRuntimeHistoryCompactor`
- `CompactAdvancedRuntimeCareerEngine`
- `CompactAdvancedWorldSaveCodec`
- `test/m28_save_history_compaction_test.dart`
- `tool/run_m28_save_history_compaction.dart`
- CI workflow'a M28 runner adımı

İlk politika denemesi:

- son `2` sezon ham detail tutuluyor
- tüm kariyer için aggregate history summary tutuluyor
- active state eksiksiz tutuluyor

Summary alanları arasında:

- total contract event count + type dağılımı
- total loan count + loan fee toplamı
- manager season count
- manager change count + reason dağılımı

## 5. İlk M28 CI — başarısız, merge YOK

Run:

`33944814109`

Job:

`101248881732`

Sonuç:

- `dart analyze` — PASS
- normal `dart test` — FAIL
- başarısızlık test aşamasında olduğu için M0–M28 runner zinciri başlamadan skip oldu
- branch merge edilmedi
- `main` hâlâ güvenli M0–M27 PASS durumunda

Bu başarısızlıktan sonra tahmine dayalı bir kod düzeltmesi veya merge yapılmadı.

## 6. Kritik M28 mimari bulgusu

M27 runtime analizinde:

- geçmiş `ContractEvent` kayıtları sonraki sezon kararlarında okunmuyor; current contract map continuation-critical.
- geçmiş inactive `loanHistory` sonraki sezon kararlarında okunmuyor; `activeLoans` continuation-critical.
- eski `ManagerCareerSeason` listesi sonraki manager kararlarında okunmuyor; current manager pool + 48 assignment continuation-critical.
- installment obligations continuation-critical ve history gibi budanmamalı.

Dolayısıyla M28 compaction yönü doğrudur; fakat M27 full-history checkpoint invariantları sessizce gevşetilmemelidir.

## 7. İncelenmesi gereken muhtemel regresyon

M28 branch'te `ManagerRuntimeState.validate(...)` şu şekilde değiştirilmiş durumda:

- eski M27 invariantı: manager season history, completed season sayısını tam karşılıyordu.
- M28 branch denemesi: `seasons.length > world.completedSeasons` kontrolü ve retained-window hesaplaması kullanıyor; yani kısa manager history'ye izin veriyor.

Bu değişiklik M28 compact state için gerekli görünse de **M27'in genel `AdvancedRuntimeCheckpoint` sözleşmesini küresel olarak gevşetiyor**. Yeni sohbette ilk teknik kontrol bu olmalı.

Tercih edilen yön:

- M27 `AdvancedRuntimeCheckpoint` full-history invariantını koru.
- Compact checkpoint için ayrı validation sözleşmesi kur.
- Compact resume sırasında M27 runtime engine'e gereken current state'i verirken full-history doğrulamasına bağımlı kalmayacak temiz bir restore/continuation state yolu tasarla.

Ancak gerçek test failure satırı görülmeden kesin yama yapılmamalıdır.

## 8. Yeni sohbette ilk yapılacaklar

1. PR #29 ve branch HEAD canlı durumunu yeniden doğrula.
2. GitHub Actions job `101248881732` için `fetch_workflow_job_logs` kullan ve gerçek başarısız test/assertion satırını çıkar.
3. Hatanın M27 invariant gevşetmesinden mi, history summary append hesabından mı, save-size guard'dan mı geldiğini kanıtla.
4. Yalnız gerçek nedene yönelik minimal düzeltme yap.
5. Yeni HEAD CI'da:
   - analyzer PASS
   - normal tests PASS
   - M0–M27 regresyon PASS
   - M28 runner PASS
   - artifact `0`
   - 5 dk altında PASS
6. Canonical M28 save-size sayılarını runner logundan kaydet.
7. `M28_SAVE_HISTORY_COMPACTION_I.md` teknik dokümanını tamamla.
8. `GENEL_PROJE_OZETI.md` içine final M28 sonuçlarını işle.
9. PR #29 final HEAD CI yeşil ve expected SHA eşleşiyorsa squash merge et.
10. Merge sonrası `main` CI + artifact `0` doğrula.

## 9. M28 sonrası plan

M28 PASS sonrası en güçlü aday:

**M29 — President / Reputation / Election Runtime Snapshot**

Sonrasında fan/media/promise runtime memory snapshot.

## 10. Kalıcı çalışma kuralları

- Kullanıcıyı mikro test operatörü yapma; mümkün olan büyük mantıklı işi tek çalışma döngüsünde tamamla.
- Canlı GitHub sonucu olmadan PASS/merge iddiası yapma.
- Eski milestone API semantiğini yeni save özelliği uğruna sessizce değiştirme.
- Deterministic continuation kesintisiz replay ile aynı geleceği üretmeli.
- Canonical hesapları CI içinde gereksiz tekrar etme.
- Artifact `0` hedefini koru.
- Gerçek kulüp/futbolcu/lisanslı varlık kullanma.
- Oyuncu teknik direktör değil kulüp başkanıdır.
