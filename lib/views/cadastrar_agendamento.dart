import 'package:flutter/material.dart';
import 'package:petagenda/models/agendamento.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/models/tipos_cuidado.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/agendamento_service.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/views/cadastrar_pet.dart';
import 'package:petagenda/widgets/campo_data.dart';
import 'package:petagenda/widgets/campo_horario.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';
import 'package:provider/provider.dart';

/// Recebe um Agendamento como argumento da rota (ou nada):
/// - sem id: cadastro de um agendamento novo (pode vir com o petId já escolhido)
/// - com id: edição de um agendamento existente
class CadastrarAgendamento extends StatefulWidget {
  static const nomeRota = "/cadastraragendamento";

  const CadastrarAgendamento({super.key});

  @override
  State<CadastrarAgendamento> createState() => _CadastrarAgendamentoState();
}

class _CadastrarAgendamentoState extends State<CadastrarAgendamento> {
  final _formKey = GlobalKey<FormState>();
  AgendamentoService? _agendamentoService;
  Stream<List<Pet>>? _streamPets;

  Agendamento _agendamento = Agendamento();
  String? _petId;
  String? _tipo;
  bool _realizado = false;
  bool _carregado = false;
  bool _salvando = false;

  final controllerTitulo = TextEditingController();
  final controllerDescricao = TextEditingController();
  final controllerData = TextEditingController();
  final controllerHorario = TextEditingController();

  bool get _novo => _agendamento.id == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só prepara a tela na primeira vez
    if (_carregado) return;
    _carregado = true;

    final usuarioId = context.read<SessaoNotifier>().usuarioId!;
    _agendamentoService = AgendamentoService(usuarioId);
    _streamPets = PetService(usuarioId).listar();

    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is Agendamento) {
      _agendamento = argumento;
      _petId = argumento.petId; // pode vir escolhido (ex: da tela do pet)
      if (!_novo) {
        // modo edição: preenche o formulário
        controllerTitulo.text = argumento.titulo ?? '';
        controllerDescricao.text = argumento.descricao ?? '';
        controllerData.text = formatarData(argumento.dataHora);
        controllerHorario.text = formatarHora(argumento.dataHora);
        _tipo = argumento.tipo;
        _realizado = argumento.realizado;
      }
    }
    if (_novo) {
      controllerData.text = formatarData(hoje()); // sugere a data de hoje
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    controllerTitulo.dispose();
    controllerDescricao.dispose();
    controllerData.dispose();
    controllerHorario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_novo ? 'Novo agendamento' : 'Editar agendamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ConteudoCentralizado(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: _construirFormulario(),
          ),
        ),
      ),
    );
  }

  Widget _construirFormulario() {
    final itensTipo = TiposCuidado.values
        .map(
          (t) => DropdownMenuItem(
            value: t.name,
            child: Row(
              children: [
                Icon(t.icone, size: 20, color: Tema.verdeEscuro),
                const SizedBox(width: 8.0),
                Text(t.rotulo),
              ],
            ),
          ),
        )
        .toList();

    return Column(
      children: <Widget>[
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controllerTitulo,
          validator: Validador.validarTitulo(),
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Ex: Vacina antirrábica',
          ),
          maxLength: 40,
        ),

        _construirSelecaoPet(),
        const SizedBox(height: 16.0),

        DropdownButtonFormField<String>(
          items: itensTipo,
          validator: Validador.validarSelecao('o tipo de cuidado'),
          decoration: const InputDecoration(labelText: 'Tipo de cuidado'),
          initialValue: _tipo,
          onChanged: (String? novoValor) {
            setState(() {
              _tipo = novoValor;
            });
          },
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerDescricao,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descrição (opcional)',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          maxLength: 200,
        ),

        CampoData(
          controller: controllerData,
          rotulo: 'Data',
          validador: Validador.validarDataAgendamento(novo: _novo),
          primeiraData: _novo ? hoje() : DateTime(hoje().year - 5),
          ultimaData: DateTime(hoje().year + 5),
        ),
        const SizedBox(height: 16.0),

        CampoHorario(
          controller: controllerHorario,
          rotulo: 'Horário',
          validador: Validador.validarHorario(controllerData, novo: _novo),
        ),
        const SizedBox(height: 16.0),

        // "Marcar como realizado": só na edição
        if (!_novo) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _realizado
                  ? Tema.verdeEscuro
                  : Colors.grey.shade700,
              minimumSize: const Size(200, 48),
              shape: const StadiumBorder(),
            ),
            onPressed: () => setState(() => _realizado = !_realizado),
            icon: Icon(
              _realizado ? Icons.check_circle : Icons.radio_button_unchecked,
            ),
            label: Text(
              _realizado
                  ? 'REALIZADO (toque para desfazer)'
                  : 'MARCAR COMO REALIZADO',
            ),
          ),
          const SizedBox(height: 12.0),
        ],

        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: Text(
            _salvando ? 'SALVANDO...' : (_novo ? 'AGENDAR' : 'SALVAR'),
          ),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  // Lista de pets do usuário no dropdown (vem do Firestore em tempo real)
  Widget _construirSelecaoPet() {
    return StreamBuilder<List<Pet>>(
      stream: _streamPets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erro ao carregar os pets: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final pets = snapshot.data!;
        if (pets.isEmpty) {
          // Sem pets não dá para agendar: leva o usuário a cadastrar um
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Você ainda não tem pets cadastrados.\n'
                    'Cadastre um pet para criar agendamentos.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, CadastrarPet.nomeRota),
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar pet'),
                  ),
                ],
              ),
            ),
          );
        }

        // se o pet escolhido não existe mais, nenhuma opção fica selecionada
        final valorInicial = pets.any((p) => p.id == _petId) ? _petId : null;

        return DropdownButtonFormField<String>(
          isExpanded: true,
          items: pets
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome ?? '')))
              .toList(),
          validator: Validador.validarSelecao('o pet'),
          decoration: const InputDecoration(labelText: 'Pet'),
          initialValue: valorInicial,
          onChanged: (String? novoValor) {
            setState(() {
              _petId = novoValor;
            });
          },
        );
      },
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return; // erro de validação: as mensagens já aparecem nos campos
    }

    setState(() => _salvando = true);
    try {
      // Junta a data e o horário em um único DateTime
      final data = lerData(controllerData.text)!;
      final hora = lerHora(controllerHorario.text)!;
      final descricao = controllerDescricao.text.trim();

      final agendamento = Agendamento.comParametros(
        id: _agendamento.id, // nulo no cadastro, preenchido na edição
        titulo: controllerTitulo.text.trim(),
        petId: _petId,
        tipo: _tipo,
        descricao: descricao.isEmpty ? null : descricao,
        dataHora: DateTime(data.year, data.month, data.day, hora.hour, hora.minute),
        realizado: _realizado,
      );

      if (agendamento.id == null) {
        await _agendamentoService!.inserir(agendamento);
      } else {
        await _agendamentoService!.atualizar(agendamento);
      }

      if (!mounted) return;
      await _dialogBox();
      if (!mounted) return;
      Navigator.pop(context); // volta para a tela anterior
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Erro ao salvar o agendamento: $erro', erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _dialogBox() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Agendamento'),
          content: const Text('Agendamento salvo com sucesso!'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }
}
