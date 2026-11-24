import 'package:flutter/material.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';

/// Lista com TODOS os requisitos da senha, mostrados juntos.
/// Aparece quando o campo ganha o foco (ou já tem texto) e marca cada
/// requisito conforme é atendido. Quando a senha atende a todos, a lista
/// inteira some.
class RequisitosSenha extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sobreVerde; // true nas telas de fundo verde (cadastro)

  const RequisitosSenha({
    super.key,
    required this.controller,
    required this.focusNode,
    this.sobreVerde = false,
  });

  @override
  Widget build(BuildContext context) {
    // Reconstrói sozinho quando o texto muda ou o campo ganha/perde o foco
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final senha = controller.text;
        final requisitos = Validador.requisitosSenha(senha);
        final atendeTodos = requisitos.every((r) => r.atendido);
        final visivel = (focusNode.hasFocus || senha.isNotEmpty) && !atendeTodos;
        if (!visivel) return const SizedBox.shrink();

        final corTexto = sobreVerde ? Colors.white : Tema.textoEscuro;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sobreVerde ? Tema.verdeEscuro : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: sobreVerde ? null : Border.all(color: Tema.cinzaCampo),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A senha precisa ter:',
                style: TextStyle(
                  color: corTexto,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4.0),
              for (final requisito in requisitos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        requisito.atendido
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: requisito.atendido
                            ? (sobreVerde ? Colors.white : Tema.verdeEscuro)
                            : (sobreVerde ? Colors.white70 : Colors.grey),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          requisito.texto,
                          style: TextStyle(color: corTexto, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
