import 'package:flutter/material.dart';
import 'package:petagenda/util/tema.dart';

/// Mostra uma mensagem na parte de baixo da tela.
/// erro: true  -> fundo vermelho com ícone de alerta
/// erro: false -> fundo escuro com ícone de confirmação
void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? Tema.vermelhoErro : Tema.textoEscuro,
        content: Row(
          children: [
            Icon(
              erro ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(texto, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}
