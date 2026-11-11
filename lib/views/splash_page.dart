import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/home_page.dart';
import 'package:petagenda/views/login_page.dart';

class SplashPage extends StatefulWidget {
  static const nomeRota = '/splash';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    // A espera mínima de 3 segundos começa agora...
    final espera = Future.delayed(const Duration(seconds: 3));
    // ...e, ao mesmo tempo, o Firebase informa se já existe alguém logado
    // (a sessão fica guardada no aparelho).
    final usuario = await FirebaseAuth.instance.authStateChanges().first;
    await espera;

    if (!mounted) return;
    // pushReplacementNamed substitui a splash na pilha: o botão "voltar"
    // não retorna para ela.
    Navigator.pushReplacementNamed(
      context,
      usuario == null ? LoginPage.nomeRota : HomePage.nomeRota,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tema.verde,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_branca.png', width: 160),
            const SizedBox(height: 12.0),
            const Text(
              'PetAgenda',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32.0),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
