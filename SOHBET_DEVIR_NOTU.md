# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 16 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı tarih için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. Bu dosyayı oku.
4. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
5. Çelişkide **canlı GitHub kazanır**.
6. Aktif milestone varsa onu bitir; yoksa fresh live-main gap scan yap.

## 2. Devredilen durum

**M0–M82 CLOSED / MERGED / PASS.**

**M83 ACTIVE / PRE-MERGE.**

Aktif milestone:
**M83 — Player President Interactive Decision Mixed File Save Slot Catalog I**

PR:
**#86 — OPEN / DRAFT / PRE-MERGE**

Branch:
`feat/m83-mixed-file-save-slot-catalog`

Executable evidence SHA:
`9474bfc179d724c3001112babe93b564ffdf66e0`

Executable workflow run:
`35016802229` — run #519

Bu PRE-MERGE docs commit’i branch HEAD'ini değiştirecektir; bundan sonraki merge gate yalnız yeni docs-included exact HEAD için geçerli olacaktır.

## 3. M83 çözümü

Yeni catalog:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog`

Yeni source enum:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSource`

Yeni summary:
`PlayerPresidentInteractiveDecisionMixedSaveSlotSummary`

Davranış:
- M78 checkpoint catalog ile M82 bootstrap catalogu read-only composition olarak birleştirir,
- physical storage namespace'lerini birleştirmez,
- source açıkça `checkpoint` / `newGameBootstrap` olarak taşınır,
- aynı raw slot ID iki namespace'te varsa iki entry de korunur,
- stable identity `source:slotId`,
- deterministic sıra slot ID ve source rank kullanır,
- source-specific exact summary korunur,
- checksum/decode/replay/world guard child cataloglara delege edilir,
- metadata sidecar veya save mutation oluşturulmaz.

Authority değişmedi:
- **M65 tek persisted game-state authority**,
- M74 replay metadata,
- M75 checkpoint-backed bundle,
- M77 checkpoint file store,
- M78 checkpoint catalog,
- M80 replay-only bootstrap snapshot,
- M81 bootstrap file store,
- M82 bootstrap catalog,
- M83 yalnız mixed read-only projection.

## 4. M83 acceptance

1. Her iki child catalog boşken empty mixed result — PASS.
2. Checkpoint + bootstrap deterministic mixed order — PASS.
3. Same raw slot ID collision iki typed identity ile korunur — PASS.
4. Corrupt checkpoint fail-closed — PASS.
5. Divergent bootstrap world fail-closed + mixed catalog read-only/no extra files — PASS.

## 5. M83 PRE-MERGE executable kanıtı

Executable exact SHA:
`9474bfc179d724c3001112babe93b564ffdf66e0`

Workflow run:
`35016802229` — run #519 — event `pull_request`

Test job:
`104721007080`

- analyzer `No issues found!`
- **382/382 tests PASS**
- **5/5 M83 acceptance PASS**
- Post Checkout + Complete job SUCCESS

Canonical:
- hedef M83 çalışmadan timing-only timeout olan attempt'ler PASS sayılmadı,
- source/docs patch'i atmadan aynı exact SHA üzerinde retry edildi,
- başarılı canonical job `104721005168`,
- **M0–M83 SUCCESS**,
- M83 step SUCCESS,
- exact M83 marker PASS,
- Post Checkout + Complete job SUCCESS.

Artifacts:
- run `35016802229` → **0**

Exact marker:
`M83_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_CATALOG_PASS total=2 checkpoint=1 bootstrap=1 collision=2 deterministic=true readOnly=true saveAuthority=M65`

## 6. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki job: `test` + `canonical`.
- Her job strict 7 dakika.
- Artifacts hedefi 0.
- Timeout'ta gerçek step/log okunur.
- Hedef milestone çalışmadan timeout olan canonical run kapanış kanıtı değildir; aynı exact SHA retry edilir.
- Sırf timeout için kod patch'i atılmaz.
- Merge öncesi final exact HEAD kullanıcıya açıkça onaylatılır.
- Merge squash + `expected_head_sha` lock.
- Post-merge gerçek `main` CI bitmeden CLOSED yazılmaz.
- Closure docs tek atomik commit; docs→CI→docs döngüsü yapılmaz.
- Aktif milestone varken başka milestone seçilmez.

## 7. Sıradaki kesin iş

**M83 ACTIVE / PRE-MERGE. Başka milestone seçme.**

Sıradaki adımlar:
1. PRE-MERGE docs commit sonrası PR #86 yeni HEAD'ini canlı doğrula.
2. Yeni exact HEAD için analyzer + **382/382 tests** + **5/5 M83 acceptance** doğrula.
3. Canonical **M0–M83** + exact marker + cleanup doğrula; timing-only timeout olursa aynı exact SHA canonical retry.
4. Artifacts `0` doğrula.
5. PR #86'yı Ready for review yap.
6. Ready sonrası HEAD'in değişmediğini ve `mergeable=true` olduğunu yeniden doğrula.
7. **Yalnız final exact SHA için kullanıcıdan açık squash-merge onayı iste.**
8. Onay olmadan merge etme.
