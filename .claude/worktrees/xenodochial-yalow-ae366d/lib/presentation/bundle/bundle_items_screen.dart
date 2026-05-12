import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../data/models/bundle/bundle_line.dart';
import '../../routes/route_names.dart';
import '../blocs/bundle/bundle_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';

/// 事前セット明細 — BLoC version (Phase 6)
class BundleItemsScreen extends StatelessWidget {
  final String transNo;

  const BundleItemsScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BundleBloc(remote: sl<BundleRemoteDataSource>())
        ..add(SelectBundle(transNo)),
      child: _BundleItemsView(transNo: transNo),
    );
  }
}

class _BundleItemsView extends StatefulWidget {
  final String transNo;
  const _BundleItemsView({required this.transNo});

  @override
  State<_BundleItemsView> createState() => _BundleItemsViewState();
}

class _BundleItemsViewState extends State<_BundleItemsView> {
  int? _selectedIndex;

  void _handleItemTap(
      BuildContext context, int index, List<BundleLine> lines) {
    setState(() => _selectedIndex = index);

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

  String _getStatusLabel(double actualQty, double demandQty) {
    if (actualQty == 0) return '未対応';
    if (actualQty < demandQty) return '一部対応';
    return '完了';
  }

  Color _getStatusColor(double actualQty, double demandQty) {
    if (actualQty == 0) return AppColors.black;
    if (actualQty < demandQty) return AppColors.textWarning;
    return AppColors.btnGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事前セット明細'),
        backgroundColor: AppColors.settingsColor4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<BundleBloc, BundleState>(
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

          final lines = state is BundleLinesLoaded ? state.lines : <BundleLine>[];
          final completedCount =
              lines.where((l) => l.actualQty >= l.demandQty).length;

          return Column(
            children: [
              // Header: transNo + progress
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderTable,
                  border:
                      Border(bottom: BorderSide(color: AppColors.light)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '事前セット：',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'MSPGothic'),
                        ),
                        Text(
                          widget.transNo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'MSPGothic'),
                        ),
                      ],
                    ),
                    Text(
                      '$completedCount/${lines.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'MSPGothic',
                        color: completedCount == lines.length
                            ? AppColors.btnGreen
                            : AppColors.textError,
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: lines.isEmpty
                    ? AppEmpty.list(message: '明細データがありません')
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          final isSelected = _selectedIndex == index;
                          final statusLabel = _getStatusLabel(
                              line.actualQty, line.demandQty);
                          final statusColor = _getStatusColor(
                              line.actualQty, line.demandQty);

                          return InkWell(
                            onTap: () =>
                                _handleItemTap(context, index, lines),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.headerColor
                                    : AppColors.white,
                                border: Border.all(
                                    color: AppColors.borderTable, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildRow(
                                        '棚番：', line.bin ?? ''),
                                    const SizedBox(height: 8),
                                    _buildRow(
                                        '商品：',
                                        line.productName ?? line.productCode,
                                        maxLines: 2),
                                    const SizedBox(height: 8),
                                    _buildRow('数量：',
                                        line.demandQty.toInt().toString()),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text(
                                          'ステータス：',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              fontFamily: 'MSPGothic'),
                                        ),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'MSPGothic',
                                              color: statusColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {int maxLines = 1}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'MSPGothic'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(fontSize: 14, fontFamily: 'MSPGothic'),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
