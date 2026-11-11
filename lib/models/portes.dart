enum Portes {
  pequeno('Pequeno'),
  medio('Médio'),
  grande('Grande');

  final String rotulo;
  const Portes(this.rotulo);

  static Portes? deNome(String? nome) {
    return Portes.values.where((p) => p.name == nome).firstOrNull;
  }
}
