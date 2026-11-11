import 'package:flutter/material.dart';

/// A validator is a function that processes a `FormField`
/// and returns an error [String] or null. A null [String] means that validation has passed.
class Validador {
  static FormFieldValidator<String> validarNome() {
    return (value) {
      final texto = value?.trim() ?? '';
      // inclui letras acentuadas (ex: João, Conceição)
      final regExp = RegExp(r'^[a-zA-ZÀ-ÿ ]+$');
      if (texto.isEmpty) {
        return "Informe o nome";
      } else if (texto.length < 3) {
        return "O nome deve ter pelo menos 3 caracteres";
      } else if (!regExp.hasMatch(texto)) {
        return "O nome deve conter apenas letras";
      } else {
        return null; // Passou na validação
      }
    };
  }

  static FormFieldValidator<String> validarEmail() {
    return (value) {
      final texto = value?.trim() ?? '';
      String pattern =
          r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
      RegExp regExp = RegExp(pattern);
      if (texto.isEmpty) {
        return "Informe o email";
      } else if (!regExp.hasMatch(texto)) {
        return "Email inválido";
      } else {
        return null;
      }
    };
  }

  /// O "Login" do protótipo: um apelido de 3 a 20 caracteres
  static FormFieldValidator<String> validarApelido() {
    return (value) {
      final texto = value?.trim() ?? '';
      final regExp = RegExp(r'^[a-zA-Z0-9._]+$');
      if (texto.isEmpty) {
        return "Informe o login";
      } else if (texto.length < 3) {
        return "O login deve ter pelo menos 3 caracteres";
      } else if (!regExp.hasMatch(texto)) {
        return "Use apenas letras, números, ponto ou _";
      } else {
        return null;
      }
    };
  }

  /// Login: a senha já existe, então só conferimos se foi preenchida.
  /// Se estiver errada, o Firebase avisa (não mostramos regra de tamanho aqui).
  static FormFieldValidator<String> validarSenhaObrigatoria() {
    return (value) {
      if (value == null || value.isEmpty) {
        return "Informe a senha";
      } else {
        return null;
      }
    };
  }

  /// Cadastro: o Firebase exige senhas com no mínimo 6 caracteres
  static FormFieldValidator<String> validarSenha() {
    return (value) {
      final texto = value ?? '';
      if (texto.isEmpty) {
        return "Informe a senha";
      } else if (texto.length < 6) {
        return "A senha deve ter pelo menos 6 caracteres";
      } else {
        return null;
      }
    };
  }

  /// Compara com o que foi digitado no campo da senha
  static FormFieldValidator<String> validarConfirmacaoSenha(
    TextEditingController controllerSenha,
  ) {
    return (value) {
      if (value == null || value.isEmpty) {
        return "Confirme a senha";
      } else if (value != controllerSenha.text) {
        return "As senhas não são iguais";
      } else {
        return null;
      }
    };
  }
}
