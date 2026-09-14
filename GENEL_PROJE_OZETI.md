# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 14 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu. Mevcut repo saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz bu repoda kurulmamıştır.

> **Oyuncu teknik direktör değil, kulüp başkanıdır.**
> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

Repo: `ZMilaStudio/futbol-baskanlik-simulatoru`
Canonical seed: `20260903`
Dünya: 48 özgün kulüp, 3 lig × 16 kulüp, 720 lig maçı/sezon, 14.400 maç/20 sezon, 864 başlangıç oyuncusu.

Kalıcı kurallar:
- Live GitHub > proje dosyaları > eski sohbetler.
- Deterministic seed/replay korunur; tarih `GameDate`, para integer minor-unit `Money` kullanır.
- Eski public simulation semantiği sessizce değiştirilmez.
- Save/load/resume determinism ve parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job: `test` + `canonical`; her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz.
- `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır ve güncel tutulur.
- Docs→CI→docs sonsuz döngüsü üretilmez.
- Her yeni PR için merge öncesi o PR'ın exact final HEAD'i için açık kullanıcı onayı gerekir.
- Merge exact-head kilidiyle ve squash yöntemiyle yapılır.
- Merge sonrası gerçek `main` executable doğrulaması tamamlanmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M74 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M75 — Player President Interactive Decision Persistence Bundle I.**

PR: **#78** — `M75: add interactive decision persistence bundle`
Branch: `feat/m75-interactive-decision-persistence-bundle`
Base `main`: `8bfdef10789459aa6786f662b5a0ccc346299846`
Pre-doc exact code HEAD: `c052b40e775dd65d9d7f36ccdfe71b89249452ce`
Pre-doc CI run: `34886961074`

M75'in canlı-main gap'i: M74 accepted-answer transcript'i durable yaptı fakat in-progress checkpoint-backed session restore için application katmanı M65 game-state save + M74 transcript + M73 resume parametrelerini ayrı ayrı doğru biçimde eşlemek zorundaydı.

M75 çözümü:
- authoritative M65 game-state save,
- M74 transcript save,
- M73 resume için minimal deterministic runtime config

tek versioned/checksummed outer persistence bundle içinde atomik eşlenir.

Authority değişmez:
- M65 tek persisted game-state authority'dir.
- M74 transcript replay metadata'sıdır.
- M75 yeni game-state schema değildir; existing nested save codec'lerini tek outer envelope altında compose eder.
- Flutter/UI, filesystem/save-slot backend veya cloud save eklenmez.

Pre-doc CI kanıtı:
- `test`: SUCCESS
- analyzer: `No issues found!`
- **339/339 tests PASS**
- 5 M75 acceptance testi PASS
- canonical attempt 1: M0–M75 + exact M75 marker + Post Checkout + Complete job SUCCESS; yalnız strict 7 dakika envelope sonunda conclusion `cancelled`
- aynı exact HEAD'te izin verilen tek canonical retry: M0–M75 + exact M75 marker + Post Checkout + Complete job tekrar SUCCESS; envelope sonunda yine `cancelled`
- runtime/assertion failure yok
- üçüncü retry yok
- artifacts: **0**

Exact M75 marker:
`M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true canonicalRoundTrip=true atomicBundle=true nestedChecksums=true parityM74=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

**Sıradaki adım:** bu merge-ready docs commit'i sonrası oluşan exact final PR HEAD'in tek final CI turunu doğrula. CI kanıtı yeterliyse PR'ı draft'tan çıkar ve kullanıcıdan o exact HEAD için açık merge onayı iste. Onaysız merge yapma.

## 3. M75 — Player President Interactive Decision Persistence Bundle I — PRE-MERGE

### 3.1 Mimari

Ana tipler:
- `PlayerPresidentInteractiveDecisionResumeConfig`
- `PlayerPresidentInteractiveDecisionPersistenceBundle`
- `PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec`

Bundle:
- `PlayerPresidentTicketPricingRuntimeCheckpoint` (M65 authority),
- `PlayerPresidentInteractiveDecisionTranscriptSnapshot` (M74 sidecar),
- `seasonCount`, `hasFutureSeasonAfterReport`, `crisisActivationThreshold`, `candidateLimit` resume config'i taşır.

