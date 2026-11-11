import 'package:flutter/material.dart';

/// Limita a largura do conteúdo e centraliza na tela.
/// No celular não muda nada; no tablet evita que formulários e listas
/// fiquem esticados ocupando a tela inteira.
class ConteudoCentralizado extends StatelessWidget {
  final Widget child;
  final double larguraMaxima;

  const ConteudoCentralizado({
    super.key,
    required this.child,
    this.larguraMaxima = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: child,
      ),
    );
  }
}
