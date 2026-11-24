import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:petagenda/models/agendamento.dart';
import 'package:petagenda/models/pet.dart';
import 'package:petagenda/models/tipos_cuidado.dart';
import 'package:petagenda/services/agendamento_service.dart';
import 'package:petagenda/services/pet_service.dart';
import 'package:petagenda/util/formatador.dart';
import 'package:timezone/timezone.dart' as tz;

/// Lembretes (notificações locais) dos agendamentos pendentes.
///
/// Dois tipos de lembrete, agendados no próprio celular:
///  1) RESUMO DO DIA: às [horaResumo]h, nos dias que têm agendamentos.
///  2) AVISO ANTES: [minutosAntes] minutos antes de cada agendamento.
///
/// A cada mudança nos agendamentos (criar, editar, excluir, marcar como
/// realizado) os lembretes são recalculados.
class LembreteService {
  // ----- Ajustes: pode mudar estes valores -----
  static const int horaResumo = 8; // resumo do dia às 08:00
  static const int minutosAntes = 30; // aviso 30 min antes (0 = desligado)
  static const int diasAFrente = 30; // agenda os próximos 30 dias

  // Só existe uma instância no app inteiro (singleton)
  static final LembreteService instancia = LembreteService._();
  LembreteService._();

  // Faixas de ids: 1 e 2 = testes | AAAAMMDD (~20 milhões) = resumo do dia |
  // acima de 100 milhões = aviso de um agendamento
  static const int _idTesteAgora = 1;
  static const int _idTesteAgendado = 2;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  StreamSubscription<List<Agendamento>>? _assinaturaAgendamentos;
  StreamSubscription<List<Pet>>? _assinaturaPets;
  List<Agendamento> _agendamentos = [];
  List<Pet> _pets = [];
  bool _recebeuAgendamentos = false;
  bool _recebeuPets = false;

  bool _sincronizando = false;
  bool _sincronizarDeNovo = false;

