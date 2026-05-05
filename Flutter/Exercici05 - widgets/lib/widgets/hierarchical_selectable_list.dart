import 'package:flutter/material.dart';

class HierarchySection {
  const HierarchySection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<HierarchyItem> items;
}

class HierarchyItem {
  const HierarchyItem({
    required this.id,
    required this.label,
    this.detail = '',
  });

  final String id;
  final String label;
  final String detail;
}

class HierarchicalSelectableList extends StatelessWidget {
  const HierarchicalSelectableList({
    super.key,
    required this.sections,
    required this.selectedId,
    required this.onSelect,
  });

  final List<HierarchySection> sections;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (final section in sections) {
      tiles.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
          child: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );

      for (final item in section.items) {
        final selected = selectedId == item.id;
        tiles.add(
          ListTile(
            dense: true,
            selected: selected,
            contentPadding: const EdgeInsets.only(left: 24, right: 8),
            onTap: () => onSelect(item.id),
            title: Text(item.label, style: const TextStyle(fontSize: 13)),
            subtitle: item.detail.isEmpty
                ? null
                : Text(item.detail, style: const TextStyle(fontSize: 11)),
          ),
        );
      }
    }

    if (tiles.isEmpty) {
      return const Center(child: Text('Sin elementos'));
    }
    return ListView(
      children: tiles,
    );
  }
}
