import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Pergunta se a foto vem da galeria ou da câmera e devolve a imagem em base64
/// (ou null se o usuário cancelar). A foto é reduzida (600 px, qualidade 70)
/// para caber com folga no documento do Firestore.
Future<String?> escolherFotoBase64(BuildContext context) async {
  final origem = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
  if (origem == null) return null;

  final imagem = await ImagePicker().pickImage(
    source: origem,
    maxWidth: 600,
    imageQuality: 70,
  );
  if (imagem == null) return null;

  final bytes = await imagem.readAsBytes();
  return base64Encode(bytes);
}
