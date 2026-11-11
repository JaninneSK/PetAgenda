import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Estado global da sessão: quem é o usuário logado.
/// Qualquer tela pode ler o uid com context.watch<SessaoNotifier>().usuarioId
/// (é ele que vai identificar os dados do usuário no Firestore).
class SessaoNotifier extends ChangeNotifier {
  User? _usuario;
  StreamSubscription<User?>? _assinatura;

  SessaoNotifier() {
    _usuario = FirebaseAuth.instance.currentUser;
    // userChanges avisa quando o usuário entra, sai ou muda o perfil (ex: nome)
    _assinatura = FirebaseAuth.instance.userChanges().listen((usuario) {
      _usuario = usuario;
      notifyListeners(); // Notifica todas as telas conectadas!
    });
  }

  bool get logado => _usuario != null;
  String? get usuarioId => _usuario?.uid;
  String get nome => _usuario?.displayName ?? '';
  String get email => _usuario?.email ?? '';

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }
}
