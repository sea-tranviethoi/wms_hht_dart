import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/bin_audit_repository.dart';
import '../../routes/route_names.dart';
import '../blocs/bin_audit/bin_audit_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/module_list_tile.dart';

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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('棚卸一覧'),
        backgroundColor: AppColors.settingsColor6,
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
                backgroundColor: AppColors.btnRed,
              ),
            );
          }
        },
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'フィルターする内容を入力してください。',
                onChanged: _handleSearch,
              ),
            ),

            // ── List ─────────────────────────────────────────
            Expanded(
              child: BlocBuilder<BinAuditBloc, BinAuditState>(
                builder: (context, state) {
                  if (state is BinAuditLoading) {
                    return AppLoading.centered(message: '読み込み中...');
                  }

                  if (state is BinAuditError) {
                    return AppError.generic(
                      message: state.message,
                      onRetry: () => context
                          .read<BinAuditBloc>()
                          .add(FetchBinAuditList()),
                    );
                  }

                  final rows = state is BinAuditListLoaded
                      ? state.rows
                      : <BinAuditRow>[];

                  if (rows.isEmpty && state is BinAuditListLoaded) {
                    return AppEmpty.list(message: '棚卸データがありません');
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
                            row.isDone
                                ? (AppColors.btnGreen, '完了')
                                : row.isPending
                                    ? (AppColors.textWarning, '進行中')
                                    : (AppColors.settingsColor6, '未開始');

                        // Subtitle: 担当者 + (場所)
                        final pic = row.personInCharge ?? '—';
                        final loc = row.location;
                        final subtitle = loc != null && loc.isNotEmpty
                            ? '$pic · $loc'
                            : pic;

                        // Trailing: ngày + #recNo
                        final dateStr = row.transactionDate != null
                            ? _dateFormat.format(row.transactionDate!)
                            : '—';

                        return ModuleListTile(
                          title: row.stockTakeNo,
                          subtitle: subtitle,
                          trailingText: dateStr,
                          statusColor: statusColor,
                          statusLabel: statusLabel,
                          isSelected: isSelected,
                          onTap: () => _handleRowTap(index, row),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Back button — module color (BinAudit = Emerald)
            BackToMenuButton(
              color: AppColors.settingsColor6,
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
