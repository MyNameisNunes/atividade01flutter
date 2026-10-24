import 'package:atividade01flutter/features/localizacoes/models/localizacao.dart';
import 'package:atividade01flutter/features/localizacoes/presentation/widgets/item_localizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final instante = DateTime.utc(2026, 10, 24, 20, 43, 5, 120);
  final localizacao = Localizacao(
    id: 7,
    latitude: -23.5505199,
    longitude: -46.6333094,
    precisao: 4.56,
    instante: instante,
  );

  group('Localizacao', () {
    test('converte para o mapa da tabela com instante ISO 8601 em UTC', () {
      final mapa = localizacao.paraMapa();

      expect(mapa['id'], 7);
      expect(mapa['latitude'], -23.5505199);
      expect(mapa['instante'], '2026-10-24T20:43:05.120Z');
    });

    test('converte instante local para UTC ao gravar', () {
      final local = DateTime(2026, 1, 2, 3, 4, 5);
      final mapa = Localizacao(
        latitude: 0,
        longitude: 0,
        precisao: 1,
        instante: local,
      ).paraMapa();

      expect(mapa.containsKey('id'), isFalse);
      expect(mapa['instante'], local.toUtc().toIso8601String());
    });

    test('reconstrói a mesma localização a partir do mapa', () {
      final copia = Localizacao.deMapa(localizacao.paraMapa());

      expect(copia.id, localizacao.id);
      expect(copia.latitude, localizacao.latitude);
      expect(copia.longitude, localizacao.longitude);
      expect(copia.precisao, localizacao.precisao);
      expect(copia.instante, instante);
      expect(copia.instante.isUtc, isTrue);
    });
  });

  testWidgets('ItemLocalizacao formata coordenadas, precisão e hora local', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ItemLocalizacao(localizacao: localizacao)),
      ),
    );

    final local = instante.toLocal();
    String dois(int valor) => valor.toString().padLeft(2, '0');
    expect(
      find.text(
        '${dois(local.day)}/${dois(local.month)}/${local.year} '
        '${dois(local.hour)}:${dois(local.minute)}:${dois(local.second)}',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Lat: -23.550520  Lon: -46.633309\nPrecisão estimada: 4.6 m'),
      findsOneWidget,
    );
  });
}
