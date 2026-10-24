import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/aviso_estado.dart';
import '../widgets/mapa_localizacoes.dart';

/// Mapa interativo com as últimas localizações salvas.
class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key, required this.repositorio});

  final RepositorioLocalizacoes repositorio;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  MapCachingProvider? _cache;

  /// Nulo até a primeira consulta terminar com sucesso.
  List<Localizacao>? _localizacoes;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // O cache das imagens é preparado antes de o mapa ser exibido.
      final cache = _cache ?? await prepararCacheMapa();
      final localizacoes = await widget.repositorio.consultarRecentes();
      if (!mounted) return;
      setState(() {
        _cache = cache;
        _localizacoes = localizacoes;
      });
    } catch (erro) {
      if (!mounted) return;
      final mensagem = 'Não foi possível carregar as localizações ($erro).';
      setState(() => _erro = mensagem);
      // Se o mapa já está na tela, mantém os dados anteriores e só avisa.
      if (_localizacoes != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensagem)));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de localizações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar registros',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: _carregando && _localizacoes != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _conteudo(),
    );
  }

  Widget _conteudo() {
    final localizacoes = _localizacoes;
    final cache = _cache;

    if (localizacoes == null || cache == null) {
      if (_erro != null) {
        return AvisoEstado(
          icone: Icons.error_outline,
          titulo: 'Erro ao carregar o mapa',
          mensagem: _erro!,
          rotuloAcao: 'Tentar novamente',
          aoAcionar: _carregar,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (localizacoes.isEmpty) {
      return AvisoEstado(
        icone: Icons.map_outlined,
        titulo: 'Nenhuma localização salva',
        mensagem:
            'Inicie a coleta na tela inicial e atualize esta tela para ver '
            'as posições no mapa.',
        rotuloAcao: 'Atualizar',
        aoAcionar: _carregando ? null : _carregar,
      );
    }

    return MapaLocalizacoes(localizacoes: localizacoes, cache: cache);
  }
}
