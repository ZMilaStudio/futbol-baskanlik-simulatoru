# Futbol Başkanlık Simülatörü — GENEL PROJE ÖZETİ

Son güncelleme: 13 Eylül 2026

## 1. Proje kimliği ve kalıcı ilkeler

ZMila Studio için geliştirilen Android futbol kulübü başkanlığı simülasyonu.

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
- CI iki paralel job: `test` + `canonical`; her job `timeout-minutes: 7`.
- Artifact hedefi `0`.
- CI kırmızıysa gerçek failure logu okunmadan patch atılmaz.
- `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır ve güncel tutulur.
- Docs→CI→docs sonsuz döngüsü üretilmez.
- Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı gerekir.
- Merge sonrası `main` CI yeşil olmadan milestone CLOSED sayılmaz.

`DEVRALMA_1_AYLIK_GPT.md` canlı `main` üzerinde bulunmamaktadır; çalışma kuralları için canlı GitHub + bu özet esas alınır.

## 2. CANLI DURUM — buradan devam et

**M0–M56 CLOSED / MERGED / PASS ve `main` üzerindedir.**

**Aktif milestone: M57 — Player President Media Statement Decision Override I.**

- Branch: `feat/m57-player-president-media-statement-control`
- PR #60 — **OPEN / NOT MERGED / ACTIVE**
- Base `main`: `6f4d05a785ee6cab509e625f0bddb9c50143baf9`
- M57 code + 5 acceptance tests + canonical runner + CI step hazırlandı.
- Canlı PR CI henüz doğrulanmadı; PASS yazılmayacaktır.
- Merge için kullanıcıdan henüz onay istenmemelidir.

M57 seçim gerekçesi: M10 başkan açıklamalarını ve medya hafızasını gerçek state etkisine bağlamıştı; ancak controlled club dahil statement stance hâlâ `MediaStatementEngine` tarafından tamamen otomatik seçiliyordu. M10 dokümanı basın toplantısı/UI katmanını kapsam dışı bırakmıştı. Bu nedenle M57, mevcut gerçek M10 event'inde başkanın tavrını oyuncuya açan dar ürün boşluğunu kapatır.

## 3. M57 kapsamı — Player President Media Statement Decision Override I

M57 çözümü:
- `PlayerMediaStatementDecisionProvider` yalnız controlled club için çalışır.
- Önce mevcut M10 `MediaStatementEngine` normal deterministic AI statement event'ini üretir.
- AI statement `null` ise provider çağrılmaz; oyuncu basın olayı yaratamaz veya event sıklığını değiştiremez.
- Gerçek event varsa oyuncu yalnız mevcut `MediaStance` değerlerinden birini seçer: `strongSupport`, `measuredSupport`, `pressure`, `noComment`.
- `id`, `clubId`, `targetManagerId`, `seasonIndex` ve `topic` AI statement'tan aynen korunur.
- Oyuncu credibility delta enjekte edemez; mevcut `MediaCredibilityEngine` seçilen stance ve gerçek manager kararı üzerinden sonucu çözer.
- Diğer 47 kulüp exact M10 AI davranışını korur.
- Provider yoksa controlled club dahil M10 exact parity korunur.
- `PlayerPresidentMediaStatementDomainCareerEngine`, aynı seam'i president-domain initial + resume yollarına opt-in bağlar.
- Provider serialize edilmez; save alanı/migration eklenmez.

M57 acceptance:
1. provider yokken M10 media generation exact parity
2. yalnız controlled club stance değişir; diğer 47 kulüp exact AI parity
3. AI event yoksa provider çağrılmaz ve oyuncu event yaratamaz
4. seçilen stance gerçek M10 credibility resolution'a akar; statement metadata korunur
5. runtime-only provider ile save/load/resume determinism (`2+2 == 4`)

M57 dosyaları:
- `lib/src/media/player_president_media_statement_control.dart`
- `lib/player_president_media_statement_control.dart`
- `test/m57_player_president_media_statement_control_test.dart`
- `tool/run_m57_player_president_media_statement_control.dart`
- `M57_PLAYER_PRESIDENT_MEDIA_STATEMENT_DECISION_OVERRIDE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M57 **ACTIVE / NOT MERGED**. Canlı CI sonucu gelmeden merge-ready sayılmaz.

## 4. Son kapanan milestone: M56 — Player President Promise Decision Override I

