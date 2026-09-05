# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 5 Eylül 2026

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

**M0–M27 PASS ve `main` üzerindedir.**

Aktif milestone:

> **M28 — Save History Compaction / Historical Memory Policy I**

Aktif branch:

`m28-save-history-compaction`

Açık PR:

`#29`

M28 ilk implementasyon HEAD / ilk başarısız CI commit'i:

`3759dcd0e2297335b5c1cbb8d5e95911e7a17c15`

İlk M28 CI:

`33944814109`

Job:

`101248881732`

Sonuç:

- analyzer PASS
- normal `dart test` FAIL
- test aşamasında durduğu için M0–M28 runner zinciri skip oldu
- PR merge edilmedi
- `main` bozulmadı; M0–M27 güvenli PASS durumunda
- başarısızlıktan sonra tahmine dayalı kod düzeltmesi veya merge yapılmadı

Yeni sohbette ilk iş:

1. PR #29 / branch HEAD canlı durumunu doğrula.
2. GitHub Actions job `101248881732` için **gerçek job logunu** al.
3. Başarısız test/assertion satırını kesin çıkar.
4. Yalnız gerçek nedene yönelik minimal düzeltme yap.
5. Analyzer + normal tests + M0–M27 regresyon + M28 runner tam PASS olmadan merge etme.
6. Artifact `0`, timeout `5 dk` politikasını koru.

Ayrıntılı sohbet devri:

`SOHBET_DEVRI_2026-09-05_M28.md`

## 4. Son kapalı milestone — M27

### M27 — Advanced World Runtime Snapshot I — PASS

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

## 5. Neden M28 gerekli

M26 sezon-8 core world save:

`187.664 bytes`

M27 sezon-8 advanced save:

`1.013.092 bytes`

Yaklaşık `5,4×` büyüme vardır.

Ana büyüme kaynakları:

- `3496` append-only contract event
- `186` loan history kaydı
- manager season/change history

Runtime analizi şu ayrımı doğruladı:

### Continuation-critical

- current active contracts
- current active loans
- installment obligations
- current manager pool
- 48 current manager assignment
- world/player/finance/league current state

### Historical / reporting ağırlıklı

- eski contract event kayıtları
- inactive eski loan history
- eski manager season/change history

Geçmiş contract events, inactive loan history ve eski manager seasons sonraki sezon kararlarında doğrudan okunmuyor. Bu nedenle compaction adayıdırlar.

Ancak kullanıcıya gösterilecek kariyer tarihçesi sessizce silinmemelidir; yakın dönem ham detail + eski dönem kontrollü summary/archive sözleşmesi gerekir.

## 6. M28 branch'te bulunan ilk tasarım

Eklenen parçalar:

- `AdvancedHistorySummary`
- `CompactAdvancedRuntimeCheckpoint`
- `AdvancedRuntimeHistoryCompactor`
- `CompactAdvancedRuntimeCareerEngine`
- `CompactAdvancedWorldSaveCodec`
- `test/m28_save_history_compaction_test.dart`
- `tool/run_m28_save_history_compaction.dart`
- workflow'a M28 runner adımı

İlk policy denemesi:

- son `2` sezon ham history detail tutulur
- bütün kariyer için aggregate summary tutulur
- active state eksiksiz tutulur

Summary örnekleri:

- total contract event count
- contract event type dağılımı
- total loan count
- total loan fee
- manager season count
- manager change count
- manager change reason dağılımı

### Kritik olası regresyon noktası

M28 branch'te `ManagerRuntimeState.validate(...)` full-history sözleşmesini gevşetecek şekilde değiştirildi:

- M27'de manager history completed seasons ile tam örtüşüyordu.
- M28 denemesinde kısa retained history'ye izin veriliyor.

Bu compact checkpoint için mantıklı olabilir; ancak **M27 genel `AdvancedRuntimeCheckpoint` invariantını küresel olarak gevşetmek doğru olmayabilir**.

Tercih edilen mimari yön:

- M27 full-history checkpoint invariantını koru.
- Compact checkpoint'in validation sözleşmesini ayrı katmanda tut.
- Compact continuation için current-state restore yolunu full-history gereksiniminden ayır.

Fakat gerçek CI failure satırı görülmeden bunun kesin hata olduğu kabul edilmemeli.

## 7. M28 kabul kriterleri

M28 PASS sayılmak için:

- continuation-critical state açık sınıflandırılmış olmalı
- history için compact/archive policy tanımlanmalı
- compact save → load → resume M27 full-history future simulation ile aynı deterministic sonucu vermeli
- aktif contract/loan/installment/manager state kaybolmamalı
- yakın dönem kullanıcı tarihçesi korunmalı
- eski dönem için kontrollü summary/archive sözleşmesi bulunmalı
- 20 sezon canonical save boyutu ölçülmeli
- save-size guard eklenmeli
- save version/migration/checksum güvenliği korunmalı
- M0–M27 baseline değişmemeli
- analyzer PASS
- normal tests PASS
- M0–M28 runners PASS
- artifact `0`
- timeout `5 dk` altında

M28 kapsamı değildir:

- Android file picker
- cloud save
- save-slot UI
- encryption / anti-cheat

## 8. Teknik mimari ve kalıcı kurallar

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

## 9. Milestone geçmişi — özet

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

