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
import '../../widgets/custom_button.dart';

/// Port từ screens/Picking/PickingItems.js
///
/// Hiển thị danh sách lines của 1 picking order.
/// Mỗi line có trạng thái hoàn thành (actualQty / pickQty).
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            final c = Uri.encodeComponent(company);
            context.go(
              '${RouteNames.pickingList}?tenantId=$tenantId&company=$c',
            );
          },
        ),
        title: Text(
          'ピッキング: $pickNo',
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      body: BlocBuilder<PickingBloc, PickingState>(
        builder: (context, state) {
          if (state is PickingLoading) {
            return AppLoading.centered(message: '読み込み中...');
          }
          if (state is PickingError) {
            return _buildError(context, state.message);
          }
          if (state is PickingLinesLoaded) {
            return _buildList(context, state.lines);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return AppError.generic(
      message: msg,
      onRetry: () =>
          context.read<PickingBloc>().add(SelectPickingList(pickNo)),
    );
  }

  Widget _buildList(BuildContext context, List<PickingLine> lines) {
    if (lines.isEmpty) {
      return AppEmpty.list(message: 'ピッキング明細がありません');
    }

    return Column(
      children: [
        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.white,
          child: Text(
            '合計: ${lines.length} 件',
            style: const TextStyle(
              fontFamily: 'MSPGothic',
              color: AppColors.grayTextColor,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: lines.length,
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
        // Start picking button (goes to first incomplete line)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: CustomButton(
              text: 'ピッキング開始',
              icon: Icons.play_arrow,
              type: ButtonType.secondary,
              size: ButtonSize.large,
              isFullWidth: true,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Index badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.btnGreen
                      : AppColors.themeBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, color: AppColors.white, size: 20)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (line.bin != null && line.bin!.isNotEmpty) ...[
                          const Icon(Icons.inventory_2_outlined,
                              size: 14, color: AppColors.gray),
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
                            size: 14, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Text(
                          '${actual.toStringAsFixed(0)} / ${line.pickQty.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'MSPGothic',
                            fontSize: 12,
                            color: isDone
                                ? AppColors.btnGreen
                                : AppColors.textWarning,
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
