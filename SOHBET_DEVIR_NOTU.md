# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 15 Eylül 2026

Bu dosyanın amacı yeni bir ChatGPT sohbeti açıldığında **nerede kaldığımızı, hangi kanıtların doğrulandığını ve sıradaki adımın ne olduğunu** hızlıca devretmektir. Ayrıntılı proje tarihi ve milestone zinciri için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

Yeni sohbet şu sırayla başlamalıdır:

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` dosyasını oku.
3. Bu `SOHBET_DEVIR_NOTU.md` dosyasını oku.
4. Branch / PR / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Canlı GitHub ile bu dosyalar çelişirse **canlı GitHub kazanır**.
6. Aktif milestone/PR varsa yeni milestone seçmeden onu tamamla.

## 2. Devredilen canlı durum

M77 başlanmadan önce doğrulanan canlı `main` HEAD:

`3e38c7eb918f11bb42eb473be66cc12376758d5a`

Commit:
`docs(m76): close interactive application session milestone`

Durum:
- **M0–M76 CLOSED / MERGED / PASS**
- **M77 ACTIVE / PRE-MERGE**
- branch: `feat/m77-interactive-decision-file-save-slot-store`
- PR: **#80 — OPEN / DRAFT**
- M77 henüz `main` üzerinde değildir

Bu dosya PR branch'i içinde güncellendiği için burada yazan branch HEAD'e körü körüne güvenme; PR #80 canlı head SHA'sını yeniden oku.

## 3. Aktif milestone — M77

**M77 — Player President Interactive Decision File Save Slot Store I**

Fresh live-main gap scan sonucu:
M76 application session exact M75 persistence bundle'ını encoded `String` olarak save/restore edebiliyor; ancak pure Dart repoda concrete file-backed save-slot/storage owner bulunmuyordu. Repo taramasında mevcut `dart:io` save backend'i de bulunmadı.

M77 çözümü:
`PlayerPresidentInteractiveDecisionFileSaveSlotStore`

Application storage surface:
- `save(slotId, session)`
- `load(slotId)`
- `contains(slotId)`
- `delete(slotId)`
- `listSlotIds()`

Store davranışı:
- slot ID yalnız `[A-Za-z0-9_-]`, uzunluk 1–64,
- path traversal / slash / backslash / whitespace reddedilir,
- exact M75 bundle bytes `<slot>.fbs.json` olarak yazılır,
- overwrite temp + backup replacement ile yapılır,
- interrupted replacement target yoksa backup'tan recovery edilir,
- corrupt bundle M75 checksum/validation zinciri üzerinden fail-closed reddedilir,
- slot listesi deterministic alfabetik sıradadır.

Authority değişmedi:
- M65 tek persisted **game-state authority**,
- M74 accepted-answer deterministic replay metadata,
- M75 atomik application persistence bundle/save format,
- M76 interactive application-session lifecycle owner,
- M77 yalnız local filesystem materialization/storage adapter.

Flutter state/provider, Android platform channel, database, cloud sync veya yeni game-state serialization authority eklenmedi.

M77 ana dosyaları:
- `lib/src/player_president/player_president_interactive_decision_file_save_slot_store.dart`
- `lib/player_president_interactive_decision_file_save_slot_store.dart`
- `test/m77_player_president_interactive_decision_file_save_slot_store_test.dart`
- `tool/run_m77_player_president_interactive_decision_file_save_slot_store.dart`
- `M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_I.md`
- `.github/workflows/m0-tests.yml`

## 4. Şu ana kadar doğrulanan M77 CI kanıtı

İlk exact code/workflow HEAD:
`e217f7bcb937e8bd83bad3cda8d6c80c4460d4fb`

Workflow run:
`34898142811`

`test` job `104157272601`:
- **SUCCESS**
- analyzer: `No issues found!`
- **350/350 tests PASS**
- M77'ye ait 6 acceptance testi PASS
- Post Checkout + Complete job SUCCESS

`canonical` job `104157272375`:
- M0–M77 executable adımlarının tamamı **SUCCESS**
- exact M77 marker PASS
- Post Checkout + Complete job SUCCESS

Artifacts:
- **0**

Bu run ilk executable source/test/canonical kanıtıdır. Ardından M77 milestone dokümanı + proje özeti + bu devir notu eklendi/güncellendi. Bu nedenle **docs dahil final exact-head CI henüz bu notta PASS olarak yazılmamıştır** ve canlı GitHub'dan yeniden doğrulanmalıdır.

Beklenen exact M77 marker:
`M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true interruptedRecovery=true invalidBlocked=true stableSave=true atomicBundle=M75 saveAuthority=M65 worldClubs=48 seed=20260903`

## 5. M77 acceptance

1. File slot yeni store instance'ından exact pending request ve exact M75 bytes ile restore edilir.
2. Overwrite yalnız en yeni exact M75 bundle'ı authoritative target olarak bırakır.
3. Path traversal / invalid slot ID fail-closed reddedilir.
4. Interrupted replacement committed backup'tan recovery edilir.
5. Corrupt target M75 validation üzerinden fail-closed reddedilir.
6. Slot listesi deterministic sıralıdır ve delete slot state'ini kaldırır.
7. M65/M75/M76 authority sınırı korunur.

İlk executable CI'da bu acceptance yüzeylerinin tamamı PASS'tir; merge için docs dahil **final exact HEAD** tekrar doğrulanacaktır.

## 6. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Determinism / replay / parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job logu okunmadan patch atılmaz.
- Merge öncesi PR'ın **exact final HEAD'i için kullanıcıdan açık onay** alınır.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- M65 tek persisted game-state authority'dir.
- M75 atomik application save formatıdır; M77 bu formatın yerine geçmez.
- Mevcut repo saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

## 7. Sıradaki kesin iş

M78 seçme. PR #80'u tamamla.

Sıra:
1. canlı PR #80 head SHA'yı doğrula,
2. docs dahil final exact-head `test` job: analyzer + **350 test** SUCCESS olmalı,
3. final exact-head `canonical`: M0–M77 executable adımları SUCCESS olmalı,
4. exact M77 marker PASS okunmalı,
5. Post Checkout / Complete job ve artifacts=0 doğrulanmalı,
6. strict 7 dakika nedeniyle outer canonical cancelled olursa gerçek log okunmalı; M77 + cleanup önceden SUCCESS ise timeout-only kabul edilebilir,
7. PR mergeable durumu doğrulanmalı,
8. draft'tan ready durumuna geçirilmeli,
9. ready sonrası exact final HEAD tekrar kilitlenmeli,
10. kullanıcıdan **exact final HEAD SHA için açık merge onayı** istenmeli,
11. onay gelmeden merge edilmemeli,
12. onay sonrası squash merge + `expected_head_sha`,
13. post-merge gerçek `main` executable CI doğrulanmadan M77 CLOSED yazılmamalı.

## 8. Kullanıcı çalışma biçimi

Kullanıcı GitHub işinin gerçekten yapılmasını bekler; yalnız açıklama yeterli değildir. Kısa ara durum güncellemeleri verilebilir. Merge onayı exact HEAD'e özeldir. Kullanıcı “Onaylıyorum” demeden ilgili exact HEAD merge edilmez.
