import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/feat/auth/data/models/login_response.dart';
import 'package:flutter_application_1/feat/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('exibe o formulário de login', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: (_) {})));

    expect(find.text('Inspeção de Campo'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('valida campos obrigatórios e permite exibir a senha', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: (_) {})));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);

    final passwordField = find.byType(TextFormField).at(1);
    TextField editablePasswordField() =>
        find
                .descendant(of: passwordField, matching: find.byType(TextField))
                .evaluate()
                .single
                .widget
            as TextField;
    expect(editablePasswordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(editablePasswordField().obscureText, isFalse);
  });

  test('converte a resposta real de login e preserva role e id String', () {
    final response = LoginResponse.fromJson({
      'accessToken': 'token',
      'tokenType': 'Bearer',
      'expiresIn': 86400,
      'user': {
        'id': 'u_001',
        'name': 'Ana Técnica',
        'email': 'tecnico@orbytis.com.br',
        'role': 'field_technician',
      },
    });

    expect(response.accessToken, 'token');
    expect(response.user.id, isA<String>());
    expect(response.user.role, 'field_technician');
  });
}
