class Usuario {
  String? id; // é o uid gerado pelo Firebase Authentication
  String? nome;
  String? apelido; // o campo "Login" do protótipo
  String? email;

  Usuario();

  Usuario.comParametros({
    this.id,
    required this.nome,
    required this.apelido,
    required this.email,
  });

  Usuario.fromMap(Map map, {this.id}) {
    nome = map['nome'];
    apelido = map['apelido'];
    email = map['email'];
  }

  // O id não entra no mapa: ele é o nome do documento no Firestore
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'apelido': apelido, 'email': email};
  }

  @override
  String toString() {
    return "Id: $id, Nome: $nome, Apelido: $apelido, Email: $email";
  }
}