Outer envelope canonical JSON + version + checksum kullanır. Nested M65 ve M74 save'leri kendi codec/version/checksum doğrulamalarını ayrıca korur. Restore M65 checkpoint'ten M73 session'ı kurar, M74 transcript'i deterministic replay eder ve exact pending request'i yeniden türetir.

### 3.2 Acceptance

1. Canonical bundle round-trip exact nested M65 + M74 save'lerini korur — PASS.
2. Restore exact pending request'e döner ve uninterrupted M74 ile final checkpoint/boundary parity verir — PASS.
3. Başka M65 save ile eşleştirilmiş checksum-valid stale transcript fail-closed olur — PASS.
4. Outer checksum corruption nested restore öncesinde reddedilir — PASS.
5. Valid outer checksum içindeki bozuk nested M65 save nested validation ile reddedilir — PASS.
6. M65 tek persisted game-state authority olarak kalır — PASS.

M75 dosyaları:
- `lib/src/player_president/player_president_interactive_decision_persistence_bundle.dart`
- `lib/player_president_interactive_decision_persistence_bundle.dart`
- `test/m75_player_president_interactive_decision_persistence_bundle_test.dart`
- `tool/run_m75_player_president_interactive_decision_persistence_bundle.dart`
- `M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M75 henüz merge edilmemiştir ve CLOSED değildir.

## 4. Son kapanan milestone: M74 — Player President Interactive Decision Transcript Snapshot I — CLOSED / MERGED / PASS

M74, M73'ün runtime-only accepted-answer transcript'ini application lifecycle boyunca geri yüklenebilir versioned/checksummed replay sidecar haline getirdi. Pending context veya game state sidecar'a yazılmaz; M65 authority değişmez.

Kapanış kanıtı:
- PR #77 — MERGED / CLOSED
- final exact pre-merge PR HEAD: `bc799eb4333ced2419bca752330d98ca2d6380be`
- exact-head squash merge SHA: `6f03d14cfcba345a8f5873fccc2d603329b71e2c`
- post-merge executable main CI `34883829920`: SUCCESS
- analyzer clean
- 334/334 tests PASS
- canonical M0–M74 SUCCESS
- exact M74 marker PASS
- artifacts 0

Exact M74 marker:
`M74_PLAYER_PRESIDENT_INTERACTIVE_DECISION_TRANSCRIPT_SNAPSHOT_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true canonicalRoundTrip=true parityM73=true transcriptOnly=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 5. M73 — Player President Interactive Decision Session I — CLOSED / MERGED / PASS

M73, M72 synchronous gateway'ini gerçek UI/application akışına uygun deterministic replay tabanlı `pending request → later response → continue` session sınırına taşıdı. Partial simulation state pending iken commit edilmez; stale veya invalid response pending request'i tüketmeden reddedilir.

Kapanış:
- PR #76
- final exact PR HEAD `8c890582f5e597bb0d1d2155250b3586ca0c0a40`
- squash merge `a82caf70f832c20e2da2929bcaddd26aad85b618`
- post-merge main CI `34872238972`: SUCCESS
- 329 tests
- M0–M73 PASS
- artifacts 0

Exact marker:
`M73_PLAYER_PRESIDENT_INTERACTIVE_DECISION_SESSION_PASS controlled=t1_01 decisions=9 uniqueKinds=9 pauseReplay=true parityM72=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 6. M72 — Player President Unified Decision Gateway Runtime I — CLOSED / MERGED / PASS

M72 facility, sponsor, crisis, manager review/replacement, promise, media, transfer strategy ve ticket pricing kararlarını tek application-facing `PlayerPresidentDecisionGateway` altında birleştirdi. Domain validation, tenure gate ve diğer 47 kulübün canonical AI yolu korunur.

Kapanış:
- PR #75
- final exact HEAD `3868fa5c1ae3c03146cfc8c32628fde75f5e8a3b`
- squash merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c`
- 324 tests
- M0–M72 PASS
- artifacts 0

