import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/home/data/models/home_summary.dart';
import 'package:flutter_application_1/feat/home/data/models/home_availability.dart';

abstract final class HomeDashboardColors {
  static const primary = Color(0xFF00478D);
  static const background = Color(0xFFF9F9FF);
  static const border = Color(0xFFC2C6D4);
  static const secondaryText = Color(0xFF424752);
  static const warning = Color(0xFF793100);
  static const error = Color(0xFFBA1A1A);
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.userName,
    required this.onLogout,
  });

  final String userName;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Perfil',
      onSelected: (value) async {
        if (value == 'logout') await onLogout();
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [Icon(Icons.logout), SizedBox(width: 12), Text('Sair')],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: HomeDashboardColors.primary,
          foregroundColor: Colors.white,
          child: Text(
            _initials(userName),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.userName,
    required this.summary,
    required this.availability,
    required this.lastSyncAt,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onViewOrders,
    required this.onPendingInspections,
    required this.onFailedSyncs,
    required this.onSync,
  });

  final String userName;
  final HomeSummary? summary;
  final HomeAvailability availability;
  final DateTime? lastSyncAt;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onViewOrders;
  final VoidCallback onPendingInspections;
  final VoidCallback onFailedSyncs;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AvailabilityBanner(availability: availability, lastSyncAt: lastSyncAt),
        const SizedBox(height: 24),
        Text(
          'Olá, $userName',
          style: const TextStyle(
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumo das suas atividades hoje.',
          style: TextStyle(
            fontSize: 16,
            color: HomeDashboardColors.secondaryText,
          ),
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const _LoadingCard()
        else if (errorMessage != null)
          _ErrorCard(message: errorMessage!, onRetry: onRetry)
        else
          _OpenOrdersCard(
            amount: summary?.openOrders ?? 0,
            onTap: onViewOrders,
          ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _SummaryCard(
                amount: summary?.pendingInspections ?? 0,
                label: 'Inspeções pendentes',
                icon: Icons.pending_actions_outlined,
                accentColor: HomeDashboardColors.warning,
                onTap: onPendingInspections,
              ),
              _SummaryCard(
                amount: summary?.failedSyncs ?? 0,
                label: 'Falhas de sincronização',
                icon: Icons.sync_problem_outlined,
                accentColor: HomeDashboardColors.error,
                onTap: onFailedSyncs,
              ),
            ];
            if (constraints.maxWidth < 340) {
              return Column(
                children: [cards.first, const SizedBox(height: 12), cards.last],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards.first),
                const SizedBox(width: 12),
                Expanded(child: cards.last),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        const Text(
          'AÇÕES RÁPIDAS',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 1,
            color: HomeDashboardColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onViewOrders,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Ver ordens'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onSync,
          style: OutlinedButton.styleFrom(
            foregroundColor: HomeDashboardColors.primary,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: HomeDashboardColors.primary),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.sync),
          label: Text(
            onSync == null
                ? 'Nenhum item para sincronizar'
                : 'Sincronizar agora',
          ),
        ),
      ],
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({
    required this.availability,
    required this.lastSyncAt,
  });

  final HomeAvailability availability;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(availability);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: presentation.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(presentation.icon, color: presentation.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  presentation.subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _BannerPresentation _presentationFor(HomeAvailability availability) {
    switch (availability.state) {
      case HomeAvailabilityState.checking:
        return const _BannerPresentation(
          icon: Icons.cloud_sync_outlined,
          color: HomeDashboardColors.primary,
          backgroundColor: Color(0xFFE8EEF7),
          title: 'Verificando conexão',
          subtitle: 'Aguarde enquanto acessamos a API.',
        );
      case HomeAvailabilityState.online:
        return _BannerPresentation(
          icon: Icons.cloud_done_outlined,
          color: const Color(0xFF166534),
          backgroundColor: const Color(0xFFDCFCE7),
          title: 'Sistema online',
          subtitle: _lastSyncText(lastSyncAt),
        );
      case HomeAvailabilityState.offline:
        return _BannerPresentation(
          icon: Icons.cloud_off_outlined,
          color: const Color(0xFF793100),
          backgroundColor: const Color(0xFFFFF1E8),
          title: 'Modo offline',
          subtitle: availability.hasLocalData
              ? 'Você pode continuar usando os dados salvos no dispositivo.'
              : 'Sem conexão e sem ordens armazenadas localmente.',
        );
      case HomeAvailabilityState.unavailable:
        return const _BannerPresentation(
          icon: Icons.cloud_off_outlined,
          color: HomeDashboardColors.secondaryText,
          backgroundColor: Color(0xFFE8EEF7),
          title: 'Status indisponível',
          subtitle: 'Não foi possível determinar o acesso à API.',
        );
    }
  }

  String _lastSyncText(DateTime? date) {
    if (date == null) {
      return 'Nenhuma sincronização realizada.';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return 'Última sincronização: $hour:$minute';
  }
}

class _BannerPresentation {
  const _BannerPresentation({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String subtitle;
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Card(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: HomeDashboardColors.error),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenOrdersCard extends StatelessWidget {
  const _OpenOrdersCard({required this.amount, required this.onTap});

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = amount == 1 ? '1 ordem aberta' : '$amount ordens abertas';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: HomeDashboardColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD6E3FF),
                foregroundColor: HomeDashboardColors.primary,
                child: Icon(Icons.assignment_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.amount,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final int amount;
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 142),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: HomeDashboardColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accentColor),
                const SizedBox(height: 16),
                Text(
                  '$amount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12, height: 1.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
