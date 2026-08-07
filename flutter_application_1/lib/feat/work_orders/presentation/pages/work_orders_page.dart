import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/database/app_database.dart'
    hide WorkOrder;
import 'package:flutter_application_1/core/database/dao/work_order_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/feat/home/presentation/pages/home_page.dart';
import 'package:flutter_application_1/feat/home/presentation/widgets/home_dashboard.dart';
import 'package:flutter_application_1/feat/work_orders/data/models/work_order.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/widgets/work_order_card.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/widgets/work_order_filters.dart';
import 'package:flutter_application_1/feat/work_orders/services/work_order_service.dart';
import 'package:flutter_application_1/shared/widgets/app_navigation_bar.dart';

class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({
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
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  final TokenStorage _tokenStorage = const TokenStorage();

  late final WorkOrderService _workOrderService;

  List<WorkOrder> _workOrders = const [];

  WorkOrderFilter _selectedFilter = WorkOrderFilter.all;

  String? _errorMessage;

  bool _isLoading = true;

  List<WorkOrder> get _filteredWorkOrders {
    return switch (_selectedFilter) {
      WorkOrderFilter.all => _workOrders,
      WorkOrderFilter.open =>
        _workOrders.where((workOrder) => workOrder.isOpen).toList(),
      WorkOrderFilter.done =>
        _workOrders.where((workOrder) => workOrder.status == 'done').toList(),
    };
  }

  @override
  void initState() {
    super.initState();

    _workOrderService = WorkOrderService(
      ApiClient(),
      WorkOrderDao(widget.database),
    );

    _loadWorkOrders();
  }

  Future<void> _loadWorkOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        await widget.onSessionInvalid();
        return;
      }

      final workOrders = await _workOrderService.getWorkOrders(
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        _workOrders = workOrders;
      });
    } on WorkOrderException catch (error) {
      if (error.shouldClearSession) {
        await widget.onSessionInvalid();
        return;
      }

      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocorreu um erro inesperado ao carregar as ordens.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          userName: widget.userName,
          onLogout: widget.onLogout,
          onSessionInvalid: widget.onSessionInvalid,
          database: widget.database,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage case final errorMessage?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadWorkOrders,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final workOrders = _filteredWorkOrders;

    if (workOrders.isEmpty) {
      final message = _workOrders.isEmpty
          ? 'Nenhuma ordem de serviço encontrada.'
          : 'Nenhuma ordem encontrada neste filtro.';

      return Center(child: Text(message, textAlign: TextAlign.center));
    }

    return RefreshIndicator(
      onRefresh: _loadWorkOrders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: workOrders.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final workOrder = workOrders[index];

          return WorkOrderCard(
            workOrder: workOrder,
            onPressed: () {
              _showUnavailable(
                'Os detalhes da ordem ainda não estão disponíveis.',
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onSelected: (value) async {
            if (value == 'logout') await widget.onLogout();
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 12),
                  Text('Sair'),
                ],
              ),
            ),
          ],
        ),

        title: const Text(
          'Inspeção de Campo',
          style: TextStyle(
            color: HomeDashboardColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        centerTitle: true,

        actions: [
          ProfileMenu(userName: widget.userName, onLogout: widget.onLogout),
          const SizedBox(width: 12),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordens de Serviço',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              WorkOrderFilters(
                selectedFilter: _selectedFilter,
                onSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),

              const SizedBox(height: 20),

              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            _goToHome();
            return;
          }

          if (index == 1) {
            return;
          }

          if (index == 2) {
            _showUnavailable('O histórico ainda não está disponível.');
          }
        },
      ),
    );
  }
}
