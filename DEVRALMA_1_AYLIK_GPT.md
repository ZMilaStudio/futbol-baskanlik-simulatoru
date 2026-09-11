# FUTBOL BAŞKANLIK SİMÜLATÖRÜ — 1 AYLIK GEÇİCİ DEVİR DOSYASI

**Amaç:** Bu projeyi yaklaşık 1 ay boyunca devralacak ChatGPT oturumunun, önceki çalışmaları yarım yamalak anlamadan, canlı GitHub durumunu esas alarak güvenli biçimde devam etmesini sağlamak.

> **OKUMA ZORUNLULUĞU:** Çalışmaya başlamadan önce bu dosyayı ve `GENEL_PROJE_OZETI.md` dosyasını tamamen oku. Ardından canlı GitHub durumunu kontrol et. Eski sohbet özetleri yardımcı bağlamdır; canlı repo/CI sonucu her zaman üstündür.

## 1. PROJEYİ TEK CÜMLEDE ANLA

Bu bir **futbol teknik direktörlüğü oyunu değil, kulüp başkanlığı simülasyonudur.** Oyuncu maç taktiği yönetmez; kulübün parasını, hocasını, transfer politikasını, sözleşmelerini, taraftar/media hafızasını, vaatlerini, seçimlerini, görev süresini ve tesis yatırımlarını yönetir.

Ana ürün fikri:

> **Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.**

## 2. TEKNİK FELSEFE

- Flutter/UI daha sonra; çekirdek önce saf Dart.
- Headless, deterministik, test edilebilir simülasyon önceliklidir.
- Canonical seed: `20260903`.
- 48 özgün kulüp, 3 lig × 16 kulüp.
- 720 lig maçı/sezon.
- GameDate cihaz saatinden bağımsızdır.
- Para integer minor-unit `Money` ile tutulur.
- Save formatları versioned + migration + checksum'ludur.
- Future save version güvenli reddedilir.
- Save/load/resume kesintisiz kariyerle deterministic eşleşmelidir.
- Invariant/balance guard'ları korunmalıdır.
- Legacy simulation davranışı sessizce değiştirilemez.

## 3. ŞU ANKİ CANLI DURUM

M0–M36 canlı olarak kapanmıştır.

M37 — **President Facility Decision Loop / Turnover Replanning I** kodu PR #38 üzerinden merge edilmiştir.

- PR #38 final HEAD: `0030caef1c292d4f1d249f9a8ed5a2abcca041fb`
- PR CI: run `34059375807`, job `101557067196` — SUCCESS
- 147 normal/non-canonical test PASS
- M0–M37 runner zinciri PASS
- artifact: 0
- squash merge sonrası main SHA: `ff1745671ce57fdaa56b937bf36f026f86b34ca5`
- post-merge main CI: run `34113979981`
- **Devir anındaki özet kaydında run `34113979981` hâlâ `in_progress` görünüyordu. Bu sonucu mutlaka canlı kontrol et.**

M37'nin amacı ve kabul edilen davranışı:
- facility/academy yatırımını sezonluk decision loop'a bağlamak
- mevcut başkan profiline göre target level, upgrade intensity ve cash reserve'i yeniden hesaplamak
- başkan değişiminde yeni profile göre yatırım yönünü yeniden planlamak
- downgrade yapmamak
- gerçek club cash finance path'ini kullanmak
- gizli borç yaratmamak
- facility decision'ı youth lifecycle'dan önce çalıştırmak
- decision history'yi derived tutmak
- save/load/resume sırasında decision sequence + youth history + final facility/world checkpoint parity'sini korumak
- eski/default simulation semantiğini explicit orchestration çağrılmadıkça değiştirmemek

M37 canonical senaryo:
- başlangıç season 8
- club `t3_05`
- president turnover season 9
- 2 decision window
- eski başkan: cautious
- yeni başkan: youth-builder
- academy target `0 → 5`
- upgrades `0 → 2`
- turnover replanning: true
- decision sequence parity: true
- youth history parity: true
- final checkpoint parity: true

## 4. M0–M36'YI NASIL OKUMALISIN?

Ayrıntılı milestone dosyaları repo kökünde bulunur. Özellikle:
- M29 president runtime snapshot
- M30 fan/media/promise runtime memory
- M31 president-domain resume orchestration
- M32 long-career save/resume stress
- M34 facility persistence/finance
- M35 academy runtime youth integration
- M36 president youth orientation → academy investment

M33–M36 zinciri özellikle önemlidir: academy facility persistent hale geldi, gerçek kulüp kasasından finanse edilmeye başladı, offseason youth generation'a gerçek etkisi bağlandı ve başkanın `youthOrientation` + `financialDiscipline` trait'leri gerçek yatırım kararına bağlandı.

## 5. M37 SONRASI İÇİN KRİTİK KURAL

M37 merge edildi diye otomatik olarak yeni milestone başlatma.

Önce:
1. `main` üzerindeki run `34113979981` sonucunu kontrol et.
2. Gerçek job/test logunu incele.
3. Artifact sayısının 0 olduğunu doğrula.
4. Main CI yeşilse M37'yi CLOSED/PASS olarak belgele.
5. `GENEL_PROJE_OZETI.md` içindeki M37 durumunu canlı kanıtla güncelle.
6. Ancak bundan sonra kullanıcı talimatına göre devam et.

Main CI kırmızıysa:
- gerçek failure logunu çıkar
- kök nedeni belirle
- tahminle düzeltme yapma
- minimal hedefli fix uygula
- test et
- gerekiyorsa yeni branch/PR aç
- **kullanıcı onayı olmadan merge etme**

