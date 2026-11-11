import 'package:flutter/material.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/views/cadastrar_pet.dart';
import 'package:petagenda/views/detalhes_pet.dart';
import 'package:petagenda/widgets/avatar_pet.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';
import 'package:provider/provider.dart';

class MeusPets extends StatefulWidget {
  static const nomeRota = '/meuspets';

  const MeusPets({super.key});

  @override
  State<MeusPets> createState() => _MeusPetsState();
}

class _MeusPetsState extends State<MeusPets> {
  Stream<List<Pet>>? _streamPets;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streamPets != null) return;
    // O uid do usuário logado vem do Provider
    final usuarioId = context.read<SessaoNotifier>().usuarioId!;
    _streamPets = PetService(usuarioId).listar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, CadastrarPet.nomeRota),
        icon: const Icon(Icons.add),
        label: const Text('Novo pet'),
      ),
      body: StreamBuilder<List<Pet>>(
        stream: _streamPets,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar os pets: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pets = snapshot.data!;
          if (pets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não cadastrou nenhum pet.\n'
                  'Toque em "Novo pet" para começar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ConteudoCentralizado(
            child: ListView.builder(
              // espaço extra embaixo para o botão flutuante não cobrir o último item
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return Card(
                  child: ListTile(
                    key: ValueKey(pet.id),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: AvatarPet(foto: pet.foto, raio: 28),
                    title: Text(
                      pet.nome ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(resumoPet(pet)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      DetalhesPet.nomeRota,
                      arguments: pet,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
