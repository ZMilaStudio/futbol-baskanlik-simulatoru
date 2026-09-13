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

Aktif PR yok. Aktif milestone yok. **M57 henüz seçilmedi.**

M56 kapanış kanıtı:
- Milestone: **M56 — Player President Promise Decision Override I**
- Branch: `feat/m56-player-president-promise-control`
- PR #59 — **MERGED / CLOSED**
- Base `main`: `6f2386494d56ef2571d36695e6e7a3ab638c863b`
- Final exact PR HEAD: `336d2c5c743d8169ab396199fa1d51c4dd2a4506`
- Final exact-head PR CI `34726631760`: **SUCCESS**
- analyzer: `No issues found!`
- **243 normal/non-canonical test PASS**
- beş M56 acceptance testinin tamamı PASS
- **M0–M56 canonical PASS**
- canonical marker: `M56_PLAYER_PROMISE_CONTROL_PASS controlled=t1_01 aiParity=47 ai=challengeTitle player=finishTopHalf deterministic=true canonicalTargets=true invalidBlocked=true worldClubs=48`
- Final PR artifacts: **0**
- Squash merge SHA: `c61ef1338cc0ab7cfb993827e46bec62524cf308`
- Post-merge `main` CI `34727519839`: **SUCCESS**
- Post-merge `main` artifacts: **0**

İlk M56 CI `34725931380` içinde yalnız save/resume acceptance testi kırmızıydı. Gerçek failure logu okundu; ürün/runtime hatası değil, 2+2 testinin ilk 2 sezonluk parçasının continuation olmasına rağmen `hasFutureSeasonAfterReport: true` verilmemesiydi. M31'in mevcut canonical split-continuation semantiğiyle aynı boundary ayarı uygulanarak yalnız test orkestrasyonu düzeltildi; M56 ürün kodu değiştirilmedi.

Yeni milestone seçmeden önce canlı `main` kodu yeniden taranmalıdır. M57 için eski sohbet tahminleri değil, güncel ürün boşluğu esas alınacaktır.

## 3. Son kapanan milestone: M56 — Player President Promise Decision Override I

M11 vaatleri ölçülebilir ve deterministik yaptı; M12–M16 vaat sonuçlarını taraftar güveni, medya itibarı ve seçim/reputation zincirine bağladı. M11 dokümanında oyuncunun UI üzerinden vaat seçmesi açıkça kapsam dışı bırakılmıştı. M55-closed kodunda controlled club dahil vaat tipi hâlâ `PromiseGenerator` tarafından otomatik seçiliyordu.

M56 çözümü:
- `PlayerPromiseDecisionProvider`, yalnız controlled club için sezon başı resmi vaat türünü seçer.
- `PlayerPromiseDecisionContext`, yalnız preseason `PresidentPromiseContext`, AI'nın mevcut vaadi ve geçerli kanonik seçenekleri taşır; sezon sonu outcome provider'a verilmez.
- `PlayerPresidentPromiseGenerator`, diğer 47 kulüp için M11 AI üretimini birebir korur.
- Provider yoksa controlled club dahil M11 exact parity korunur.
- Oyuncu keyfi hedef/puan/fan/media/election etkisi enjekte edemez; yalnız mevcut `PresidentPromiseType` seçer.
- `finishTopHalf` genel sportif seçenektir.
- `avoidRelegation` yalnız beklenen sıra son dört bölgesindeyse geçerlidir.
- `earnPromotion` yalnız alt lig + beklenen ilk 5 bağlamında geçerlidir.
- `challengeTitle` yalnız birinci lig + beklenen ilk 3 bağlamında geçerlidir.
- `reduceDebt` ve `stabilizeFinances` yalnız M11 `financialStress` bağlamında geçerlidir.
- Kanonik hedefler mevcut M11 semantiğinden türetilir: top-half=lig yarısı, promotion=3, title=1, debt reduction=%8/%12.
- Seçilen vaat mevcut `PromiseResolver`, fan impact, media impact ve election/reputation zincirinden geçer.
- `PlayerPresidentPromiseDomainCareerEngine`, aynı player provider seam'ini initial president-domain ve resume yoluna opt-in bağlar.
- Provider serialize edilmez; save alanı/migration eklenmez.

