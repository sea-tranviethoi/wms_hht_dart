import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/route_optimizer_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/di/injection.dart';
import '../../blocs/picking/picking_bloc.dart';
import '../../../data/models/picking/picking_line.dart';
import '../../../routes/route_names.dart';
import '../../widgets/app_empty.dart';
import '../../widgets/app_error.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/module_tinted_button.dart';

/// Ported from screens/Picking/PickingItems.js
///
/// Displays the list of lines for one picking order.
class PickingItemsScreen extends StatelessWidget {
  final String pickNo;
  final int tenantId;
  final String company;

  const PickingItemsScreen({
    super.key,
    required this.pickNo,
    required this.tenantId,
    this.company = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PickingBloc(remote: sl())
        ..add(SelectPickingList(pickNo)),
      child: _PickingItemsView(
        pickNo: pickNo,
        tenantId: tenantId,
        company: company,
      ),
    );
  }
}

class _PickingItemsView extends StatelessWidget {
  final String pickNo;
  final int tenantId;
  final String company;

  const _PickingItemsView({
    required this.pickNo,
    required this.tenantId,
    required this.company,
  });

  void _backToList(BuildContext context) {
    final c = Uri.encodeComponent(company);
    context.go('${RouteNames.pickingList}?tenantId=$tenantId&company=$c');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
          onPressed: () => _backToList(context),
        ),
        title: Text('ピッキング: $pickNo', style: AppStyles.appBarTitle),
      ),
      body: BlocBuilder<PickingBloc, PickingState>(
        builder: (context, state) {
          if (state is PickingLoading) {
            return AppLoading.centered(message: '読み込み中...');
          }
          if (state is PickingError) {
            return AppError.generic(
              message: state.message,
              onRetry: () =>
                  context.read<PickingBloc>().add(SelectPickingList(pickNo)),
            );
          }
          if (state is PickingLinesLoaded) {
            return _OptimizedLinesView(
              lines: state.lines,
              pickNo: pickNo,
              tenantId: tenantId,
              company: company,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Reorders [lines] by the picking-route optimizer (proposal #7, "Nhóm A")
/// before rendering, so the walking order shown here — not just the order
/// the backend happened to return — reflects the shortest route through the
/// racks that need a pick. Falls back to the server's original order if the
/// optimizer is unreachable or any line is missing a bin: this is a display
/// enhancement, not something that should block the screen.
class _OptimizedLinesView extends StatefulWidget {
  final List<PickingLine> lines;
  final String pickNo;
  final int tenantId;
  final String company;

  const _OptimizedLinesView({
    required this.lines,
    required this.pickNo,
    required this.tenantId,
    required this.company,
  });

  @override
  State<_OptimizedLinesView> createState() => _OptimizedLinesViewState();
}

class _OptimizedLinesViewState extends State<_OptimizedLinesView> {
  late List<PickingLine> _lines;

  @override
  void initState() {
    super.initState();
    _lines = widget.lines;
    _optimizeOrder();
  }

  @override
  void didUpdateWidget(covariant _OptimizedLinesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lines, widget.lines)) {
      _lines = widget.lines;
      _optimizeOrder();
    }
  }

  Future<void> _optimizeOrder() async {
    final bins = widget.lines.map((l) => l.bin).toList();
    if (bins.any((b) => b == null || b.isEmpty)) return;

    try {
      final order =
          await sl<RouteOptimizerClient>().optimize(bins.cast<String>());
      if (!mounted) return;

      final remaining = List<PickingLine>.from(widget.lines);
      final sorted = <PickingLine>[];
      for (final bin in order) {
        final idx = remaining.indexWhere((l) => l.bin == bin);
        if (idx >= 0) sorted.add(remaining.removeAt(idx));
      }
      sorted.addAll(remaining); // any bin the optimizer didn't return (shouldn't happen)
      setState(() => _lines = sorted);
    } on RouteOptimizerException {
      // Non-critical — keep the server's original order.
    } catch (_) {
      // Non-critical — keep the server's original order.
    }
  }

  void _backToList(BuildContext context) {
    final c = Uri.encodeComponent(widget.company);
    context.go('${RouteNames.pickingList}?tenantId=${widget.tenantId}&company=$c');
  }

  @override
  Widget build(BuildContext context) {
    return _buildList(context, _lines);
  }

  Widget _buildList(BuildContext context, List<PickingLine> lines) {
    if (lines.isEmpty) {
      return AppEmpty.list(message: 'ピッキング明細がありません');
    }

    return Column(
      children: [
        // ── Count header strip — Orange 8% tint ─────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.settingsColor3.withOpacity(0.08),
            border: const Border(bottom: BorderSide(color: AppColors.light)),
          ),
          child: Text(
            '合計: ${lines.length} 件',
            style: const TextStyle(
              fontFamily: AppStyles.font,
              color: AppColors.grayTextColor,
              fontSize: AppStyles.sizeBodyText,
            ),
          ),
        ),

        // ── Item list ────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: lines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _LineCard(
              line: lines[index],
              index: index,
              onTap: () => context.push(
                RouteNames.pickingDetail,
                extra: {
                  'pickNo': widget.pickNo,
                  'pickingLine': lines[index],
                  'currentIndex': index,
                  'tenantId': widget.tenantId,
                  'company': widget.company,
                  'allLines': lines,
                },
              ),
            ),
          ),
        ),

        // ── Bottom bar: Back + Start ──────────────────────────────
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.light)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Material(
                    color: AppColors.settingsColor7,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    child: InkWell(
                      onTap: () => _backToList(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: AppStyles.heightBottomButton,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back,
                                color: AppColors.white, size: AppStyles.sizeBottomButtonIcon),
                            SizedBox(width: 8),
                            Text('戻る', style: AppStyles.button),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ModuleTintedButton(
                    label: '開始',
                    icon: Icons.play_arrow,
                    color: AppColors.settingsColor3,
                    height: AppStyles.heightBottomButton,
                    onPressed: () {
                      final firstIdx = lines.indexWhere(
                        (l) => (l.actualQty ?? 0) < l.pickQty,
                      );
                      final idx = firstIdx >= 0 ? firstIdx : 0;
                      context.push(
                        RouteNames.pickingDetail,
                        extra: {
                          'pickNo': widget.pickNo,
                          'pickingLine': lines[idx],
                          'currentIndex': idx,
                          'tenantId': widget.tenantId,
                          'company': widget.company,
                          'allLines': lines,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Line Card ────────────────────────────────────────────────────────────────

class _LineCard extends StatelessWidget {
  final PickingLine line;
  final int index;
  final VoidCallback onTap;

  const _LineCard({
    required this.line,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actual = line.actualQty ?? 0.0;
    final isDone = actual >= line.pickQty;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDone
                  ? AppColors.wageningenGreen.withOpacity(0.4)
                  : AppColors.light,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ── Index badge ───────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.wageningenGreen
                      : AppColors.settingsColor3,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppStyles.sizeBodyText,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // ── Product info ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productCode,
                      style: const TextStyle(
                        fontFamily: AppStyles.font,
                        fontWeight: FontWeight.bold,
                        fontSize: AppStyles.sizeMainTitle,
                        color: AppColors.blackTextColor,
                      ),
                    ),
                    if (line.productName != null &&
                        line.productName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        line.productName!,
                        style: const TextStyle(
                          fontFamily: AppStyles.font,
                          color: AppColors.grayTextColor,
                          fontSize: AppStyles.sizeSubText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (line.bin != null && line.bin!.isNotEmpty) ...[
                          const Icon(Icons.inventory_2_outlined,
                              size: 13, color: AppColors.gray),
                          const SizedBox(width: 4),
                          Text(
                            line.bin!,
                            style: const TextStyle(
                              fontFamily: AppStyles.font,
                              fontSize: AppStyles.sizeSubText,
                              color: AppColors.grayTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Icon(Icons.format_list_numbered,
                            size: 13, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Text(
                          '${actual.toStringAsFixed(0)} / ${line.pickQty.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: AppStyles.font,
                            fontSize: AppStyles.sizeSubText,
                            color: isDone
                                ? AppColors.wageningenGreen
                                : AppColors.settingsColor3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gray),
            ],
          ),
        ),
      ),
    );
  }
}
