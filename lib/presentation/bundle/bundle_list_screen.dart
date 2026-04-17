import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../routes/route_names.dart';
import '../blocs/bundle/bundle_bloc.dart';

/// 事前セット一覧 — BLoC version (Phase 6)
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
    context.read<BundleBloc>().add(FetchBundleLists(hhtInfo: hhtInfo));
  }

  void _handleSearch(String keyword) {
    context.read<BundleBloc>().add(SearchBundleLists(keyword));
  }

  void _handleRowTap(BuildContext context, int index, BundleRow row) {
    if (row.scanStatus == 2) {
      final otherUser = row.hhtInfoOther.split('-').first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notification'),
          content: Text(
            'ユーザー「$otherUser」は別デバイスで ${row.transNo} を対応してます。ご確認ください。',
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
      RouteNames.bundleItems,
      extra: {'transNo': row.transNo},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事前セット一覧'),
        backgroundColor: Theme.of(context).primaryColor,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
                  borderSide: BorderSide(color: AppColors.lighter, width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.lighter, width: 2),
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
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.borderTable),
                      ),
                    ),
                    child: const Text(
                      '事前セット',
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
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      '明細数',
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

          // Bundle list
          Expanded(
            child: BlocBuilder<BundleBloc, BundleState>(
              builder: (context, state) {
                if (state is BundleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BundleError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  );
                }

                final rows = state is BundleListsLoaded
                    ? state.rows
                    : <BundleRow>[];

                if (rows.isEmpty && state is BundleListsLoaded) {
                  return const Center(
                    child: Text(
                      '事前セットデータがありません',
                      style: TextStyle(fontFamily: 'MSPGothic'),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final isSelected = _selectedIndex == index;

                    Color textColor = AppColors.black;
                    Widget? leadingIcon;

                    if (row.scanStatus == 1) {
                      textColor = AppColors.text_warning;
                      leadingIcon = const Icon(Icons.refresh,
                          color: AppColors.blackText, size: 35);
                    } else if (row.scanStatus == 2) {
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
                      onTap: () => _handleRowTap(context, index, row),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.headerColor
                              : Colors.white,
                          border: Border(
                            bottom:
                                BorderSide(color: AppColors.borderTable),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: row.scanStatus != 0 ? 0 : 8,
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
                                    if (row.scanStatus != 0)
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
                                            row.transNo,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              fontFamily: 'MSPGothic',
                                            ),
                                          ),
                                          if (row.productName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2),
                                              child: Text(
                                                row.productName.length > 25
                                                    ? '${row.productName.substring(0, 25)}...'
                                                    : row.productName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: textColor,
                                                  fontFamily: 'MSPGothic',
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
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                child: Text(
                                  row.countLine.toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontFamily: 'MSPGothic',
                                  ),
                                  textAlign: TextAlign.center,
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
              border: Border(top: BorderSide(color: Colors.grey.shade400)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(RouteNames.mainMenu),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btn_red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('戻る', style: TextStyle(fontSize: 16)),
              ),
            ),
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
