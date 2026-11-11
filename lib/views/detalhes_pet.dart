import 'package:flutter/material.dart';
import 'package:petagenda/models/agendamento.dart';
import 'package:petagenda/models/especies.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/models/portes.dart';
import 'package:petagenda/models/sexos.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/cadastrar_agendamento.dart';
import 'package:petagenda/views/cadastrar_pet.dart';
import 'package:petagenda/widgets/avatar_pet.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';
import 'package:provider/provider.dart';

class DetalhesPet extends StatefulWidget {
  static const nomeRota = '/detalhespet';

  const DetalhesPet({super.key});

  @override
  State<DetalhesPet> createState() => _DetalhesPetState();
}

class _DetalhesPetState extends State<DetalhesPet> {
  PetService? _petService;
  Pet? _petRecebido;
  Stream<Pet?>? _streamPet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_petRecebido != null) return;

    _petRecebido = ModalRoute.of(context)!.settings.arguments as Pet;
    assert(_petRecebido!.id != null, "'id' do pet é nulo");

    final usuarioId = context.read<SessaoNotifier>().usuarioId!;
    _petService = PetService(usuarioId);
    // Acompanha o pet em tempo real: depois de editar, esta tela se atualiza sozinha
    _streamPet = _petService!.observar(_petRecebido!.id!);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pet?>(
      stream: _streamPet,
      builder: (context, snapshot) {
        final pet = snapshot.data ?? _petRecebido!;

        return Scaffold(
          appBar: AppBar(title: Text(pet.nome ?? 'Pet')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConteudoCentralizado(child: _construirConteudo(pet)),
          ),
        );
      },
    );
  }

  Widget _construirConteudo(Pet pet) {
    final nascimento = pet.dataNascimento == null
        ? ''
        : '${formatarData(pet.dataNascimento)} (${calcularIdade(pet.dataNascimento!)})';

    return Column(
      children: [
        AvatarPet(foto: pet.foto, raio: 64),
        const SizedBox(height: 12.0),
        Text(
          pet.nome ?? '',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),

        _info(Icons.pets, 'Espécie', Especies.deNome(pet.especie)?.rotulo),
        _info(Icons.badge, 'Raça', pet.raca),
        _info(Icons.wc, 'Sexo', Sexos.deNome(pet.sexo)?.rotulo),
        _info(Icons.cake, 'Nascimento', nascimento),
        _info(Icons.straighten, 'Porte', Portes.deNome(pet.porte)?.rotulo),
        _info(Icons.monitor_weight, 'Peso atual', formatarPeso(pet.peso)),
        _info(Icons.notes, 'Mais informações', pet.observacoes),

        const SizedBox(height: 24.0),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            CadastrarAgendamento.nomeRota,
            // um agendamento novo, já com este pet escolhido
            arguments: Agendamento()..petId = pet.id,
          ),
          icon: const Icon(Icons.event_available),
          label: const Text('NOVO AGENDAMENTO'),
        ),
        const SizedBox(height: 8.0),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Tema.verdeEscuro,
            minimumSize: const Size(200, 48),
            shape: const StadiumBorder(),
          ),
          onPressed: () => Navigator.pushNamed(
            context,
            CadastrarPet.nomeRota,
            arguments: pet,
          ),
          icon: const Icon(Icons.edit),
          label: const Text('EDITAR PET'),
        ),
        const SizedBox(height: 8.0),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Tema.vermelhoErro),
          onPressed: () => _excluir(pet),
          icon: const Icon(Icons.delete_outline),
          label: const Text('EXCLUIR PET'),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  // Uma linha de informação. Se o valor estiver vazio, a linha não aparece.
  Widget _info(IconData icone, String titulo, String? valor) {
    if (valor == null || valor.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: Icon(icone, color: Tema.verdeEscuro),
        title: Text(titulo),
        subtitle: Text(valor, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _excluir(Pet pet) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir pet'),
          content: Text(
            'Deseja realmente excluir ${pet.nome}? '
            'Os agendamentos dele também serão excluídos.',
          ),
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
      await _petService!.excluir(pet.id!);
      if (!mounted) return;
      Navigator.pop(context); // volta para a lista (que já se atualiza sozinha)
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Não foi possível excluir: $erro', erro: true);
    }
  }
}
