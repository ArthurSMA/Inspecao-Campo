import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:flutter_application_1/core/database/app_database.dart'
    hide WorkOrder;
import 'package:flutter_application_1/core/database/dao/user_dao.dart';
import 'package:flutter_application_1/feat/auth/data/models/login_response.dart';
import 'package:flutter_application_1/feat/auth/presentation/pages/login_page.dart';
import 'package:flutter_application_1/feat/home/data/models/home_availability.dart';
import 'package:flutter_application_1/feat/home/data/models/home_summary.dart';
import 'package:flutter_application_1/feat/home/presentation/widgets/home_dashboard.dart';
import 'package:flutter_application_1/feat/work_orders/data/models/work_order.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/widgets/work_order_card.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/widgets/work_order_filters.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/work_order_presentation.dart';

void main() {
  late AppDatabase database;
  late UserDao userDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    userDao = UserDao(database);
  });

  tearDown(() => database.close());

  testWidgets('exibe o formulário de login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(onLogin: (_) {}, userDao: userDao),
      ),
    );

    expect(find.text('Inspeção de Campo'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('valida campos obrigatórios e permite exibir a senha', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(onLogin: (_) {}, userDao: userDao),
      ),
    );

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

  test('identifica ordens abertas e aceita notes ausente', () {
    WorkOrder orderWithStatus(String status) => WorkOrder.fromJson({
      'id': 'wo_1',
      'code': 'OS-001',
      'title': 'Inspeção',
      'description': 'Descrição',
      'address': 'Endereço',
      'priority': 'high',
      'status': status,
      'latitude': -7.1,
      'longitude': -34.8,
      'scheduledAt': '2026-07-28T13:00:00.000Z',
      'updatedAt': '2026-07-26T12:00:00.000Z',
    });

    expect(orderWithStatus('open').isOpen, isTrue);
    expect(orderWithStatus('in_progress').isOpen, isTrue);
    expect(orderWithStatus('done').isOpen, isFalse);
    expect(orderWithStatus('open').notes, isEmpty);
    expect(orderWithStatus('open').latitude, isA<double>());
    expect(orderWithStatus('open').scheduledAt, isA<DateTime>());
  });

  testWidgets('WorkOrderCard traduz prioridade e status', (tester) async {
    final workOrder = WorkOrder.fromJson({
      'id': 'wo_1',
      'code': 'OS-001',
      'title': 'Inspeção de poste',
      'description': 'Descrição',
      'address': 'Rua das Acácias, 120',
      'priority': 'high',
      'status': 'open',
      'latitude': -7.1,
      'longitude': -34.8,
      'scheduledAt': '2026-07-28T13:00:00.000Z',
      'updatedAt': '2026-07-26T12:00:00.000Z',
      'notes': '',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WorkOrderCard(workOrder: workOrder)),
      ),
    );

    expect(find.text('OS-001'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Aberta'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(workOrder.statusColor, const Color(0xFF7895B2));
    expect(workOrder.priorityLabel, 'Alta');
  });

  test('padroniza apresentação de todos os status e prioridades', () {
    WorkOrder workOrder(String status, String priority) => WorkOrder.fromJson({
      'id': 'wo_1',
      'code': 'OS-001',
      'title': 'Inspeção',
      'description': 'Descrição',
      'address': 'Endereço',
      'priority': priority,
      'status': status,
      'latitude': -7.1,
      'longitude': -34.8,
      'scheduledAt': '2026-07-28T13:00:00.000Z',
      'updatedAt': '2026-07-26T12:00:00.000Z',
    });

    expect(workOrder('open', 'high').statusLabel, 'Aberta');
    expect(workOrder('in_progress', 'medium').statusLabel, 'Em andamento');
    expect(workOrder('done', 'low').statusLabel, 'Concluída');
    expect(workOrder('open', 'high').priorityLabel, 'Alta');
    expect(workOrder('open', 'medium').priorityLabel, 'Média');
    expect(workOrder('open', 'low').priorityLabel, 'Baixa');
  });

  testWidgets('WorkOrderFilters informa a seleção', (tester) async {
    var selected = WorkOrderFilter.all;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkOrderFilters(
            selectedFilter: selected,
            onSelected: (filter) => selected = filter,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Concluídas'));
    expect(selected, WorkOrderFilter.done);
  });

  testWidgets('HomeDashboard exibe resumo real e indicadores zerados', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeDashboard(
              userName: 'Ana Técnica',
              summary: const HomeSummary(openOrders: 3),
              availability: const HomeAvailability(
                state: HomeAvailabilityState.online,
              ),
              lastSyncAt: null,
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onViewOrders: () {},
              onPendingInspections: () {},
              onFailedSyncs: () {},
              onSync: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Olá, Ana Técnica'), findsOneWidget);
    expect(find.text('3 ordens abertas'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Nenhuma sincronização realizada.'), findsOneWidget);
  });

  testWidgets('HomeDashboard exibe erro e permite tentar novamente', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeDashboard(
              userName: 'Ana',
              summary: null,
              availability: const HomeAvailability(
                state: HomeAvailabilityState.online,
              ),
              lastSyncAt: null,
              isLoading: false,
              errorMessage: 'API indisponível',
              onRetry: () => retried = true,
              onViewOrders: () {},
              onPendingInspections: () {},
              onFailedSyncs: () {},
              onSync: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('API indisponível'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, isTrue);
  });

  testWidgets('HomeDashboard não apresenta overflow em tela estreita', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeDashboard(
              userName: 'Ana Técnica',
              summary: const HomeSummary(openOrders: 0),
              availability: const HomeAvailability(
                state: HomeAvailabilityState.online,
              ),
              lastSyncAt: null,
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onViewOrders: () {},
              onPendingInspections: () {},
              onFailedSyncs: () {},
              onSync: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('0 ordens abertas'), findsOneWidget);
  });

  testWidgets('HomeDashboard diferencia online de modo offline sem cache', (
    tester,
  ) async {
    Widget dashboard(HomeAvailability availability, String? error) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeDashboard(
              userName: 'Ana',
              summary: null,
              availability: availability,
              lastSyncAt: null,
              isLoading: false,
              errorMessage: error,
              onRetry: () {},
              onViewOrders: () {},
              onPendingInspections: () {},
              onFailedSyncs: () {},
              onSync: null,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      dashboard(
        const HomeAvailability(state: HomeAvailabilityState.online),
        null,
      ),
    );
    expect(find.text('Sistema online'), findsOneWidget);
    expect(find.text('Nenhuma sincronização realizada.'), findsOneWidget);

    await tester.pumpWidget(
      dashboard(
        const HomeAvailability(state: HomeAvailabilityState.offline),
        'Não foi possível acessar a API e não há dados salvos.',
      ),
    );
    await tester.pump();

    expect(find.text('Modo offline'), findsOneWidget);
    expect(
      find.text('Sem conexão e sem ordens armazenadas localmente.'),
      findsOneWidget,
    );
    expect(find.text('Sistema online'), findsNothing);
    expect(find.text('Nenhum item para sincronizar'), findsOneWidget);
  });
}
