import 'package:flutter/material.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/cadastrar_agendamento.dart';
import 'package:petagenda/views/cadastrar_pet.dart';
import 'package:petagenda/views/listar_agendamentos.dart';
import 'package:petagenda/views/login_page.dart';
import 'package:petagenda/views/meus_pets.dart';
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
                'Use o menu para cadastrar e ver seus pets. Nos próximos passos '
                'esta tela vai mostrar o calendário e os agendamentos.',
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
          // Cabeçalho sem altura fixa: acompanha o conteúdo e não estoura.
          // (O DrawerHeader tem altura fixa e causava "bottom overflowed".)
          Container(
            width: double.infinity,
            color: Tema.verde,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 16, // abaixo da barra de status
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LogoPetAgenda(altura: 48),
                const SizedBox(height: 8.0),
                Text(
                  sessao.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  sessao.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          _itemMenu(context, Icons.pets, 'Meus pets', MeusPets.nomeRota),
          _itemMenu(
            context,
            Icons.add_circle_outline,
            'Cadastrar pet',
            CadastrarPet.nomeRota,
          ),
          _itemMenu(
            context,
            Icons.event,
            'Agendamentos',
            ListarAgendamentos.nomeRota,
          ),
          _itemMenu(
            context,
            Icons.edit_calendar,
            'Novo agendamento',
            CadastrarAgendamento.nomeRota,
          ),
          // A tela abaixo será criada nos próximos passos
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

  // Se vier uma rota, navega para ela; se não, avisa que a tela ainda não existe.
  Widget _itemMenu(
    BuildContext context,
    IconData icone,
    String titulo, [
    String? rota,
  ]) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      onTap: () {
        Navigator.pop(context); // fecha o menu
        if (rota != null) {
          Navigator.pushNamed(context, rota);
        } else {
          // TODO: navegar para a tela correspondente (próximos passos)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$titulo" será criado no próximo passo.')),
          );
        }
      },
    );
  }
}
