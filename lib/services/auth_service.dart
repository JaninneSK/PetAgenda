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

  /// true se a conta entra com e-mail e senha
  /// (contas do Google, no futuro, não têm senha para alterar)
  bool get temSenha {
    final usuario = _auth.currentUser;
    if (usuario == null) return false;
    return usuario.providerData.any((info) => info.providerId == 'password');
  }

  /// Operações sensíveis (alterar senha, excluir conta) exigem um login recente.
  /// Por isso confirmamos a senha atual antes de executá-las.
  Future<void> _reautenticar(String senhaAtual) async {
    final usuario = _auth.currentUser!;
    final credencial = EmailAuthProvider.credential(
      email: usuario.email!,
      password: senhaAtual,
    );
    await usuario.reauthenticateWithCredential(credencial);
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    await _reautenticar(senhaAtual);
    await _auth.currentUser!.updatePassword(novaSenha);
  }

  /// Atualiza o nome no Authentication e nome, login e foto no Firestore
  Future<void> atualizarPerfil({
    required String nome,
    required String apelido,
    String? foto,
  }) async {
    final usuario = _auth.currentUser!;
    if (usuario.displayName != nome) {
      await usuario.updateDisplayName(nome);
    }
    await _usuarioService.atualizar(
      usuario.uid,
      nome: nome,
      apelido: apelido,
      foto: foto,
    );
  }

  /// Confirma a senha, apaga os dados do Firestore e, por último, a conta.
  /// (Se a senha estiver errada, nada é apagado.)
  Future<void> excluirConta(String senhaAtual) async {
    await _reautenticar(senhaAtual);
    final usuario = _auth.currentUser!;
    await _usuarioService.excluirDados(usuario.uid);
    await usuario.delete();
  }
}
