import 'package:flutter/material.dart';
import 'package:petagenda/models/agendamento.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/models/tipos_cuidado.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/util/tema.dart';

/// Cartão de um agendamento, usado na lista e na tela inicial.
/// Pendente com data/hora já passada fica todo em vermelho claro.
class CartaoAgendamento extends StatelessWidget {
  final Agendamento agendamento;
  final Pet? pet;
  final ValueChanged<bool>? onRealizadoChanged; // se vier, mostra o checkbox
  final VoidCallback? onExcluir; // se vier, mostra a lixeira
  final VoidCallback? onTap;

  const CartaoAgendamento({
    super.key,
    required this.agendamento,
    this.pet,
    this.onRealizadoChanged,
    this.onExcluir,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = TiposCuidado.deNome(agendamento.tipo);
    final atrasado =
        !agendamento.realizado &&
        agendamento.dataHora != null &&
        agendamento.dataHora!.isBefore(DateTime.now());

    return Card(
      color: atrasado ? Tema.fundoErro : null,
      shape: atrasado
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Tema.vermelhoErro, width: 1.5),
            )
          : null,
      child: ListTile(
        key: ValueKey(agendamento.id),
        leading: onRealizadoChanged == null
            ? null
            : Checkbox(
                value: agendamento.realizado,
                onChanged: (valor) => onRealizadoChanged!(valor ?? false),
              ),
        title: Row(
          children: [
            Icon(
              tipo?.icone ?? Icons.event,
              size: 20,
              color: atrasado ? Tema.vermelhoErro : Tema.verdeEscuro,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                agendamento.titulo ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: agendamento.realizado
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pet?.nome ?? 'Pet removido'} • ${tipo?.rotulo ?? ''}'),
            Text(
              '${formatarData(agendamento.dataHora)} às '
              '${formatarHora(agendamento.dataHora)}'
              '${atrasado ? ' • Atrasado' : ''}',
              style: TextStyle(
                color: atrasado ? Tema.vermelhoErro : null,
                fontWeight: atrasado ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: onExcluir == null
            ? null
            : IconButton(
                tooltip: 'Excluir agendamento',
                icon: const Icon(Icons.delete_outline),
                onPressed: onExcluir,
              ),
        onTap: onTap,
      ),
    );
  }
}
