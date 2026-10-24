/// Uma posição coletada pelo GPS e salva no banco local.
class Localizacao {
  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  /// Cria uma localização a partir de uma linha da tabela `localizacoes`.
  factory Localizacao.deMapa(Map<String, Object?> mapa) {
    return Localizacao(
      id: mapa['id'] as int?,
      latitude: (mapa['latitude'] as num).toDouble(),
      longitude: (mapa['longitude'] as num).toDouble(),
      precisao: (mapa['precisao'] as num).toDouble(),
      instante: DateTime.parse(mapa['instante'] as String).toUtc(),
    );
  }

  /// Identificador gerado pelo banco; nulo antes da inserção.
  final int? id;

  final double latitude;
  final double longitude;

  /// Precisão horizontal estimada, em metros.
  final double precisao;

  /// Momento da leitura, em UTC.
  final DateTime instante;

  /// Converte para o mapa gravado na tabela `localizacoes`.
  Map<String, Object?> paraMapa() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': _instanteIso8601Utc(),
    };
  }

  /// ISO 8601 em UTC sempre com milissegundos (ex.: 2026-10-24T20:43:05.000Z),
  /// para que a ordem alfabética da coluna coincida com a cronológica.
  String _instanteIso8601Utc() {
    return DateTime.fromMillisecondsSinceEpoch(
      instante.millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String();
  }
}
