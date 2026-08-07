class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.address,
    required this.priority,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.updatedAt,
    required this.notes,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String address;
  final String priority;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final DateTime updatedAt;
  final String notes;

  bool get isOpen => status == 'open' || status == 'in_progress';

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }
}
