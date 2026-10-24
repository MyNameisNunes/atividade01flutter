import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Abre o banco SQLite `localizacoes.db` e reaproveita a mesma conexão.
class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final instancia = BancoLocalizacoes._();

  static const nomeArquivo = 'localizacoes.db';
  static const versao = 1;
  static const tabela = 'localizacoes';

  Future<Database>? _abertura;

  /// Retorna a conexão, abrindo o banco na primeira chamada.
  ///
  /// Se a abertura falhar, a próxima chamada tenta abrir novamente.
  Future<Database> obter() async {
    final abertura = _abertura ??= _abrir();
    try {
      return await abertura;
    } catch (_) {
      if (identical(_abertura, abertura)) {
        _abertura = null;
      }
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), nomeArquivo);
    return openDatabase(caminho, version: versao, onCreate: _criar);
  }

  Future<void> _criar(Database banco, int versao) async {
    await banco.execute('''
      CREATE TABLE $tabela (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        precisao REAL NOT NULL,
        instante TEXT NOT NULL
      )
    ''');
    // Acelera a consulta das mais recentes (ORDER BY instante ... LIMIT).
    await banco.execute(
      'CREATE INDEX idx_${tabela}_instante ON $tabela (instante)',
    );
  }
}
