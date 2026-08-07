import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/work_orders/data/models/work_order.dart';
import 'package:flutter_application_1/feat/work_orders/presentation/work_order_presentation.dart';

class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.workOrder, this.onPressed});

  final WorkOrder workOrder;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: workOrder.statusColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      workOrder.code,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  _PriorityBadge(
                    label: workOrder.priorityLabel,
                    backgroundColor: workOrder.priorityBackgroundColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workOrder.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workOrder.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: workOrder.statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workOrder.statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: workOrder.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onPressed,
                    child: Text(workOrder.actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
