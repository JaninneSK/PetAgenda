import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petagenda/models/usuario.dart';

/// Guarda o perfil do usuário na coleção "usuarios", em um documento
/// cujo id é o próprio uid do Firebase Authentication: usuarios/{uid}
class UsuarioService {
  final CollectionReference<Map<String, dynamic>> _usuarios = FirebaseFirestore
      .instance
      .collection('usuarios');

  // CREATE
  Future<void> salvar(Usuario usuario) async {
    final dados = usuario.toMap();
    dados['criadoEm'] = FieldValue.serverTimestamp();
    await _usuarios.doc(usuario.id).set(dados);
  }

  // READ: acompanha o perfil em tempo real
  Stream<Usuario?> observar(String id) {
    return _usuarios.doc(id).snapshots().map((doc) {
      final dados = doc.data();
      if (!doc.exists || dados == null) return null;
      return Usuario.fromMap(dados, id: doc.id);
    });
  }

  // UPDATE: o merge altera só estes campos e preserva o resto do documento
  Future<void> atualizar(
    String id, {
    required String nome,
    required String apelido,
    String? foto,
  }) async {
    await _usuarios.doc(id).set({
      'nome': nome,
      'apelido': apelido,
      'foto': foto,
    }, SetOptions(merge: true));
  }

  // DELETE: apaga TUDO do usuário (pets, agendamentos e o próprio perfil).
  // O Firestore não apaga subcoleções sozinho, por isso listamos os documentos
  // e apagamos em lotes (o limite de um lote é 500 operações).
  Future<void> excluirDados(String id) async {
    final raiz = _usuarios.doc(id);

    final referencias = <DocumentReference>[];
    for (final subcolecao in ['pets', 'agendamentos']) {
      final documentos = await raiz.collection(subcolecao).get();
      referencias.addAll(documentos.docs.map((doc) => doc.reference));
    }
    referencias.add(raiz); // o perfil por último

    for (var i = 0; i < referencias.length; i += 400) {
      final lote = FirebaseFirestore.instance.batch();
      for (final referencia in referencias.skip(i).take(400)) {
        lote.delete(referencia);
      }
      await lote.commit();
    }
  }
}
