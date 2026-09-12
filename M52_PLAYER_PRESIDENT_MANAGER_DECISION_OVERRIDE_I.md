# M52 — Player President Manager Decision Override I

## Amaç

M51 ile tesis, sponsor ve kriz kararları oyuncu başkana açılmıştı. M52, başkanlığın en temel kararlarından biri olan teknik direktör sezon-sonu değerlendirmesini oyuncuya açar.

Oyuncu yalnız `controlledClubId` için:

- teknik direktörle devam etme veya değişime gitme kararını verir,
- değişim gerekiyorsa gerçek manager pool içinden sunulan deterministic adaylardan birini seçer.

Diğer kulüpler oyuncu kontrolü almaz ve mevcut AI manager sistemiyle devam eder.

## Sınırlar ve güvenlik kuralları

- Manager provider yoksa M51 exact path korunur.
- Karar yalnız tamamlanmış sezon ile sonraki sezon arasındaki boundary'de uygulanır.
- Son rapordan sonra gelecek sezon yoksa manager kararı istenmez.
- Emeklilik zorunlu ayrılıktır; oyuncu emekli olacak teknik direktörü tutamaz.
- Oyuncu keyfi manager nesnesi veya özellik enjekte edemez.
- Replacement yalnız gerçek manager pool içindeki, başka kulübe atanmış olmayan, emeklilik yaşına ulaşmamış deterministic adaylardan seçilebilir.
- Aday listesi mevcut M6 manager fit/reputation/coaching seçim skorunu kullanır ve bounded (`candidateLimit`, varsayılan 5) tutulur.
- Oyuncunun seçtiği teknik direktör gerçek `ManagerRuntimeState.assignments` state'ine yazılır ve sonraki gerçek sezonda manager impact yoluna girer.
- Manager history ve compact history summary, controlled-club override ile tutarlı güncellenir.
- Provider serialize edilmez; seçim sonucu mevcut nested manager checkpoint/save state'i üzerinden persist eder.
- `controlledClubId` M49→M50→M51 nested checkpoint zincirinde korunmaya devam eder.
- Facility + sponsor + crisis player-control zinciri aynı runtime içinde korunur.

## Karar modeli

### Review

`PlayerManagerReviewContext` oyuncuya şunları verir:

- sezon ve kulüp,
- current president kimliği,
- current manager,
- sezon performansı / beklenen ve gerçek sıra,
- board relationship,
- AI'nin retain/replace kararı,
- AI change reason ve AI next manager,
- retain seçiminin hukuken/runtime açısından mümkün olup olmadığı,
- zorunlu retirement bilgisi.

Oyuncu `retain` veya `replace` seçer. Retirement durumunda review provider çağrılmaz ve `replace` zorunludur.

### Replacement

`replace` seçildiğinde oyuncuya bounded deterministic candidate listesi verilir. Her aday gerçek manager nesnesi, fit skoru ve canonical selection score içerir. Oyuncu yalnız sunulan manager ID'lerinden birini seçebilir.

## Acceptance

1. Manager provider yokken M51 checkpoint/source exact parity korunur.
2. Controlled club replacement override gerçek assignment'ı değiştirir; aynı boundary'de diğer 47 kulüp AI assignment'ları korunur.
3. Seçilen manager sonraki gerçek sezonda controlled club'ı çalıştırır.
4. Uygun ve emekli olmayan bir manager için oyuncu AI dismissal kararını `retain` ile geri çevirebilir.
5. Facility + sponsor + crisis + manager deterministic provider zincirinde save round-trip ve `2+2 == uninterrupted 4` final checkpoint / boundary / manager / crisis / sponsor decision parity korunur.

## Canonical

Canonical seed: `20260903`.

Canonical gate: `tool/run_m52_player_president_manager_control.dart`.

CI koşusu yeşil olmadan M52 PASS sayılmaz. PR merge edilmeden önce PR'a özel açık kullanıcı onayı gerekir; merge sonrası `main` CI yeşil olmadan M52 CLOSED sayılmaz.
