# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 15 Eylül 2026

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

## 2. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Deterministic seed / replay / save-resume parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI iki paralel job içerir: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızı/cancelled ise gerçek job step/logu okunmadan patch atılmaz.
- Canonical hedef milestone'a ulaşmadan timeout olursa aynı exact SHA retry edilir; sırf timing için kod değiştirilmez.
- Merge öncesi PR'ın **exact final HEAD'i için açık kullanıcı onayı** gerekir.
- Merge squash + `expected_head_sha` lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Closure docs executable kanıttan sonra tek atomik commit ile güncellenir.
- Closure-docs CI gözlemseldir; parent merge SHA tam executable kanıta sahipse timing-only timeout yeni docs döngüsü yaratmaz.
- Aktif milestone varsa başka milestone seçilmez.

## 3. CANLI DURUM — buradan devam et

**M0–M81 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone yoktur.**

**M82 henüz seçilmemiştir.**

Son kapanan milestone:
**M81 — Player President Interactive Decision New-Game Bootstrap File Save Slot Store I**

PR:
**#84 — MERGED**

M81 final approved PR HEAD:
`fb343a41cba6f79fb8b64c8590b8d4a57f8af3f5`

M81 squash merge SHA:
`76566493c7f5999487b53db4794088a75bbe6a7b`

Post-merge gerçek `main` workflow run:
`34986135432`

Post-merge canonical başarılı retry job:
`104441763719`

Bu kapanış doküman commit'i `main` HEAD'ini yukarıdaki merge SHA'dan sonra ilerletir. Yeni sohbette güncel HEAD canlı GitHub'dan yeniden okunmalıdır.

## 4. M81 neden seçildi?

M80 pre-checkpoint new-game ilerlemesini versioned/checksummed replay-only bootstrap + M74 transcript olarak encode edebiliyordu. M77 ise yalnız M75 checkpoint bundle için disk slotu sağlıyordu. Böylece pre-checkpoint bootstrap bytes için dayanıklı yerel dosya persistence katmanı eksik kalıyordu.

En küçük authority-safe çözüm, M77'yi dual-format hale getirmek yerine ayrı bootstrap file adapter eklemekti.

## 5. M81 çözümü

Yeni adapter:
`PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore`

Davranış:
- exact M80 bootstrap envelope bytes saklar,
- ayrı `.fbs.bootstrap.json` namespace kullanır,
- M77 `.fbs.json` checkpoint slotlarını değiştirmez,
- atomic temp → target replacement + committed backup recovery uygular,
- invalid/path-traversal slot ID'lerini fail-closed reddeder,
- checkpoint-backed application session'ı disk mutation öncesi reddeder,
- load sırasında M80 checksum/format validation + world fingerprint guard çalışır,
- `listSlotIds`, `contains`, `delete` yalnız bootstrap namespace'ini görür.

Authority sınırı değişmedi:
- **M65 tek persisted game-state authority.**
- M74 accepted-answer replay metadata.
- M75 checkpoint-backed atomik application bundle.
- M77 M75-only checkpoint file-slot store.
- M78 M75-backed read-only checkpoint catalog.
- M80 pre-checkpoint replay-only bootstrap snapshot.
- M81 yalnız exact M80 bytes file adapter; ikinci game-state authority değildir.

M81 non-scope:
- M77 formatını dual-format yapmak,
- M78 catalog'a bootstrap metadata eklemek,
- checkpoint + bootstrap slotlarını tek load-game catalog altında birleştirmek,
- timestamp/nondeterministic metadata,
- database/cloud/Flutter/provider state.

## 6. M81 acceptance

1. Fresh store exact pending request + stable M80 bytes restore eder — **PASS**.
2. Overwrite yalnız latest M80 bootstrap'ı bırakır — **PASS**.
3. Invalid slot ID + checkpoint-backed session write fail-closed ve disk mutation yok — **PASS**.
4. Interrupted replacement committed backup'tan recover edilir — **PASS**.
5. Corrupted bytes + divergent supplied world fail-closed — **PASS**.
6. Bootstrap list/delete/contains M77 checkpoint namespace'inden izoledir — **PASS**.

