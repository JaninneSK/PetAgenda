import 'package:flutter/material.dart';
import 'package:petagenda/models/usuario.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/selecionar_foto.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/widgets/avatar_pet.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';

/// Recebe o Usuario (perfil atual) como argumento da rota
class EditarPerfil extends StatefulWidget {
  static const nomeRota = '/editarperfil';

  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String? _foto;
  bool _carregado = false;
  bool _salvando = false;

  final controllerNome = TextEditingController();
  final controllerApelido = TextEditingController();
  final controllerEmail = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só preenche o formulário na primeira vez
    if (_carregado) return;
    _carregado = true;

    final usuario = ModalRoute.of(context)!.settings.arguments as Usuario;
    controllerNome.text = usuario.nome ?? '';
    controllerApelido.text = usuario.apelido ?? '';
    controllerEmail.text = usuario.email ?? '';
    _foto = usuario.foto;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    controllerNome.dispose();
    controllerApelido.dispose();
    controllerEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ConteudoCentralizado(
          larguraMaxima: 480,
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
    return Column(
      children: <Widget>[
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: _escolherFoto,
          child: Stack(
            children: [
              AvatarPet(foto: _foto, raio: 56, icone: Icons.person),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Tema.laranja,
                  child: Icon(
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
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerNome,
          validator: Validador.validarNome(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          maxLength: 40,
        ),
        TextFormField(
          controller: controllerApelido,
          validator: Validador.validarApelido(),
          decoration: const InputDecoration(labelText: 'Login'),
          maxLength: 20,
        ),

        // O e-mail é o que identifica a conta no login: aqui só aparece
        TextFormField(
          controller: controllerEmail,
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: 'O e-mail não pode ser alterado.',
          ),
        ),

        const SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'SALVANDO...' : 'SALVAR'),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  Future<void> _escolherFoto() async {
    try {
      final foto = await escolherFotoBase64(context);
      if (foto == null || !mounted) return;
      setState(() => _foto = foto);
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(
        context,
        'Não foi possível carregar a foto: $erro',
        erro: true,
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return; // erro de validação: as mensagens já aparecem nos campos
    }

    setState(() => _salvando = true);
    try {
      await _authService.atualizarPerfil(
        nome: controllerNome.text.trim(),
        apelido: controllerApelido.text.trim(),
        foto: _foto,
      );

      if (!mounted) return;
      await _dialogBox();
      if (!mounted) return;
      Navigator.pop(context); // volta para o perfil
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem(context, 'Erro ao salvar o perfil: $erro', erro: true);
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
          title: const Text('Perfil'),
          content: const Text('Perfil atualizado com sucesso!'),
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
