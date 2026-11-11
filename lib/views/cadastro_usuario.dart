import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/util/mensagens_erro.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/views/home_page.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';

class CadastroUsuario extends StatefulWidget {
  static const nomeRota = '/cadastro';

  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final controllerNome = TextEditingController();
  final controllerEmail = TextEditingController();
  final controllerApelido = TextEditingController();
  final controllerSenha = TextEditingController();
  final controllerConfirmarSenha = TextEditingController();

  bool _ocultarSenha = true;
  bool _salvando = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    controllerNome.dispose();
    controllerEmail.dispose();
    controllerApelido.dispose();
    controllerSenha.dispose();
    controllerConfirmarSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Tema.sobreVerde(Theme.of(context)),
      child: Scaffold(
        backgroundColor: Tema.verde,
        // AppBar transparente: só para mostrar a seta de voltar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConteudoCentralizado(
              larguraMaxima: 400,
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: _construirFormulario(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirFormulario() {
    return Column(
      children: <Widget>[
        const Text(
          'Criar uma conta',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Preencha seus dados:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 20.0),

        TextFormField(
          controller: controllerNome,
          validator: Validador.validarNome(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nome',
            prefixIcon: Icon(Icons.badge),
          ),
          maxLength: 40,
        ),
        const SizedBox(height: 8.0),

        TextFormField(
          controller: controllerEmail,
          validator: Validador.validarEmail(),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
          maxLength: 40,
        ),
        const SizedBox(height: 8.0),

        TextFormField(
          controller: controllerApelido,
          validator: Validador.validarApelido(),
          decoration: const InputDecoration(
            hintText: 'Login',
            prefixIcon: Icon(Icons.person),
          ),
          maxLength: 20,
        ),
        const SizedBox(height: 8.0),

        TextFormField(
          controller: controllerSenha,
          validator: Validador.validarSenha(),
          obscureText: _ocultarSenha,
          obscuringCharacter: "*",
          decoration: InputDecoration(
            hintText: 'Senha',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(
                _ocultarSenha ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
            ),
          ),
          maxLength: 30,
        ),
        const SizedBox(height: 8.0),

        TextFormField(
          controller: controllerConfirmarSenha,
          validator: Validador.validarConfirmacaoSenha(controllerSenha),
          obscureText: _ocultarSenha,
          obscuringCharacter: "*",
          decoration: const InputDecoration(
            hintText: 'Confirmar senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          maxLength: 30,
        ),

        // Checkbox dos termos: um FormField<bool> participa do validate()
        // do formulário como qualquer TextFormField.
        FormField<bool>(
          initialValue: false,
          validator: (aceitou) =>
              aceitou == true ? null : 'É preciso aceitar os termos de uso',
          builder: (campo) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: campo.value,
                  onChanged: campo.didChange,
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Li e aceito os ',
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: _mostrarTermos,
                        child: const Text(
                          'termos de uso',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (campo.hasError)
                  Text(
                    campo.errorText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 20.0),
        ElevatedButton(
          style: Tema.botaoBranco,
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'CADASTRANDO...' : 'CADASTRAR'),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return; // erro de validação: as mensagens já aparecem nos campos
    }

    setState(() => _salvando = true);
    try {
      await _authService.cadastrar(
        nome: controllerNome.text.trim(),
        apelido: controllerApelido.text.trim(),
        email: controllerEmail.text.trim(),
        senha: controllerSenha.text,
      );
      if (!mounted) return;
      await _dialogBox();
      if (!mounted) return;
      // A conta já está logada: vai para a tela inicial e limpa a pilha de telas
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomePage.nomeRota,
        (rota) => false,
      );
    } on FirebaseAuthException catch (erro) {
      _mostrarMensagem(mensagemErroAuth(erro));
    } catch (erro) {
      _mostrarMensagem('Não foi possível criar a conta: $erro');
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
          title: const Text('Cadastro'),
          content: const Text('Conta criada com sucesso!'),
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

  void _mostrarTermos() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Termos de uso'),
          // Texto de exemplo: troque pelo texto que você quiser apresentar
          content: const Text(
            'O PetAgenda é um aplicativo de organização dos cuidados com '
            'animais de estimação. Os dados informados (pets e agendamentos) '
            'ficam associados à sua conta e são usados apenas para o '
            'funcionamento do aplicativo.',
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
