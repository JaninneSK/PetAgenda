import 'package:flutter/material.dart';

/// A logo branca do PetAgenda.
/// Se o arquivo não for encontrado (asset não registrado no pubspec.yaml),
/// mostra uma patinha no lugar, em vez da mensagem de erro vermelha.
class LogoPetAgenda extends StatelessWidget {
  final double? largura;
  final double? altura;

  const LogoPetAgenda({super.key, this.largura, this.altura});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_branca.png',
      width: largura,
      height: altura,
      errorBuilder: (context, erro, pilha) =>
          Icon(Icons.pets, size: largura ?? altura ?? 48, color: Colors.white),
    );
  }
}
