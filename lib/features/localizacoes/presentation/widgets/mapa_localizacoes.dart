import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

/// Mapa com a camada de ruas do OpenStreetMap e um marcador por localização.
///
/// A localização mais recente aparece em vermelho. Os pontos são enquadrados
/// quando o mapa abre e sempre que a lista de localizações muda.
class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.cache,
  });

  /// Localizações ordenadas da mais recente para a mais antiga (não vazia).
  final List<Localizacao> localizacoes;

  /// Cache local das imagens do mapa, já preparado.
  final MapCachingProvider cache;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  static const _urlTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identifica o aplicativo nas requisições, como exige o OpenStreetMap.
  static const _pacoteAplicativo = 'br.edu.pdm.atividade01flutter';

  static final _urlDireitosAutorais = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );

  final _controlador = MapController();

  // O TileLayer descarta o provedor ao ser removido da árvore.
  late final _provedorTiles = NetworkTileProvider(
    cachingProvider: widget.cache,
  );

  @override
  void didUpdateWidget(MapaLocalizacoes antigo) {
    super.didUpdateWidget(antigo);
    if (!identical(antigo.localizacoes, widget.localizacoes)) {
      // Move a câmera após o frame atual, fora da fase de construção.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  CameraFit get _enquadramento => CameraFit.coordinates(
    coordinates: [
      for (final localizacao in widget.localizacoes)
        LatLng(localizacao.latitude, localizacao.longitude),
    ],
    padding: const EdgeInsets.all(56),
    maxZoom: 17,
  );

  void _enquadrar() => _controlador.fitCamera(_enquadramento);

  void _mostrarDetalhes(Localizacao localizacao, {required bool maisRecente}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ItemLocalizacao(
            localizacao: localizacao,
            maisRecente: maisRecente,
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDireitosAutorais() async {
    final abriu = await launchUrl(
      _urlDireitosAutorais,
      mode: LaunchMode.externalApplication,
    );
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o navegador.')),
      );
    }
  }

  List<Marker> _marcadores() {
    final localizacoes = widget.localizacoes;
    return [
      // Da mais antiga para a mais recente, para que a mais recente
      // seja desenhada por cima das demais.
      for (var i = localizacoes.length - 1; i >= 0; i--)
        _marcador(localizacoes[i], maisRecente: i == 0),
    ];
  }

  Marker _marcador(Localizacao localizacao, {required bool maisRecente}) {
    final tamanho = maisRecente ? 48.0 : 36.0;
    return Marker(
      point: LatLng(localizacao.latitude, localizacao.longitude),
      width: tamanho,
      height: tamanho,
      // A ponta do ícone fica exatamente sobre a coordenada.
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _mostrarDetalhes(localizacao, maisRecente: maisRecente),
        child: Icon(
          Icons.location_on,
          size: tamanho,
          color: maisRecente ? Colors.red : Colors.blue.shade700,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCameraFit: _enquadramento,
            minZoom: 2,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _urlTiles,
              userAgentPackageName: _pacoteAplicativo,
              tileProvider: _provedorTiles,
              maxNativeZoom: 19,
            ),
            MarkerLayer(markers: _marcadores()),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap contributors'),
              onTap: _abrirDireitosAutorais,
            ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _enquadrar,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
