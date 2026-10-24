import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

/// Exibe data e hora locais, coordenadas e precisão de uma localização.
///
/// Usado na lista do histórico e nos detalhes de um marcador do mapa.
class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.maisRecente = false,
  });

  final Localizacao localizacao;

  /// Destaca o item (em vermelho) como a localização mais recente.
  final bool maisRecente;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final latitude = localizacao.latitude.toStringAsFixed(6);
    final longitude = localizacao.longitude.toStringAsFixed(6);
    final precisao = localizacao.precisao.toStringAsFixed(1);

    return ListTile(
      leading: Icon(
        Icons.location_on,
        color: maisRecente ? Colors.red : cores.primary,
      ),
      title: Text(_formatarDataHora(localizacao.instante)),
      subtitle: Text(
        'Lat: $latitude  Lon: $longitude\n'
        'Precisão estimada: $precisao m',
      ),
      isThreeLine: true,
      trailing: maisRecente
          ? Text(
              'Mais recente',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            )
          : null,
    );
  }

  /// Formata o instante (UTC) como data e hora locais: dd/MM/aaaa HH:mm:ss.
  static String _formatarDataHora(DateTime instante) {
    final local = instante.toLocal();
    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year} '
        '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}:'
        '${doisDigitos(local.second)}';
  }
}
