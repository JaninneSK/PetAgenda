import 'package:flutter/material.dart';

enum TiposCuidado {
  vacina('Vacina', Icons.vaccines),
  consulta('Consulta', Icons.local_hospital),
  medicamento('Medicamento', Icons.medication),
  banho('Banho', Icons.bathtub),
  tosa('Tosa', Icons.content_cut),
  outro('Outro', Icons.pets);

  final String rotulo;
  final IconData icone;
  const TiposCuidado(this.rotulo, this.icone);

  static TiposCuidado? deNome(String? nome) {
    return TiposCuidado.values.where((t) => t.name == nome).firstOrNull;
  }
}
