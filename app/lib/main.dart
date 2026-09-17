import 'package:flutter/material.dart';

import 'composition/app_composition.dart';
import 'screens/opening_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final composition = await AppComposition.create();
  runApp(FutbolBaskanlikApp(composition: composition));
}

class FutbolBaskanlikApp extends StatelessWidget {
  const FutbolBaskanlikApp({
    super.key,
    required this.composition,
  });

  final AppComposition composition;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Futbol Başkanlık Simülatörü',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF17324D)),
        useMaterial3: true,
      ),
      home: OpeningScreen(composition: composition),
    );
  }
}
