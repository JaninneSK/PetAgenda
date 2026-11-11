import 'package:flutter/material.dart';
import 'package:petagenda/util/formatador.dart';

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

  /// Nome do pet: aceita letras, números, espaço, hífen e apóstrofo
  static FormFieldValidator<String> validarNomePet() {
    return (value) {
      final texto = value?.trim() ?? '';
      final regExp = RegExp(r"^[a-zA-ZÀ-ÿ0-9 '\-]+$");
      if (texto.isEmpty) {
        return "Informe o nome do pet";
      } else if (texto.length < 2) {
        return "O nome deve ter pelo menos 2 caracteres";
      } else if (!regExp.hasMatch(texto)) {
        return "Use apenas letras, números, espaço, hífen ou apóstrofo";
      } else {
        return null;
      }
    };
  }

  /// Para os DropdownButtonFormField: exige que uma opção seja escolhida
  /// (ex: validarSelecao('a espécie') -> "Selecione a espécie")
  static FormFieldValidator<String> validarSelecao(String descricao) {
    return (value) {
      if (value == null || value.isEmpty) {
        return "Selecione $descricao";
      } else {
        return null;
      }
    };
  }

  static FormFieldValidator<String> validarPeso() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return "Informe o peso";
      }
      // aceita vírgula ou ponto (4,5 ou 4.5)
      final peso = double.tryParse(value.trim().replaceAll(',', '.'));
      if (peso == null) {
        return "Peso inválido. Use apenas números (ex: 4,5)";
      } else if (peso <= 0) {
        return "O peso deve ser maior que zero";
      } else if (peso > 200) {
        return "O peso deve ser de no máximo 200 kg";
      } else {
        return null;
      }
    };
  }

  /// Data obrigatória que não pode ser posterior a hoje
  static FormFieldValidator<String> validarDataPassada() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return "Informe a data";
      }
      final data = lerData(value);
      if (data == null) {
        return "Data incorreta. Use o formato dd/MM/aaaa";
      } else if (data.isAfter(hoje())) {
        return "A data não pode ser posterior à data atual";
      } else {
        return null; // Data válida: menor ou igual a hoje
      }
    };
  }

  static FormFieldValidator<String> validarDataNascimento() {
    return (value) {
      final erro = validarDataPassada()(value);
      if (erro != null) return erro;
      final data = lerData(value)!;
      if (data.year < hoje().year - 40) {
        return "Data de nascimento muito antiga";
      }
      return null;
    };
  }

  /// Título do agendamento: de 3 a 40 caracteres
  static FormFieldValidator<String> validarTitulo() {
    return (value) {
      final texto = value?.trim() ?? '';
      if (texto.isEmpty) {
        return "Informe o título";
      } else if (texto.length < 3) {
        return "O título deve ter pelo menos 3 caracteres";
      } else {
        return null;
      }
    };
  }

  /// Data do agendamento. Em um agendamento novo não pode ser anterior a hoje;
  /// na edição qualquer data válida é aceita (pode ser um cuidado antigo).
  static FormFieldValidator<String> validarDataAgendamento({
    required bool novo,
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return "Informe a data";
      }
      final data = lerData(value);
      if (data == null) {
        return "Data incorreta. Use o formato dd/MM/aaaa";
      } else if (novo && data.isBefore(hoje())) {
        return "A data não pode ser anterior à data atual";
      } else {
        return null;
      }
    };
  }

  /// Horário no formato HH:mm. Se o agendamento é novo e a data é hoje,
  /// o horário também não pode já ter passado.
  static FormFieldValidator<String> validarHorario(
    TextEditingController controllerData, {
    required bool novo,
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return "Informe o horário";
      }
      final hora = lerHora(value);
      if (hora == null) {
        return "Horário inválido. Use o formato HH:mm";
      }
      final data = lerData(controllerData.text);
      if (novo && data != null && data == hoje()) {
        final agora = TimeOfDay.now();
        final minutosAgora = agora.hour * 60 + agora.minute;
        if (hora.hour * 60 + hora.minute < minutosAgora) {
          return "Esse horário já passou";
        }
      }
      return null;
    };
  }
}
