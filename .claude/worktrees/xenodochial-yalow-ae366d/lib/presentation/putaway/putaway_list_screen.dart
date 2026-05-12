import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/putaway_remote_datasource.dart';
import '../../routes/route_names.dart';
import '../blocs/putaway/putaway_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/back_to_menu_button.dart';

/// 棚上げ一覧 — BLoC version (Phase 5)
class PutawayListScreen extends StatelessWidget {
  const PutawayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PutawayBloc(remote: sl<PutawayRemoteDataSource>()),
      child: const _PutawayListView(),
    );
  }
}

class _PutawayListView extends StatefulWidget {
  const _PutawayListView();

  @override
  State<_PutawayListView> createState() => _PutawayListViewState();
}

class _PutawayListViewState extends State<_PutawayListView> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  void _loadData() {
    final hhtInfo = sl<CacheStorage>().getString('hhtInfo') ?? '';
    context.read<PutawayBloc>().add(FetchPutawayLists(hhtInfo: hhtInfo));
  }

  void _handleSearch(String keyword) {
    context.read<PutawayBloc>().add(SearchPutawayLists(keyword));
  }

  void _handleRowTap(BuildContext context, int index, PutawayRow row) {
    if (row.scanStatus == 3) {
      // Handled by other device
      final otherUser = row.hhtInfoOther.split('-').first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notification'),
          content: Text(
            'ユーザー「$otherUser」は別デバイスで ${row.productCode} を対応してます。ご確認ください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.themeBackground),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _selectedIndex = index);

    context.push(
      RouteNames.putawayDetail,
      extra: {
        'productCode': row.productCode,
        'productName': row.productName,
        'lines': row.lines,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('棚上げ一覧'),
        backgroundColor: AppColors.settingsColor2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.mainMenu),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'フィルターする内容を入力してください。',
              onChanged: _handleSearch,
            ),
          ),

          // List
          Expanded(
            child: BlocBuilder<PutawayBloc, PutawayState>(
              builder: (context, state) {
                if (state is PutawayLoading) {
                  return AppLoading.centered(message: '読み込み中...');
                }

                if (state is PutawayError) {
                  return AppError.generic(
                    message: state.message,
                    onRetry: _loadData,
                  );
                }

                final rows = state is PutawayListsLoaded
                    ? state.rows
                    : <PutawayRow>[];

                if (rows.isEmpty && state is PutawayListsLoaded) {
                  return AppEmpty.list(message: '棚上げデータがありません');
                }

                return Container(
                  color: AppColors.white,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.light,
                    ),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final isSelected = _selectedIndex == index;
                      final progress = row.totalQty > 0
                          ? (row.scannedQty / row.totalQty).clamp(0.0, 1.0)
                          : 0.0;

                      final (Color statusColor, String statusLabel) =
                          switch (row.scanStatus) {
                        0  => (AppColors.btnGreen,        '完了'),
                        1  => (AppColors.textWarning,     '進行中'),
                        3  => (AppColors.gray,            'ロック'),
                        _  => (AppColors.themeBackground, '未開始'),
                      };

                      return _PutawayTile(
                        productCode: row.productCode,
                        productName: row.productName,
                        scanned: row.scannedQty,
                        total: row.totalQty,
                        progress: progress,
                        statusColor: statusColor,
                        statusLabel: statusLabel,
                        isSelected: isSelected,
                        onTap: () => _handleRowTap(context, index, row),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Back button — module color (Putaway = Purple)
          BackToMenuButton(
            color: AppColors.settingsColor2,
            onPressed: () => context.go(RouteNames.mainMenu),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Minimal row: status dot + code/name + qty + tiny progress bar
class _PutawayTile extends StatelessWidget {
  final String productCode;
  final String productName;
  final double scanned;
  final double total;
  final double progress;
  final Color statusColor;
  final String statusLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _PutawayTile({
    required this.productCode,
    required this.productName,
    required this.scanned,
    required this.total,
    required this.progress,
    required this.statusColor,
    required this.statusLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppColors.headerColor : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            // Code + name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          productCode,
                          style: const TextStyle(
                            fontFamily: 'MSPGothic',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (productName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      productName,
                      style: const TextStyle(
                        fontFamily: 'MSPGothic',
                        fontSize: 12,
                        color: AppColors.grayTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Qty + progress
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'MSPGothic'),
                    children: [
                      TextSpan(
                        text: scanned.toStringAsFixed(0),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.grayTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    width: 48,
                    height: 3,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.lighter,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
