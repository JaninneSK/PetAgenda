import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/mensagens_erro.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';

class AlterarSenha extends StatefulWidget {
  static const nomeRota = '/alterarsenha';

  const AlterarSenha({super.key});

  @override
  State<AlterarSenha> createState() => _AlterarSenhaState();
}

class _AlterarSenhaState extends State<AlterarSenha> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final controllerSenhaAtual = TextEditingController();
  final controllerNovaSenha = TextEditingController();
  final controllerConfirmarSenha = TextEditingController();

  bool _ocultarSenha = true;
  bool _salvando = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    controllerSenhaAtual.dispose();
    controllerNovaSenha.dispose();
    controllerConfirmarSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar senha')),
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
        const Text(
          'Por segurança, informe a senha atual para escolher uma nova.',
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerSenhaAtual,
          validator: Validador.validarSenhaObrigatoria(),
          obscureText: _ocultarSenha,
          obscuringCharacter: "*",
          decoration: InputDecoration(
            labelText: 'Senha atual',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _ocultarSenha ? 'Mostrar senhas' : 'Ocultar senhas',
              icon: Icon(
                _ocultarSenha ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: controllerNovaSenha,
          validator: Validador.validarNovaSenha(controllerSenhaAtual),
          obscureText: _ocultarSenha,
          obscuringCharacter: "*",
          decoration: const InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: Icon(Icons.lock),
          ),
          maxLength: 30,
        ),
        const SizedBox(height: 8.0),

        TextFormField(
          controller: controllerConfirmarSenha,
          validator: Validador.validarConfirmacaoSenha(controllerNovaSenha),
          obscureText: _ocultarSenha,
          obscuringCharacter: "*",
          decoration: const InputDecoration(
            labelText: 'Confirmar nova senha',
            prefixIcon: Icon(Icons.lock),
          ),
          maxLength: 30,
        ),

        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'ALTERANDO...' : 'ALTERAR SENHA'),
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
      await _authService.alterarSenha(
        senhaAtual: controllerSenhaAtual.text,
        novaSenha: controllerNovaSenha.text,
      );

      if (!mounted) return;
      await _dialogBox();
      if (!mounted) return;
      Navigator.pop(context); // volta para o perfil
    } on FirebaseAuthException catch (erro) {
      // Aqui sabemos que o erro de credencial é a senha ATUAL digitada
      final senhaErrada =
          erro.code == 'wrong-password' || erro.code == 'invalid-credential';
      _mostrarMensagem(
        senhaErrada ? 'Senha atual incorreta.' : mensagemErroAuth(erro),
      );
    } catch (erro) {
      _mostrarMensagem('Não foi possível alterar a senha: $erro');
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
          title: const Text('Senha'),
          content: const Text('Senha alterada com sucesso!'),
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

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    mostrarMensagem(context, texto, erro: true);
  }
}
