# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 17 Eylül 2026

## 1. Proje kimliği

ZMila Studio için geliştirilen futbol kulübü başkanlığı simülasyonu.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`

Repo hâlâ saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

Canonical dünya:
- seed `20260903`
- 48 özgün kulüp
- 3 lig × 16 kulüp
- 720 lig maçı / sezon
- 864 başlangıç oyuncusu

Kalıcı mimari ve çalışma kararları için `PROJE_KARARLARI.md` okunmalıdır.

## 2. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Deterministic seed / replay / save-resume parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek step/log okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan timeout olursa aynı exact SHA retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın exact final HEAD'i için açık kullanıcı onayı gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Closure docs executable kanıttan sonra tek atomik commit ile güncellenir.
- Closure-docs CI gözlemseldir; parent merge SHA tam executable kanıta sahipse timing-only docs CI timeout yeni docs döngüsü yaratmaz.
- Aktif milestone varsa başka milestone seçilmez.

## 3. CANLI DURUM — buradan devam et

**M0–M86 CLOSED / MERGED / PASS.**

**Aktif milestone yok. M87 preselect edilmedi.**

Son kapanan milestone:
**M86 — Player President Interactive Decision Mixed File Save Slot Deleter I**

PR:
**#89 — MERGED**

Final kullanıcı-onaylı PR HEAD:
`cb319f7fc37251792ed2e7b0b74a92b2d376800b`

Squash merge SHA / M86 executable code SHA:
`70f096a38e76894b909b334833409c4507a8fe4f`

Pre-merge final workflow:
`35125161506` — run #533 — event `pull_request`

Final pre-merge gate:
- test job `104922552313` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `104922550855` — SUCCESS,
- canonical M0–M86 — SUCCESS,
- exact M86 marker — PASS,
- artifacts — 0.

Post-merge actual-main workflow:
`35150547145` — run #534 — event `push` — exact merge SHA `70f096a38e76894b909b334833409c4507a8fe4f`

Post-merge executable kanıt:
- run attempt `3`,
- test job `104982654233` — SUCCESS,
- Analyze — SUCCESS,
- normal tests — SUCCESS,
- canonical job `104982652224`,
- checkout exact merge SHA — doğrulandı,
- M0–M86 tüm milestone step'leri — SUCCESS,
- M86 step — SUCCESS,
- exact M86 marker — PASS,
- Post Checkout + Complete job — SUCCESS,
- artifacts — 0.

Run-level conclusion strict 7 dakikalık sınır nedeniyle `cancelled` olarak kaydedildi; ancak timeout M86 çalışıp PASS marker'ını bastıktan sonra geldi. Hedef milestone ve tüm M0–M86 executable step'leri başarıyla tamamlandığı için actual-main executable gate tamamlanmıştır.

## 4. M86 neden seçildi?

M85 kapandıktan sonra fresh live-main gap scan yapıldı.

M83 mixed typed catalog, M84 source-aware loader ve M85 source-aware writer ile iki fiziksel save namespace'i application yüzeyinde okunup yüklenip yazılabiliyordu. Her iki child store'da delete capability zaten vardı; ancak M83 typed source identity'yi kullanıp doğru child store'a delete route eden mixed dispatcher eksikti.

En küçük authority-safe boşluk bu source-aware delete dispatcher oldu.

## 5. M86 çözümü

Yeni deleter:
`PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter`

Temel davranış:
- checkpoint source → mevcut M77 checkpoint store `delete`,
- new-game bootstrap source → mevcut M81 bootstrap store `delete`,
- M83 typed summary doğrudan `deleteSummary` ile route edilebilir,
- aynı raw slot ID sibling namespace'te korunur,
- missing source `false` döndürür ve sibling namespace'e dokunmaz,
- target/temp/backup cleanup ve invalid-slot validation child store'lara delege edilir,
- yeni save schema, migration, metadata cache/sidecar veya persisted authority oluşturmaz.

Authority sınırı:
- **M65 tek persisted game-state authority.**
- M74 replay metadata.
- M75 checkpoint bundle.
- M77 checkpoint store.
- M78 checkpoint catalog.
- M80 bootstrap snapshot.
- M81 bootstrap store.
- M82 bootstrap catalog.
- M83 mixed typed read-only catalog.
- M84 source-aware loader.
- M85 source-aware writer.
- M86 source-aware deleter.

## 6. M86 acceptance

1. Checkpoint/bootstrap delete doğru child store'a route edilir — PASS.
2. Same-id sibling namespace source-specific delete sırasında korunur — PASS.
3. M83 summary identity deletion'ı exact source'a route eder — PASS.
4. Missing source `false` döndürür ve sibling mutation oluşturmaz — PASS.
5. Child cleanup ve invalid-slot davranışı unchanged delege edilir / fail-closed kalır — PASS.

Exact canonical M86 marker:
`M86_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_DELETER_PASS controlled=t1_01 checkpointDeleted=true bootstrapDeleted=true collisionPreserved=true summaryRouted=true namespaceIsolation=true missingFalse=true cleanupDelegated=true invalidBlocked=true saveAuthority=M65 catalog=M83 loader=M84 writer=M85 checkpointStore=M77 bootstrapStore=M81 worldClubs=48 seed=20260903`

## 7. M86 kanıt zinciri

Final PRE-MERGE kullanıcı-onaylı PR HEAD:
`cb319f7fc37251792ed2e7b0b74a92b2d376800b`

Final PRE-MERGE workflow:
`35125161506` — run #533

Başarılı PRE-MERGE işler:
- test job `104922552313` — SUCCESS,
- canonical job `104922550855` — SUCCESS,
- exact final HEAD üzerinde M0–M86 SUCCESS,
- M86 marker PASS,
- artifacts 0.

PR #89 kullanıcı exact-HEAD onayından sonra squash merge edildi.

Squash merge SHA:
`70f096a38e76894b909b334833409c4507a8fe4f`

Post-merge actual-main run:
`35150547145` — run #534 — event `push`

İlk post-merge canonical attempt M76 sonrası, ikinci attempt M75 sonrası strict 7 dakika nedeniyle timing-only cancelled oldu. Loglar incelendi; fonksiyonel hata görülmedi ve kod/workflow patch'i yapılmadı.

Üçüncü attempt'te exact merge SHA checkout edildi ve M0–M86'nin tamamı çalıştı. M86 marker PASS olduktan sonra run-level timeout/cancel kaydı oluştu; milestone step'lerinin tamamı SUCCESS kaldı.

Böylece M86 için merge öncesi exact-HEAD gate + merge sonrası exact-main executable gate tamamlandı.

## 8. Yakın milestone zinciri

- M86 — Mixed File Save Slot Deleter — PR #89 — merge `70f096a38e76894b909b334833409c4507a8fe4f` — **CLOSED / MERGED / PASS**.
- M85 — Mixed File Save Slot Writer — PR #88 — merge `7191fb734291420a077f5954fbdf4028763bc5c8` — CLOSED / MERGED / PASS.
- M84 — Mixed File Save Slot Loader — PR #87 — merge `232efbbb60d52340f056504b8a25f34cbc3d52c7` — CLOSED / MERGED / PASS.
- M83 — Mixed File Save Slot Catalog — PR #86 — merge `a71d9d83ae0f043f7e2d2e7f90e98840439bd53f` — CLOSED / MERGED / PASS.
- M82 ve öncesi — CLOSED / MERGED / PASS.

## 9. Sistem mimarisi — kısa harita

- M0–M18: temel sezon/kariyer/world/başkanlık sistemleri.
- M19–M24: başkan trait feedback.
- M25–M32: save/load ve runtime snapshots.
- M33–M48: facility/academy/stadium/sponsor/crisis runtime.
- M49–M65: player-president kontrolleri + tenure gate; **M65 persisted state authority**.
- M66–M71: tüm player-president domain composition.
- M72: tek application decision gateway.
- M73: pending request → response → continue interactive runtime.
- M74: accepted-answer transcript replay metadata.
- M75: M65 + M74 + resume config atomik checkpoint persistence bundle.
- M76: application-session lifecycle.
- M77/M78: checkpoint file-slot store + catalog.
- M79/M80/M81/M82: new-game bootstrap session/snapshot/store/catalog.
- M83: mixed typed read-only catalog.
- M84: source-aware loader.
- M85: source-aware writer.
- M86: source-aware deleter.

## 10. Sıradaki kesin iş

**Aktif milestone yok. M87 preselect edilmedi.**

Sıradaki adımlar:
1. Final M86 closure docs commit'inin canlı `main` HEAD olduğunu doğrula.
2. Closure-docs push CI oluşursa yalnız gözlemle; parent M86 merge SHA üzerinde executable kanıt tamamlandığı için timing-only docs CI timeout yeni docs döngüsü başlatmaz.
3. Yeni geliştirme öncesinde fresh live-`main` gap scan yap.
4. En küçük doğal authority-safe boşluğu seç; ancak o zaman M87 kapsamını kilitle.

M65 tek persisted game-state authority olarak korunacaktır.
