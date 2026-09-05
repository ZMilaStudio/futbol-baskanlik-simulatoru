# M27 — Advanced World Runtime Snapshot I

Tarih: 5 Eylül 2026

## Amaç

M26'nın doğrulanmış `WorldCheckpoint` save/resume sözleşmesini, `WorldCareerEngine` dışında hook/controller katmanlarında yaşayan sezonlar-arası state'e genişletmek.

M27'nin temel kabul ilkesi:

> **20 sezon kesintisiz advanced runtime ile `8 sezon → save → load → 12 sezon resume` aynı seed'de yalnız final dünyada değil, devam için sahip olunan runtime state'in tamamında birebir deterministic olmalıdır.**

Canonical seed: `20260903`.

## State sahipliği

Kod incelemesinde state sahipliği şu şekilde doğrulandı.

### Advanced transfer / contract

`PlayerContractController`:

- aktif `PlayerContract` kayıtları
- `ContractEvent` geçmişi
- initialization state

`AdvancedTransferController`:

- contract controller
- aktif `LoanAgreement` kayıtları
- loan history
- `TransferInstallmentObligation` kayıtları

### Manager

`ManagerCareerController`:

- manager pool
- 48 kulübün current manager assignment'ı
- manager season history
- sezon içi `_pending` manager state'i

Checkpoint yalnız temiz sezon sınırında üretildiği için manager `_pending` state'i save anında boş olmalıdır; restore yolu da boş pending ile başlar.

## Yeni çekirdek

### `AdvancedRuntimeCheckpoint`

Nested state:

- M26 `WorldCheckpoint`
- `AdvancedTransferRuntimeState`
- `ManagerRuntimeState`

### `AdvancedTransferRuntimeState`

Taşınan state:

- active contracts
- contract event history
- active loans
- loan history
- installment obligations

Validation:

- contract player/club referansları geçerli
- aynı oyuncuya duplicate active contract yok
- active loan parent contract ile uyumlu
- active loan oyuncusu loan club'da
- active loan checkpoint sezonunda gerçekten aktif
- active loan aynı zamanda loan history içinde
- installment club referansları ve due season geçerli
- contract event club referansları geçerli

### `ManagerRuntimeState`

Taşınan state:

- deterministic manager pool
- current assignments
- manager career season history

Validation:

- manager ID'leri unique
- 48 kulübün tamamında tam bir assignment var
- active assignment'larda manager duplicate değil
- assignment manager ID'si manager pool'da var
- manager history sayısı completed season sayısına eşit
- her history sezonu 48 kulübü tam bir kez kapsıyor
- manager change referansları geçerli

## Restore API'leri

M27 ile eklendi:

- `PlayerContractController.restore(...)`
- `AdvancedTransferController.restore(...)`
- `ManagerCareerController.restore(...)`

Restore edilen controller'lar tekrar initial state üretmez; save'den gelen state'i devam ettirir.

## Checkpoint-capable world hook desteği

M26 `WorldCareerEngine.simulateWithCheckpoint(...)` ve `resume(...)` API'leri optional:

- `WorldCareerHooks`
- `WorldRosterHooks`
- `WorldFinanceHooks`
- `WorldTransferHooks`
- `enableTransferInstallments`

parametrelerini kabul edecek şekilde genişletildi.

Default değerler `Noop...` / `false` olduğu için M26 core world save yolu ve legacy `simulate()` davranışı değişmedi.

## `AdvancedRuntimeCareerEngine`

Yeni orchestration katmanı:

- initial advanced checkpoint run
- advanced controller'ları kurma
- nested world checkpoint üretme
- controller state'i snapshot'a alma
- save sonrası controller restore
- `WorldCareerEngine.resume(...)` üzerinden deterministik continuation

M27 ilk sürümde manager patience/president timeline eklemez; manager sistemi neutral mevcut davranışla çalışır.

## `AdvancedWorldSaveCodec`

Format:

`zmila-fbs-advanced-world`

Sürüm:

