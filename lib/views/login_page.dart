import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/util/mensagens_erro.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/views/cadastro_usuario.dart';
import 'package:petagenda/views/home_page.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';

class LoginPage extends StatefulWidget {
  static const nomeRota = '/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final controllerEmail = TextEditingController();
  final controllerSenha = TextEditingController();

  bool _ocultarSenha = true;
  bool _entrando = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    controllerEmail.dispose();
    controllerSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tela de fundo verde: ajusta cores dos erros e dos botões de texto
    return Theme(
      data: Tema.sobreVerde(Theme.of(context)),
      child: Scaffold(
        backgroundColor: Tema.verde,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
        Image.asset('assets/logo_branca.png', width: 130),
        const SizedBox(height: 8.0),
        const Text(
          'PetAgenda',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32.0),

        TextFormField(
          controller: controllerEmail,
          validator: Validador.validarEmail(),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16.0),

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
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _esqueciSenha,
            child: const Text('Esqueci minha senha'),
          ),
        ),
        const SizedBox(height: 16.0),

        ElevatedButton(
          style: Tema.botaoBranco,
          onPressed: _entrando ? null : _entrar,
          child: Text(_entrando ? 'ENTRANDO...' : 'ENTRAR'),
        ),
        const SizedBox(height: 12.0),
        ElevatedButton(
          style: Tema.botaoBranco,
          onPressed: _entrando
              ? null
              : () => Navigator.pushNamed(context, CadastroUsuario.nomeRota),
          child: const Text('CADASTRAR'),
        ),
      ],
    );
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) {
      return; // erro de validação: as mensagens já aparecem nos campos
    }

    setState(() => _entrando = true);
    try {
      await _authService.entrar(
        email: controllerEmail.text.trim(),
        senha: controllerSenha.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomePage.nomeRota);
    } on FirebaseAuthException catch (erro) {
      _mostrarMensagem(mensagemErroAuth(erro));
    } catch (erro) {
      _mostrarMensagem('Erro inesperado: $erro');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    // Usa o e-mail que já foi digitado no campo acima
    final erro = Validador.validarEmail()(controllerEmail.text);
    if (erro != null) {
      _mostrarMensagem('Digite seu e-mail no campo acima para recuperar a senha.');
      return;
    }

    try {
      await _authService.recuperarSenha(controllerEmail.text.trim());
      _mostrarMensagem(
        'Se o e-mail estiver cadastrado, enviamos um link para redefinir a senha.',
      );
    } on FirebaseAuthException catch (erro) {
      _mostrarMensagem(mensagemErroAuth(erro));
    } catch (erro) {
      _mostrarMensagem('Erro inesperado: $erro');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
