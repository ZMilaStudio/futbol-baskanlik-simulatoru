# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 6 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen tam kapsamlı Android mobil futbol kulübü başkanlığı simülasyonu.

Değişmez ana kimlik:

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**

Ana satış fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Alternatif slogan:

> **Hoca gider. Futbolcu gider. Borç kalır. Başkan sensin.**

Başkanın ana sorumlulukları:

- ekonomi, nakit ve borç
- teknik direktör seçimi ve görev güvenliği
- transfer stratejisi
- sözleşme/maaş politikası
- kiralık/taksit seçenekleri
- taraftar beklentisi ve güveni
- medya açıklamaları ve hafıza
- başkan vaatleri
- başkanlık seçimleri ve görev süresi
- ilerleyen aşamalarda altyapı, tesis, sponsor ve krizler
- uzun vadeli kulüp sağlığı

Football Manager benzeri maç içi taktik yönetimi yapılmaz. Oyuncu diziliş, antrenman, dakika bazlı oyuncu değişikliği veya duran top planlamaz.

Gerçek kulüp, futbolcu, logo veya lisanslı materyal kullanılmaz.

## 2. Geliştirme stratejisi

Şu aşamada görsel ekran veya APK ana hedef değildir.

> **Önce sağlam, deterministik, uzun kariyerde otomatik test edilebilir simülasyon çekirdeği.**

Repo:

`ZMilaStudio/futbol-baskanlik-simulatoru`

Repo public tutulur; kaynak kod açık kaynak lisansı altında değildir (`LICENSE.md`).

Saf Dart simülasyon çekirdeği önce tamamlanır; Flutter mobil kabuk daha sonra gelir.

Codex gereksiz tüketilmez. Büyük çok-dosyalı refactor/test/migration işlerinde gerekirse kullanılır; çekirdek milestone'ların önemli bölümü doğrudan GitHub araçlarıyla yürütülür.

## 3. CANLI DURUM — yeni sohbet buradan devam etmeli

**M0–M28 PASS ve `main` üzerindedir.**

M28 PR:

- PR `#29` — MERGED
- squash merge commit: `8fb9846c70b438641521a4023068a5a707d0ea38`
- merge sonrası `main` CI: run `33998088249`
- job `101392009597`
- workflow conclusion: **SUCCESS**
- analyzer PASS
- normal/non-canonical tests PASS
- M0–M18 runner zinciri PASS
- combined M19–M24 canonical profile feedback PASS
- M25 save/load continuation PASS
- M26 world save continuation PASS
- M27 advanced runtime save continuation PASS
- M28 save history compaction PASS
- artifact `0`
- CI timeout `7 dk`

Aktif durum:

> **M28 tamamen kapandı. Sıradaki teknik milestone M29 için hazırlık yapılabilir.**

M28 canonical sonuçları:

- M27 season-8 full save: `1.013.092 bytes`
- M28 season-8 compact save: `736.274 bytes`
- azalma: `%27,3`
- M28 season-20 compact save: `915.648 bytes`
- 8 sezon save/load + 12 sezon resume: kesintisiz 20 sezonla birebir PASS
- final compact checkpoint: birebir PASS

Ayrıntılı eski sohbet devri:

`SOHBET_DEVRI_2026-09-05_M28.md`

Canlı GitHub durumu her zaman eski sohbet notlarından üstündür.

## 4. Son kapalı milestone — M28

### M28 — Save History Compaction / Historical Memory Policy I — PASS

M27 correctness temelini değiştirmeden append-only advanced runtime history'nin save boyutunu sınırlayan ayrı compact save katmanı eklendi.

Eklenen ana parçalar:

- `AdvancedHistorySummary`
- `CompactAdvancedRuntimeCheckpoint`
- `AdvancedRuntimeHistoryCompactor`
- `CompactAdvancedRuntimeCareerEngine`
- `CompactAdvancedWorldSaveCodec`
- `test/m28_save_history_compaction_test.dart`
- `tool/run_m28_save_history_compaction.dart`
- workflow M28 runner adımı

Uygulanan policy:

- son `2` sezonun contract/loan ham history detayı tutulur
- bütün kariyer için all-time aggregate summary tutulur
- active contract/loan/installment ve current manager state eksiksiz tutulur
- active loan detayı yaşından bağımsız korunur
- M27 strict manager full-history checkpoint invariantı korunur
- M27 `AdvancedWorldSaveCodec` geriye uyumlu kalır
- compact codec canonical JSON, checksum, explicit failure code ve v0→v1 migration sağlar

Compact save formatı:

`zmila-fbs-advanced-world-compact`