## 7. M81 final PRE-MERGE kanıtı

Final approved exact HEAD:
`fb343a41cba6f79fb8b64c8590b8d4a57f8af3f5`

Final PR run:
`34976042057`

- analyzer `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- canonical aynı exact SHA üzerinde timing retry sonrası **M0–M81 SUCCESS**
- exact M81 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts **0**
- PR Ready, `mergeable=true`
- kullanıcı exact HEAD için açık merge onayı verdi

## 8. M81 POST-MERGE gerçek main kanıtı

Squash merge SHA:
`76566493c7f5999487b53db4794088a75bbe6a7b`

Push workflow run:
`34986135432`

Test job:
- analyzer: `No issues found!`
- **372/372 tests PASS**
- **6/6 M81 acceptance PASS**
- Post Checkout + Complete job SUCCESS
- job SUCCESS

Canonical ilk deneme:
- M0–M77 SUCCESS
- M78 strict 7 dakikalık outer envelope sırasında cancelled
- M79–M81 skipped
- fonksiyonel hata değildi; M81 çalışmadığı için kapanış kanıtı sayılmadı

Canonical aynı merge SHA retry:
- job `104441763719`
- **M0–M81 tüm executable adımlar SUCCESS**
- M81 step SUCCESS
- exact M81 marker PASS
- Post Checkout + Complete job SUCCESS

Artifacts:
- **0**

Exact marker:
`M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_PASS controlled=t1_01 savedDecisions=4 diskRoundTrip=true stableSave=true interruptedRecovery=true invalidBlocked=true worldGuard=true m77Isolated=true saveAuthority=M65 replayMetadata=M74 bootstrap=M80 worldClubs=48 seed=20260903`

Sonuç:
**M81 CLOSED / MERGED / PASS.**

## 9. Yakın milestone zinciri

- M81 — Bootstrap File Save Slot Store — PR #84 — merge `76566493c7f5999487b53db4794088a75bbe6a7b` — 372 tests.
- M80 — New-Game Bootstrap Snapshot — PR #83 — merge `44dbc898de57307050f4f26525886af32c999b51` — 366 tests.
- M79 — Application New-Game Session — PR #82 — merge `1f75d9e7e363d17e429af77a7aa28c21a04e06ae` — 360 tests.
- M78 — File Save Slot Catalog — PR #81 — merge `cb9334341e42a8dacf629f4aa25f123b8a6f7160` — 355 tests.
- M77 — File Save Slot Store — PR #80 — merge `be1f8d382d84be01a502a4849ebd43528d97a7b0` — 350 tests.
- M76 ve öncesi — CLOSED / MERGED / PASS.

## 10. Sistem mimarisi — kısa harita

- M0–M18: temel sezon/kariyer/world/başkanlık sistemleri.
- M19–M24: başkan trait feedback.
- M25–M32: save/load ve runtime snapshots.
- M33–M48: facility/academy/stadium/sponsor/crisis runtime.
- M49–M65: player-president kontrolleri + tenure gate; M65 persisted state authority.
- M66–M71: tüm player-president domain composition.
- M72: tek application decision gateway.
- M73: pending request → response → continue interactive runtime.
- M74: accepted-answer transcript replay metadata.
- M75: M65 + M74 + resume config atomik checkpoint persistence bundle.
- M76: checkpoint-backed application-session lifecycle.
- M77: exact M75 bytes local checkpoint file-slot store.
- M78: authoritative M75-backed checkpoint load-game catalog.
- M79: application-owned deterministic season-0 new-game session.
- M80: pre-checkpoint bootstrap + M74 transcript replay snapshot.
- M81: exact M80 bootstrap bytes için ayrı atomic local file-slot store.

## 11. Sıradaki kesin iş

Aktif milestone yoktur. Sonraki `Devam et` çağrısında:
1. canlı `main` HEAD yeniden doğrulanır,
2. açık PR/branch/workflow/artifact durumu kontrol edilir,
3. fresh live-main gap scan yapılır,
4. ancak bu scan sonucunda en küçük güvenli sonraki milestone seçilir.

**M82 önceden tanımlı değildir. Fresh gap scan yapılmadan kapsam seçme veya kod yazma.**
