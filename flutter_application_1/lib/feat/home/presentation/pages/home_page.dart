import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/database/app_database.dart';
import 'package:flutter_application_1/core/database/dao/work_order_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/feat/home/data/models/home_availability.dart';
import 'package:flutter_application_1/feat/home/data/models/home_summary.dart';
import 'package:flutter_application_1/feat/home/presentation/widgets/home_dashboard.dart';
import 'package:flutter_application_1/feat/work_orders/services/work_order_service.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/pages/work_orders_page.dart';
import 'package:flutter_application_1/shared/widgets/app_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.userName,
    required this.onLogout,
    required this.onSessionInvalid,
    required this.database,
  });

  final String userName;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionInvalid;
  final AppDatabase database;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TokenStorage _tokenStorage = const TokenStorage();
  late final WorkOrderService _workOrderService;

  HomeSummary? _summary;
  HomeAvailability _availability = const HomeAvailability.checking();
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _workOrderService = WorkOrderService(
      ApiClient(),
      WorkOrderDao(widget.database),
    );
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _availability = const HomeAvailability.checking();
      });
    }

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        await widget.onSessionInvalid();
        return;
      }

      final workOrders = await _workOrderService.getWorkOrders(
        accessToken: token,
      );
      final openOrders = workOrders.where((order) => order.isOpen).length;
      final isUsingCache =
          _workOrderService.lastDataSource == WorkOrderDataSource.cache;

      if (mounted) {
        setState(() {
          _summary = HomeSummary(openOrders: openOrders);
          _availability = HomeAvailability(
            state: isUsingCache
                ? HomeAvailabilityState.offline
                : HomeAvailabilityState.online,
            hasLocalData: isUsingCache,
          );
        });
      }
    } on WorkOrderException catch (error) {
      if (error.shouldClearSession) {
        await widget.onSessionInvalid();
        return;
      }
      if (error.kind == WorkOrderErrorKind.connection) {
        _showOfflineWithoutCache();
        return;
      }
      if (mounted) {
        setState(() {
          _availability = const HomeAvailability(
            state: HomeAvailabilityState.online,
          );
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availability = const HomeAvailability(
            state: HomeAvailabilityState.unavailable,
          );
          _errorMessage = 'Não foi possível carregar o resumo da Home.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOfflineWithoutCache() {
    if (!mounted) return;
    setState(() {
      _availability = const HomeAvailability(
        state: HomeAvailabilityState.offline,
      );
      _errorMessage = 'Não foi possível acessar a API e não há dados salvos.';
    });
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToWorkOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkOrdersPage(
          userName: widget.userName,
          onLogout: widget.onLogout,
          onSessionInvalid: widget.onSessionInvalid,
          database: widget.database,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeDashboardColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Inspeção de Campo',
          style: TextStyle(
            color: HomeDashboardColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          ProfileMenu(userName: widget.userName, onLogout: widget.onLogout),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: HomeDashboard(
              userName: widget.userName,
              summary: _summary,
              availability: _availability,
              lastSyncAt: null,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onRetry: _loadSummary,
              onViewOrders: _goToWorkOrders,
              onPendingInspections: () =>
                  _showUnavailable('As inspeções ainda não estão disponíveis.'),
              onFailedSyncs: () => _showUnavailable(
                'A fila de sincronização ainda não está disponível.',
              ),
              onSync: null,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            _goToWorkOrders();
          }
          if (index == 2) {
            _showUnavailable('O histórico ainda não está disponível.');
          }
        },
      ),
    );
  }
}
