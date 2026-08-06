import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../data/models/bundle/bundle_line.dart';
import '../../routes/route_names.dart';
import '../blocs/bundle/bundle_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';

/// Bundle detail (line list) screen
class BundleItemsScreen extends StatelessWidget {
  final String transNo;

  /// When preloadedLines is provided → bypass BLoC and use them directly (for mock/test)
  final List<BundleLine>? preloadedLines;

  const BundleItemsScreen({
    super.key,
    required this.transNo,
    this.preloadedLines,
  });

  @override
  Widget build(BuildContext context) {
    if (preloadedLines != null) {
      return _BundleItemsView(
        transNo: transNo,
        preloadedLines: preloadedLines,
      );
    }
    return BlocProvider(
      create: (_) => BundleBloc(remote: sl<BundleRemoteDataSource>())
        ..add(SelectBundle(transNo)),
      child: _BundleItemsView(transNo: transNo),
    );
  }
}

class _BundleItemsView extends StatefulWidget {
  final String transNo;
  final List<BundleLine>? preloadedLines;

  const _BundleItemsView({required this.transNo, this.preloadedLines});

  @override
  State<_BundleItemsView> createState() => _BundleItemsViewState();
}

class _BundleItemsViewState extends State<_BundleItemsView> {
  void _backToList(BuildContext context) =>
      context.go(RouteNames.bundleList);

  void _onItemTap(BuildContext context, int index, List<BundleLine> lines) {
    context.push(
      RouteNames.bundleDetail,
      extra: {
        'transNo': widget.transNo,
        'bundleLine': lines[index],
        'currentIndex': index,
        'allLines': lines,
      },
    );
  }

  void _startFirst(BuildContext context, List<BundleLine> lines) {
    if (lines.isEmpty) return;
    final firstIdx =
        lines.indexWhere((l) => l.actualQty < l.demandQty);
    final idx = firstIdx >= 0 ? firstIdx : 0;
    context.push(
      RouteNames.bundleDetail,
      extra: {
        'transNo': widget.transNo,
        'bundleLine': lines[idx],
        'currentIndex': idx,
        'allLines': lines,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
          onPressed: () => _backToList(context),
        ),
        title: Text('事前セット: ${widget.transNo}', style: AppStyles.appBarTitle),
      ),
      body: widget.preloadedLines != null
          ? _buildContent(context, widget.preloadedLines!)
          : BlocBuilder<BundleBloc, BundleState>(
              builder: (context, state) {
                if (state is BundleLoading) {
                  return AppLoading.centered(message: '読み込み中...');
                }
                if (state is BundleError) {
                  return AppError.generic(
                    message: state.message,
                    onRetry: () => context
                        .read<BundleBloc>()
                        .add(SelectBundle(widget.transNo)),
                  );
                }
                final lines = state is BundleLinesLoaded
                    ? state.lines
                    : <BundleLine>[];
                return _buildContent(context, lines);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, List<BundleLine> lines) {
    if (lines.isEmpty) {
      return AppEmpty.list(message: '明細データがありません');
    }
    final completedCount =
        lines.where((l) => l.actualQty >= l.demandQty).length;

    return Column(
      children: [
        // ── Header strip ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.settingsColor4.withOpacity(0.08),
            border:
                const Border(bottom: BorderSide(color: AppColors.light)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '合計: ${lines.length} 件',
                style: const TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.grayTextColor,
                  fontSize: AppStyles.sizeBodyText,
                ),
              ),
              Text(
                '$completedCount / ${lines.length} 完了',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontSize: AppStyles.sizeBodyText,
                  fontWeight: FontWeight.bold,
                  color: completedCount == lines.length
                      ? AppColors.wageningenGreen
                      : AppColors.settingsColor4,
                ),
              ),
            ],
          ),
        ),

        // ── Item list ─────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: lines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _BundleLineCard(
              line: lines[index],
              index: index,
              onTap: () => _onItemTap(context, index, lines),
            ),
          ),
        ),

        // ── Bottom bar ────────────────────────────────────────────
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
                  child: SizedBox(
                    height: AppStyles.heightBottomButton,
                    child: ElevatedButton.icon(
                      onPressed: () => _backToList(context),
                      icon: const Icon(Icons.arrow_back, size: AppStyles.sizeBottomButtonIcon),
                      label: const Text('戻る',
                          style: AppStyles.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.settingsColor7,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.zero,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: AppStyles.heightBottomButton,
                    child: ElevatedButton.icon(
                      onPressed: () => _startFirst(context, lines),
                      icon: const Icon(Icons.play_arrow, size: AppStyles.sizeBottomButtonIcon),
                      label: const Text('開始',
                          style: AppStyles.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.settingsColor4,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.zero,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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

class _BundleLineCard extends StatelessWidget {
  final BundleLine line;
  final int index;
  final VoidCallback onTap;

  const _BundleLineCard({
    required this.line,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = line.actualQty >= line.demandQty;
    final isPartial = line.actualQty > 0 && !isDone;

    final statusColor = isDone
        ? AppColors.wageningenGreen
        : isPartial
            ? AppColors.textWarning
            : AppColors.settingsColor4;
    final statusLabel =
        isDone ? '完了' : isPartial ? '一部対応' : '未対応';

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
                  color: statusColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check,
                        color: Colors.white, size: AppStyles.sizeBottomButtonIcon)
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
                        if (line.bin != null &&
                            line.bin!.isNotEmpty) ...[
                          const Icon(Icons.inventory_2_outlined,
                              size: AppStyles.sizeBottomButtonIcon, color: AppColors.gray),
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
                            size: AppStyles.sizeBottomButtonIcon, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Text(
                          '${line.actualQty.toStringAsFixed(0)} / ${line.demandQty.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: AppStyles.font,
                            fontSize: AppStyles.sizeSubText,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontFamily: AppStyles.font,
                              fontSize: AppStyles.sizeSubText,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
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
