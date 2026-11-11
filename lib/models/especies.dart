enum Especies {
  cachorro('Cachorro'),
  gato('Gato'),
  passaro('Pássaro'),
  coelho('Coelho'),
  roedor('Roedor'),
  outro('Outro');

  final String rotulo;
  const Especies(this.rotulo);

  // Converte o texto salvo no banco ("gato") de volta para o enum
  static Especies? deNome(String? nome) {
    return Especies.values.where((e) => e.name == nome).firstOrNull;
  }
}
