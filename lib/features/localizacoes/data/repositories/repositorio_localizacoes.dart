import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

/// Concentra as operações de persistência das localizações.
class RepositorioLocalizacoes {
  /// Quantidade de registros exibidos no histórico e no mapa.
  static const limiteConsulta = 100;

  final _banco = BancoLocalizacoes.instancia;

  Future<int> inserir(Localizacao localizacao) async {
    final banco = await _banco.obter();
    return banco.insert(BancoLocalizacoes.tabela, localizacao.paraMapa());
  }

  /// Retorna as localizações mais recentes, da mais nova para a mais antiga.
  ///
  /// O limite vale apenas para a consulta; nenhum registro antigo é excluído.
  Future<List<Localizacao>> consultarRecentes({
    int limite = limiteConsulta,
  }) async {
    final banco = await _banco.obter();
    final linhas = await banco.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.deMapa).toList();
  }

  /// Remove todas as linhas, preservando a tabela e o arquivo do banco.
  Future<int> excluirTodas() async {
    final banco = await _banco.obter();
    return banco.delete(BancoLocalizacoes.tabela);
  }
}
