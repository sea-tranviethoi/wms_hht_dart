import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/bin_movement_remote_datasource.dart';
import '../../routes/route_names.dart';
import '../blocs/bin_movement/bin_movement_bloc.dart';

/// 棚移動一覧 — BLoC version (Phase 7)
class BinMovementListScreen extends StatelessWidget {
  const BinMovementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BinMovementBloc(remote: sl<BinMovementRemoteDataSource>()),
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
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
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

  Future<void> _handleReset(BinMovementRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認'),
        content: Text('移動番号: ${row.transferNo}\nスキャンデータをリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('はい'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<BinMovementBloc>().add(ResetBinMovementStatus(row));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('棚移動一覧'),
        backgroundColor: Theme.of(context).primaryColor,
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
                  backgroundColor: Colors.red),
            );
          }
        },
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'フィルターする内容を入力してください。',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.lighter, width: 2),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.lighter, width: 2),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: AppColors.primaryLight, width: 2),
                  ),
                ),
                onChanged: (v) {
                  setState(() {});
                  _handleSearch(v);
                },
              ),
            ),

            // Table header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderTable),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppColors.borderTable),
                        ),
                      ),
                      child: const Text(
                        '移動番号',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'MSPGothic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        '移動元→先',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'MSPGothic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: BlocBuilder<BinMovementBloc, BinMovementState>(
                builder: (context, state) {
                  if (state is BinMovementLoading ||
                      state is BinMovementResetting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (state is BinMovementError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message,
                              style:
                                  const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    );
                  }

                  final rows = state is BinMovementListsLoaded
                      ? state.rows
                      : <BinMovementRow>[];

                  if (rows.isEmpty && state is BinMovementListsLoaded) {
                    return const Center(
                      child: Text(
                        '棚移動データがありません',
                        style: TextStyle(fontFamily: 'MSPGothic'),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final isSelected = _selectedIndex == index;
                      final scanStatus = row.scanStatus;

                      Color textColor = AppColors.black;
                      Widget? leadingIcon;

                      if (scanStatus == 1) {
                        textColor = AppColors.text_warning;
                        leadingIcon = IconButton(
                          icon: const Icon(Icons.refresh),
                          color: AppColors.blackText,
                          iconSize: 35,
                          onPressed: () => _handleReset(row),
                        );
                      } else if (scanStatus == 3) {
                        textColor = AppColors.text_placeholder;
                        leadingIcon = IconButton(
                          icon: const Icon(Icons.construction),
                          color: AppColors.blackText,
                          iconSize: 35,
                          onPressed: () =>
                              _handleRowTap(context, index, row),
                        );
                      }

                      return InkWell(
                        onTap: () =>
                            _handleRowTap(context, index, row),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.headerColor
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.borderTable),
                            ),
                          ),
                          child: Row(
                            children: [
                              // 移動番号 + 商品名
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                    left: scanStatus != -1 ? 0 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: AppColors.borderTable),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (scanStatus != -1)
                                        SizedBox(
                                          width: 50,
                                          child: leadingIcon ??
                                              const SizedBox(),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              row.transferNo,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 16,
                                                fontFamily: 'MSPGothic',
                                              ),
                                            ),
                                            if (row.productNames !=
                                                    null &&
                                                row.productNames!
                                                    .isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 2),
                                                child: Text(
                                                  row.productNames!
                                                              .length >
                                                          30
                                                      ? '${row.productNames!.substring(0, 30)}...'
                                                      : row.productNames!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor,
                                                    fontFamily:
                                                        'MSPGothic',
                                                  ),
                                                ),
                                              ),
                                            if (row.description !=
                                                    null &&
                                                row.description!
                                                    .isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 2),
                                                child: Text(
                                                  row.description!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor
                                                        .withValues(alpha: 0.7),
                                                    fontFamily:
                                                        'MSPGothic',
                                                    fontStyle:
                                                        FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 移動元→先
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        row.fromBin ?? '—',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontFamily: 'MSPGothic',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const Icon(Icons.arrow_downward,
                                          size: 16, color: Colors.grey),
                                      Text(
                                        row.toBin ?? '—',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontFamily: 'MSPGothic',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Back button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade400)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RouteNames.mainMenu),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btn_red,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('戻る',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
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
