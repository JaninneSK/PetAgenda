import 'package:firebase_auth/firebase_auth.dart';

/// Traduz os códigos de erro do Firebase Authentication para mensagens
/// que o usuário entende.
String mensagemErroAuth(FirebaseAuthException erro) {
  switch (erro.code) {
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'weak-password':
      return 'Senha muito fraca. Use pelo menos 6 caracteres.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-mail ou senha incorretos.';
    case 'user-disabled':
      return 'Esta conta foi desativada.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    default:
      return 'Não foi possível concluir (${erro.code}). Tente novamente.';
  }
}