M56 acceptance:
1. provider yokken M11 exact promise generation parity — PASS
2. yalnız controlled club değişir; diğer 47 AI promise exact parity — PASS
3. canonical target korunur ve context-invalid vaat reddedilir — PASS
4. seçilen vaat gerçek fan/media reputation zincirine akar — PASS
5. runtime-only provider ile save/load/resume determinism korunur — PASS

M56 dosyaları:
- `lib/src/promise/player_president_promise_control.dart`
- `lib/player_president_promise_control.dart`
- `test/m56_player_president_promise_control_test.dart`
- `tool/run_m56_player_president_promise_control.dart`
- `M56_PLAYER_PRESIDENT_PROMISE_DECISION_OVERRIDE_I.md`
- `.github/workflows/m0-tests.yml`
- `GENEL_PROJE_OZETI.md`

M56 **CLOSED / MERGED / PASS**.

## 4. Önceki milestone: M55 — Player President Transfer Strategy Decision Override I

- PR #58 — MERGED / CLOSED
- Final PR HEAD: `8f96cbfa5a482d378635822c3eca1fb51185c226`
- Merge SHA: `f4034bf35e11d52dc97d2d5a39abaed6672bbc7c`
- Final exact-head PR CI `34724489311`: SUCCESS
- Post-merge `main` CI `34724755590`: SUCCESS
- closure docs commit `6f2386494d56ef2571d36695e6e7a3ab638c863b`
- closure docs-only CI `34725059438`: SUCCESS
- analyzer clean; **238 tests PASS**; **M0–M55 canonical PASS**; artifacts **0**
- canonical marker: `M55_PLAYER_TRANSFER_STRATEGY_CONTROL_PASS controlled=t1_01 aiParity=47 ai=ready_forward player=young_forward deterministic=true identityPreserved=true worldClubs=48`

M55, gerçek M54 transfer penceresinde yalnız controlled club için transfer stratejisinin dört başkanlık eksenini oyuncuya açtı. Diğer 47 kulüp AI profile davranışını korur; başkan kimliği/archetype/manager patience değişmez; explicit policy bypass, determinism ve M54 parity korunur.

## 5. Yakın milestone geçmişi

- M54 Transfer Strategy World Runtime Bridge I — PR #57 merge `837198d3480be5571d4eeae1934c72454f47dec1`; 233 tests; M0–M54 PASS; artifact 0.
- M53 President Transfer Strategy Runtime Hook I — PR #56 merge `f83e159793f80d7f53c40a0845e795339e400d3c`; 228 tests; M0–M53 PASS; artifact 0.
- M52 Player President Manager Decision Override I — PR #55 merge `bce9efe6c214526b0018110c5a10d2fa9e7ec5c8`; 223 tests; M0–M52 PASS; artifact 0.
- M51 Player President Crisis Decision Override I — PR #54 merge `4b2832f3bfb091ae3adaeb504a7369b1190b2438`; 218 tests; M0–M51 PASS; artifact 0.
- M50 Player President Sponsor Decision Override I — PR #53 merge `f8519d4f0be247f7029a2e29d4de10588d97736f`; 213 tests; M0–M50 PASS; artifact 0.
- M49 Player President Facility Decision Override I — PR #52 merge `c0c40bada13e3dd83c06cded64ead38dc2f30d8`; 208 tests; M0–M49 PASS; artifact 0.

## 6. Sistem zinciri

M0–M18 temel sezon/kariyer/oyuncu/ekonomi/transfer/world/manager/contract/fan/media/vaat/seçim/başkanlık; M19–M24 başkan trait feedback; M25–M32 save/runtime/history; M33–M39 facility/academy/portfolio; M40 stadium; M41 fan trust→attendance; M42 sponsor; M43 crisis; M44–M48 runtime composition; M49–M52 player-president facility/sponsor/crisis/manager controls; M53 president transfer strategy runtime hook; M54 transfer strategy world runtime bridge; M55 player-president transfer strategy control; M56 player-president promise control.

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
- M56 kontrollü kulübün resmi sezon vaadini M11'in geçerli kanonik seçenekleri arasından oyuncu başkana açar; sonuç mevcut fan/media/election zincirine akar.

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