Exact marker:
`M72_PLAYER_PRESIDENT_UNIFIED_DECISION_GATEWAY_RUNTIME_PASS controlled=t1_01 singleGateway=true managerCalls=1 gatewayCalls=7 singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

## 7. Yakın milestone geçmişi

- M74 — PR #77 merge `6f03d14cfcba345a8f5873fccc2d603329b71e2c`; 334 tests; M0–M74 PASS; artifacts 0.
- M73 — PR #76 merge `a82caf70f832c20e2da2929bcaddd26aad85b618`; 329 tests; M0–M73 PASS; artifacts 0.
- M72 — PR #75 merge `44aa7f9c830551a4e980b9bd233153feb92d6d2c`; 324 tests; M0–M72 PASS; artifacts 0.
- M71 — PR #74 merge `fc373ee6dde881aa9bc730d0930924e7905725c9`; 321 tests; M0–M71 PASS; artifacts 0.
- M70 — PR #73 merge `b66512f08240f978286d1b6eaa128bd02ef2cfdb`; 315 tests; M0–M70 PASS; artifacts 0.
- M69 — PR #72 merge `bf94f3e411f30c0d4474067650ab18c491b4f997`; 309 tests; M0–M69 PASS; artifacts 0.
- M68 — PR #71 merge `779a0eb4d5c79b80d5afc743b9a53341bf56fcf2`; 303 tests; M0–M68 PASS; artifacts 0.
- M67 — PR #70 merge `9f4f3a3f314de29e770b2031de29c288a7761684`; 298 tests; M0–M67 PASS; artifacts 0.
- M66 — PR #69 merge `7860ef0e03a4326a884595eeef37d0b088b6e14a`; 293 tests; M0–M66 PASS; artifacts 0.
- M65 — PR #68 merge `9e4de0ea84446293155292af39d7e887f6cdab3b`; 288 tests; M0–M65 PASS; artifacts 0.
- M64 — PR #67 merge `4a76d1546fa02675e1c94cd57621a82d70e15a8c`; 283 tests; M0–M64 PASS; artifacts 0.
- M63 — PR #66 merge `72f5387fe416746244eb41cbc6aaaaf179f9442f`; 278 tests; M0–M63 PASS; artifacts 0.
- M62 — PR #65 merge `64aab836ab707fe33c204465348f9bc0bc50a54f`; 273 tests; M0–M62 PASS; artifacts 0.
- M61 — PR #64 merge `0a00895a185e4dc2b8a97485767be888a8bfde85`; 268 tests; M0–M61 PASS; artifacts 0.
- M60 — PR #63 merge `b149e4f9c661ce5f2aa43f16ee4b5cbfc9b79b6d`; 263 tests; M0–M60 PASS; artifacts 0.
- M59 — PR #62 merge `d49424573d7db1c2f02554bffec2e3b13c40b6dd`; 258 tests; M0–M59 PASS; artifacts 0.

## 8. Sistem zinciri ve authority sınırları

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 transfer strategy runtime hook; M54 world bridge; M55 transfer strategy control; M56 promise; M57 media; M58 tenure ownership gate; M59–M64 tenure-gated player controls; M65 ticket pricing → real economy + persisted runtime authority; M66–M71 domain composition; M72 unified gateway; M73 interactive session; M74 transcript snapshot; M75 atomic application persistence bundle.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response + AI ticket pricing
- `transferAmbition`: transfer activity + stadium priority + supporter crisis
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority

Authority zinciri:
- M58 player-president tenure ownership state'ini sağlar.
- M59–M64 tenure-gated domain authority'lerini kurar.
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted **game-state** authority'dir.
- M66–M71 aynı M65 authority üzerinde domain'leri compose eder; yeni persisted authority üretmez.
- M72 application/UI için tek runtime decision gateway sağlar.
- M73 runtime-only deterministic interactive session sağlar.
- M74 yalnız accepted-answer replay metadata sidecar'ını persist eder.
- M75 M65 game-state save + M74 transcript + minimal M73 resume config'i tek checksummed outer envelope içinde atomik eşler; nested authority'leri değiştirmez.

## 9. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; milestone kapanışlarında güncellenir.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, tam iki job, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simulation semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` gap scan yap; eski sohbet kapsamını otomatik kabul etme.
8. Her PR için merge öncesi exact final HEAD'e açık kullanıcı onayı al; squash + exact-head lock kullan; post-merge `main` executable gates doğrulanmadan milestone'u CLOSED sayma.
9. Docs-only merge-ready/kapanış commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf kendi run ID'sini yazmak için yeni docs commit atılmaz.
10. M75 şu an pre-merge'dir. Final exact-head CI doğrulanmadan ve kullanıcı onay vermeden merge etme.
