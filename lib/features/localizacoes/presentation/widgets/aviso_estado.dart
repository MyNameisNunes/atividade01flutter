import 'package:flutter/material.dart';

/// Mensagem centralizada para estados de erro ou de lista vazia.
class AvisoEstado extends StatelessWidget {
  const AvisoEstado({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.aoAcionar,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? aoAcionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
            if (rotuloAcao != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: aoAcionar,
                child: Text(rotuloAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