Save version:

`1`

İlk gerçek M28 failure:

- run `33962416197`
- job `101296509828`
- resume boundary'deki opening transfer history ikinci kez all-time summary'ye ekleniyordu
- overcount: contract event `+380`, loan `+23`

Düzeltme:

- commit `f2a3cc4bf8b6ca0d516ca3ab7c94e9817c6db5fb`
- contract/loan resume delta sınırı exclusive (`>`) yapıldı
- manager completed-season aralığı doğru olarak inclusive (`>=`) bırakıldı

Tam zincir 5 dakikalık limite dayandığı için timeout:

- commit `ac3f32c79e2b4053743ecd98e41f18b1b51dc71c`
- `7 dk`

Final PR HEAD:

`433a5caf168bf92bdbe474efa0d8c0ba46263a04`

Final PR CI:

- run `33997254719`
- job `101389831400`
- PASS
- artifact `0`

Squash merge:

`8fb9846c70b438641521a4023068a5a707d0ea38`

Merge sonrası `main` kapanış CI:

- run `33998088249`
- job `101392009597`
- PASS
- M0–M28 tüm adımlar PASS
- artifact `0`

## 5. M28 kabul kriterleri — PASS

- continuation-critical state açık sınıflandırıldı — PASS
- history compact/archive policy tanımlandı — PASS
- compact save → load → resume deterministic eşitlik — PASS
- aktif contract/loan/installment/manager state korunumu — PASS
- yakın dönem ham kullanıcı tarihçesi — PASS
- eski dönem all-time summary sözleşmesi — PASS
- canonical save boyutu ölçümü — PASS
- season-8 `< 750.000 bytes` ve `>%25` küçülme guard'ı — PASS
- save version/migration/checksum güvenliği — PASS
- M0–M27 baseline — PASS
- analyzer — PASS
- normal tests — PASS
- M0–M28 runners — PASS
- artifact — `0`
- timeout — gerçek zincire uygun `7 dk`

M28 kapsamı değildir:

- Android file picker
- cloud save
- save-slot UI
- encryption / anti-cheat

## 6. M27 — Advanced World Runtime Snapshot I — PASS

M27, M26 core world state'ini gerçek hook/controller-owned sezonlar-arası state'e genişletti.

Yeni çekirdek:

- `AdvancedRuntimeCheckpoint`
- `AdvancedTransferRuntimeState`
- `ManagerRuntimeState`
- `AdvancedRuntimeSimulationResult`
- `AdvancedRuntimeCareerEngine`
- `AdvancedWorldSaveCodec`
- `PlayerContractController.restore(...)`
- `AdvancedTransferController.restore(...)`
- `ManagerCareerController.restore(...)`

Snapshot state:

- nested M26 `WorldCheckpoint`
- active contracts
- contract event history
- active loans
- loan history
- installment obligations
- manager pool
- 48 current manager assignment
- manager season history

Checkpoint yalnız temiz sezon sınırında üretilir; manager `_pending` state'i save'e yazılmaz ve restore sonrası boş başlar.

`AdvancedWorldSaveCodec`:

- format `zmila-fbs-advanced-world`
- save version `1`
- nested `WorldSaveCodec`
- canonical JSON
- FNV-1a corruption checksum
- future version rejection
- checksum-valid structural corruption rejection
- sentetik `v0 → v1` migration

Canonical seed `20260903`:

`20 sezon advanced runtime` ile `8 sezon → save → load → 12 sezon resume` birebir eşittir.

M27 canonical runner:

- checksum `49e9d08e`
- save boyutu `1.013.092 bytes`
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
- legacy fixture `v0 → v1`

M27 final PR CI:

`33933550850` — PASS

M27 squash merge:

`46e52be2b65910f200b4dee85647d1ae982b5d94`

Merge sonrası `main` CI:

`33933781498` — PASS

Canonical kapanış docs CI:

`33944395011` — PASS

Tüm kapanış doğrulamalarında artifact `0`.

Ayrıntı:

`M27_ADVANCED_WORLD_RUNTIME_SNAPSHOT_I.md`

## 7. Teknik mimari ve kalıcı kurallar

