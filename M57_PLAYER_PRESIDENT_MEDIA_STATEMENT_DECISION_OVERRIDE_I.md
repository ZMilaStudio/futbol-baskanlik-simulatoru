# M57 — Player President Media Statement Decision Override I

## Amaç

M10'un deterministik başkan açıklamalarını controlled club için gerçek oyuncu başkan karar yüzeyine açmak; açıklama olayının varlığını, manager hedefini ve medya etkisini kanonik motorlarda tutmak.

## Kapsam

- `PlayerMediaStatementDecisionProvider` yalnız controlled club için çalışır.
- M10 `MediaStatementEngine` önce normal AI statement event'ini üretir.
- AI statement yoksa player provider çağrılmaz; oyuncu basın olayı yaratamaz.
- Statement varsa oyuncu yalnız mevcut dört `MediaStance` değerinden birini seçer:
  - `strongSupport`
  - `measuredSupport`
  - `pressure`
  - `noComment`
- Statement `id`, `clubId`, `targetManagerId`, `seasonIndex` ve `topic` kanonik AI statement'tan korunur.
- Credibility delta oyuncu tarafından verilemez; M10 `MediaCredibilityEngine` seçilen stance ile sonucu hesaplar.
- Diğer 47 kulüp exact M10 AI davranışını korur.
- Provider yoksa M10 exact parity korunur.
- `PlayerPresidentMediaStatementDomainCareerEngine`, aynı seam'i president-domain initial + resume yollarına opt-in taşır.
- Provider runtime-only'dir; save schema/migration değişmez.

## Acceptance

1. provider yokken M10 media generation exact parity
2. yalnız controlled club stance override; diğer 47 kulüp exact AI parity
3. AI event yoksa provider çağrılmaz ve event yaratılamaz
4. seçilen stance mevcut M10 credibility resolution'a gerçek olarak akar; statement metadata korunur
5. runtime-only provider ile save/load/resume determinism (`2+2 == 4`)

## Kalıcı semantik

M57 serbest metin basın toplantısı UI'sı değildir. Yeni medya konusu, yeni credibility formülü veya yeni event sıklığı eklemez. M10'un mevcut olay ve hafıza sistemi korunur; yalnız controlled club'ın mevcut kanonik statement event'indeki başkan tavrı oyuncuya açılır.
