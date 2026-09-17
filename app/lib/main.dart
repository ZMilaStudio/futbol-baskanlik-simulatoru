import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main() {
  runApp(const FutbolBaskanlikApp());
}

class FutbolBaskanlikApp extends StatelessWidget {
  const FutbolBaskanlikApp({super.key});

  @override
  Widget build(BuildContext context) {
    final world = const FictionalWorldFactory().build();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Futbol Başkanlık Simülatörü',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Futbol Başkanlık Simülatörü'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text('Core bağlantısı: ${world.clubs.length} kulüp'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
