import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  String? id; // no Firestore o id é um texto gerado pelo banco (não é int)
  String? nome;
  String? especie; // nome do enum Especies (ex: "gato")
  String? raca;
  String? sexo; // nome do enum Sexos
  DateTime? dataNascimento; // pode ser nula (tutor não sabe)
  bool nascimentoAproximado = false; // true: veio de uma idade aproximada
  String? porte; // nome do enum Portes
  double? peso;
  String? observacoes; // "Mais informações" no protótipo
  String? foto; // imagem codificada em base64 (opcional)

  Pet();

  Pet.comParametros({
    this.id,
    required this.nome,
    required this.especie,
    required this.raca,
    required this.sexo,
    required this.dataNascimento,
    this.nascimentoAproximado = false,
    required this.porte,
    required this.peso,
    required this.observacoes,
    required this.foto,
  });

  // O id não fica dentro dos dados do documento, por isso vem como parâmetro
  Pet.fromMap(Map map, {this.id}) {
    nome = map['nome'];
    especie = map['especie'];
    raca = map['raca'];
    sexo = map['sexo'];
    dataNascimento = (map['dataNascimento'] as Timestamp?)?.toDate();
    nascimentoAproximado = map['nascimentoAproximado'] ?? false;
    porte = map['porte'];
    peso = (map['peso'] as num?)?.toDouble();
    observacoes = map['observacoes'];
    foto = map['foto'];
  }

  // Aqui não colocamos o id: é o Firestore que cria e controla o id do documento
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'especie': especie,
      'raca': raca,
      'sexo': sexo,
      'dataNascimento':
          dataNascimento == null ? null : Timestamp.fromDate(dataNascimento!),
      'nascimentoAproximado': nascimentoAproximado,
      'porte': porte,
      'peso': peso,
      'observacoes': observacoes,
      'foto': foto,
    };
  }

  @override
  String toString() {
    return "Id: $id, Nome: $nome, Espécie: $especie, Raça: $raca, Sexo: $sexo, Nascimento: $dataNascimento, Porte: $porte, Peso: $peso";
  }
}
