import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:petagenda/util/tema.dart';

/// Mostra a foto do pet (guardada em base64) ou uma patinha branca no verde da marca
class AvatarPet extends StatelessWidget {
  final String? foto;
  final double raio;
  final IconData icone; // ícone mostrado quando não há foto

  const AvatarPet({
    super.key,
    this.foto,
    this.raio = 24,
    this.icone = Icons.pets,
  });

  @override
  Widget build(BuildContext context) {
    if (foto != null && foto!.isNotEmpty) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: Tema.cinzaCampo,
        backgroundImage: MemoryImage(base64Decode(foto!)),
      );
    }
    return CircleAvatar(
      radius: raio,
      backgroundColor: Tema.verde,
      child: Icon(icone, size: raio, color: Colors.white),
    );
  }
}
