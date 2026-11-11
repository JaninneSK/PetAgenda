enum Sexos {
  macho('Macho'),
  femea('Fêmea');

  final String rotulo;
  const Sexos(this.rotulo);

  static Sexos? deNome(String? nome) {
    return Sexos.values.where((s) => s.name == nome).firstOrNull;
  }
}
