import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petagenda/models/agendamento.dart';

/// CRUD dos agendamentos do usuário logado.
/// Os dados ficam em: usuarios/{uid}/agendamentos
class AgendamentoService {
  final String usuarioId;
  late CollectionReference<Map<String, dynamic>> _agendamentos;

  AgendamentoService(this.usuarioId) {
    _agendamentos = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuarioId)
        .collection('agendamentos');
  }

  // READ: em tempo real, do mais próximo ao mais distante
  Stream<List<Agendamento>> listar() {
    return _agendamentos.orderBy('dataHora').snapshots().map((resultado) {
      return resultado.docs
          .map((doc) => Agendamento.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  // CREATE
  Future<void> inserir(Agendamento agendamento) async {
    final dados = agendamento.toMap();
    dados['criadoEm'] = FieldValue.serverTimestamp();
    await _agendamentos.add(dados);
  }

  // UPDATE
  Future<void> atualizar(Agendamento agendamento) {
    return _agendamentos.doc(agendamento.id).update(agendamento.toMap());
  }

  // UPDATE de um único campo (marcar / desmarcar como realizado)
  Future<void> alterarRealizado(String id, bool realizado) {
    return _agendamentos.doc(id).update({'realizado': realizado});
  }

  // DELETE
  Future<void> excluir(String id) {
    return _agendamentos.doc(id).delete();
  }
}
