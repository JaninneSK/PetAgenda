# PetAgenda: passos 1 e 2

**Passo 1:** base do projeto (tema, splash, Firebase, sessão com Provider).
**Passo 2:** cadastro e login por e-mail e senha, com perfil salvo no Firestore.

## 1. Montar o projeto

```bash
flutter create petagenda
cd petagenda
```

Copie para dentro do projeto:
- a pasta `lib/` deste material (substituindo a que existe);
- a pasta `assets/` (com a `logo_branca.png`);
- o arquivo `firestore.rules` (só para consulta; quem vale é o que você colar no console).

Abra o `pubspec.yaml` e confira o bloco `assets` do arquivo `pubspec_trecho.yaml`.

```bash
flutter pub add firebase_core firebase_auth cloud_firestore provider intl
flutter pub add flutter_localizations --sdk=flutter
```

## 2. Configurar o Firebase (Console: https://console.firebase.google.com)

1. **Criar projeto** (ex: PetAgenda). Pode desativar o Google Analytics.
2. **Authentication > Começar > Método de login > E-mail/senha > Ativar.**
3. **Firestore Database > Criar banco de dados.** Escolha uma região (ex: `southamerica-east1`) e o
   modo **produção**. Em seguida, na aba **Regras**, cole o conteúdo de `firestore.rules` e **Publicar**.
   (O modo de teste deixa o banco aberto para qualquer pessoa e expira em 30 dias.)
4. No terminal, dentro do projeto:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Escolha o projeto criado e as plataformas (android, ios). Isso gera o `lib/firebase_options.dart`,
que o `main.dart` importa.

## 3. Rodar e testar

```bash
flutter run
```

Teste nesta ordem:
1. A splash aparece por 3 segundos e vai para o **login**.
2. **CADASTRAR**: deixe campos vazios, coloque e-mail inválido, senha curta, senhas diferentes e
   não marque os termos. Cada erro deve aparecer no campo.
3. Cadastre uma conta de verdade. Deve aparecer "Conta criada" e abrir a tela inicial.
4. No Console do Firebase confira: a conta em **Authentication** e o documento em
   **Firestore > usuarios > (uid)**.
5. **Menu > Sair**, depois **ENTRAR** com a conta. Feche o app e abra de novo: ele deve ir
   direto para a tela inicial (a sessão fica guardada).
6. **Esqueci minha senha**: digite o e-mail no campo e toque no link. Confira a caixa de entrada
   (e o spam).

## 4. O que cada pasta faz (e onde isso foi visto em aula)

| Arquivo | Para que serve | Aula |
|---|---|---|
| `main.dart` | inicia o Firebase e o Provider | Firestore / Provider |
| `myapp.dart` | tema, idioma e rotas nomeadas | Navegação |
| `util/tema.dart` | cores e estilos do Figma | |
| `util/validador.dart` | validação dos campos (`FormFieldValidator`) | Validação de Formulários |
| `util/mensagens_erro.dart` | traduz os erros do Firebase | Tratamento de Erros |
| `models/usuario.dart` | classe do perfil (`fromMap` / `toMap`) | Banco de Dados |
| `services/auth_service.dart` | cadastrar, entrar, sair, recuperar senha | |
| `services/usuario_service.dart` | grava `usuarios/{uid}` no Firestore | Conectando Flutter ao Firestore |
| `notifiers/sessao_notifier.dart` | guarda quem está logado (uid, nome) | Provider |
| `views/splash_page.dart` | tela de abertura | Navegação (`pushReplacementNamed`) |
| `views/login_page.dart` | login | Formulários |
| `views/cadastro_usuario.dart` | cadastro | Formulários |
| `views/home_page.dart` | tela inicial provisória + menu lateral (Drawer) | |

## 5. Próximos passos

3. CRUD de pets  4. CRUD de agendamentos  5. Tela inicial com calendário (TableCalendar)
6. Minha conta  7. Tablet  8. Login com Google (se der tempo)
