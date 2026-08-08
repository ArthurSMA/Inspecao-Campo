import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/database/app_database.dart' as db;
import 'package:flutter_application_1/core/database/dao/inspection_dao.dart';
import 'package:flutter_application_1/core/database/dao/work_order_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection.dart';
import 'package:flutter_application_1/feat/inspection/presentation/pages/inspection_form_page.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_service.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_sync_service.dart';
import 'package:flutter_application_1/shared/widgets/app_navigation_bar.dart';

class InspectionsHistoryPage extends StatefulWidget {
  const InspectionsHistoryPage({
    super.key,
    required this.database,
    required this.onLogout,
    required this.onSessionInvalid,
    this.onNavigateHome,
    this.onNavigateOrders,
  });

  final db.AppDatabase database;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionInvalid;
  final VoidCallback? onNavigateHome;
  final VoidCallback? onNavigateOrders;

  @override
  State<InspectionsHistoryPage> createState() => _InspectionsHistoryPageState();
}

class _InspectionsHistoryPageState extends State<InspectionsHistoryPage> {
  final _tokenStorage = const TokenStorage();
  late final InspectionDao _inspectionDao;
  late final WorkOrderDao _workOrderDao;
  late final InspectionSyncService _syncService;
  List<db.Inspection> _inspections = const [];
  Map<String, db.WorkOrder> _workOrders = const {};
  InspectionStatus? _filter;
  bool _isLoading = true;
  String? _errorMessage;

  List<db.Inspection> get _filtered {
    return filterInspectionsByStatus(_inspections, _filter);
  }

  @override
  void initState() {
    super.initState();
    _inspectionDao = InspectionDao(widget.database);
    _workOrderDao = WorkOrderDao(widget.database);
    _syncService = InspectionSyncService(
      _inspectionDao,
      InspectionService(ApiClient()),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final inspections = await _inspectionDao.getAllInspections();
      final workOrders = await _workOrderDao.getAllWorkOrders();
      inspections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _inspections = inspections;
        _workOrders = {for (final order in workOrders) order.id: order};
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Não foi possível carregar o histórico.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retry(db.Inspection inspection) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      await widget.onSessionInvalid();
      return;
    }
    try {
      final result = await _syncService.retry(
        accessToken: token,
        clientId: inspection.clientId,
      );
      if (!mounted) return;
      _showMessage(
        result.synced > 0
            ? 'Inspeção sincronizada.'
            : 'A sincronização falhou.',
      );
      await _load();
    } on InspectionException catch (error) {
      if (error.shouldClearSession) {
        await widget.onSessionInvalid();
        return;
      }
      _showMessage(error.message);
      await _load();
    }
  }

  Future<void> _openDraft(db.Inspection inspection) async {
    final order = _workOrders[inspection.workOrderId];
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionFormPage(
          database: widget.database,
          workOrderId: inspection.workOrderId,
          workOrderCode: order?.code ?? inspection.workOrderId,
          workOrderTitle: order?.title ?? 'Ordem de serviço',
          onSessionInvalid: widget.onSessionInvalid,
          initialInspection: InspectionModel.fromDatabase(inspection),
        ),
      ),
    );
    if (changed == true) await _load();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de inspeções'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<InspectionStatus?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Todos')),
                ButtonSegment(
                  value: InspectionStatus.draft,
                  label: Text('Draft'),
                ),
                ButtonSegment(
                  value: InspectionStatus.pending,
                  label: Text('Pending'),
                ),
                ButtonSegment(
                  value: InspectionStatus.synced,
                  label: Text('Synced'),
                ),
                ButtonSegment(
                  value: InspectionStatus.failed,
                  label: Text('Failed'),
                ),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 2) return;
          Navigator.pop(context);
          if (index == 0) widget.onNavigateHome?.call();
          if (index == 1) widget.onNavigateOrders?.call();
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage case final message?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final inspections = _filtered;
    if (inspections.isEmpty) {
      return const Center(child: Text('Nenhuma inspeção encontrada.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: inspections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final inspection = inspections[index];
          final order = _workOrders[inspection.workOrderId];
          return Card(
            child: ListTile(
              onTap: inspection.status == 'draft'
                  ? () => _openDraft(inspection)
                  : null,
              title: Text(order?.code ?? inspection.workOrderId),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateText(inspection.updatedAt)),
                  Text(
                    inspection.observation.isEmpty
                        ? 'Sem observação'
                        : inspection.observation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (inspection.errorMessage case final error?)
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
              trailing: inspection.status == 'failed'
                  ? SizedBox(
                      width: 130,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatusBadge(status: inspection.status),
                          TextButton(
                            onPressed: () => _retry(inspection),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _StatusBadge(status: inspection.status),
            ),
          );
        },
      ),
    );
  }

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

List<db.Inspection> filterInspectionsByStatus(
  List<db.Inspection> inspections,
  InspectionStatus? status,
) {
  if (status == null) return inspections;
  return inspections.where((item) => item.status == status.name).toList();
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'synced' => Colors.green,
      'failed' => Theme.of(context).colorScheme.error,
      'pending' => Colors.orange,
      _ => Colors.blueGrey,
    };
    return Chip(
      label: Text(status),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
    );
  }
}