## 6. KULLANICIYLA ÇALIŞMA ŞEKLİ

Kullanıcı kısa komutlar kullanabilir: **"Devam et"**, **"Onaylıyorum"** vb.

"Devam et" demek gerçek işi araçlarla ilerletmek demektir; tekrar tekrar ne yapılacağını sormak değildir.

Ancak merge/release gibi açık kullanıcı onayı gerektiren işlemlerde onay beklenmelidir.

Kullanıcı özellikle şunları ister:
- GitHub araçlarını gerektiğinde kendin kullan.
- Gereksiz durum raporları verme.
- Hard blocker yoksa işi ilerlet.
- Eski sohbet notlarından çok canlı GitHub'a güven.
- Yarım çalışan/varsayımsal çözümleri tamamlanmış gibi sunma.

## 7. CI KURALLARI — DEĞİŞMEZ

- CI timeout: **7 dakika**.
- Timeout'u performans problemini gizlemek için yükseltme.
- Yavaş test varsa runner/test setup'ını optimize et.
- `actions/upload-artifact` ekleme.
- Artifact hedefi: **0**.
- Analyzer PASS olmalı.
- İlgili tüm testler PASS olmalı.
- Milestone PASS/CLOSED yalnız canlı CI kanıtıyla ilan edilmeli.

## 8. SAVE / RUNTIME KURALLARI

- Checkpoint, bir sonraki sezonun opening state'idir.
- Save version + migration + checksum korunur.
- Migration fixture/test zorunludur.
- Future version güvenli reddedilmelidir.
- Continuation-critical state ile append-only history ayrılmalıdır.
- History eklemenin save büyümesini kontrolsüz artırmasına izin verme.
- İlk 20 sezonun canonical manager davranışını koru.
- 21+ sezonda manager detail compaction olabilir; all-time summary kaybolmaz.
- Long-career split continuation ve multi-checkpoint resume parity'sini bozma.

## 9. FACILITY / ACADEMY KURALLARI

- Academy level 0 eski youth-generation davranışını korur.
- Academy facility persistent state'tir.
- Yatırım gerçek club cash'ten düşer.
- Yetersiz cash'te yatırım uygulanmaz; gizli debt yaratılmaz.
- `youthOrientation` academy target/intensity'yi etkiler.
- `financialDiscipline` protected cash reserve'i etkiler.
- Persistent academy level gerçek offseason youth intake quality'sini etkiler.
- Facility-aware lifecycle mevcut youth lifecycle'a delegate eder; paralel yeni generator kurma.
- M37 decision loop başkan değişiminde yeniden planlama yapar.
- Downgrade yok.

## 10. TEST / GELİŞTİRME PRENSİBİ

Her yeni değişiklik için şu zinciri koru:

**canlı durum → küçük tasarım → minimal kod değişikliği → regression test → canonical/parity test → CI → dokümantasyon**

Gereksiz refactor yapma.

Bir şeyin "mantıklı görünmesi" yeterli değildir. Özellikle determinism ve save/resume konusunda doğrudan test kanıtı gerekir.

## 11. AÇIK ÜRÜN KONULARI

Şu alanlar henüz tamamlanmış ürün sistemi olarak kabul edilmez:
- Android file system / save-slot UI / autosave / backup / cloud save
- stadium / training-ground facility türleri
- sponsor sistemi
- kriz sistemi
- seçim kaybında game-over / başka kulübe geçiş UX'i
- 30+ sezon player/economy/manager balance sertleştirmesi

Bunları sırf listede duruyor diye hemen milestone'a çevirme. Önce mevcut zincirin stabil olduğunu doğrula ve kullanıcı yönlendirmesini esas al.

## 12. EN ÖNEMLİ HATALAR

Şunları yapma:

- Eski sohbetten bir sonucu canlı CI kontrol etmeden "PASS" kabul etme.
- Main CI tamamlanmadan milestone'u kapatma.
- Kullanıcı onayı olmadan PR merge etme.
- CI timeout'unu artırarak sorunu gizleme.
- Artifact upload ekleme.
- Legacy davranışı sessizce değiştirme.
- Save formatını migration olmadan değiştirme.
- Deterministic seed/replay'i bozma.
- Save/load/resume parity'sini test etmeden kabul etme.
- Gereksiz büyük refactor yapma.
- Yeni milestone'u sırf sıradaki fikir olduğu için otomatik başlatma.
- "Muhtemelen düzeldi" diyerek kullanıcıya bitmiş iş sunma.

## 13. DEVİR SONU KURALI

Bu dosya **geçici devir dosyasıdır**. Yaklaşık 1 aylık devir amacıyla oluşturuldu.

Projeyi devralan oturum:
1. Bu dosyayı tamamen okur.
2. `GENEL_PROJE_OZETI.md` dosyasını okur.
3. Canlı GitHub durumunu kontrol eder.
4. Çalışmaya devam eder.
5. Devir süresi sona erdiğinde veya kullanıcı "devir dosyasını sil" dediğinde bu dosyayı repo'dan siler.

**Silme işlemi yapılmadan önce bu dosyadaki kalıcı ve önemli bilgiler `GENEL_PROJE_OZETI.md` içine aktarılmış olmalıdır.**

Bu dosyanın amacı kalıcı dokümantasyon değil, yeni ChatGPT oturumunun projeyi eksiksiz anlamasını sağlamaktır.
