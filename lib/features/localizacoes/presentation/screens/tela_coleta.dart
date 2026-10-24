import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

/// Tela inicial: inicia e para a coleta e dá acesso às demais telas.
///
/// A assinatura do stream pertence a esta tela, que permanece na pilha de
/// navegação; por isso a coleta continua ao abrir o histórico ou o mapa.
class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final _repositorio = RepositorioLocalizacoes();
  final _servico = ServicoLocalizacao();
  final _coletaAtiva = ValueNotifier(false);

  StreamSubscription<Localizacao>? _assinatura;

  /// Fila de gravações: cada posição só é gravada após a anterior terminar.
  Future<void> _gravacoes = Future.value();

  /// Mensagem exibida enquanto a coleta está sendo iniciada ou parada.
  String? _mensagemEspera;

  int _salvasNaSessao = 0;
  Localizacao? _ultimaSalva;

  bool get _ativa => _assinatura != null;
  bool get _ocupado => _mensagemEspera != null;

  @override
  void dispose() {
    _assinatura?.cancel();
    _coletaAtiva.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _definirAssinatura(StreamSubscription<Localizacao>? assinatura) {
    _assinatura = assinatura;
    _coletaAtiva.value = assinatura != null;
  }

  Future<void> _iniciarColeta() async {
    if (_ativa || _ocupado) return;
    setState(
      () => _mensagemEspera =
          'Verificando o serviço de localização e as permissões.',
    );
    try {
      final status = await _servico.verificarPermissao();
      if (!mounted) return;
      if (!await _orientarSobrePermissao(status)) return;

      final notificacoesPermitidas = await _servico
          .solicitarPermissaoNotificacao();
      if (!mounted) return;

      _definirAssinatura(
        _servico.posicoes().listen(
          _aoReceberLocalizacao,
          onError: _aoFalharColeta,
          onDone: _aoEncerrarColeta,
          cancelOnError: true,
        ),
      );
      setState(() => _salvasNaSessao = 0);

      final avisos = [
        'Coleta iniciada.',
        if (status == StatusLocalizacao.aproximada)
          'Apenas a localização aproximada foi permitida; habilite a '
              'localização precisa nas configurações de permissão.',
        if (!notificacoesPermitidas)
          'As notificações estão bloqueadas; habilite-as nas configurações '
              'de permissão para ver o aviso da coleta.',
      ];
      _mostrarMensagem(avisos.join(' '));
    } catch (erro) {
      if (mounted) {
        _mostrarMensagem(
          'Não foi possível iniciar a coleta. ${_servico.descreverErro(erro)}',
        );
      }
    } finally {
      if (mounted) setState(() => _mensagemEspera = null);
    }
  }

  /// Orienta o usuário quando o GPS ou a permissão impedem a coleta.
  ///
  /// Retorna `true` se a coleta pode começar.
  Future<bool> _orientarSobrePermissao(StatusLocalizacao status) async {
    switch (status) {
      case StatusLocalizacao.liberada:
      case StatusLocalizacao.aproximada:
        return true;
      case StatusLocalizacao.servicoDesativado:
        await _mostrarOrientacao(
          titulo: 'Localização desativada',
          mensagem:
              'Ative o serviço de localização (GPS) do aparelho e toque '
              'novamente em Iniciar coleta.',
          abrirConfiguracoes: _servico.abrirConfiguracoesLocalizacao,
        );
        return false;
      case StatusLocalizacao.negada:
        _mostrarMensagem(
          'Permissão de localização negada. A coleta precisa dela; toque em '
          'Iniciar coleta para solicitá-la novamente.',
        );
        return false;
      case StatusLocalizacao.negadaPermanentemente:
        await _mostrarOrientacao(
          titulo: 'Permissão necessária',
          mensagem:
              'A permissão de localização foi negada e só pode ser '
              'habilitada nas configurações do aplicativo. Em Permissões, '
              'escolha Localização e permita o acesso.',
          abrirConfiguracoes: _servico.abrirConfiguracoesPermissao,
        );
        return false;
    }
  }

  Future<void> _mostrarOrientacao({
    required String titulo,
    required String mensagem,
    required Future<bool> Function() abrirConfiguracoes,
  }) async {
    final abrir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
    if (abrir == true) await abrirConfiguracoes();
  }

  void _aoReceberLocalizacao(Localizacao localizacao) {
    // Encadeia na fila para evitar gravações sobrepostas.
    _gravacoes = _gravacoes.then((_) => _salvar(localizacao));
  }

  Future<void> _salvar(Localizacao localizacao) async {
    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _ultimaSalva = localizacao;
        _salvasNaSessao++;
      });
    } catch (erro) {
      if (mounted) {
        _mostrarMensagem('Falha ao salvar a localização no banco ($erro).');
      }
    }
  }

  void _aoFalharColeta(Object erro) {
    // Com cancelOnError, a assinatura já foi cancelada pelo stream.
    _definirAssinatura(null);
    if (!mounted) return;
    setState(() {});
    _mostrarMensagem(
      'A coleta foi interrompida. ${_servico.descreverErro(erro)}',
    );
  }

  void _aoEncerrarColeta() {
    _definirAssinatura(null);
    if (!mounted) return;
    setState(() {});
    _mostrarMensagem('A coleta foi encerrada pelo sistema.');
  }

  Future<void> _pararColeta() async {
    final assinatura = _assinatura;
    if (assinatura == null || _ocupado) return;
    setState(() {
      _mensagemEspera = 'Encerrando a coleta e concluindo a última gravação.';
      _definirAssinatura(null);
    });
    try {
      await assinatura.cancel();
      // Conclui a gravação que estiver em andamento.
      await _gravacoes;
      if (mounted) _mostrarMensagem('Coleta parada.');
    } finally {
      if (mounted) setState(() => _mensagemEspera = null);
    }
  }

  Future<void> _abrirConfiguracoesPermissao() async {
    final abriu = await _servico.abrirConfiguracoesPermissao();
    if (!abriu && mounted) {
      _mostrarMensagem('Não foi possível abrir as configurações.');
    }
  }

  void _abrirHistorico() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaLocalizacoes(
          repositorio: _repositorio,
          coletaAtiva: _coletaAtiva,
        ),
      ),
    );
  }

  void _abrirMapa() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaMapa(repositorio: _repositorio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultimaSalva = _ultimaSalva;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localizações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CartaoStatus(
              ativa: _ativa,
              mensagemEspera: _mensagemEspera,
              salvasNaSessao: _salvasNaSessao,
            ),
            if (ultimaSalva != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        'Última localização salva',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ItemLocalizacao(localizacao: ultimaSalva),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: !_ativa && !_ocupado ? _iniciarColeta : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _ativa && !_ocupado ? _pararColeta : null,
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _abrirHistorico,
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _abrirMapa,
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _abrirConfiguracoesPermissao,
              icon: const Icon(Icons.settings),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoStatus extends StatelessWidget {
  const _CartaoStatus({
    required this.ativa,
    required this.mensagemEspera,
    required this.salvasNaSessao,
  });

  final bool ativa;
  final String? mensagemEspera;
  final int salvasNaSessao;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final intervalo = ServicoLocalizacao.intervalo.inSeconds;

    final Widget icone;
    final String titulo;
    final String descricao;
    if (mensagemEspera != null) {
      icone = const SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(),
      );
      titulo = 'Aguarde…';
      descricao = mensagemEspera!;
    } else if (ativa) {
      icone = Icon(Icons.gps_fixed, size: 32, color: cores.primary);
      titulo = 'Coleta ativa';
      descricao =
          'Intervalo solicitado: $intervalo s. '
          'Localizações salvas nesta coleta: $salvasNaSessao. '
          'A coleta continua em outras telas e com o app minimizado.';
    } else {
      icone = Icon(Icons.gps_off, size: 32, color: cores.outline);
      titulo = 'Coleta parada';
      descricao = 'Toque em Iniciar coleta para registrar sua posição.';
    }

    return Card(
      color: ativa ? cores.primaryContainer : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: icone,
        title: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(descricao),
      ),
    );
  }
}
