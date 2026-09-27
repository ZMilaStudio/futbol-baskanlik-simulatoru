import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../composition/app_composition.dart';
import 'club_selection_screen.dart';
import 'save_list_screen.dart';

final _privacyPolicyUri = Uri.parse(
  'https://zmilastudio.com/futbol-baskanlik-simulatoru/privacy/',
);

typedef PrivacyPolicyLauncher = Future<bool> Function(Uri uri);

class OpeningScreen extends StatelessWidget {
  const OpeningScreen({
    super.key,
    required this.composition,
    this.privacyPolicyLauncher = _launchPrivacyPolicy,
  });

  final AppComposition composition;
  final PrivacyPolicyLauncher privacyPolicyLauncher;

  static Future<bool> _launchPrivacyPolicy(Uri uri) => launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await privacyPolicyLauncher(_privacyPolicyUri);
    if (opened || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gizlilik Politikası bağlantısı açılamadı.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Futbol Başkanlık Simülatörü',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kulübünün başkanı olarak karşına çıkan yönetim kararlarıyla '
                    'kulübünün geleceğine yön verirsin. Maç taktiğini değil, '
                    'kulübü yönetirsin.',
                    key: const Key('opening-role-description'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kararı incele, seçimini yap ve uygulanan sonucu gör. '
                    'Kararlar tamamlandığında sezon raporunu inceleyebilirsin. '
                    'Başkanlığın sürüyorsa sonraki sezona geçebilirsin.',
                    key: const Key('opening-career-flow-description'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('new-game-button'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ClubSelectionScreen(
                            composition: composition,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Yeni Oyun'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('load-game-button'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SaveListScreen(
                            composition: composition,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Kayıt Yükle'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    key: const Key('privacy-policy-link'),
                    onPressed: () => _openPrivacyPolicy(context),
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: const Text('Gizlilik Politikası'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
