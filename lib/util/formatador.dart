import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';
import 'package:petagenda/models/especies.dart';
import 'package:petagenda/models/pet.dart';

final DateFormat _formatoData = DateFormat('dd/MM/yyyy');

/// DateTime -> "dd/MM/yyyy" (texto vazio se a data for nula)
String formatarData(DateTime? data) {
  if (data == null) return '';
  return _formatoData.format(data);
}

/// "dd/MM/yyyy" -> DateTime (null se o texto estiver vazio ou for inválido)
DateTime? lerData(String? texto) {
  if (texto == null || texto.trim().isEmpty) return null;
  try {
    return _formatoData.parseStrict(texto.trim());
  } on FormatException {
    return null;
  }
}

/// DateTime -> "HH:mm" (texto vazio se for nulo)
String formatarHora(DateTime? data) {
  if (data == null) return '';
  return DateFormat('HH:mm').format(data);
}

/// TimeOfDay (do seletor de horário) -> "HH:mm"
String formatarTimeOfDay(TimeOfDay hora) {
  final h = hora.hour.toString().padLeft(2, '0');
  final m = hora.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// "HH:mm" -> TimeOfDay (null se vazio ou inválido, ex: 25:00)
TimeOfDay? lerHora(String? texto) {
  final resultado = RegExp(
    r'^([01]\d|2[0-3]):([0-5]\d)$',
  ).firstMatch(texto?.trim() ?? '');
  if (resultado == null) return null;
  return TimeOfDay(
    hour: int.parse(resultado.group(1)!),
    minute: int.parse(resultado.group(2)!),
  );
}

/// Data de hoje sem a hora (00:00), para comparar apenas o dia
DateTime hoje() {
  final agora = DateTime.now();
  return DateTime(agora.year, agora.month, agora.day);
}

String calcularIdade(DateTime nascimento) {
  final agora = DateTime.now();
  int anos = agora.year - nascimento.year;
  int meses = agora.month - nascimento.month;
  if (agora.day < nascimento.day) meses--;
  if (meses < 0) {
    anos--;
    meses += 12;
  }
  if (anos > 0) return anos == 1 ? '1 ano' : '$anos anos';
  if (meses <= 0) return 'menos de 1 mês';
  return meses == 1 ? '1 mês' : '$meses meses';
}

String formatarPeso(double? peso) {
  if (peso == null) return '';
  final texto = peso == peso.roundToDouble()
      ? peso.toStringAsFixed(0)
      : peso.toString().replaceAll('.', ',');
  return '$texto kg';
}

/// Texto curto para listas: "Gato • Siamês • 2 anos"
String resumoPet(Pet pet) {
  final partes = <String>[];
  final especie = Especies.deNome(pet.especie);
  if (especie != null) partes.add(especie.rotulo);
  if (pet.raca != null && pet.raca!.isNotEmpty) partes.add(pet.raca!);
  if (pet.dataNascimento != null) {
    partes.add(calcularIdade(pet.dataNascimento!));
  }
  return partes.join(' • ');
}
