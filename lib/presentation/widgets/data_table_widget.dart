import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class DataTableColumn {
  final String label;
  final double? width;
  final TextAlign alignment;

  const DataTableColumn({
    required this.label,
    this.width,
    this.alignment = TextAlign.left,
  });
}

class DataTableWidget extends StatelessWidget {
  final List<DataTableColumn> columns;
  final List<List<Widget>> rows;
  final bool isScrollable;
  final Color? headerColor;
  final Color? rowColor;
  final Function(int)? onRowTap;
  final double? rowHeight;

  const DataTableWidget({
    Key? key,
    required this.columns,
    required this.rows,
    this.isScrollable = true,
    this.headerColor,
    this.rowColor,
    this.onRowTap,
    this.rowHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final table = Table(
      columnWidths: _buildColumnWidths(),
      border: TableBorder.all(
        color: AppColors.lighter,
        width: 1,
      ),
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: headerColor ?? AppColors.headerColor,
          ),
          children: columns.map((column) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                column.label,
                textAlign: column.alignment,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.blackText,
                ),
              ),
            );
          }).toList(),
        ),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index.isEven
                  ? (rowColor ?? AppColors.white)
                  : AppColors.lighter.withOpacity(0.3),
            ),
            children: row.map((cell) {
              return InkWell(
                onTap: onRowTap != null ? () => onRowTap!(index) : null,
                child: Container(
                  height: rowHeight ?? 50,
                  padding: const EdgeInsets.all(12),
                  child: cell,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );

    if (isScrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: table,
        ),
      );
    }

    return table;
  }

  Map<int, TableColumnWidth> _buildColumnWidths() {
    final widths = <int, TableColumnWidth>{};
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      if (column.width != null) {
        widths[i] = FixedColumnWidth(column.width!);
      } else {
        widths[i] = const FlexColumnWidth();
      }
    }
    return widths;
  }
}

