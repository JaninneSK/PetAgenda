import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petagenda/models/especies.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/models/portes.dart';
import 'package:petagenda/models/sexos.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/widgets/avatar_pet.dart';
import 'package:petagenda/widgets/campo_data.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';
import 'package:provider/provider.dart';

/// Serve para cadastrar e também para editar:
/// se receber um Pet como argumento da rota, a tela abre em modo de edição.
class CadastrarPet extends StatefulWidget {
  static const nomeRota = "/cadastrarpet";

  const CadastrarPet({super.key});

  @override
  State<CadastrarPet> createState() => _CadastrarPetState();
}

class _CadastrarPetState extends State<CadastrarPet> {
  final _formKey = GlobalKey<FormState>();
  PetService? _petService;

  Pet _pet = Pet();
  String? _especie;
  String? _sexo;
  String? _porte;
  String? _foto;
  bool _carregado = false;
  bool _salvando = false;

  final controllerNome = TextEditingController();
  final controllerRaca = TextEditingController();
  final controllerNascimento = TextEditingController();
  final controllerPeso = TextEditingController();
  final controllerObservacoes = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só prepara a tela na primeira vez
    if (_carregado) return;
    _carregado = true;

    _petService = PetService(context.read<SessaoNotifier>().usuarioId!);

    // Se veio um Pet pela rota, é edição: preenche o formulário
    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is Pet) {
      _pet = argumento;
      controllerNome.text = _pet.nome ?? '';
      controllerRaca.text = _pet.raca ?? '';
      controllerNascimento.text = formatarData(_pet.dataNascimento);
      controllerPeso.text = _pet.peso?.toString().replaceAll('.', ',') ?? '';
      controllerObservacoes.text = _pet.observacoes ?? '';
      _especie = _pet.especie;
      _sexo = _pet.sexo;
      _porte = _pet.porte;
      _foto = _pet.foto;
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    controllerNome.dispose();
    controllerRaca.dispose();
    controllerNascimento.dispose();
    controllerPeso.dispose();
    controllerObservacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.id == null ? 'Cadastrar pet' : 'Editar pet'),
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
    final itensEspecie = Especies.values
        .map((e) => DropdownMenuItem(value: e.name, child: Text(e.rotulo)))
        .toList();
    final itensSexo = Sexos.values
        .map((s) => DropdownMenuItem(value: s.name, child: Text(s.rotulo)))
        .toList();
    final itensPorte = Portes.values
        .map((p) => DropdownMenuItem(value: p.name, child: Text(p.rotulo)))
        .toList();

    return Column(
      children: <Widget>[
        const SizedBox(height: 8.0),
        _construirFoto(),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerNome,
          validator: Validador.validarNomePet(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          maxLength: 30,
        ),

        DropdownButtonFormField<String>(
          items: itensEspecie,
          validator: Validador.validarSelecao('a espécie'),
          decoration: const InputDecoration(labelText: 'Espécie'),
          initialValue: _especie,
          onChanged: (String? novoValor) {
            setState(() {
              _especie = novoValor;
            });
          },
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerRaca,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Raça (opcional)'),
          maxLength: 30,
        ),

        DropdownButtonFormField<String>(
          items: itensSexo,
          validator: Validador.validarSelecao('o sexo'),
          decoration: const InputDecoration(labelText: 'Sexo'),
          initialValue: _sexo,
          onChanged: (String? novoValor) {
            setState(() {
              _sexo = novoValor;
            });
          },
        ),
        const SizedBox(height: 16.0),

        CampoData(
          controller: controllerNascimento,
          rotulo: 'Data de nascimento',
          validador: Validador.validarDataNascimento(),
          primeiraData: DateTime(hoje().year - 40),
          ultimaData: hoje(),
        ),
        const SizedBox(height: 16.0),

        DropdownButtonFormField<String>(
          items: itensPorte,
          validator: Validador.validarSelecao('o porte'),
          decoration: const InputDecoration(labelText: 'Porte'),
          initialValue: _porte,
          onChanged: (String? novoValor) {
            setState(() {
              _porte = novoValor;
            });
          },
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerPeso,
          validator: Validador.validarPeso(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Peso atual',
            suffixText: 'kg',
          ),
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerObservacoes,
          decoration: const InputDecoration(
            labelText: 'Mais informações (opcional)',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          maxLength: 200,
        ),

        const SizedBox(height: 15.0),
        ElevatedButton(
          // sem os parênteses: não queremos chamar a função agora
          onPressed: _salvando ? null : _salvar,
          child: Text(
            _salvando
                ? 'SALVANDO...'
                : (_pet.id == null ? 'CADASTRAR' : 'SALVAR'),
          ),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  Widget _construirFoto() {
    return Column(
      children: [
        GestureDetector(
          onTap: _escolherFoto,
          child: Stack(
            children: [
              AvatarPet(foto: _foto, raio: 56),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Tema.laranja,
                  child: const Icon(
                    Icons.add_a_photo,
                    size: 18,
                    color: Tema.textoEscuro,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _escolherFoto,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(_foto == null ? 'Adicionar foto' : 'Trocar foto'),
            ),
            if (_foto != null)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Tema.vermelhoErro),
                onPressed: () => setState(() => _foto = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _escolherFoto() async {
    // Pergunta se a foto vem da galeria ou da câmera
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (origem == null) return;

    try {
      // A foto é reduzida (600 px, qualidade 70) para caber no documento do Firestore
      final imagem = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 600,
        imageQuality: 70,
      );
      if (imagem == null) return;
      final bytes = await imagem.readAsBytes();
      if (!mounted) return;
      setState(() {
        _foto = base64Encode(bytes);
      });
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Não foi possível carregar a foto: $erro',
          erro: true);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      // erro de validação: as mensagens já aparecem nos campos
      return;
    }

    setState(() => _salvando = true);
    try {
      final raca = controllerRaca.text.trim();
      final observacoes = controllerObservacoes.text.trim();

      final pet = Pet.comParametros(
        id: _pet.id, // nulo no cadastro, preenchido na edição
        nome: controllerNome.text.trim(),
        especie: _especie,
        raca: raca.isEmpty ? null : raca,
        sexo: _sexo,
        dataNascimento: lerData(controllerNascimento.text),
        porte: _porte,
        peso: double.parse(controllerPeso.text.trim().replaceAll(',', '.')),
        observacoes: observacoes.isEmpty ? null : observacoes,
        foto: _foto,
      );

      if (pet.id == null) {
        await _petService!.inserir(pet);
      } else {
        await _petService!.atualizar(pet);
      }

      if (!mounted) return;
      await _dialogBox();
      if (!mounted) return;
      Navigator.pop(context); // volta para a tela anterior
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Erro ao salvar o pet: $erro', erro: true);
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
          title: const Text('Cadastro de pet'),
          content: const Text('Pet salvo com sucesso!'),
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