- saf Dart simülasyon çekirdeği
- Flutter shell daha sonra
- deterministik seed/replay
- cihaz saatinden bağımsız `GameDate`
- integer minor-unit `Money`
- headless runner + invariant/balance guard
- profile feedback için deterministic fixed-point replay
- convergence/cycle kontrolü
- neutral trait eski davranışı korur
- checkpoint save bir sonraki sezonun opening state'idir
- save version açık olmalıdır
- unsupported future version güvenli reddedilmelidir
- migration fixture/test zorunludur
- checksum accidental corruption detection içindir; kriptografik güvenlik değildir
- state sahipliği farklı controller/hook katmanlarında ise tek milestone'a zorla yığılmaz
- eski public simülasyon API semantiği save uğruna sessizce değişmez
- continuation-critical state ile append-only historical state aynı kabul edilmez
- yeni historical subsystem eklenmeden önce uzun kariyer save büyümesi ölçülür
- canlı GitHub durumu eski sohbet notlarından üstündür
- PASS yalnız canlı CI kanıtıyla yazılır
- aynı canonical full-career hesaplar gereksiz tekrar edilmez
- artifact hedefi `0`
- `actions/upload-artifact` kullanılmaz

Canonical kariyer seed'i:

`20260903`

Dünya ölçeği:

- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 14.400 maç / 20 sezon
- 864 başlangıç oyuncusu
- terfi/düşme
- ekonomi
- oyuncu yaşam döngüsü
- kontrat
- transfer
- manager
- taraftar
- medya
- vaat
- seçim
- başkan profili

## 8. Milestone geçmişi — özet

### M0 — Deterministik sezon çekirdeği — PASS
Lig/fixture/match simülasyonu, deterministic replay, 100 sezon batch invariant.

### M1 — 20 sezon kariyer — PASS
Ardışık sezon kariyeri, custom başlangıç sezonu/tarih.

### M2 — Oyuncu yaşam döngüsü — PASS
Yaşlanma, emeklilik, genç oyuncu üretimi, uzun vadeli kadro devamlılığı.

### M3 — Ekonomi — PASS
Exact `Money`, gelir/gider, nakit/borç/financial health, emergency borrowing.

### M4 — Transfer pazarı — PASS
Market value, buyer/seller mantığı, ihtiyaç, teklif/ask pazarlığı.

### M5 — 48 kulüp / 3 lig world — PASS
3×16 lig, 20 sezon world simulation, terfi/düşme, ortak ekonomi/transfer ölçeği.

### M6 — Teknik direktör sistemi — PASS
Deterministik manager pool, manager profilleri, dismissal/retirement, manager strength impact.

### M7 — Oyuncu sözleşmesi + gerçek maaş — PASS
Contract lifecycle, wage bill, renewal/release/free-agent signing, transfer sonrası yeni kontrat.

### M8 — Kiralık + taksit — PASS
Loan fee, wage share, parent contract korunumu, auto-return, installments.

### M9 — Taraftar beklentisi + güven — PASS
Sporting / financial / transfer / identity trust ve reason codes.

### M10 — Medya hafızası — PASS
Statements, stance, credibility, contradiction memory.

### M11 — Başkan vaatleri — PASS
Preseason promise üretimi ve fulfilled/partial/broken çözümü.

### M12 — Vaat → taraftar güveni — PASS
Promise sonucu trust katmanına kontrollü etki eder.

### M13 — Vaat → medya güvenilirliği — PASS
Promise sonucu media credibility'ye kontrollü etki eder.

### M14 — Başkanlık seçimi I — PASS
4 sezonda bir deterministik election.

### M15 — Başkan görev süresi + devir — PASS
Reelection/incumbent ve election loss/turnover gerçek president profile üretir.

### M16 — Başkan devrinde kişisel itibar — PASS
Kurumsal trust korunur; kişisel reputation kontrollü nötre yaklaşır.

### M17 — Başkan yönetim profili — PASS
6 archetype + 5 trait.

### M18 — Manager patience → dismissal threshold — PASS
İlk davranış bağlı trait.

### M19 — Manager/world ↔ election fixed-point — PASS
President timeline ile world/election deterministic feedback loop.

### M20 — Financial discipline → transfer affordability — PASS
Trait yalnız budget/affordability alanına bağlandı.

### M21 — Transfer ambition → aktivite — PASS
Trait completed transfer slot sayısını etkiler.

### M22 — Profile Feedback Orchestration I — PASS
Canonical duplicate computation azaltıldı; CI yaklaşık 6+ dakikadan ~3 dakika bandına çekildi.

### M23 — Risk appetite → buyer max-bid ceiling — PASS
Causal invariant: low risk < neutral < high risk max bid.

### M24 — Youth orientation → genç/potansiyel transfer tercihi — PASS
Son davranışsız trait gerçek candidate scoring kararına bağlandı.

Canonical M24 seed `20260903`:

- convergence `4`
- cycle `false`
- elections `240`
- reelected/lost `159/81`
- manager `86`
- transfers `157`
- transfer volume `1.417,94M`
- installment deals `79`
- commitment `261,26M`
- cash `1.217,05M`
- debt `347,57M`
- emergency `144,39M`
- validation `0`

