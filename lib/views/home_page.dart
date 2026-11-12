import 'package:flutter/material.dart';
import 'package:petagenda/models/agendamento.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/agendamento_service.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/views/cadastrar_agendamento.dart';
import 'package:petagenda/views/cadastrar_pet.dart';
import 'package:petagenda/views/detalhes_pet.dart';
import 'package:petagenda/views/listar_agendamentos.dart';
import 'package:petagenda/views/login_page.dart';
import 'package:petagenda/views/meus_pets.dart';
import 'package:petagenda/widgets/avatar_pet.dart';
import 'package:petagenda/widgets/cartao_agendamento.dart';
import 'package:petagenda/widgets/logo_petagenda.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  static const nomeRota = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AgendamentoService? _agendamentoService;
  Stream<List<Pet>>? _streamPets;
  Stream<List<Agendamento>>? _streamAgendamentos;

  DateTime _diaFoco = DateTime.now(); // mês que o calendário está mostrando
  DateTime? _diaSelecionado; // dia tocado no calendário (null = nenhum)

  // Um controlador para cada coluna (no modo de duas colunas),
  // necessários para mostrar a barra de rolagem
  final _rolagemEsquerda = ScrollController();
  final _rolagemDireita = ScrollController();

  @override
  void dispose() {
    _rolagemEsquerda.dispose();
    _rolagemDireita.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_agendamentoService != null) return;
    // O uid do usuário logado vem do Provider
    final usuarioId = context.read<SessaoNotifier>().usuarioId!;
    _agendamentoService = AgendamentoService(usuarioId);
    _streamAgendamentos = _agendamentoService!.listar();
    _streamPets = PetService(usuarioId).listar();
  }

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          CadastrarAgendamento.nomeRota,
          arguments: Agendamento(), // um agendamento novo (sem id)
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
      ),
      // Se a sessão já foi encerrada, não escuta mais o Firestore
      body: !sessao.logado
          ? const SizedBox.shrink()
          : StreamBuilder<List<Pet>>(
        stream: _streamPets,
        builder: (context, snapshotPets) {
          return StreamBuilder<List<Agendamento>>(
            stream: _streamAgendamentos,
            builder: (context, snapshot) {
              if (snapshot.hasError || snapshotPets.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar os dados: '
                    '${snapshot.error ?? snapshotPets.error}',
                  ),
                );
              }
              if (!snapshot.hasData || !snapshotPets.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _construirConteudo(
                sessao,
                snapshotPets.data!,
                snapshot.data!,
              );
            },
          );
        },
      ),
    );
  }

  // Dia -> número único (ex: 20261124), usado como chave dos agrupamentos
  int _chave(DateTime dia) => dia.year * 10000 + dia.month * 100 + dia.day;

  Widget _construirConteudo(
    SessaoNotifier sessao,
    List<Pet> pets,
    List<Agendamento> agendamentos,
  ) {
    final mapaPets = {
      for (final p in pets)
        if (p.id != null) p.id!: p,
    };

    // Agrupa os agendamentos por dia (a lista já vem em ordem de data/hora)
    final porDia = <int, List<Agendamento>>{};
    for (final a in agendamentos) {
      if (a.dataHora == null) continue;
      porDia.putIfAbsent(_chave(a.dataHora!), () => []).add(a);
    }

    final saudacao = Text(
      'Olá, ${sessao.nome}!',
      style: Theme.of(context).textTheme.titleLarge,
    );
    final lista = _construirListaAgendamentos(agendamentos, porDia, mapaPets);
    final secaoPets = _construirSecaoPets(pets);

    // espaço extra embaixo para o botão flutuante não cobrir o último item
    const margem = EdgeInsets.fromLTRB(16, 16, 16, 88);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Pouca altura (celular deitado): o calendário usa linhas mais baixas.
        // Em tablet a altura é grande e ele mantém o tamanho normal.
        final calendario = _construirCalendario(
          porDia,
          compacto: constraints.maxHeight < 500,
        );

        // Tablet (ou celular deitado): duas colunas lado a lado
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Scrollbar(
                  controller: _rolagemEsquerda,
                  thumbVisibility: true, // barra sempre visível: mostra que rola
                  child: SingleChildScrollView(
                    controller: _rolagemEsquerda,
                    padding: margem,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        saudacao,
                        const SizedBox(height: 12.0),
                        calendario,
                        const SizedBox(height: 16.0),
                        lista,
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Scrollbar(
                  controller: _rolagemDireita,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _rolagemDireita,
                    padding: margem,
                    child: secaoPets,
                  ),
                ),
              ),
            ],
          );
        }

        // Celular: uma coluna só
        return SingleChildScrollView(
          padding: margem,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              saudacao,
              const SizedBox(height: 12.0),
              calendario,
              const SizedBox(height: 16.0),
              lista,
              const SizedBox(height: 24.0),
              secaoPets,
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Calendário (TableCalendar): marca os dias que têm agendamento pendente
  // ---------------------------------------------------------------------
  Widget _construirCalendario(
    Map<int, List<Agendamento>> porDia, {
    required bool compacto,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<Agendamento>(
          locale: 'pt_BR',
          firstDay: DateTime(hoje().year - 1, 1, 1),
          lastDay: DateTime(hoje().year + 5, 12, 31),
          focusedDay: _diaFoco,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          // Só o arrasto para os lados troca de mês. O padrão (all) também
          // captura o arrasto vertical e impedia a tela de rolar.
          availableGestures: AvailableGestures.horizontalSwipe,
          rowHeight: compacto ? 40 : 52,
          daysOfWeekHeight: 24, // o padrão (16) cortava a letra "g" de "seg."
          availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Tema.laranjaClaro,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: Tema.textoEscuro),
            selectedDecoration: BoxDecoration(
              color: Tema.verdeEscuro,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Tema.laranja,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          selectedDayPredicate: (dia) => isSameDay(_diaSelecionado, dia),
          // Os "pontinhos" laranja: só agendamentos ainda pendentes
          eventLoader: (dia) => (porDia[_chave(dia)] ?? [])
              .where((a) => !a.realizado)
              .toList(),
          onDaySelected: (selecionado, foco) {
            setState(() {
              // tocar de novo no mesmo dia tira a seleção
              _diaSelecionado = isSameDay(_diaSelecionado, selecionado)
                  ? null
                  : selecionado;
              _diaFoco = foco;
            });
          },
          onPageChanged: (foco) {
            _diaFoco = foco; // trocou de mês
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Lista: agendamentos do dia tocado ou, sem dia escolhido, os próximos
  // ---------------------------------------------------------------------
  Widget _construirListaAgendamentos(
    List<Agendamento> todos,
    Map<int, List<Agendamento>> porDia,
    Map<String, Pet> pets,
  ) {
    final dia = _diaSelecionado;
    final List<Agendamento> itens;
    final String titulo;
    if (dia != null) {
      itens = porDia[_chave(dia)] ?? [];
      titulo = 'Agendamentos de ${formatarData(dia)}';
    } else {
      // pendentes em ordem de data (os atrasados aparecem primeiro, em vermelho)
      itens = todos.where((a) => !a.realizado).take(5).toList();
      titulo = 'Próximos agendamentos';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (dia != null)
              TextButton(
                onPressed: () => setState(() => _diaSelecionado = null),
                child: const Text('Limpar'),
              )
            else
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, ListarAgendamentos.nomeRota),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        if (itens.isEmpty) ...[
          Text(
            dia != null
                ? 'Nenhum agendamento neste dia.'
                : 'Nenhum agendamento pendente.',
          ),
          // Só dá para agendar hoje ou em dias futuros
          if (dia == null || !dia.isBefore(hoje()))
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                CadastrarAgendamento.nomeRota,
                // já com o dia tocado no calendário (se houver)
                arguments: Agendamento()..dataHora = dia,
              ),
              icon: const Icon(Icons.add),
              label: Text(
                dia != null ? 'Agendar neste dia' : 'Novo agendamento',
              ),
            ),
        ],
        for (final a in itens)
          CartaoAgendamento(
            agendamento: a,
            pet: pets[a.petId],
            onRealizadoChanged: (valor) => _alterarRealizado(a, valor),
            onTap: () => Navigator.pushNamed(
              context,
              CadastrarAgendamento.nomeRota,
              arguments: a,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Meus pets
  // ---------------------------------------------------------------------
  Widget _construirSecaoPets(List<Pet> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Meus pets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (pets.isNotEmpty)
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, MeusPets.nomeRota),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        if (pets.isEmpty) ...[
          const Text('Você ainda não cadastrou nenhum pet.'),
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, CadastrarPet.nomeRota),
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar pet'),
          ),
        ],
        for (final pet in pets)
          Card(
            child: ListTile(
              key: ValueKey(pet.id),
              leading: AvatarPet(foto: pet.foto, raio: 24),
              title: Text(
                pet.nome ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(resumoPet(pet)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                DetalhesPet.nomeRota,
                arguments: pet,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _alterarRealizado(Agendamento agendamento, bool valor) async {
    try {
      await _agendamentoService!.alterarRealizado(agendamento.id!, valor);
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Não foi possível atualizar: $erro', erro: true);
    }
  }

  // ---------------------------------------------------------------------
  // Menu lateral
  // ---------------------------------------------------------------------
  Widget _construirMenu(BuildContext context, SessaoNotifier sessao) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cabeçalho sem altura fixa: acompanha o conteúdo e não estoura
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
              // Primeiro vai para o login (isso encerra as telas que escutam o
              // Firestore) e só depois encerra a sessão, evitando erros de permissão.
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginPage.nomeRota,
                (rota) => false,
              );
              await AuthService().sair();
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
