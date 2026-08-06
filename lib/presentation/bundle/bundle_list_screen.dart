import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../data/models/bundle/bundle_line.dart';
import '../../routes/route_names.dart';
import '../blocs/bundle/bundle_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/module_list_tile.dart';

// ─── Mock data for UI testing ────────────────────────────────────
const _kMockTransNo = 'DEMO-TEST-001';
final _kMockLines = [
  BundleLine(
    id: 'mock-1',
    transNo: _kMockTransNo,
    productCode: 'PROD-A001',
    productName: 'サンプル商品 Alpha / テスト製品 001',
    bin: '01-A101',
    lotNo: 'LOT-2025-001',
    demandQty: 5,
    actualQty: 0,
    expirationDate: '2026-12-31',
  ),
  BundleLine(
    id: 'mock-2',
    transNo: _kMockTransNo,
    productCode: 'PROD-B002',
    productName: 'サンプル商品 Beta / テスト製品 002',
    bin: '02-B205',
    lotNo: 'LOT-2025-002',
    demandQty: 10,
    actualQty: 6,
    expirationDate: '2026-06-30',
  ),
  BundleLine(
    id: 'mock-3',
    transNo: _kMockTransNo,
    productCode: 'PROD-C003',
    productName: 'サンプル商品 Gamma',
    bin: '03-C310',
    lotNo: 'LOT-2025-003',
    demandQty: 3,
    actualQty: 3,
    expirationDate: '2027-03-15',
  ),
  BundleLine(
    id: 'mock-4',
    transNo: _kMockTransNo,
    productCode: 'PROD-D004',
    productName: 'サンプル商品 Delta / 長い商品名のテスト用データ',
    bin: '04-D412',
    lotNo: 'LOT-2025-004',
    demandQty: 8,
    actualQty: 0,
    expirationDate: '2026-09-01',
  ),
];

class BundleListScreen extends StatelessWidget {
  const BundleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BundleBloc(remote: sl<BundleRemoteDataSource>()),
      child: const _BundleListView(),
    );
  }
}

class _BundleListView extends StatefulWidget {
  const _BundleListView();
  @override
  State<_BundleListView> createState() => _BundleListViewState();
}

class _BundleListViewState extends State<_BundleListView> {
  final _searchCtrl = TextEditingController();
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    final hhtInfo = sl<CacheStorage>().getString('hhtInfo') ?? '';
    context.read<BundleBloc>().add(FetchBundleLists(hhtInfo: hhtInfo));
  }

  void _backToMenu() => context.go(RouteNames.mainMenu);

  void _handleRowTap(BuildContext context, int index, BundleRow row) {
    if (row.scanStatus == 2) {
      final other = row.hhtInfoOther.split('-').first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('通知', style: TextStyle(fontFamily: AppStyles.font)),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.transNo} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: AppStyles.font),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor4),
              child: const Text('閉じる', style: TextStyle(fontFamily: AppStyles.font)),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    context.push(RouteNames.bundleItems, extra: {'transNo': row.transNo});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
          onPressed: _backToMenu,
        ),
        title: const Text('事前セット一覧', style: AppStyles.appBarTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.white, size: AppStyles.sizeTopBarIcon), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'フィルターする内容を入力してください。',
              onChanged: (v) => context.read<BundleBloc>().add(SearchBundleLists(v)),
            ),
          ),
          Expanded(child: _buildBody()),
          BackToMenuButton(color: AppColors.settingsColor4, onPressed: _backToMenu),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<BundleBloc, BundleState>(
      builder: (context, state) {
        if (state is BundleLoading) return AppLoading.centered(message: '読み込み中...');
        if (state is BundleError) return AppError.generic(message: state.message, onRetry: _loadData);
        final rows = state is BundleListsLoaded ? state.rows : <BundleRow>[];
        if (rows.isEmpty && state is BundleListsLoaded) return AppEmpty.list(message: '事前セットデータがありません');
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length + 1,
          separatorBuilder: (_, __) => const ModuleListDivider(),
          itemBuilder: (context, index) {
            // Demo tile at the end
            if (index == rows.length) {
              return _DemoTile(
                onTap: () => context.push(
                  RouteNames.bundleItems,
                  extra: {
                    'transNo': _kMockTransNo,
                    'preloadedLines': _kMockLines,
                  },
                ),
              );
            }
            final row = rows[index];
            final (Color statusColor, String statusLabel) = switch (row.scanStatus) {
              1 => (AppColors.textWarning,    '進行中'),
              2 => (AppColors.gray,           'ロック'),
              _ => (AppColors.settingsColor4, '未開始'),
            };
            return ModuleListTile(
              title: row.transNo,
              subtitle: null,
              trailingText: '',
              statusColor: statusColor,
              statusLabel: statusLabel,
              isSelected: _selectedIndex == index,
              onTap: () => _handleRowTap(context, index, row),
            );
          },
        );
      },
    );
  }
}

// ─── Demo tile ────────────────────────────────────────────────────────────────

class _DemoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _DemoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.settingsColor4, width: 3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.settingsColor4.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.settingsColor4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                _kMockTransNo,
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.blackTextColor,
                ),
              ),
            ),
            Text(
              '${_kMockLines.length} 件',
              style: const TextStyle(
                fontFamily: AppStyles.font,
                fontSize: 13,
                color: AppColors.grayTextColor,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
