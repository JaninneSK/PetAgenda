import 'package:flutter/material.dart';
import 'package:petagenda/models/agendamento.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/models/tipos_cuidado.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/agendamento_service.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/cadastrar_agendamento.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';
import 'package:provider/provider.dart';

class ListarAgendamentos extends StatefulWidget {
  static const nomeRota = '/agendamentos';

  const ListarAgendamentos({super.key});

  @override
  State<ListarAgendamentos> createState() => _ListarAgendamentosState();
}

class _ListarAgendamentosState extends State<ListarAgendamentos> {
  AgendamentoService? _agendamentoService;
  Stream<List<Pet>>? _streamPets;
  Stream<List<Agendamento>>? _streamAgendamentos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_agendamentoService != null) return;
    // O uid do usuário logado vem do Provider
    final usuarioId = context.read<SessaoNotifier>().usuarioId!;
    _agendamentoService = AgendamentoService(usuarioId);
    _streamAgendamentos = _agendamentoService!.listar();
    // Os pets são necessários para mostrar o nome do pet em cada agendamento
    _streamPets = PetService(usuarioId).listar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          CadastrarAgendamento.nomeRota,
          arguments: Agendamento(), // um agendamento novo (sem id)
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo agendamento'),
      ),
      body: StreamBuilder<List<Pet>>(
        stream: _streamPets,
        builder: (context, snapshotPets) {
          return StreamBuilder<List<Agendamento>>(
            stream: _streamAgendamentos,
            builder: (context, snapshot) {
              if (snapshot.hasError || snapshotPets.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar os agendamentos: '
                    '${snapshot.error ?? snapshotPets.error}',
                  ),
                );
              }
              if (!snapshot.hasData || !snapshotPets.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // id do pet -> pet, para achar o nome rapidamente
              final pets = {
                for (final p in snapshotPets.data!)
                  if (p.id != null) p.id!: p,
              };
              return _construirLista(snapshot.data!, pets);
            },
          );
        },
      ),
    );
  }

  Widget _construirLista(List<Agendamento> todos, Map<String, Pet> pets) {
    if (todos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum agendamento ainda.\n'
            'Toque em "Novo agendamento" para começar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // A lista já vem em ordem de data (mais próximo primeiro)
    final pendentes = todos.where((a) => !a.realizado).toList();
    final realizados = todos.where((a) => a.realizado).toList().reversed.toList();

    return ConteudoCentralizado(
      child: ListView(
        // espaço extra embaixo para o botão flutuante não cobrir o último item
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          if (pendentes.isNotEmpty) ...[
            _titulo('Pendentes'),
            for (final a in pendentes) _item(a, pets),
          ],
          if (realizados.isNotEmpty) ...[
            _titulo('Realizados'),
            for (final a in realizados) _item(a, pets),
          ],
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _item(Agendamento agendamento, Map<String, Pet> pets) {
    final pet = pets[agendamento.petId];
    final tipo = TiposCuidado.deNome(agendamento.tipo);
    final atrasado =
        !agendamento.realizado &&
        agendamento.dataHora != null &&
        agendamento.dataHora!.isBefore(DateTime.now());

    return Card(
      child: ListTile(
        key: ValueKey(agendamento.id),
        // Marcar / desmarcar como realizado direto na lista
        leading: Checkbox(
          value: agendamento.realizado,
          onChanged: (valor) => _alterarRealizado(agendamento, valor ?? false),
        ),
        title: Row(
          children: [
            Icon(tipo?.icone ?? Icons.event, size: 20, color: Tema.verdeEscuro),
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
        trailing: IconButton(
          tooltip: 'Excluir agendamento',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _excluir(agendamento),
        ),
        // Tocar no item abre a edição
        onTap: () => Navigator.pushNamed(
          context,
          CadastrarAgendamento.nomeRota,
          arguments: agendamento,
        ),
      ),
    );
  }

  Future<void> _alterarRealizado(Agendamento agendamento, bool valor) async {
    try {
      await _agendamentoService!.alterarRealizado(agendamento.id!, valor);
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Não foi possível atualizar: $erro', erro: true);
    }
  }

  Future<void> _excluir(Agendamento agendamento) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir agendamento'),
          content: Text('Deseja excluir "${agendamento.titulo}"?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Tema.vermelhoErro),
              child: const Text('Excluir'),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );
    if (confirmou != true) return;

    try {
      await _agendamentoService!.excluir(agendamento.id!);
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Não foi possível excluir: $erro', erro: true);
    }
  }
}
