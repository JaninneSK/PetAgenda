# PetAgenda
 
Aplicativo para celular e tablet (Android) que ajuda tutores a organizar os cuidados com
os seus animais de estimação: vacinas, consultas, medicamentos, banho e tosa.
 
Trabalho final da disciplina **Programação para Dispositivos Móveis (2026)**, Profa. Karen Borges.
Autora: Janinne Silva Krauspenhar.
 
## Funcionalidades
 
- **Conta de usuário:** cadastro e login por e-mail e senha, recuperação de senha por e-mail,
  edição de perfil (nome, login e foto), alteração de senha e exclusão da conta.
- **Pets:** cadastrar, visualizar, editar e excluir, com foto (galeria ou câmera), espécie, raça,
  sexo, porte, peso e nascimento (data exata, idade aproximada ou não informado).
- **Agendamentos:** cadastrar, listar, editar e excluir cuidados com pet, tipo, data e horário,
  e marcar como realizado. Agendamentos pendentes com data passada aparecem como "Atrasado".
- **Tela inicial:** calendário com os dias que têm agendamento, lista dos próximos
  agendamentos (ou do dia tocado no calendário) e os pets cadastrados.
- **Lembretes (notificações):** um resumo às 8h nos dias com agendamentos e um aviso 30 minutos
  antes de cada horário.
- **Celular e tablet:** a tela inicial passa para duas colunas quando há largura (tablet ou
  celular deitado), e formulários e listas ficam centralizados e com largura limitada.
## Requisitos do trabalho e onde estão
 
| Requisito | Onde |
|---|---|
| Tela de abertura (splash) | `lib/views/splash_page.dart` |
| Persistência em banco de dados (CRUD) | Cloud Firestore: `lib/services/` (pets, agendamentos e perfil) |
| Validação de campos | `lib/util/validador.dart`, usado em todos os formulários |
| Widget além dos vistos em aula | `TableCalendar` (pacote `table_calendar`), em `lib/views/home_page.dart` |
| Rotas de navegação | `lib/myapp.dart` (rotas nomeadas) e mapa abaixo |
| Execução no celular | testado em aparelho Android |
| Execução no tablet | testado em dois emuladores de tablet (Android Studio) |
 
## Tecnologias
 
- **Flutter e Dart** (Material Design)
- **Firebase Authentication** (e-mail e senha)
- **Cloud Firestore** (banco de dados)
- **Provider** (sessão do usuário logado)
- `table_calendar`, `image_picker`, `mask_text_input_formatter`, `intl`,
  `flutter_local_notifications`
## Como executar
 
Pré-requisitos: Flutter instalado (Dart 3.12 ou mais novo, ou seja, Flutter 3.44+), Android Studio
com um emulador ou um celular Android com depuração USB, e internet.
 
```bash
git clone https://github.com/JaninneSK/PetAgenda.git
cd PetAgenda
flutter pub get
flutter run
```
 
A configuração do Firebase já está no repositório (`lib/firebase_options.dart` e
`android/app/google-services.json`), então não é preciso configurar nada. Na tela de login,
toque em **CADASTRAR** para criar uma conta de teste.
 
Na primeira execução, o Android 13 ou mais novo pede permissão para mostrar notificações.
Em **Minha conta > Lembretes**, os botões de teste conferem se as notificações funcionam.
 
## Mapa de rotas
 
```
/splash ──(3 s)──> /login ──> /cadastro
        └──────>  /home  (menu lateral)
                    ├─> /meuspets ──> /detalhespet ──> /cadastrarpet (editar)
                    │        └──────> /cadastrarpet (novo)
                    ├─> /agendamentos ──> /cadastraragendamento (novo / editar)
                    ├─> /cadastraragendamento
                    └─> /minhaconta ──> /editarperfil
                                  └──> /alterarsenha
```
 
  models/              Pet, Agendamento, Usuario e enums (espécie, sexo, porte, tipo de cuidado)
  services/            acesso ao Firebase: AuthService, PetService, AgendamentoService,
                       UsuarioService e LembreteService
  notifiers/           SessaoNotifier (usuário logado)
  views/               telas
  widgets/             widgets reutilizáveis (avatar, campos de data e hora, cartão de agendamento)
  util/                validadores, formatadores, tema e mensagens
```
 
## Dados no Firestore
 
```
usuarios/{uid}                     nome, apelido, email, foto
usuarios/{uid}/pets/{id}           nome, espécie, raça, sexo, nascimento, porte, peso, observações, foto
usuarios/{uid}/agendamentos/{id}   título, petId, tipo, descrição, dataHora, realizado
```
 
As fotos são guardadas em base64 (reduzidas) dentro do próprio documento.
 
## Observações
 
- Notificações e testes foram feitos em **Android**. iOS não foi configurado.
- O horário das notificações é aproximado e pode atrasar alguns minutos.
- Login com Google não foi implementado.
 