  /// Prepara o plugin. Chamado uma vez, no main().
  Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        settings: const InitializationSettings(android: android),
      );
      _inicializado = true;
    } catch (_) {
      // Se o plugin falhar, o app continua normal, só sem lembretes
    }
  }

  /// Android 13+ pede permissão para mostrar notificações.
  Future<bool> pedirPermissao() async {
    if (!_inicializado) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final concedida = await android?.requestNotificationsPermission();
      return concedida ?? true; // null: plataforma que não precisa pedir
    } catch (_) {
      return false;
    }
  }

  /// Começa a acompanhar os agendamentos do usuário e a manter os lembretes
  /// em dia. Chamado pela tela inicial.
  Future<void> iniciar(String usuarioId) async {
    parar();
    if (!_inicializado) return;

    _assinaturaAgendamentos = AgendamentoService(usuarioId).listar().listen((
      lista,
    ) {
      _agendamentos = lista;
      _recebeuAgendamentos = true;
      _sincronizar();
    }, onError: (_) {});

    _assinaturaPets = PetService(usuarioId).listar().listen((lista) {
      _pets = lista;
      _recebeuPets = true;
      _sincronizar();
    }, onError: (_) {});

    await pedirPermissao();
  }

  /// Para de acompanhar (os lembretes já agendados continuam valendo).
  void parar() {
    _assinaturaAgendamentos?.cancel();
    _assinaturaPets?.cancel();
    _assinaturaAgendamentos = null;
    _assinaturaPets = null;
    _agendamentos = [];
    _pets = [];
    _recebeuAgendamentos = false;
    _recebeuPets = false;
  }

  /// Ao sair da conta ou excluí-la: apaga todos os lembretes.
  Future<void> cancelarTodos() async {
    parar();
    if (!_inicializado) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Cálculo e agendamento
  // ---------------------------------------------------------------------

  // Se chegar uma mudança enquanto está agendando, repete depois
  // (evita duas rodadas ao mesmo tempo).
  Future<void> _sincronizar() async {
    if (!_recebeuAgendamentos || !_recebeuPets) return;
    if (_sincronizando) {
      _sincronizarDeNovo = true;
      return;
    }
    _sincronizando = true;
    try {
      do {
        _sincronizarDeNovo = false;
        await _agendarTudo();
      } while (_sincronizarDeNovo);
    } catch (_) {
      // falha ao agendar não pode derrubar o app
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> _agendarTudo() async {
    final agora = DateTime.now();
    final limite = DateTime(agora.year, agora.month, agora.day + diasAFrente);
    final nomes = {
      for (final p in _pets)
        if (p.id != null) p.id!: p.nome ?? 'Pet',
    };

    // Só agendamentos pendentes e ainda no futuro, em ordem de data
    final futuros =
        _agendamentos
            .where(
              (a) =>
                  !a.realizado &&
                  a.dataHora != null &&
                  a.dataHora!.isAfter(agora) &&
                  a.dataHora!.isBefore(limite),
            )
            .toList()
          ..sort((a, b) => a.dataHora!.compareTo(b.dataHora!));

    // id do lembrete -> lembrete
    final desejados = <int, _Lembrete>{};

    // 1) Resumo do dia
    final porDia = <int, List<Agendamento>>{};
    for (final a in futuros) {
      porDia.putIfAbsent(_chaveDia(a.dataHora!), () => []).add(a);
    }
    for (final entrada in porDia.entries) {
      final primeiro = entrada.value.first.dataHora!;
      final horaDoResumo = DateTime(
        primeiro.year,
        primeiro.month,
        primeiro.day,
        horaResumo,
      );
      if (!horaDoResumo.isAfter(agora)) continue; // as 8h de hoje já passaram

      // O resumo só lista o que acontece depois da hora dele
      final doDia = entrada.value
          .where((a) => a.dataHora!.isAfter(horaDoResumo))
          .toList();
      if (doDia.isEmpty) continue;

      final linhas = doDia.map((a) {
        final tipo = TiposCuidado.deNome(a.tipo)?.rotulo ?? 'Cuidado';
        final pet = nomes[a.petId] ?? 'Pet';
        return '${formatarHora(a.dataHora)} • $pet: $tipo';
      });
      desejados[entrada.key] = _Lembrete(
        quando: horaDoResumo,
        titulo: doDia.length == 1
            ? 'Hoje: 1 agendamento'
            : 'Hoje: ${doDia.length} agendamentos',
        corpo: linhas.join('\n'),
      );
    }

    // 2) Aviso antes de cada agendamento
    if (minutosAntes > 0) {
      for (final a in futuros) {
        if (a.id == null) continue;
        final quando = a.dataHora!.subtract(
          const Duration(minutes: minutosAntes),
        );
        if (!quando.isAfter(agora)) continue;

        final tipo = TiposCuidado.deNome(a.tipo)?.rotulo ?? 'Cuidado';
        final pet = nomes[a.petId] ?? 'Pet';
        desejados[_idAgendamento(a.id!)] = _Lembrete(
          quando: quando,
          titulo: '$pet: $tipo em $minutosAntes minutos',
          corpo: '${a.titulo ?? tipo} às ${formatarHora(a.dataHora)}',
        );
      }
    }

    // Cancela os que não valem mais (agendamento excluído, editado ou realizado)
    final agendados = await _plugin.pendingNotificationRequests();
    for (final pendente in agendados) {
      if (pendente.id <= _idTesteAgendado) continue; // não mexe nos testes
      if (!desejados.containsKey(pendente.id)) {
        await _plugin.cancel(id: pendente.id);
      }
    }

    // Agenda (ou atualiza) os que valem
    for (final entrada in desejados.entries) {
      await _agendar(
        id: entrada.key,
        quando: entrada.value.quando,
        titulo: entrada.value.titulo,
        corpo: entrada.value.corpo,
      );
    }
  }

  Future<void> _agendar({
    required int id,
    required DateTime quando,
    required String titulo,
    required String corpo,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        // Usamos o fuso UTC apenas como "régua": o instante é o mesmo, então
        // dispara no horário certo do celular sem precisar descobrir o fuso.
        scheduledDate: tz.TZDateTime.from(quando, tz.UTC),
        notificationDetails: _detalhes(corpo),
        // inexact: sem permissão especial de alarme exato; pode atrasar
        // alguns minutos, o que não importa para um lembrete.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: titulo,
        body: corpo,
      );
    } catch (_) {
      // se este lembrete falhar (ex: horário que acabou de passar), segue
    }
  }

  NotificationDetails _detalhes(String corpo) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'agendamentos', // id do canal
        'Agendamentos', // nome que aparece nas configurações do Android
        channelDescription: 'Lembretes dos agendamentos dos seus pets',
        importance: Importance.high,
        priority: Priority.high,
        // texto expansível: mostra várias linhas quando abrir a notificação
        styleInformation: BigTextStyleInformation(corpo),
      ),
    );
  }

  int _chaveDia(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  // Número estável a partir do id do agendamento (texto do Firestore)
  int _idAgendamento(String id) {
    int h = 17;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x3FFFFFFF;
    }
    return 100000000 + (h % 900000000);
  }

  // ---------------------------------------------------------------------
  // Testes (botões na tela Minha conta)
  // ---------------------------------------------------------------------

  /// Mostra uma notificação agora. Confere permissão e canal.
  Future<bool> testarAgora() async {
    if (!_inicializado) return false;
    if (!await pedirPermissao()) return false;
    try {
      const texto = 'Teste: as notificações estão funcionando!';
      await _plugin.show(
        id: _idTesteAgora,
        title: 'PetAgenda',
        body: texto,
        notificationDetails: _detalhes(texto),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Agenda uma notificação para daqui a 1 minuto. Confere o agendamento.
  Future<bool> testarEmUmMinuto() async {
    if (!_inicializado) return false;
    if (!await pedirPermissao()) return false;
    try {
      const texto = 'Teste agendado: os lembretes chegam mesmo com o app fechado!';
      await _plugin.zonedSchedule(
        id: _idTesteAgendado,
        scheduledDate: tz.TZDateTime.from(
          DateTime.now().add(const Duration(minutes: 1)),
          tz.UTC,
        ),
        notificationDetails: _detalhes(texto),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'PetAgenda',
        body: texto,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _Lembrete {
  final DateTime quando;
  final String titulo;
  final String corpo;

  const _Lembrete({
    required this.quando,
    required this.titulo,
    required this.corpo,
  });
}
