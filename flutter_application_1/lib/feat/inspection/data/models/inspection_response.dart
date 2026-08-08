class InspectionResponse {
  const InspectionResponse({required this.id, required this.clientId});

  final String id;
  final String clientId;

  factory InspectionResponse.fromJson(Map<String, dynamic> json) {
    return InspectionResponse(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
    );
  }
}
