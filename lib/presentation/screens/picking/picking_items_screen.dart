import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../blocs/picking/picking_bloc.dart';
import '../../../data/models/picking/picking_line.dart';
import '../../../routes/route_names.dart';
import '../../widgets/app_empty.dart';
import '../../widgets/app_error.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/module_tinted_button.dart';

/// Port từ screens/Picking/PickingItems.js
///
/// Hiển thị danh sách lines của 1 picking order.
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
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 32),
          onPressed: () => _backToList(context),
        ),
        title: Text(
          'ピッキング: $pickNo',
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
            return _buildList(context, state.lines);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PickingLine> lines) {
    if (lines.isEmpty) {
      return AppEmpty.list(message: 'ピッキング明細がありません');
    }

    return Column(
      children: [
        // ── 件数 header strip — Orange 8% tint ──────────────────
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
              fontFamily: 'MSPGothic',
              color: AppColors.grayTextColor,
              fontSize: 13,
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
                  'pickNo': pickNo,
                  'pickingLine': lines[index],
                  'currentIndex': index,
                  'tenantId': tenantId,
                  'company': company,
                  'allLines': lines,
                },
              ),
            ),
          ),
        ),

        // ── Bottom bar: 戻る + 開始 ───────────────────────────────
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
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back,
                                color: AppColors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '戻る',
                              style: TextStyle(
                                fontFamily: 'MSPGothic',
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                    height: 52,
                    onPressed: () {
                      final firstIdx = lines.indexWhere(
                        (l) => (l.actualQty ?? 0) < l.pickQty,
                      );
                      final idx = firstIdx >= 0 ? firstIdx : 0;
                      context.push(
                        RouteNames.pickingDetail,
                        extra: {
                          'pickNo': pickNo,
                          'pickingLine': lines[idx],
                          'currentIndex': idx,
                          'tenantId': tenantId,
                          'company': company,
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
                          fontSize: 14,
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
                        fontFamily: 'MSPGothic',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.blackTextColor,
                      ),
                    ),
                    if (line.productName != null &&
                        line.productName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        line.productName!,
                        style: const TextStyle(
                          fontFamily: 'MSPGothic',
                          color: AppColors.grayTextColor,
                          fontSize: 12,
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
                              fontFamily: 'MSPGothic',
                              fontSize: 12,
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
                            fontFamily: 'MSPGothic',
                            fontSize: 12,
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