Canonical eski kabul:

- final active contracts `874`
- renewals `3757`
- releases `1143`
- free signings `776`
- annual wage bill `491,27M`

### M8 — Kiralık + taksit — PASS

Loan fee, wage share, parent contract korunumu, auto-return, installments.

Canonical eski kabul:

- permanent transfer `140`
- installment deal `68`
- loan `478`
- final active loan `32`
- installment commitment `234,79M`

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

6 archetype + 5 trait:

- `financialDiscipline`
- `riskAppetite`
- `transferAmbition`
- `youthOrientation`
- `managerPatience`

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

Canonical seed `20260903`:

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

Temel `CareerEngine` season-boundary checkpoint.

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

Detayı bu dosyanın 4. bölümündedir.

## 10. Başkan trait durumu

Beş trait'in tamamı gerçek davranışa bağlıdır:

| Trait | Gerçek etki | Milestone |
|---|---|---|
| `managerPatience` | manager dismissal threshold | M18 |
| `financialDiscipline` | transfer affordability/budget | M20 |
| `transferAmbition` | completed transfer slots | M21 |
| `riskAppetite` | buyer max-bid ceiling | M23 |
| `youthOrientation` | youth/potential candidate preference | M24 |

M25–M28 yeni trait davranışı eklemiyor; save/runtime güvenilirliği üzerinde çalışıyor.

## 11. CI politikası

Workflow ana zinciri:

- `dart analyze`
- `dart test --exclude-tags canonical-feedback`
- M0 100-season batch
- M1–M18 ayrı headless runner
- tek en yeni profile-feedback runner ile nested M19–M24 canonical guards
- M25 save/load runner
- M26 world save runner
- M27 advanced runtime save runner
- M28 branch'te save history compaction runner

Current profile runner:

`tool/run_m24_president_youth_orientation_feedback.dart 20260903`

Save runners:

- `tool/run_m25_save_load.dart 20260903`
- `tool/run_m26_world_save.dart 20260903`
- `tool/run_m27_advanced_runtime_save.dart 20260903`
- M28 branch: `tool/run_m28_save_history_compaction.dart 20260903`

Kurallar:

- artifact `0`
- `actions/upload-artifact` yok
- timeout `5 dk`
- duplicate canonical full-career koşuları yok
- save/load resume uninterrupted career ile aynı deterministic sonucu verir
- future save version güvenli reddedilir
- migration fixture test edilir
- checksum-valid structural corruption validator tarafından reddedilir
- checkpoint eklenirken eski public simulation semantiği korunur
- save boyutu ayrıca ölçülür

## 12. Reddedilen / ertelenen fikirler

- 3D maç motoru — ilk sürüm dışında
- online multiplayer — ilk sürüm dışında
- gerçek kulüp/futbolcu/lisanslı varlık — kullanılmayacak
- FM seviyesinde taktik/antrenman — başkanlık kimliğine aykırı
- aşırı kiralık/taksit pazarı — reddedildi
- dar fan trust bandı — reddedildi
- aşırı medya açıklaması sıklığı — reddedildi
- beş trait'i aynı milestone'da bağlamak — causal izlenebilirlik için reddedildi
- aggregate world sonucunu tek trait causal yönü gibi yorumlamak — yasak
- checksum'u encryption/anti-cheat gibi sunmak — reddedildi
- tüm runtime state'i tek save milestone'ına zorla yığmak — reddedildi
- eski `WorldCareerEngine.simulate()` davranışını checkpoint uğruna değiştirmek — reddedildi
- M27'de president/fan/media/promise history'yi de eklemek — save büyümesi nedeniyle ertelendi
- M27 `1 MB+` save boyutunu görmezden gelip history eklemeye devam etmek — reddedildi

## 13. Açık teknik borçlar

- M19+ literal single-pass orchestration değil; fixed-point replay.
- President/reputation/election runtime state henüz save kapsamında değil.
- Fan/media/promise runtime memory henüz save kapsamında değil.
- M28 compaction policy henüz PASS değil.
- Android file system / save-slot UI / cloud save daha sonra.
- Autosave/yedek slot politikası henüz platforma bağlanmadı.
- Tesis yatırımının youth intake kalitesine etkisi henüz yok.
- Sponsor/tesis/kriz sistemleri henüz çekirdek milestone olarak uygulanmadı.
- Seçim kaybında game-over / başka kulübe geçiş UX'i henüz yok.

## 14. Uzun vadeli teknik yön

Save zinciri:

- M25: temel `CareerEngine` checkpoint — PASS
- M26: core `WorldCareerEngine` checkpoint — PASS
- M27: contract/loan/installment/manager runtime checkpoint — PASS
- M28: save history compaction + historical memory policy — **aktif / PR #29 başarısız ilk CI sonrası düzeltme bekliyor**
- M29 adayı: president/reputation/election runtime snapshot
- sonraki katman: fan/media/promise memory snapshot
- daha sonra platform save slotları, autosave/yedek policy ve gerekirse cloud save

Uzun vadeli hedef:

> **20–30 sezonluk kariyerin tüm kritik state'iyle deterministic, migration-safe ve makul boyutta kaydedilip devam ettirilebilmesi.**

Sonrasında 100/500/1000 kariyer batch QA genişletilecektir.
