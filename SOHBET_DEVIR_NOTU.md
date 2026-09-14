# Futbol Başkanlık Simülatörü — SOHBET DEVİR NOTU

Son güncelleme: 14 Eylül 2026

Bu dosyanın amacı yeni bir ChatGPT sohbeti açıldığında **nerede kaldığımızı, hangi kanıtların doğrulandığını ve sıradaki adımın ne olduğunu** hızlıca devretmektir. Ayrıntılı proje tarihi ve milestone zinciri için `GENEL_PROJE_OZETI.md` okunmalıdır.

## 1. Zorunlu başlangıç sırası

Yeni sohbet şu sırayla başlamalıdır:

1. Canlı GitHub `main` HEAD'ini doğrula.
2. `GENEL_PROJE_OZETI.md` dosyasını oku.
3. Bu `SOHBET_DEVIR_NOTU.md` dosyasını oku.
4. Branch / PR / workflow / job / artifact durumunu gerektiğinde canlı GitHub'dan yeniden doğrula.
5. Canlı GitHub ile bu dosyalar çelişirse **canlı GitHub kazanır**.
6. Yeni milestone kapsamını eski sohbetten otomatik devralma; önce canlı `main` üzerinde fresh gap scan yap.

## 2. Devredilen canlı durum

Bu devir notu oluşturulmadan hemen önce doğrulanan `main` HEAD:

`f7ae064e63d1ef05bff841f54ed25253dd9b024c`

Commit:
`docs(m75): close interactive persistence bundle milestone`

Durum:
- **M0–M75 CLOSED / MERGED / PASS**
- **Aktif milestone yok**
- **M76 seçilmedi / başlatılmadı**
- Açık bir milestone PR'ı devredilmiyor

Bu devir dosyası ve ardından proje özeti güncellemesi docs commit'leri oluşturacağı için yeni sohbet işe başlarken burada yazan HEAD'e körü körüne güvenmemeli; canlı `main` tekrar okunmalıdır.

## 3. Son kapanan milestone — M75

**M75 — Player President Interactive Decision Persistence Bundle I**

Amaç:
M65 authoritative game-state save + M74 accepted-answer transcript + M73 resume için gereken minimal deterministic config'i tek versioned/checksummed application persistence envelope içinde atomik olarak eşlemek.

Authority sınırı değişmedi:
- M65 `PlayerPresidentTicketPricingRuntimeCheckpoint` + `PlayerPresidentTicketPricingRuntimeSaveCodec` tek persisted **game-state authority** olmaya devam eder.
- M74 transcript yalnız deterministic replay metadata'sıdır.
- M75 yeni game-state schema değildir.
- Flutter/UI, filesystem save-slot backend ve cloud save M75 kapsamında eklenmedi.

M75 ana dosyaları:
- `lib/src/player_president/player_president_interactive_decision_persistence_bundle.dart`
- `lib/player_president_interactive_decision_persistence_bundle.dart`
- `test/m75_player_president_interactive_decision_persistence_bundle_test.dart`
- `tool/run_m75_player_president_interactive_decision_persistence_bundle.dart`
- `M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_I.md`

## 4. M75 merge ve CI kanıtı

PR:
- **#78 — MERGED / CLOSED**
- branch: `feat/m75-interactive-decision-persistence-bundle`
- final exact pre-merge HEAD: `6c71902ba8c8cd3398aac3e40828fb4093cdd436`
- kullanıcı bu exact HEAD için açık merge onayı verdi
- squash merge SHA: `c88d65f6c06769fa2298d92bc791f76a0ebf5bed`

Final exact-head PR CI:
- run `34888876382`
- analyzer clean
- 339/339 tests PASS
- 5 M75 acceptance testi PASS
- canonical executable M0–M75 SUCCESS
- exact M75 marker PASS
- Post Checkout + Complete job SUCCESS
- artifacts 0
- canonical dış etiketi yalnız strict 7 dakika envelope sonunda `cancelled`; assertion/runtime failure yok

Post-merge gerçek `main` executable CI:
- run `34890260125`
- test job SUCCESS
- analyzer `No issues found!`
- 339 tests PASS
- 5 M75 acceptance testi PASS
- canonical executable M0–M75 SUCCESS
- M72, M73, M74 ve M75 exact marker'ları PASS
- Post Checkout + Complete job SUCCESS
- artifacts 0
- canonical dış etiketi yalnız strict 7 dakika envelope sonunda `cancelled`; tüm executable gates önceden SUCCESS

M75 exact marker:
`M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_PASS controlled=t1_01 savedDecisions=4 pendingRestore=true canonicalRoundTrip=true atomicBundle=true nestedChecksums=true parityM74=true singleCheckpoint=true saveAuthority=M65 worldClubs=48 seed=20260903`

M75 closure docs commit:
- `f7ae064e63d1ef05bff841f54ed25253dd9b024c`

Closure docs CI:
- run `34891239476`
- test job SUCCESS
- analyzer SUCCESS
- canonical M0–M75 + Post Checkout + Complete job SUCCESS
- outer workflow/canonical conclusion strict 7 dakika timeout envelope nedeniyle `cancelled`
- runtime/assertion failure yok
- artifacts 0
- bu docs CI için retry veya yeni bir docs→CI→docs döngüsü açılmadı

## 5. Kalıcı çalışma kuralları

- **Live GitHub > proje dosyaları > eski sohbetler.**
- Determinism / replay / parity korunur.
- PASS yalnız canlı CI kanıtıyla yazılır.
- CI tam iki paralel job: `test` + `canonical`.
- Her job strict `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızıysa gerçek job logu okunmadan patch atılmaz.
- Merge öncesi PR'ın **exact final HEAD'i için kullanıcıdan açık onay** alınır.
- Merge squash + exact-head lock ile yapılır.
- Post-merge gerçek `main` executable doğrulaması bitmeden milestone CLOSED değildir.
- Docs→CI→docs sonsuz döngüsü yapılmaz.
- M65 tek persisted game-state authority'dir; yeni iş bunu bilmeden yeni authority üretmemelidir.
- Mevcut repo saf Dart deterministic simulation core'dur; Flutter/UI katmanı henüz kurulmamıştır.

## 6. Sıradaki iş

Şu anda yarım kalmış kod işi yoktur.

Yeni sohbette kullanıcı **“devam et”** dediğinde:

1. canlı `main` ve en son CI durumunu doğrula,
2. `GENEL_PROJE_OZETI.md` + bu devir notunu oku,
3. repo mimarisi üzerinde fresh gap scan yap,
4. oyunu gerçek ürüne yaklaştıran en küçük, test edilebilir ve deterministic sıradaki açığı seç,
5. ancak bundan sonra M76 veya başka bir milestone öner / başlat.

**M76 kapsamı önceden belirlenmiş değildir.**

## 7. Kullanıcı çalışma biçimi

Kullanıcı GitHub işinin gerçekten yapılmasını bekler; yalnız açıklama yeterli değildir. Kısa ara durum güncellemeleri verilebilir. Merge onayı exact HEAD'e özeldir. Kullanıcı “Onaylıyorum” demeden ilgili exact HEAD merge edilmez.
