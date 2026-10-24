import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/aviso_estado.dart';
import '../widgets/item_localizacao.dart';

/// Histórico com as últimas localizações salvas.
class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({
    super.key,
    required this.repositorio,
    required this.coletaAtiva,
  });

  final RepositorioLocalizacoes repositorio;

  /// Indica se a coleta continua gravando enquanto esta tela está aberta.
  final ValueListenable<bool> coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  /// Nulo até a primeira consulta terminar com sucesso.
  List<Localizacao>? _localizacoes;
  bool _carregando = false;
  bool _limpando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final localizacoes = await widget.repositorio.consultarRecentes();
      if (!mounted) return;
      setState(() => _localizacoes = localizacoes);
    } catch (erro) {
      if (!mounted) return;
      final mensagem = 'Não foi possível consultar o histórico ($erro).';
      setState(() => _erro = mensagem);
      // Se a lista já está na tela, mantém os dados anteriores e só avisa.
      if (_localizacoes != null) _mostrarMensagem(mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _confirmarLimpeza() async {
    final coletaAtiva = widget.coletaAtiva.value;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever),
        title: const Text('Limpar histórico?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Todas as localizações salvas serão excluídas, inclusive as '
              'que não aparecem nesta lista. Esta operação é permanente e '
              'não pode ser desfeita.',
            ),
            if (coletaAtiva) ...[
              const SizedBox(height: 12),
              const Text(
                'A coleta está ativa: novos registros continuarão sendo '
                'salvos após a limpeza.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _limpando = true);
    try {
      await widget.repositorio.excluirTodas();
      if (!mounted) return;
      await _carregar();
      if (mounted) _mostrarMensagem('Histórico limpo com sucesso.');
    } catch (erro) {
      if (mounted) {
        _mostrarMensagem('Não foi possível limpar o histórico ($erro).');
      }
    } finally {
      if (mounted) setState(() => _limpando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _carregando || _limpando;
    final temRegistros = _localizacoes?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar registros',
            onPressed: ocupado ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: ocupado || !temRegistros ? null : _confirmarLimpeza,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
        bottom: ocupado && _localizacoes != null
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

    if (localizacoes == null) {
      if (_erro != null) {
        return AvisoEstado(
          icone: Icons.error_outline,
          titulo: 'Erro ao consultar o histórico',
          mensagem: _erro!,
          rotuloAcao: 'Tentar novamente',
          aoAcionar: _carregar,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (localizacoes.isEmpty) {
      return AvisoEstado(
        icone: Icons.location_off_outlined,
        titulo: 'Nenhuma localização salva',
        mensagem:
            'Inicie a coleta na tela inicial e atualize esta tela para ver '
            'os registros.',
        rotuloAcao: 'Atualizar',
        aoAcionar: _carregando ? null : _carregar,
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: localizacoes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, indice) => ItemLocalizacao(
          localizacao: localizacoes[indice],
          maisRecente: indice == 0,
        ),
      ),
    );
  }
}
