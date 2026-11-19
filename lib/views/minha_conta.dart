import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petagenda/models/usuario.dart';
import 'package:petagenda/notifiers/sessao_notifier.dart';
import 'package:petagenda/services/auth_service.dart';
import 'package:petagenda/services/usuario_service.dart';
import 'package:petagenda/util/mensagem.dart';
import 'package:petagenda/util/mensagens_erro.dart';
import 'package:petagenda/util/tema.dart';
import 'package:petagenda/util/validador.dart';
import 'package:petagenda/views/alterar_senha.dart';
import 'package:petagenda/views/editar_perfil.dart';
import 'package:petagenda/views/login_page.dart';
import 'package:petagenda/widgets/avatar_pet.dart';
import 'package:petagenda/widgets/conteudo_centralizado.dart';
import 'package:provider/provider.dart';

class MinhaConta extends StatefulWidget {
  static const nomeRota = '/minhaconta';

  const MinhaConta({super.key});

  @override
  State<MinhaConta> createState() => _MinhaContaState();
}

class _MinhaContaState extends State<MinhaConta> {
  final AuthService _authService = AuthService();
  final UsuarioService _usuarioService = UsuarioService();
  Stream<Usuario?>? _streamPerfil;
  bool _processando = false; // true enquanto a conta está sendo excluída

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streamPerfil != null) return;
    // O uid do usuário logado vem do Provider
    final usuarioId = context.read<SessaoNotifier>().usuarioId!;
    _streamPerfil = _usuarioService.observar(usuarioId);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoNotifier>();
    // Sessão encerrada (ex: conta excluída): não escuta mais o Firestore
    if (!sessao.logado) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConteudoCentralizado(
              larguraMaxima: 480,
              child: StreamBuilder<Usuario?>(
                stream: _streamPerfil,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Erro ao carregar o perfil: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    );
                  }
                  return _construirConteudo(snapshot.data, sessao);
                },
              ),
            ),
          ),
          // Bloqueia a tela enquanto exclui (a operação tem vários passos)
          if (_processando) ...[
            const ModalBarrier(dismissible: false, color: Colors.black38),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _construirConteudo(Usuario? perfil, SessaoNotifier sessao) {
    // Se o perfil ainda não existe no Firestore, usa o que o login informa
    final usuario =
        perfil ??
        Usuario.comParametros(
          id: sessao.usuarioId,
          nome: sessao.nome,
          apelido: '',
          email: sessao.email,
        );
    final apelido = (usuario.apelido ?? '').isEmpty ? '-' : usuario.apelido!;

    return Column(
      children: [
        AvatarPet(foto: usuario.foto, raio: 56, icone: Icons.person),
        const SizedBox(height: 16.0),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _campo('Nome', usuario.nome ?? ''),
                const Divider(),
                _campo('Email', usuario.email ?? ''),
                const Divider(),
                _campo('Login', apelido),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24.0),

        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            EditarPerfil.nomeRota,
            arguments: usuario,
          ),
          icon: const Icon(Icons.edit),
          label: const Text('EDITAR PERFIL'),
        ),
        const SizedBox(height: 8.0),

        // Contas que não entram com senha (ex: Google) não têm o que alterar
        if (_authService.temSenha)
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AlterarSenha.nomeRota),
            icon: const Icon(Icons.lock_reset),
            label: const Text('Alterar senha'),
          ),
        const SizedBox(height: 16.0),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Tema.vermelhoErro,
            side: const BorderSide(color: Tema.vermelhoErro),
            minimumSize: const Size(200, 48),
            shape: const StadiumBorder(),
          ),
          onPressed: _excluirConta,
          icon: const Icon(Icons.delete_forever),
          label: const Text('EXCLUIR CONTA'),
        ),
        const SizedBox(height: 8.0),

        TextButton.icon(
          onPressed: _sair,
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _campo(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: Tema.verdeEscuro,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(valor, style: const TextStyle(fontSize: 17)),
      ],
    );
  }

  Future<void> _sair() async {
    // Primeiro vai para o login (encerra as telas que escutam o Firestore)
    // e só depois encerra a sessão, evitando erros de permissão.
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.nomeRota,
      (rota) => false,
    );
    await _authService.sair();
  }

  Future<void> _excluirConta() async {
    // 1) Pede a senha (confirma que é mesmo o dono da conta)
    // TODO (login com Google): contas sem senha precisam de outra confirmação
    final senha = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _DialogoExcluirConta(),
    );
    if (senha == null) return; // cancelou

    // Guardados antes do await: a tela será fechada durante o processo
    final navegador = Navigator.of(context);
    final mensagens = ScaffoldMessenger.of(context);

    setState(() => _processando = true);
    try {
      // 2) Confirma a senha, apaga os dados e a conta
      await _authService.excluirConta(senha);

      // 3) Volta para o login
      navegador.pushNamedAndRemoveUntil(LoginPage.nomeRota, (rota) => false);
      mensagens.showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso.')),
      );
    } on FirebaseAuthException catch (erro) {
      final senhaErrada =
          erro.code == 'wrong-password' || erro.code == 'invalid-credential';
      _mostrarMensagem(
        senhaErrada ? 'Senha incorreta.' : mensagemErroAuth(erro),
      );
    } catch (erro) {
      _mostrarMensagem('Não foi possível excluir a conta: $erro');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    mostrarMensagem(context, texto, erro: true);
  }
}

/// Diálogo que pede a senha para confirmar a exclusão da conta.
/// Devolve a senha digitada (ou null se o usuário cancelar).
class _DialogoExcluirConta extends StatefulWidget {
  const _DialogoExcluirConta();

  @override
  State<_DialogoExcluirConta> createState() => _DialogoExcluirContaState();
}

class _DialogoExcluirContaState extends State<_DialogoExcluirConta> {
  final _formKey = GlobalKey<FormState>();
  final controllerSenha = TextEditingController();
  bool _ocultarSenha = true;

  @override
  void dispose() {
    controllerSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir conta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta ação é permanente. Seus pets e agendamentos serão apagados '
              'e não poderão ser recuperados.',
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: controllerSenha,
              validator: Validador.validarSenhaObrigatoria(),
              obscureText: _ocultarSenha,
              obscuringCharacter: "*",
              decoration: InputDecoration(
                labelText: 'Digite sua senha para confirmar',
                suffixIcon: IconButton(
                  tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _ocultarSenha ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _ocultarSenha = !_ocultarSenha),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Tema.vermelhoErro),
          child: const Text('EXCLUIR'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, controllerSenha.text);
            }
          },
        ),
      ],
    );
  }
}
