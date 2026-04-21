import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/bin_audit_repository.dart';
import '../../routes/route_names.dart';
import '../blocs/bin_audit/bin_audit_bloc.dart';

/// 棚卸一覧 — BLoC version (Phase 8)
class BinAuditListScreen extends StatelessWidget {
  const BinAuditListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BinAuditBloc(repository: sl<BinAuditRepository>())
        ..add(FetchBinAuditList()),
      child: const _BinAuditListView(),
    );
  }
}

class _BinAuditListView extends StatefulWidget {
  const _BinAuditListView();

  @override
  State<_BinAuditListView> createState() => _BinAuditListViewState();
}

class _BinAuditListViewState extends State<_BinAuditListView> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedIndex;

  static final _dateFormat = DateFormat('yyyy/MM/dd');

  void _handleSearch(String keyword) {
    context.read<BinAuditBloc>().add(SearchBinAuditList(keyword));
  }

  void _handleRowTap(int index, BinAuditRow row) {
    setState(() => _selectedIndex = index);
    context.push(
      RouteNames.binAuditDetail,
      extra: {
        'id': row.id,
        'stockTakeNo': row.stockTakeNo,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('棚卸一覧'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.mainMenu),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<BinAuditBloc>().add(FetchBinAuditList()),
          ),
        ],
      ),
      body: BlocListener<BinAuditBloc, BinAuditState>(
        listener: (context, state) {
          if (state is BinAuditError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────
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

            // ── Table header ──────────────────────────────────
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
                        '棚卸No',
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
                        '担当者',
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

            // ── List ─────────────────────────────────────────
            Expanded(
              child: BlocBuilder<BinAuditBloc, BinAuditState>(
                builder: (context, state) {
                  if (state is BinAuditLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is BinAuditError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<BinAuditBloc>()
                                .add(FetchBinAuditList()),
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    );
                  }

                  final rows = state is BinAuditListLoaded
                      ? state.rows
                      : <BinAuditRow>[];

                  if (rows.isEmpty && state is BinAuditListLoaded) {
                    return const Center(
                      child: Text(
                        '棚卸データがありません',
                        style: TextStyle(fontFamily: 'MSPGothic'),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final isSelected = _selectedIndex == index;

                      // Color based on status
                      Color textColor;
                      if (row.isPending) {
                        textColor = AppColors.text_warning; // orange
                      } else if (row.isDone) {
                        textColor = AppColors.text_placeholder; // grey
                      } else {
                        textColor = AppColors.black;
                      }

                      final dateStr = row.transactionDate != null
                          ? _dateFormat.format(row.transactionDate!)
                          : null;
                      final recStr = row.recordNo != null
                          ? '#${row.recordNo}'
                          : null;

                      return InkWell(
                        onTap: () => _handleRowTap(index, row),
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
                              // ── 棚卸No + recordNo + date ──
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: AppColors.borderTable),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.stockTakeNo,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'MSPGothic',
                                        ),
                                      ),
                                      if (recStr != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2),
                                          child: Text(
                                            recStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textColor,
                                              fontFamily: 'MSPGothic',
                                            ),
                                          ),
                                        ),
                                      if (dateStr != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2),
                                          child: Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textColor
                                                  .withValues(alpha: 0.7),
                                              fontFamily: 'MSPGothic',
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // ── 担当者 + 場所 ─────────────
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.personInCharge ?? '—',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontFamily: 'MSPGothic',
                                        ),
                                      ),
                                      if (row.location != null &&
                                          row.location!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2),
                                          child: Text(
                                            row.location!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textColor
                                                  .withValues(alpha: 0.7),
                                              fontFamily: 'MSPGothic',
                                            ),
                                          ),
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

            // ── Back button ───────────────────────────────────
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