`saveVersion=1`

Özellikler:

- nested M26 `WorldSaveCodec`
- canonical deterministic JSON
- FNV-1a corruption checksum
- explicit save/load failures
- checksum mismatch rejection
- future version rejection
- checksum-valid structural corruption rejection
- sentetik `v0 → v1` migration fixture

Checksum güvenlik/anti-cheat değildir; accidental corruption detection içindir.

## Testler

Yeni M27 testleri:

1. deterministic encoding + round-trip
2. `8 + 12 == uninterrupted 20` advanced world continuation
3. owned runtime stream'lerin tamamının round-trip korunumu
4. checksum corruption rejection
5. checksum-valid future version rejection
6. checksum-valid invalid manager assignment rejection
7. synthetic `v0 → v1` migration
8. malformed JSON explicit failure

İlk tam PR CI'da toplam normal/non-canonical test sayısı:

`102`

## Canonical kabul — PR #28 ilk tam CI

Run:

`33933116072` — **SUCCESS**

Doğrulananlar:

- analyzer PASS
- `102` normal/non-canonical test PASS
- M0–M18 runner PASS
- combined M19–M24 canonical runner PASS
- M25 save/load runner PASS
- M26 world save runner PASS
- M27 advanced runtime save runner PASS
- artifact `0`
- 5 dakikalık workflow timeout altında PASS

M27 canonical runner çıktısı:

- seed `20260903`
- save version `1`
- checksum `49e9d08e`
- save bytes `1.013.092`
- split `8 + 12`
- loaded next season index `8`
- season replay match `true`
- final runtime checkpoint match `true`
- active contracts `897`
- contract events `3496`
- active loans `23`
- loan history `186`
- installment obligations `36`
- manager pool `96`
- manager assignments `48`
- manager seasons `8`
- legacy fixture migration `v0 → v1`

## Save boyutu: yeni teknik borç

M26 core world save, sezon 8 checkpoint'inde:

`187.664 bytes`

M27 advanced runtime save, aynı canonical checkpoint'te:

`1.013.092 bytes`

Bu yaklaşık `5,4×` büyümedir.

Ana neden runtime için gerekli current state'ten çok append-only tarihçe kayıtlarıdır:

- `3496` contract event
- `186` loan history entry
- 8 sezon × 48 kulüp manager history + manager change kayıtları

Bu M27 correctness milestone'unu geçersiz kılmaz; tam history round-trip bilinçli olarak korunmuştur. Ancak president/fan/media/promise history de aynı biçimde eklenirse 20–30 sezon save boyutu gereksiz büyüyecektir.

Bu nedenle yeni historical runtime state eklemeden önce continuation-critical state ile historical archive state'in ayrılması gerekir.

## Bilinçli kapsam dışı

M27 şunları içermez:

- president/reputation/election timeline
- fan state/history
- media memory/history
- promise memory/history
- Android file picker
- save slot UI
- autosave/backup platform policy
- cloud save
- Google Play Games save
- encryption / anti-cheat

## Sonraki yön — M28

> **M28 — Save History Compaction / Historical Memory Policy I**

M28'in amacı yeni oyun davranışı eklemek değil, M27 ile görünür hale gelen save büyümesini mimari olarak kontrol altına almaktır.

İlk hedefler:

1. continuation-critical state ile historical/reporting state'i açıkça ayırmak
2. geçmiş event listesinin tamamının gerçekten resume için gerekli olup olmadığını sınıflandırmak
3. contract/loan/manager history için compact representation veya archive policy belirlemek
4. 20 sezon save-size guard eklemek
5. compact save → load → resume sonucunun M27 full-history save ile aynı deterministic future world'ü verdiğini kanıtlamak
6. kullanıcıya gösterilecek tarihçenin kaybolmaması için history UI gereksinimi ile simulation continuation gereksinimini birbirine karıştırmamak

President/reputation/election runtime snapshot bu optimizasyon sonrasında doğal olarak M29 adayıdır.
