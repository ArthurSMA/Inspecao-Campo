import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/work_orders/data/models/work_order.dart';

extension WorkOrderPresentation on WorkOrder {
  String get statusLabel => switch (status) {
    'open' => 'Aberta',
    'in_progress' => 'Em andamento',
    'done' => 'Concluída',
    _ => status,
  };

  Color get statusColor => switch (status) {
    'open' => const Color(0xFF7895B2),
    'in_progress' => const Color(0xFF1976D2),
    'done' => const Color(0xFF388E3C),
    _ => const Color(0xFF757575),
  };

  String get priorityLabel => switch (priority) {
    'high' => 'Alta',
    'medium' => 'Média',
    'low' => 'Baixa',
    _ => priority,
  };

  Color get priorityBackgroundColor => switch (priority) {
    'high' => const Color(0xFFFFE8D6),
    'medium' => const Color(0xFFE3F2FD),
    'low' => const Color(0xFFE8F5E9),
    _ => const Color(0xFFEEEEEE),
  };

  String get actionLabel => status == 'open' ? 'Iniciar' : 'Detalhes';
}
