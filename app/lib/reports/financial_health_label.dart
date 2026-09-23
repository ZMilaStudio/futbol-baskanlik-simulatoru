import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

String financialHealthLabel(FinancialHealth health) => switch (health) {
      FinancialHealth.veryStrong => 'Çok güçlü',
      FinancialHealth.solid => 'Sağlam',
      FinancialHealth.balanced => 'Dengeli',
      FinancialHealth.tight => 'Sıkışık',
      FinancialHealth.debtCrisis => 'Borç krizi',
    };
