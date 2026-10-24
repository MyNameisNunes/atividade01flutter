import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/localizacao.dart';

/// Resultado da verificação do GPS e da permissão de localização.
enum StatusLocalizacao {
  /// Permissão concedida com localização precisa.
  liberada,

  /// Permissão concedida, mas o usuário escolheu localização aproximada.
  aproximada,

  /// O serviço de localização (GPS) do aparelho está desativado.
  servicoDesativado,

  /// O usuário negou a permissão; ela pode ser solicitada de novo.
  negada,

  /// A permissão só pode ser habilitada nas configurações do aplicativo.
  negadaPermanentemente,
}

/// Acesso ao GPS: serviço, permissões e stream de posições.
class ServicoLocalizacao {
  /// Intervalo solicitado entre leituras. O sistema pode variá-lo.
  static const intervalo = Duration(seconds: 20);

  /// Verifica o GPS e solicita a permissão de localização quando necessário.
  Future<StatusLocalizacao> verificarPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return StatusLocalizacao.servicoDesativado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    switch (permissao) {
      case LocationPermission.deniedForever:
        return StatusLocalizacao.negadaPermanentemente;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return StatusLocalizacao.negada;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        final precisao = await Geolocator.getLocationAccuracy();
        return precisao == LocationAccuracyStatus.reduced
            ? StatusLocalizacao.aproximada
            : StatusLocalizacao.liberada;
    }
  }

  /// Solicita a permissão para exibir a notificação do serviço em primeiro
  /// plano (exigida a partir do Android 13).
  Future<bool> solicitarPermissaoNotificacao() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Stream de posições com alta precisão e intervalo solicitado de 20 s.
  ///
  /// No Android, a leitura ocorre em um serviço em primeiro plano que mantém
  /// uma notificação visível enquanto houver uma assinatura ativa.
  Stream<Localizacao> posicoes() {
    final configuracoes = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: intervalo,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Coleta de localização ativa',
        notificationText: 'Registrando sua posição a cada 20 segundos.',
        notificationChannelName: 'Coleta de localização',
        notificationIcon: AndroidResource(
          name: 'ic_notificacao_localizacao',
          defType: 'drawable',
        ),
        enableWakeLock: true,
        setOngoing: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: configuracoes).map(
      (posicao) => Localizacao(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
        precisao: posicao.accuracy,
        instante: posicao.timestamp.toUtc(),
      ),
    );
  }

  /// Abre a tela de configurações do aplicativo, onde ficam as permissões.
  Future<bool> abrirConfiguracoesPermissao() => Geolocator.openAppSettings();

  /// Abre as configurações de localização (GPS) do aparelho.
  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();

  /// Converte erros do GPS em uma mensagem para o usuário.
  String descreverErro(Object erro) {
    return switch (erro) {
      LocationServiceDisabledException() =>
        'O serviço de localização do aparelho foi desativado.',
      PermissionDeniedException() => 'A permissão de localização foi negada.',
      PermissionRequestInProgressException() =>
        'Já existe uma solicitação de permissão em andamento.',
      _ => 'Falha ao obter a localização ($erro).',
    };
  }
}
