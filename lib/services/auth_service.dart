import 'package:firebase_auth/firebase_auth.dart';
import 'package:petagenda/models/usuario.dart';
import 'package:petagenda/services/usuario_service.dart';

/// Tudo o que o app faz com o Firebase Authentication (login por e-mail e senha)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UsuarioService _usuarioService = UsuarioService();

  /// Cria a conta no Authentication e guarda o perfil no Firestore.
  /// Depois de criada, a conta já fica logada.
  Future<void> cadastrar({
    required String nome,
    required String apelido,
    required String email,
    required String senha,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    final usuarioFirebase = credencial.user!;

    try {
      await usuarioFirebase.updateDisplayName(nome);
      await _usuarioService.salvar(
        Usuario.comParametros(
          id: usuarioFirebase.uid,
          nome: nome,
          apelido: apelido,
          email: email,
        ),
      );
    } catch (_) {
      // Se não deu para salvar o perfil, desfaz a criação da conta
      // para não ficar uma conta "pela metade".
      await usuarioFirebase.delete();
      rethrow;
    }
  }

  Future<void> entrar({required String email, required String senha}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sair() async {
    await _auth.signOut();
  }
}
