import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../routes/route_names.dart';
import '../blocs/bundle/bundle_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/module_list_tile.dart';

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
          title: const Text('通知', style: TextStyle(fontFamily: 'MSPGothic')),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.transNo} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: 'MSPGothic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor4),
              child: const Text('閉じる', style: TextStyle(fontFamily: 'MSPGothic')),
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
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _backToMenu,
        ),
        title: const Text(
          '事前セット一覧',
          style: TextStyle(fontFamily: 'MSPGothic', color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.white), onPressed: _loadData),
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
          itemCount: rows.length,
          separatorBuilder: (_, __) => const ModuleListDivider(),
          itemBuilder: (context, index) {
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
