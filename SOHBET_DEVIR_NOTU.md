# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 17 Eylül 2026

Bu dosya yeni sohbette nerede kaldığımızı ve sıradaki kesin adımı taşır. Ayrıntılı durum için `GENEL_PROJE_OZETI.md`, kalıcı kararlar için `PROJE_KARARLARI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` oku.
3. `PROJE_KARARLARI.md` oku.
4. Bu dosyayı oku.
5. Açık PR / branch / workflow / job / artifact durumunu canlı GitHub'dan yeniden doğrula.
6. Çelişkide **canlı GitHub kazanır**.
7. Aktif milestone varsa onu bitir; yoksa fresh live-main gap scan yap.

## 2. Devredilen durum

**M0–M87 CLOSED / MERGED / PASS.**

**Aktif milestone yok. M88 preselect edilmedi.**

Son kapanan milestone:
**M87 — Player President Interactive Decision Mixed File Save Slot Service I**

PR:
**#90 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`064e19d3397f3e03c086fbab272ea628cf8905bf`

Squash merge SHA / executable code SHA:
`290de87297af115301b1e9d6d3ff0c0b5980087c`

## 3. M87 çözümü

Yeni unified façade:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotService`

Davranış:
- `list` / `inspect` → M83 mixed typed catalog,
- `load` / `loadSummary` → M84 source-aware loader,
- `save` → M85 session-origin-aware writer,
- `delete` / `deleteSummary` → M86 source-aware deleter,
- root factory gerçek checkpoint/bootstrap child store zincirini tek application-facing composition root üzerinden kurar,
- same raw slot ID iki namespace'te ayrı typed identity olarak korunur,
- child exact-bytes / validation / cleanup / recovery semantics'i yeniden uygulanmaz,
- yeni save schema, migration, metadata cache/sidecar, namespace merge veya persisted authority yaratılmaz.

Authority zinciri:
- **M65 tek persisted game-state authority**,
- M74 replay metadata,
- M75 checkpoint bundle,
- M77 checkpoint store,
- M78 checkpoint catalog,
- M80 bootstrap snapshot,
- M81 bootstrap store,
- M82 bootstrap catalog,
- M83 mixed read-only catalog,
- M84 source-aware loader,
- M85 source-aware writer,
- M86 source-aware deleter,
- M87 unified application-facing façade.

M87 yalnız route/delegate eder; M65 authority rolünü devralmaz.

## 4. M87 acceptance

1. Tek façade üzerinden list + inspect — PASS.
2. Save + load doğru child namespace/store zincirine delege edilir — PASS.
3. Summary tabanlı routing exact typed source identity'yi korur — PASS.
4. Same-id namespace collision typed identity olarak korunur — PASS.
5. Source-specific delete sibling namespace'i korur — PASS.
6. Root factory gerçek child store zincirini kurar — PASS.
7. Invalid slot child validation contract'larında fail-closed kalır — PASS.
8. M65 tek persisted game-state authority olarak kalır — PASS.

Exact marker:
`M87_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_SERVICE_PASS controlled=t1_01 unifiedFacade=true listInspect=true saveLoad=true summaryRouting=true collisionPreserved=true deleteIsolation=true rootFactory=true invalidBlocked=true saveAuthority=M65 catalog=M83 loader=M84 writer=M85 deleter=M86 checkpointStore=M77 bootstrapStore=M81 worldClubs=48 seed=20260903`

## 5. M87 kapanış kanıtı

Final PRE-MERGE run:
`35162467750` — run #537 — event `pull_request`

Final PRE-MERGE işler:
- test job `105183751608` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `105183750488` — SUCCESS,
- M0–M87 tüm canonical step'ler — SUCCESS,
- M87 marker — PASS,
- artifacts — 0.

Kullanıcı exact final HEAD `064e19d3397f3e03c086fbab272ea628cf8905bf` için açık merge onayı verdi ve PR #90 squash merge edildi.

Post-merge actual-main run:
`35217065854` — run #538 — event `push`

Run exact head SHA:
`290de87297af115301b1e9d6d3ff0c0b5980087c`

İlk post-merge canonical attempt'lerde strict 7 dakika nedeniyle farklı tail noktalarında timing-only cancellation görüldü. Her seferinde gerçek step/log incelendi; fonksiyonel hata olmadığı doğrulandı ve kod/workflow patch'i yapılmadan aynı exact SHA retry edildi.

Final executable attempt:
- run attempt `10`,
- test job `105265777969` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `105265775729` — SUCCESS,
- exact merge SHA checkout — doğrulandı,
- M0–M87 milestone step'leri — SUCCESS,
- M87 step — SUCCESS,
- exact M87 marker — PASS,
- Post Checkout + Complete job — SUCCESS,
- artifacts — 0,
- run-level conclusion — SUCCESS.

Bu nedenle M87 actual-main executable gate tamamlandı ve milestone **CLOSED / MERGED / PASS** oldu.

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
- Post-merge exact-main executable CI bitmeden CLOSED yazılmaz.
- Closure docs executable kanıttan sonra güncellenir.
- Closure-docs push CI gözlemseldir; parent code SHA tam executable kanıta sahipse timing-only docs CI timeout yeni docs döngüsü yaratmaz.
- Aktif milestone varken başka milestone seçilmez.

## 7. Sıradaki kesin iş

**Aktif milestone yok. M88 preselect edilmedi.**

Sıradaki adımlar:
1. M87 closure docs commit'lerinin canlı `main` HEAD zincirinde olduğunu doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; sonucu yazmak için yeni docs commit oluşturma.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç.
5. Ancak fresh gap scan sonrası M88 kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
