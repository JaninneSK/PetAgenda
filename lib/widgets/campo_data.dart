import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:petagenda/util/formatador.dart';

/// Campo de data com máscara dd/MM/aaaa e botão que abre o calendário
class CampoData extends StatelessWidget {
  final TextEditingController controller;
  final String rotulo;
  final FormFieldValidator<String> validador;
  final DateTime primeiraData;
  final DateTime ultimaData;

  const CampoData({
    super.key,
    required this.controller,
    required this.rotulo,
    required this.validador,
    required this.primeiraData,
    required this.ultimaData,
  });

  Future<void> _escolherData(BuildContext context) async {
    // a data inicial do calendário precisa estar dentro do intervalo permitido
    DateTime inicial = lerData(controller.text) ?? hoje();
    if (inicial.isBefore(primeiraData)) inicial = primeiraData;
    if (inicial.isAfter(ultimaData)) inicial = ultimaData;

    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeiraData,
      lastDate: ultimaData,
    );
    if (escolhida != null) {
      controller.text = formatarData(escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    var maskFormatterData = MaskTextInputFormatter(
      mask: '##/##/####',
      type: MaskAutoCompletionType.lazy,
    );

    return TextFormField(
      controller: controller,
      validator: validador,
      keyboardType: TextInputType.datetime,
      inputFormatters: [maskFormatterData],
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: 'dd/MM/aaaa',
        suffixIcon: IconButton(
          tooltip: 'Escolher no calendário',
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _escolherData(context),
        ),
      ),
    );
  }
}
