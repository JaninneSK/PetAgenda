import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:petagenda/util/formatador.dart';

/// Campo de horário com máscara HH:mm e botão que abre o seletor de horas
class CampoHorario extends StatelessWidget {
  final TextEditingController controller;
  final String rotulo;
  final FormFieldValidator<String> validador;

  const CampoHorario({
    super.key,
    required this.controller,
    required this.rotulo,
    required this.validador,
  });

  Future<void> _escolherHorario(BuildContext context) async {
    final escolhido = await showTimePicker(
      context: context,
      initialTime: lerHora(controller.text) ?? TimeOfDay.now(),
      // horário no formato 24 horas (14:30)
      builder: (contextoPicker, child) {
        return MediaQuery(
          data: MediaQuery.of(
            contextoPicker,
          ).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (escolhido != null) {
      controller.text = formatarTimeOfDay(escolhido);
    }
  }

  @override
  Widget build(BuildContext context) {
    var maskFormatterHora = MaskTextInputFormatter(
      mask: '##:##',
      type: MaskAutoCompletionType.lazy,
    );

    return TextFormField(
      controller: controller,
      validator: validador,
      keyboardType: TextInputType.datetime,
      inputFormatters: [maskFormatterHora],
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: 'HH:mm',
        suffixIcon: IconButton(
          tooltip: 'Escolher o horário',
          icon: const Icon(Icons.access_time),
          onPressed: () => _escolherHorario(context),
        ),
      ),
    );
  }
}