- Branch: `feat/m56-player-president-promise-control`
- PR #59 — MERGED / CLOSED
- Final exact PR HEAD: `336d2c5c743d8169ab396199fa1d51c4dd2a4506`
- Final exact-head PR CI `34726631760`: SUCCESS
- analyzer clean; **243 tests PASS**; **M0–M56 canonical PASS**; artifacts **0**
- canonical marker: `M56_PLAYER_PROMISE_CONTROL_PASS controlled=t1_01 aiParity=47 ai=challengeTitle player=finishTopHalf deterministic=true canonicalTargets=true invalidBlocked=true worldClubs=48`
- Squash merge SHA: `c61ef1338cc0ab7cfb993827e46bec62524cf308`
- Post-merge `main` CI `34727519839`: SUCCESS; artifacts **0**
- closure docs commit: `6f4d05a785ee6cab509e625f0bddb9c50143baf9`
- closure docs-only CI `34727862233`: SUCCESS; artifacts **0**

M56, controlled club'ın resmi sezon vaadini M11'in bağlama uygun kanonik seçenekleri arasından oyuncu başkana açtı. Diğer 47 kulüp AI kaldı; hedefler/effects kanonik motorlarda kaldı; save/resume determinism korundu.

M56 **CLOSED / MERGED / PASS**.

## 5. Yakın milestone geçmişi

- M55 Player President Transfer Strategy Decision Override I — PR #58 merge `f4034bf35e11d52dc97d2d5a39abaed6672bbc7c`; 238 tests; M0–M55 PASS; artifact 0.
- M54 Transfer Strategy World Runtime Bridge I — PR #57 merge `837198d3480be5571d4eeae1934c72454f47dec1`; 233 tests; M0–M54 PASS; artifact 0.
- M53 President Transfer Strategy Runtime Hook I — PR #56 merge `f83e159793f80d7f53c40a0845e795339e400d3c`; 228 tests; M0–M53 PASS; artifact 0.
- M52 Player President Manager Decision Override I — PR #55 merge `bce9efe6c214526b0018110c5a10d2fa9e7ec5c8`; 223 tests; M0–M52 PASS; artifact 0.
- M51 Player President Crisis Decision Override I — PR #54 merge `4b2832f3bfb091ae3adaeb504a7369b1190b2438`; 218 tests; M0–M51 PASS; artifact 0.
- M50 Player President Sponsor Decision Override I — PR #53 merge `f8519d4f0be247f7029a2e29d4de10588d97736f`; 213 tests; M0–M50 PASS; artifact 0.
- M49 Player President Facility Decision Override I — PR #52 merge `c0c40bada13e3dd83c06cded64ead38dc2f30d8`; 208 tests; M0–M49 PASS; artifact 0.

## 6. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control; M57 player-president media statement control.

Başkan/state gerçek etkileri:
- `managerPatience`: manager dismissal + training priority + crisis response
- `financialDiscipline`: transfer affordability + facility reserve + sponsor preference + crisis response
- `transferAmbition`: transfer activity + stadium priority + supporter-crisis response
- `riskAppetite`: bid ceiling + stadium priority + sponsor preference + crisis response
- `youthOrientation`: youth transfer preference + academy/training priority
- M49–M52 controlled club oyuncu başkan facility/sponsor/crisis/manager kararlarıdır; diğer kulüpler AI kalır.
- M53 transfer trait'lerini gerçek transfer-market API'sinde birleştirir.
- M54 M53 stratejisini gerçek world transfer window'a opt-in pre-window bridge ile taşır.
- M55 aynı real transfer seam'inde yalnız controlled club için dört transfer stratejisi eksenini oyuncu başkana açar.
- M56 controlled club resmi sezon vaadini kanonik M11 seçeneklerinden oyuncu başkana açar.
- M57 controlled club için yalnız gerçek M10 statement event'indeki medya stance kararını oyuncu başkana açar; event ve credibility hesabı kanonik kalır.

## 7. Devir / çalışma talimatı

1. Her işlemden önce canlı GitHub durumunu doğrula.
2. `GENEL_PROJE_OZETI.md` kalıcı handoff dosyasıdır; silinmez.
3. Branch/commit/PR/workflow/job/log/artifact durumunu GitHub'dan doğrula.
4. CI kırmızıysa gerçek logdan kök neden bul; tahminle patch atma.
5. `timeout-minutes: 7`, artifacts `0`, determinism ve parity kurallarını koru.
6. Eski public simülasyon semantiğini sessizce değiştirme.
7. Yeni milestone seçmeden önce canlı `main` kodunu ve bu özeti incele; kapsamı gerçek ürün boşluğundan türet.
8. Her yeni PR için merge öncesi o PR'a özel açık kullanıcı onayı al; merge sonrası `main` CI yeşil olmadan milestone'u CLOSED sayma.
9. Docs-only kapanış/refresh commit'i CI tetikliyorsa bu CI bir kez doğrulanır; sırf run ID'yi özete yazmak için yeni docs commit atılmaz.
