import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/repositories/bin_movement_repository.dart';
import '../../routes/route_names.dart';
import '../blocs/bin_movement/bin_movement_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/module_list_tile.dart';

class BinMovementListScreen extends StatelessWidget {
  const BinMovementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BinMovementBloc(repository: sl<BinMovementRepository>()),
      child: const _BinMovementListView(),
    );
  }
}

class _BinMovementListView extends StatefulWidget {
  const _BinMovementListView();
  @override
  State<_BinMovementListView> createState() => _BinMovementListViewState();
}

class _BinMovementListViewState extends State<_BinMovementListView> {
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
    context.read<BinMovementBloc>().add(FetchBinMovementLists(hhtInfo: hhtInfo));
  }

  void _backToMenu() => context.go(RouteNames.mainMenu);

  void _handleRowTap(BuildContext context, int index, BinMovementRow row) {
    if (row.scanStatus == 3) {
      final other = row.hhtInfoOther?.split('-').first ?? '他のユーザー';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('通知', style: TextStyle(fontFamily: 'MSPGothic')),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.transferNo} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: 'MSPGothic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor5),
              child: const Text('閉じる', style: TextStyle(fontFamily: 'MSPGothic')),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    context.push(RouteNames.binMovementDetail, extra: {
      'transferNo': row.transferNo,
      'description': row.description,
      'lines': row.lines,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _backToMenu,
        ),
        title: const Text(
          '棚移動一覧',
          style: TextStyle(fontFamily: 'MSPGothic', color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          BlocBuilder<BinMovementBloc, BinMovementState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white),
              onPressed: (state is BinMovementLoading || state is BinMovementResetting) ? null : _loadData,
            ),
          ),
        ],
      ),
      body: BlocListener<BinMovementBloc, BinMovementState>(
        listener: (context, state) {
          if (state is BinMovementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.btnRed),
            );
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: AppSearchBar(
                controller: _searchCtrl,
                hintText: 'フィルターする内容を入力してください。',
                onChanged: (v) => context.read<BinMovementBloc>().add(SearchBinMovementLists(v)),
              ),
            ),
            Expanded(child: _buildBody()),
            BackToMenuButton(color: AppColors.settingsColor5, onPressed: _backToMenu),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<BinMovementBloc, BinMovementState>(
      builder: (context, state) {
        if (state is BinMovementLoading || state is BinMovementResetting) {
          return AppLoading.centered(message: '読み込み中...');
        }
        if (state is BinMovementError) {
          return AppError.generic(message: state.message, onRetry: _loadData);
        }
        final rows = state is BinMovementListsLoaded ? state.rows : <BinMovementRow>[];
        if (rows.isEmpty && state is BinMovementListsLoaded) return AppEmpty.list(message: '棚移動データがありません');
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const ModuleListDivider(),
          itemBuilder: (context, index) {
            final row = rows[index];
            final (Color statusColor, String statusLabel) = switch (row.scanStatus) {
              1 => (AppColors.textWarning,    '進行中'),
              3 => (AppColors.gray,           'ロック'),
              _ => (AppColors.settingsColor5, '未開始'),
            };
            return ModuleListTile(
              title: row.transferNo,
              subtitle: (row.description != null && row.description!.isNotEmpty) ? row.description : null,
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