M24 squash merge:

`cfdca8f63dfa6c91fd2432031e0e2c34a8101a06`

### M25 — Save/Load + Kayıt Versiyonlama I — PASS

- `CareerCheckpoint`
- `CareerSimulationResult`
- `simulateWithCheckpoint`
- `resume`
- `CareerSaveCodec`
- save version `1`
- canonical JSON
- FNV-1a checksum
- explicit failures
- v0→v1 migration

Canonical:

- checksum `536de64d`
- save `1039 bytes`
- next season index `8`
- next date `2034-07-01`
- `8 + 12 == 20`

Squash merge:

`c46d5fc99655476f389de82d861ce7a5e6a93aec`

### M26 — World Save Snapshot I — PASS

Core world checkpoint:

- config
- 48 base clubs
- 3×16 next-season league membership
- next-season players
- 48 finance states

Canonical:

- checksum `0645c8a5`
- save `187.664 bytes`
- `8 + 12 == 20`

Squash merge:

`c721588f998f5d29495c8074d956e48e306a1dc8`

### M27 — Advanced World Runtime Snapshot I — PASS
Detayı bu dosyanın 6. bölümündedir.

### M28 — Save History Compaction / Historical Memory Policy I — PASS

- compact advanced checkpoint + codec
- son iki sezon contract/loan detayı
- all-time aggregate history summary
- season-8 save `1.013.092 → 736.274 bytes`
- 8+12 deterministic continuation PASS
- PR #29 squash merge `8fb9846c70b438641521a4023068a5a707d0ea38`
- merge sonrası main run `33998088249` PASS
- artifact `0`

## 9. Başkan trait durumu

Beş trait'in tamamı gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

M25–M28 yeni trait davranışı eklemiyor; save/runtime güvenilirliği üzerinde çalışıyor.

## 10. CI politikası

Workflow ana zinciri:

- `dart analyze`
- `dart test --exclude-tags canonical-feedback`
- M0 100-season batch
- M1–M18 ayrı headless runner
- tek en yeni profile-feedback runner ile nested M19–M24 canonical guards
- M25 save/load runner
- M26 world save runner
- M27 advanced runtime save runner
- M28 save history compaction runner

Current profile runner:

`tool/run_m24_president_youth_orientation_feedback.dart 20260903`

Save runners:

- `tool/run_m25_save_load.dart 20260903`
- `tool/run_m26_world_save.dart 20260903`
- `tool/run_m27_advanced_runtime_save.dart 20260903`
- `tool/run_m28_save_history_compaction.dart 20260903`

Kurallar:

- artifact `0`
- `actions/upload-artifact` yok
- timeout `7 dk`
- duplicate canonical full-career koşuları yok
- save/load resume uninterrupted career ile aynı deterministic sonucu verir
- future save version güvenli reddedilir
- migration fixture test edilir
- checksum-valid structural corruption validator tarafından reddedilir
- checkpoint eklenirken eski public simulation semantiği korunur
- save boyutu ayrıca ölçülür

## 11. Açık teknik borçlar

- M19+ literal single-pass orchestration değil; fixed-point replay.
- President/reputation/election runtime state henüz save kapsamında değil.
- Fan/media/promise runtime memory henüz save kapsamında değil.
- M28 manager season history, M27 strict invariantı nedeniyle halen tam tutulur; 20-sezon compact save `915.648 bytes` olduğundan ileride current manager state/history ayrımı ayrıca optimize edilebilir.
- Android file system / save-slot UI / cloud save daha sonra.
- Autosave/yedek slot politikası henüz platforma bağlanmadı.
- Tesis yatırımının youth intake kalitesine etkisi henüz yok.
- Sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı.
- Seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok.

## 12. Uzun vadeli teknik yön

Save zinciri:

- M25: temel `CareerEngine` checkpoint — PASS
- M26: core `WorldCareerEngine` checkpoint — PASS
- M27: contract/loan/installment/manager runtime checkpoint — PASS
- M28: save history compaction + historical memory policy — PASS
- M29 adayı: president/reputation/election runtime snapshot
- sonraki katman: fan/media/promise memory snapshot
- daha sonra platform save slotları, autosave/yedek policy ve gerekirse cloud save

Uzun vadeli hedef:

> **20–30 sezonluk kariyerin tüm kritik state'iyle deterministic, migration-safe ve makul boyutta kaydedilip devam ettirilebilmesi.**

Sonrasında 100/500/1000 kariyer batch QA genişletilecektir.
