import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petagenda/models/pet.dart';

/// CRUD dos pets do usuário logado.
/// Os dados ficam em: usuarios/{uid}/pets
class PetService {
  final String usuarioId;
  late CollectionReference<Map<String, dynamic>> _pets;

  PetService(this.usuarioId) {
    _pets = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuarioId)
        .collection('pets');
  }

  // READ: snapshots() emite uma nova lista sempre que o banco muda.
  // A ordem alfabética é feita aqui, sem diferenciar maiúsculas de minúsculas.
  Stream<List<Pet>> listar() {
    return _pets.snapshots().map((resultado) {
      final pets = resultado.docs
          .map((doc) => Pet.fromMap(doc.data(), id: doc.id))
          .toList();
      pets.sort(
        (a, b) => (a.nome ?? '').toLowerCase().compareTo(
          (b.nome ?? '').toLowerCase(),
        ),
      );
      return pets;
    });
  }

  // READ: acompanha um único pet (a tela de detalhes se atualiza após uma edição)
  Stream<Pet?> observar(String id) {
    return _pets.doc(id).snapshots().map((doc) {
      final dados = doc.data();
      if (!doc.exists || dados == null) return null;
      return Pet.fromMap(dados, id: doc.id);
    });
  }

  // CREATE
  Future<void> inserir(Pet pet) async {
    final dados = pet.toMap();
    dados['criadoEm'] = FieldValue.serverTimestamp();
    await _pets.add(dados);
  }

  // UPDATE
  Future<void> atualizar(Pet pet) {
    return _pets.doc(pet.id).update(pet.toMap());
  }

  // DELETE: apaga o pet e todos os agendamentos dele, em um único lote
  // (se a exclusão falhar, nada é apagado pela metade)
  Future<void> excluir(String id) async {
    final banco = FirebaseFirestore.instance;
    final agendamentos = await banco
        .collection('usuarios')
        .doc(usuarioId)
        .collection('agendamentos')
        .where('petId', isEqualTo: id)
        .get();

    final lote = banco.batch();
    for (final doc in agendamentos.docs) {
      lote.delete(doc.reference);
    }
    lote.delete(_pets.doc(id));
    await lote.commit();
  }
}
