import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/cadastro_usuario.dart';
import 'package:petagenda/views/home_page.dart';
import 'package:petagenda/views/login_page.dart';
import 'package:petagenda/views/splash_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetAgenda',
      debugShowCheckedModeBanner: false,
      theme: Tema.claro,

      // Deixa os componentes do Material (calendário, botões de diálogo...) em português
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],

      initialRoute: SplashPage.nomeRota,
      routes: {
        SplashPage.nomeRota: (context) => const SplashPage(),
        LoginPage.nomeRota: (context) => const LoginPage(),
        CadastroUsuario.nomeRota: (context) => const CadastroUsuario(),
        HomePage.nomeRota: (context) => const HomePage(),
      },
    );
  }
}
