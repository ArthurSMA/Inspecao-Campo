class HomeSummary {
  const HomeSummary({
    required this.openOrders,
    this.pendingInspections = 0,
    this.failedSyncs = 0,
  });

  final int openOrders;
  final int pendingInspections;
  final int failedSyncs;
}
