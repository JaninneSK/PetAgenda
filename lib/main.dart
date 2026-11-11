import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:petagenda/firebase_options.dart'; // gerado pelo comando "flutterfire configure"
import 'package:petagenda/myapp.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // Necessário antes de usar o Firebase antes do runApp()
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // Estado global: quem é o usuário logado (uid, nome, e-mail)
        ChangeNotifierProvider(create: (_) => SessaoNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}
