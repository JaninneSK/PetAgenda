import 'package:flutter/material.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/login_page.dart';
import 'package:petagenda/widgets/logo_petagenda.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  static const nomeRota = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: a tela é reconstruída sempre que a sessão mudar
    final sessao = context.watch<SessaoNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoPetAgenda(altura: 30),
            const SizedBox(width: 8.0),
            const Text('PetAgenda'),
          ],
        ),
      ),
      drawer: _construirMenu(context, sessao),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Olá, ${sessao.nome}!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Login funcionando. Nos próximos passos esta tela vai mostrar '
                'o calendário e os seus pets.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirMenu(BuildContext context, SessaoNotifier sessao) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(color: Tema.verde),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const LogoPetAgenda(altura: 48),
                const SizedBox(height: 8.0),
                Text(
                  sessao.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  sessao.email,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          // As telas abaixo serão criadas nos próximos passos
          _itemMenu(context, Icons.pets, 'Meus pets'),
          _itemMenu(context, Icons.add_circle_outline, 'Cadastrar pet'),
          _itemMenu(context, Icons.event, 'Agendamentos'),
          _itemMenu(context, Icons.edit_calendar, 'Novo agendamento'),
          _itemMenu(context, Icons.account_circle, 'Minha conta'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              await AuthService().sair();
              if (!context.mounted) return;
              // Volta para o login e limpa a pilha de telas
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginPage.nomeRota,
                (rota) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _itemMenu(BuildContext context, IconData icone, String titulo) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      onTap: () {
        Navigator.pop(context); // fecha o menu
        // TODO: navegar para a tela correspondente (próximos passos)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$titulo" será criado no próximo passo.')),
        );
      },
    );
  }
}
