import 'package:flutter/material.dart';

/// Cores e estilos do PetAgenda, tirados do protótipo no Figma.
class Tema {
  static const Color verde = Color(0xFF5EB89D); // cor da marca (fundos grandes)
  // Versão mais escura do verde, para botões e textos sobre fundo branco
  // (o branco sobre o verde da marca tem pouco contraste).
  static const Color verdeEscuro = Color(0xFF42826F);
  static const Color laranja = Color(0xFFF8BB64); // destaques (dias do calendário)
  static const Color cinzaCampo = Color(0xFFF2F1F1);
  static const Color fundo = Color(0xFFF5F5F5);
  static const Color textoEscuro = Color(0xFF1F2D2A);

  static OutlineInputBorder _borda(Color cor, double largura) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: cor, width: largura),
    );
  }

  // Aparência de todos os campos de texto do app
  static InputDecorationTheme _temaCampos({
    required Color corErro,
    required TextStyle estiloErro,
    Color? corContador,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: cinzaCampo,
      border: _borda(Colors.transparent, 0),
      enabledBorder: _borda(Colors.transparent, 0),
      focusedBorder: _borda(verdeEscuro, 2),
      errorBorder: _borda(corErro, 1.5),
      focusedErrorBorder: _borda(corErro, 2),
      errorStyle: estiloErro,
      // contador de caracteres do maxLength (ex: 0/40)
      counterStyle: corContador == null ? null : TextStyle(color: corContador),
    );
  }

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(seedColor: verde).copyWith(
      primary: verdeEscuro,
      onPrimary: Colors.white,
      secondary: laranja,
      onSecondary: textoEscuro,
    );

    return ThemeData(
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      inputDecorationTheme: _temaCampos(
        corErro: esquema.error,
        estiloErro: TextStyle(color: esquema.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeEscuro,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: verdeEscuro),
      ),
    );
  }

  /// Ajusta o tema para as telas com fundo verde (login e cadastro):
  /// mensagens de erro em branco e botões de texto brancos.
  static ThemeData sobreVerde(ThemeData base) {
    return base.copyWith(
      inputDecorationTheme: _temaCampos(
        corErro: Colors.white,
        estiloErro: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        corContador: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: const WidgetStatePropertyAll(Colors.white),
        checkColor: const WidgetStatePropertyAll(verdeEscuro),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }

  /// Botão branco com texto verde, como no protótipo (ENTRAR / CADASTRAR)
  static ButtonStyle get botaoBranco {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: verdeEscuro,
    );
  }
}
