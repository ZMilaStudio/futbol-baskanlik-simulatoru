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

**M0–M83 CLOSED / MERGED / PASS.**

**Aktif milestone yok. M84 preselect edilmedi.**

Son kapanan milestone:
**M83 — Player President Interactive Decision Mixed File Save Slot Catalog I**

PR:
**#86 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`1e69bfa0afab205fce80aec5282d158cf13bac34`

Squash merge SHA:
`a71d9d83ae0f043f7e2d2e7f90e98840439bd53f`

Post-merge executable workflow run:
`35075992189` — run #521 — event `push`

Post-merge exact merge SHA üzerinde M83 tam kanıtla kapandı.

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

## 5. M83 kapanış kanıtı

Final PRE-MERGE exact SHA:
`1e69bfa0afab205fce80aec5282d158cf13bac34`

Final PRE-MERGE run:
`35074707295` — run #520

Final PRE-MERGE gate:
- analyzer `No issues found!`,
- **382/382 tests PASS**,
- **5/5 M83 acceptance PASS**,
- canonical **M0–M83 SUCCESS**,
- exact M83 marker PASS,
- artifacts **0**.

User exact SHA onayından sonra PR #86 squash merge edildi.

Squash merge SHA:
`a71d9d83ae0f043f7e2d2e7f90e98840439bd53f`

Post-merge run:
`35075992189` — run #521 — event `push`

Başarılı post-merge test job:
`104746735582`

Başarılı post-merge canonical job:
`104746734713`

Post-merge evidence:
- analyzer `No issues found!`,
- **382/382 tests PASS**,
- **5/5 M83 acceptance PASS**,
- **M0–M83 SUCCESS**,
- M83 step SUCCESS,
- exact M83 marker PASS,
- Post Checkout + Complete job SUCCESS,
- artifacts **0**.

Exact post-merge marker:
`M83_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_CATALOG_PASS controlled=t1_01 summaries=3 collisionPreserved=true deterministicOrder=true readOnly=true metadataExact=true worldGuard=true namespacesSeparate=true saveAuthority=M65 checkpointCatalog=M78 bootstrapCatalog=M82 worldClubs=48 seed=20260903`

Timing notu:
- önceki post-merge canonical attempt'leri strict 7 dakika nedeniyle hedef M83 çalışmadan timing-only cancelled oldu,
- PASS sayılmadılar,
- source/docs değiştirilmeden exact merge SHA üzerinde retry edildi,
- başarılı attempt M0–M83 tam yürüdü.

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

**Aktif milestone yok. M84 preselect edilmedi.**

Sıradaki adımlar:
1. Closure docs commit sonrası canlı `main` HEAD'ini doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; sonucu yazmak için yeni docs commit oluşturma.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman yeni milestone kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
