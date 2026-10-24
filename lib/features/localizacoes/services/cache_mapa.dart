import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Tamanho máximo do cache de imagens do mapa, em bytes.
const _tamanhoMaximoCache = 200 * 1024 * 1024;

/// Prepara o armazenamento local das imagens (tiles) do mapa.
///
/// As imagens ficam em uma pasta privada do aplicativo, dentro do diretório
/// de cache, e são reaproveitadas enquanto os cabeçalhos HTTP do provedor as
/// considerarem válidas, como pede a política de uso do OpenStreetMap.
/// Deve ser chamado antes de o mapa começar a carregar as imagens.
Future<MapCachingProvider> prepararCacheMapa() async {
  final base = await getApplicationCacheDirectory();
  final pasta = await Directory(join(base.path, 'cache_mapa'))
      .create(recursive: true);
  return BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: pasta.path,
    maxCacheSize: _tamanhoMaximoCache,
  );
}
