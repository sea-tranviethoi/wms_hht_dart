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

/// 棚移動一覧 — BLoC version (Phase 7)
class BinMovementListScreen extends StatelessWidget {
  const BinMovementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BinMovementBloc(repository: sl<BinMovementRepository>()),
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
    context.read<BinMovementBloc>().add(FetchBinMovementLists(hhtInfo: hhtInfo));
  }

  void _handleSearch(String keyword) {
    context.read<BinMovementBloc>().add(SearchBinMovementLists(keyword));
  }

  void _handleRowTap(BuildContext context, int index, BinMovementRow row) {
    if (row.scanStatus == 3) {
      final otherUser = row.hhtInfoOther?.split('-').first ?? '他のユーザー';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notification'),
          content: Text(
            'ユーザー「$otherUser」は別デバイスで ${row.transferNo} を対応してます。ご確認ください。',
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
      RouteNames.binMovementDetail,
      extra: {
        'transferNo': row.transferNo,
        'description': row.description,
        'lines': row.lines,
      },
    );
  }

  // _handleReset removed: was triggered by status-icon button on old table
  // layout. New minimal tile only handles row tap → detail navigation.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('棚移動一覧'),
        backgroundColor: AppColors.settingsColor5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.mainMenu),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: BlocListener<BinMovementBloc, BinMovementState>(
        listener: (context, state) {
          if (state is BinMovementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.btnRed),
            );
          }
        },
        child: Column(
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
              child: BlocBuilder<BinMovementBloc, BinMovementState>(
                builder: (context, state) {
                  if (state is BinMovementLoading ||
                      state is BinMovementResetting) {
                    return AppLoading.centered(message: '読み込み中...');
                  }

                  if (state is BinMovementError) {
                    return AppError.generic(
                      message: state.message,
                      onRetry: _loadData,
                    );
                  }

                  final rows = state is BinMovementListsLoaded
                      ? state.rows
                      : <BinMovementRow>[];

                  if (rows.isEmpty && state is BinMovementListsLoaded) {
                    return AppEmpty.list(message: '棚移動データがありません');
                  }

                  return Container(
                    color: AppColors.white,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const ModuleListDivider(),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final isSelected = _selectedIndex == index;

                        final (Color statusColor, String statusLabel) =
                            switch (row.scanStatus) {
                          1 => (AppColors.textWarning,    '進行中'),
                          3 => (AppColors.gray,           'ロック'),
                          _ => (AppColors.settingsColor5, '未開始'),
                        };

                        final from = row.fromBin ?? '—';
                        final to = row.toBin ?? '—';
                        final names = (row.productNames ?? '').isEmpty
                            ? null
                            : (row.productNames!.length > 30
                                ? '${row.productNames!.substring(0, 30)}…'
                                : row.productNames!);

                        return ModuleListTile(
                          title: row.transferNo,
                          subtitle: names,
                          trailingText: '$from → $to',
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

            // Back button — module color (BinMove = Cyan)
            BackToMenuButton(
              color: AppColors.settingsColor5,
              onPressed: () => context.go(RouteNames.mainMenu),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
