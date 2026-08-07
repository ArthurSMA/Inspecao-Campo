import 'package:flutter/material.dart';

enum WorkOrderFilter { all, open, done }

class WorkOrderFilters extends StatelessWidget {
  const WorkOrderFilters({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  final WorkOrderFilter selectedFilter;
  final ValueChanged<WorkOrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<WorkOrderFilter>(
        segments: const [
          ButtonSegment(value: WorkOrderFilter.all, label: Text('Todas')),
          ButtonSegment(value: WorkOrderFilter.open, label: Text('Abertas')),
          ButtonSegment(value: WorkOrderFilter.done, label: Text('Concluídas')),
        ],
        selected: {selectedFilter},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}
