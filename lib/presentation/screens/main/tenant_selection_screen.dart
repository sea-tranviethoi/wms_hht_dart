import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../blocs/master/master_bloc.dart';
import '../../../data/models/tenant.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../routes/route_names.dart';

/// Port từ screens/TenantSelection.js
///
/// Hiển thị danh sách tenant để chọn trước khi vào module.
/// funcNumber xác định module sẽ navigate sau khi chọn:
///   "1" → Warehouse Receipt list
///   "3" → Picking list
///   (others) → Warehouse Receipt list (default)
class TenantSelectionScreen extends StatelessWidget {
  final String? funcNumber;

  const TenantSelectionScreen({super.key, this.funcNumber});

  String get _title {
    switch (funcNumber) {
      case '3': return 'ピッキング — テナント選択';
      default:  return '入荷 — テナント選択';
    }
  }

  Color get _moduleColor {
    switch (funcNumber) {
      case '3': return AppColors.settingsColor3; // Picking  — Amber
      default:  return AppColors.settingsColor1; // WR       — Steel Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MasterBloc(repository: sl())..add(FetchTenants()),
      child: _TenantSelectionView(
        funcNumber: funcNumber,
        title: _title,
        moduleColor: _moduleColor,
      ),
    );
  }
}

class _TenantSelectionView extends StatefulWidget {
  final String? funcNumber;
  final String title;
  final Color moduleColor;

  const _TenantSelectionView({
    required this.funcNumber,
    required this.title,
    required this.moduleColor,
  });

  @override
  State<_TenantSelectionView> createState() => _TenantSelectionViewState();
}

class _TenantSelectionViewState extends State<_TenantSelectionView> {
  final _searchCtrl = TextEditingController();
  List<Tenant> _allTenants = [];
  List<Tenant> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final kw = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = kw.isEmpty
          ? _allTenants
          : _allTenants
              .where((t) => t.tenantFullName.toLowerCase().contains(kw))
              .toList();
    });
  }

  void _onTenantTap(Tenant tenant) {
    final company = Uri.encodeComponent(tenant.tenantFullName);
    if (widget.funcNumber == '3') {
      context.push(
        '${RouteNames.pickingList}?tenantId=${tenant.tenantId}&company=$company',
      );
    } else {
      context.push(
        '${RouteNames.warehouseReceiptList}?tenantId=${tenant.tenantId}&company=$company',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: widget.moduleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon),
          onPressed: () => context.go(RouteNames.mainMenu),
        ),
        title: Text(widget.title, style: AppTextStyles.appBarTitle),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          // Tenant list
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(
          fontFamily: AppTextStyles.font,
          fontSize: AppTextStyles.sizeInput,
          color: AppColors.blackTextColor,
        ),
        decoration: InputDecoration(
          hintText: 'テナントを検索...',
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.font,
            color: AppColors.gray,
            fontSize: AppTextStyles.sizeHint,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray, size: AppTextStyles.sizeSearchIcon),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.gray, size: AppTextStyles.sizeSearchClearIcon),
                  onPressed: () { _searchCtrl.clear(); },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 0),
                )
              : null,
          filled: true,
          fillColor: AppColors.ghostWhiteColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<MasterBloc, MasterState>(
      listener: (context, state) {
        if (state is TenantsLoaded) {
          setState(() {
            _allTenants = state.tenants;
            _filtered = state.tenants;
          });
        }
      },
      builder: (context, state) {
        if (state is MasterLoading) {
          return Center(
            child: CircularProgressIndicator(color: widget.moduleColor),
          );
        }
        if (state is MasterError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textError, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(fontFamily: AppTextStyles.font, color: AppColors.textError),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<MasterBloc>().add(FetchTenants()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.moduleColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('再試行', style: TextStyle(fontFamily: AppTextStyles.font)),
                ),
              ],
            ),
          );
        }
        if (_filtered.isEmpty && state is! MasterLoading) {
          return const Center(
            child: Text(
              'テナントが見つかりません',
              style: TextStyle(fontFamily: AppTextStyles.font, color: AppColors.gray),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            final tenant = _filtered[index];
            return _TenantTile(
              tenant: tenant,
              index: index,
              color: widget.moduleColor,
              onTap: () => _onTenantTap(tenant),
            );
          },
        );
      },
    );
  }
}

class _TenantTile extends StatelessWidget {
  final Tenant tenant;
  final int index;
  final Color color;
  final VoidCallback onTap;

  const _TenantTile({
    required this.tenant,
    required this.index,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(18),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}. ${tenant.tenantFullName}',
              style: TextStyle(
                fontFamily: AppTextStyles.font,
                color: AppColors.onColor(color),
                fontSize: AppTextStyles.sizeAppBar,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
