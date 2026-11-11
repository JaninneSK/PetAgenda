import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:petagenda/util/tema.dart';

/// Mostra a foto do pet (guardada em base64) ou uma patinha branca no verde da marca
class AvatarPet extends StatelessWidget {
  final String? foto;
  final double raio;

  const AvatarPet({super.key, this.foto, this.raio = 24});

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
      child: Icon(Icons.pets, size: raio, color: Colors.white),
    );
  }
}
