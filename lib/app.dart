import 'package:flutter/material.dart';

import 'features/localizacoes/presentation/screens/tela_coleta.dart';

class AppLocalizacoes extends StatelessWidget {
  const AppLocalizacoes({super.key});

  static const _corBase = Color(0xFF00796B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _corBase),
      darkTheme: ThemeData(
        colorSchemeSeed: _corBase,
        brightness: Brightness.dark,
      ),
      home: const TelaColeta(),
    );
  }
}
