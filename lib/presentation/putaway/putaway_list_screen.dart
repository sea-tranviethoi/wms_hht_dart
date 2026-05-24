import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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
import '../widgets/module_list_tile.dart';

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
    context.read<PutawayBloc>().add(FetchPutawayLists(hhtInfo: hhtInfo));
  }

  void _backToMenu() => context.go(RouteNames.mainMenu);

  void _handleRowTap(BuildContext context, int index, PutawayRow row) {
    if (row.scanStatus == 3) {
      final other = row.hhtInfoOther.split('-').first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('通知', style: TextStyle(fontFamily: AppTextStyles.font)),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.productCode} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: AppTextStyles.font),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor2),
              child: const Text('閉じる', style: TextStyle(fontFamily: AppTextStyles.font)),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    context.push(RouteNames.putawayDetail, extra: {
      'productCode': row.productCode,
      'productName': row.productName,
      'lines': row.lines,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon),
          onPressed: _backToMenu,
        ),
        title: const Text('棚上げ一覧', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'フィルターする内容を入力してください。',
              onChanged: (v) => context.read<PutawayBloc>().add(SearchPutawayLists(v)),
            ),
          ),
          Expanded(child: _buildBody()),
          BackToMenuButton(color: AppColors.settingsColor2, onPressed: _backToMenu),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<PutawayBloc, PutawayState>(
      builder: (context, state) {
        if (state is PutawayLoading) return AppLoading.centered(message: '読み込み中...');
        if (state is PutawayError) return AppError.generic(message: state.message, onRetry: _loadData);
        final rows = state is PutawayListsLoaded ? state.rows : <PutawayRow>[];
        if (rows.isEmpty && state is PutawayListsLoaded) return AppEmpty.list(message: '棚上げデータがありません');
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const ModuleListDivider(),
          itemBuilder: (context, index) {
            final row = rows[index];
            final (Color statusColor, String statusLabel) = switch (row.scanStatus) {
              1 => (AppColors.textWarning,    '進行中'),
              3 => (AppColors.gray,           'ロック'),
              _ => (AppColors.settingsColor2, '未開始'),
            };
            return ModuleListTile(
              title: row.productCode,
              subtitle: row.productName.isNotEmpty ? row.productName : null,
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
