import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petagenda/models/usuario.dart';

/// Guarda o perfil do usuário na coleção "usuarios", em um documento
/// cujo id é o próprio uid do Firebase Authentication: usuarios/{uid}
class UsuarioService {
  final CollectionReference<Map<String, dynamic>> _usuarios = FirebaseFirestore
      .instance
      .collection('usuarios');

  Future<void> salvar(Usuario usuario) async {
    final dados = usuario.toMap();
    dados['criadoEm'] = FieldValue.serverTimestamp();
    await _usuarios.doc(usuario.id).set(dados);
  }
}
