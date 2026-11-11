import 'package:cloud_firestore/cloud_firestore.dart';

class Agendamento {
  String? id;
  String? titulo;
  String? petId; // id do pet ao qual o agendamento pertence
  String? tipo; // nome do enum TiposCuidado (ex: "vacina")
  String? descricao;
  DateTime? dataHora; // data e horário juntos
  bool realizado = false;

  Agendamento();

  Agendamento.comParametros({
    this.id,
    required this.titulo,
    required this.petId,
    required this.tipo,
    required this.descricao,
    required this.dataHora,
    required this.realizado,
  });

  Agendamento.fromMap(Map map, {this.id}) {
    titulo = map['titulo'];
    petId = map['petId'];
    tipo = map['tipo'];
    descricao = map['descricao'];
    dataHora = (map['dataHora'] as Timestamp?)?.toDate();
    realizado = map['realizado'] ?? false;
  }

  // O id não entra no mapa: ele é o nome do documento no Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'petId': petId,
      'tipo': tipo,
      'descricao': descricao,
      'dataHora': dataHora == null ? null : Timestamp.fromDate(dataHora!),
      'realizado': realizado,
    };
  }

  @override
  String toString() {
    return "Id: $id, Título: $titulo, PetId: $petId, Tipo: $tipo, Data/hora: $dataHora, Realizado: $realizado";
  }
}
